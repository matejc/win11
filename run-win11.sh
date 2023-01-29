#!/usr/bin/env bash

set -e

MEMORY_QEMU="${MEMORY_QEMU:-"12G"}"
SMP_QEMU="${SMP_QEMU:-"12,sockets=1,cores=6,threads=2"}"
EXTRA_QEMU_ARGS="${EXTRA_QEMU_ARGS:-""}"
STATE_DIR="$PWD/state"
WIN11_ISO="${WIN11_ISO:-"$HOME/Downloads/Win11_22H2_English_x64v1.iso"}"
VIRTIO_WIN_ISO="${VIRTIO_WIN_ISO:-"$HOME/Downloads/virtio-win-0.1.229.iso"}"
FLOPPY_DIR="${FLOPPY_DIR:-$PWD/floppy}"
VIDEO="$1"

mkdir -p "$STATE_DIR"

function _killtpm() {
    pkill swtpm || true
}

trap _killtpm EXIT

mkdir -p "$STATE_DIR/emulated_tpm"

if [ -d /dev/hugepages ]
then
    test -d /dev/hugepages/win11 || sudo mkdir -p /dev/hugepages/win11
    test -w /dev/hugepages/win11 || sudo chown -R "$USER" /dev/hugepages/win11
    EXTRA_QEMU_ARGS="$EXTRA_QEMU_ARGS -mem-prealloc -mem-path /dev/hugepages/win11";
fi

mkdir -p "$STATE_DIR/FV"
test -f "$STATE_DIR/FV/OVMF_VARS.fd" || { cp -f "${OVMF_DIR}"/FV/* "$STATE_DIR/FV/" && chmod +w "$STATE_DIR/FV/OVMF_VARS.fd"; }

test -f "$STATE_DIR/windows_11.qcow2" || qemu-img create -f qcow2 "$STATE_DIR/windows_11.qcow2" 100G

mkdir -p "$STATE_DIR/shared"

swtpm socket --tpmstate dir="$STATE_DIR/emulated_tpm" --ctrl type=unixio,path="$STATE_DIR/emulated_tpm/swtpm-sock" --log level=1 --tpm2 &

if [[ "$VIDEO" == "looking-glass" ]]
then
    EXTRA_QEMU_ARGS="$EXTRA_QEMU_ARGS -spice unix=on,addr=$STATE_DIR/spice.sock,disable-ticketing=on -device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent"
    EXTRA_QEMU_ARGS="$EXTRA_QEMU_ARGS -device ivshmem-plain,memdev=ivshmem,bus=pcie.0 -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=64M"
    if [ -e /dev/shm/looking-glass ] && [ ! -w /dev/shm/looking-glass ]
    then
        sudo chown "$USER" /dev/shm/looking-glass
    fi
    { sleep 5; looking-glass-client input:mouseRedraw=yes input:autoCapture=yes input:rawMouse=yes input:escapeKey=KEY_F11 -p 0 -c "$STATE_DIR/spice.sock"; } &
else
    EXTRA_QEMU_ARGS="$EXTRA_QEMU_ARGS -usb -device usb-tablet"
fi

qemu-kvm \
    -m "$MEMORY_QEMU" \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -machine type=q35,accel=kvm,kernel_irqchip=on,smm=on \
    -cpu host,kvm=off,hv_relaxed,hv_vapic,hv_time,hv_spinlocks=0x1fff \
    -smp "$SMP_QEMU" \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file="$STATE_DIR/FV/OVMF_CODE.fd",readonly=on \
    -drive if=pflash,format=raw,unit=1,file="$STATE_DIR/FV/OVMF_VARS.fd" \
    -chardev socket,id=chrtpm,path="$STATE_DIR/emulated_tpm/swtpm-sock" \
    -tpmdev emulator,id=tpm-1,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm-1 \
    -drive file="$STATE_DIR/windows_11.qcow2",if=virtio,aio=native,cache.direct=on,format=qcow2,index=1 \
    -drive file="$WIN11_ISO",media=cdrom,index=2 \
    -drive file="$VIRTIO_WIN_ISO",media=cdrom,index=3 \
    -netdev user,id=user.0,smb="$STATE_DIR/shared" \
    -device virtio-net,netdev=user.0 \
    -fda fat:floppy:rw:"$FLOPPY_DIR" \
    -vga qxl $EXTRA_QEMU_ARGS
