# win11

This project is an example of (almost) unattended installation of Windows 11 in the virtual machine.

It is not completely unattended, since on first run you have to press any key to start the installation. And besides, at the last boot in installation process you need to power off the machine yourself.

Project inspired by [packer-windows](https://github.com/joefitzgerald/packer-windows), just without `packer`, only for `Windows 11` and Qemu/KVM.

Features:
- Qemu/KVM, you need to have KVM enabled on system
- Virtual TPM2 device
- Secure boot enabled

## Usage

Run as regular user! It will ask for sudo when needed.

```
$ nix-shell . --run "./run-win11.sh"
```

### Looking glass

After you manually install it and configure it in the guest Windows 11, then start the virtual machine like so:

```
$ nix-shell . --run "./run-win11.sh looking-glass"
```

### Kernel parameters

This is my example, please do not use ones that you have no idea what they do. Not all are required for this to work well.

```
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "default_hugepagesz=1G"
    "hugepagesz=1G"
    "hugepages=20"
    "i915.enable_hd_vgaarb=1"
    "vfio_iommu_type1.allow_unsafe_interrupts=1"
    "kvm.allow_unsafe_assigned_interrupts=1"
    "kvm.ignore_msrs=1"
  ];
```
