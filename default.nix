{ pkgs ? import <nixpkgs> { } }:
let
  ovmf_fd = (pkgs.OVMF.override { secureBoot = true; tpmSupport = true; }).fd;
  qemu_kvm = pkgs.qemu_kvm.override { smbdSupport = true; };
in
pkgs.stdenv.mkDerivation {
  name = "win11-env";
  buildInputs = [ qemu_kvm pkgs.swtpm pkgs.looking-glass-client ];
  shellHook = ''
    set -e

    function _killtpm() {
      pkill swtpm || true
    }

    function cleanall() {
      rm ./FV/OVMF_VARS.fd || true
      rm ./emulated_tpm/tpm2-00.permall || true
      rm ./emulated_tpm/.lock || true
    }

    trap _killtpm EXIT

    mkdir -p ./emulated_tpm
    swtpm socket --tpmstate dir=./emulated_tpm --ctrl type=unixio,path=./emulated_tpm/swtpm-sock --log level=1 --tpm2 &

    mkdir -p FV
    test -f ./FV/OVMF_VARS.fd || cp -f ${ovmf_fd}/FV/* ./FV/ && chmod +w ./FV/OVMF_VARS.fd

    test -f ./windows_11.qcow2 || qemu-img create -f qcow2 ./windows_11.qcow2 100G

    mkdir -p ./shared

    echo Run: ./run-win11.sh
  '';
}
