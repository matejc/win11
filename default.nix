{ pkgs ? import <nixpkgs> { } }:
let
  ovmf_fd = (pkgs.OVMF.override { secureBoot = true; tpmSupport = true; }).fd;
  qemu_kvm = pkgs.qemu_kvm.override { smbdSupport = true; };
  looking-glass-client = pkgs.looking-glass-client.overrideDerivation (old: {
    name = "looking-glass-client-B6";
    src = pkgs.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "B6";
      sha256 = "sha256-6vYbNmNJBCoU23nVculac24tHqH7F4AZVftIjL93WJU=";
      fetchSubmodules = true;
    };
    buildInputs = old.buildInputs ++ [ pkgs.pipewire.dev pkgs.pulseaudio.dev pkgs.libsamplerate.dev ];
  });
in
pkgs.stdenv.mkDerivation {
  name = "win11-env";
  buildInputs = [ qemu_kvm pkgs.swtpm looking-glass-client pkgs.spice-gtk ];
  OVMF_DIR = "${ovmf_fd}";

  shellHook = ''
    echo "Run: ./run-win11.sh [looking-glass]"
  '';
}
