#!/usr/bin/env bash

{ sleep 5; looking-glass-client input:mouseRedraw=yes input:autoCapture=yes input:rawMouse=yes input:escapeKey=KEY_F11 -p 0 -c ./spice.sock; } &

qemu-kvm \
    -m 12G \
    -mem-prealloc -mem-path /dev/hugepages/win11 \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -machine type=q35,accel=kvm,kernel_irqchip=on,smm=on \
    -cpu host,kvm=off,hv_relaxed,hv_vapic,hv_time,hv_spinlocks=0x1fff \
    -smp 12,sockets=1,cores=6,threads=2 \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file=./FV/OVMF_CODE.fd,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=./FV/OVMF_VARS.fd \
    -chardev socket,id=chrtpm,path=./emulated_tpm/swtpm-sock \
    -tpmdev emulator,id=tpm-1,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm-1 \
    -drive file=./windows_11.qcow2,if=virtio,aio=native,cache.direct=on,format=qcow2,index=1 \
    -drive file=~/Downloads/Win11_22H2_English_x64v1.iso,media=cdrom,index=2 \
    -drive file=~/Downloads/virtio-win-0.1.229.iso,media=cdrom,index=3 \
    -netdev user,id=user.0,hostfwd=tcp::3389-:3389,smb=./shared/ \
    -device virtio-net,netdev=user.0 \
    -device ivshmem-plain,memdev=ivshmem,bus=pcie.0 \
    -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=64M \
    -fda fat:floppy:rw:./floppy \
    -vga qxl \
    -device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent \
    -spice unix=on,addr=./spice.sock,disable-ticketing=on
