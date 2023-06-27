{ pkgs ? import <nixpkgs> { } }:
let
  ovmf_fd = (pkgs.OVMF.override { secureBoot = true; tpmSupport = true; }).fd;
  qemu_kvm = pkgs.qemu_kvm.override { smbdSupport = true; };
in
pkgs.stdenv.mkDerivation rec {
  name = "win11-env";
  buildInputs = [ pkgs.makeWrapper pkgs.looking-glass-client qemu_kvm pkgs.swtpm ];
  OVMF_DIR = "${ovmf_fd}";
  src = {
    outPath = ./run-win11.sh;
  };

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/run
    wrapProgram $out/bin/run \
      --set OVMF_DIR "${ovmf_fd}" \
      --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}
  '';

  shellHook = ''
    echo "Run: ./run-win11.sh [looking-glass]"
  '';
}
