#!/usr/bin/env bash

{ sleep 5; looking-glass-client input:mouseRedraw=yes input:autoCapture=yes input:rawMouse=yes input:escapeKey=KEY_F11 -g OpenGL -p 0 -c ./spice.sock; } &

qemu-kvm \
    -m 12G \
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
    -device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent \
    -spice unix=on,addr=./spice.sock,disable-ticketing=on

#[]string{"-cpu", "host,kvm=off,hv_relaxed,hv_vapic,hv_time,hv_spinlocks=0x1fff", "-drive", "if=pflash,format=raw,unit=0,file=./FV/OVMF_CODE.fd,readonly=on", "-drive", "if=pflash,format=raw,unit=1,file=./FV/OVMF_VARS.fd", "-drive", "file=windows_11-qemu/windows_11,if=virtio,aio=native,cache.direct=on,format=qcow2,index=1", "-drive", "file=/home/matejc/Downloads/Win11_22H2_English_x64v1.iso,media=cdrom,index=2", "-drive", "file=/home/matejc/Downloads/virtio-win-0.1.229.iso,media=cdrom,index=3", "-netdev", "user,id=user.0,hostfwd=tcp::3930-:5985", "-boot", "once=d", "-vga", "virtio", "-display", "gtk", "-object", "rng-random,filename=/dev/urandom,id=rng0", "-smp", "12,sockets=1,cores=6,threads=2", "-fda", "/tmp/packer2097629322", "-m", "8192M", "-device", "virtio-rng-pci,rng=rng0", "-device", "nec-usb-xhci,id=xhci", "-device", "usb-tablet,bus=xhci.0", "-device", "tpm-tis,tpmdev=tpm-1", "-device", "virtio-net,netdev=user.0", "-machine", "type=q35,accel=kvm,kernel_irqchip=on,smm=on", "-global", "driver=cfi.pflash01,property=secure,value=on", "-chardev", "socket,id=chrtpm,path=./emulated_tpm/swtpm-sock", "-tpmdev", "emulator,id=tpm-1,chardev=chrtpm", "-name", "windows_11", "-vnc", "127.0.0.1:49"}
#/usr/bin/qemu-system-x86_64 -name guest=w10,debug-threads=on -S -object {"qom-type":"secret","id":"masterKey0","format":"raw","file":"/var/lib/libvirt/qemu/domain-12-w10/master-key.aes"} -blockdev {"driver":"file","filename":"/usr/share/OVMF/OVMF_CODE_4M.ms.fd","node-name":"libvirt-pflash0-storage","auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-pflash0-format","read-only":true,"driver":"raw","file":"libvirt-pflash0-storage"} -blockdev {"driver":"file","filename":"/var/lib/libvirt/qemu/nvram/w10_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"} -machine pc-q35-6.0,accel=kvm,usb=off,vmport=off,dump-guest-core=off,pflash0=libvirt-pflash0-format,pflash1=libvirt-pflash1-format,memory-backend=pc.ram -cpu Skylake-Client-IBRS,ss=on,vmx=on,pdcm=on,hypervisor=on,tsc-adjust=on,clflushopt=on,umip=on,md-clear=on,stibp=on,arch-capabilities=on,ssbd=on,xsaves=on,pdpe1gb=on,ibpb=on,ibrs=on,amd-stibp=on,amd-ssbd=on,skip-l1dfl-vmentry=on,pschange-mc-no=on,hv-time,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff -m 10240 -object {"qom-type":"memory-backend-ram","id":"pc.ram","size":10737418240} -overcommit mem-lock=off -smp 4,sockets=1,dies=1,cores=2,threads=2 -uuid 79a5c172-4b7f-4992-a3a8-3099ba795480 -no-user-config -nodefaults -chardev socket,id=charmonitor,fd=33,server=on,wait=off -mon chardev=charmonitor,id=monitor,mode=control -rtc base=localtime,driftfix=slew -global kvm-pit.lost_tick_policy=delay -no-hpet -no-shutdown -global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1 -boot strict=on -device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x2 -device pcie-root-port,port=0x11,chassis=2,id=pci.2,bus=pcie.0,addr=0x2.0x1 -device pcie-root-port,port=0x12,chassis=3,id=pci.3,bus=pcie.0,addr=0x2.0x2 -device pcie-root-port,port=0x13,chassis=4,id=pci.4,bus=pcie.0,addr=0x2.0x3 -device pcie-root-port,port=0x14,chassis=5,id=pci.5,bus=pcie.0,addr=0x2.0x4 -device pcie-root-port,port=0x15,chassis=6,id=pci.6,bus=pcie.0,addr=0x2.0x5 -device pcie-pci-bridge,id=pci.7,bus=pci.1,addr=0x0 -device pcie-root-port,port=0x16,chassis=8,id=pci.8,bus=pcie.0,addr=0x2.0x6 -device qemu-xhci,p2=15,p3=15,id=usb,bus=pci.3,addr=0x0 -device virtio-serial-pci,id=virtio-serial0,bus=pci.4,addr=0x0 -blockdev {"driver":"file","filename":"/var/lib/libvirt/images/w10.qcow2","node-name":"libvirt-3-storage","auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-3-format","read-only":false,"driver":"qcow2","file":"libvirt-3-storage","backing":null} -device virtio-blk-pci,bus=pci.5,addr=0x0,drive=libvirt-3-format,id=virtio-disk0,bootindex=1 -device ide-cd,bus=ide.0,share-rw=on,id=sata0-0-0,bootindex=2 -device ide-cd,bus=ide.1,share-rw=on,id=sata0-0-1,bootindex=3 -netdev tap,fd=35,id=hostnet0,vhost=on,vhostfd=36 -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:54:00:70:33:62,bus=pci.2,addr=0x0 -chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0 -chardev spicevmc,id=charchannel0,name=vdagent -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=com.redhat.spice.0 -device usb-tablet,id=input0,bus=usb.0,port=1 -audiodev id=audio1,driver=spice -spice port=5900,addr=127.0.0.1,disable-ticketing=on,image-compression=off,seamless-migration=on -device qxl-vga,id=video0,ram_size=67108864,vram_size=67108864,vram64_size_mb=0,vgamem_mb=16,max_outputs=1,bus=pcie.0,addr=0x1 -device ich9-intel-hda,id=sound0,bus=pcie.0,addr=0x1b -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0,audiodev=audio1 -chardev spicevmc,id=charredir0,name=usbredir -device usb-redir,chardev=charredir0,id=redir0,bus=usb.0,port=2 -chardev spicevmc,id=charredir1,name=usbredir -device usb-redir,chardev=charredir1,id=redir1,bus=usb.0,port=3 -device virtio-balloon-pci,id=balloon0,bus=pci.6,addr=0x0 -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny -msg timestamp=on