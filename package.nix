{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "flutter-starter";
  version = "1.0.0";

  src = builtins.path {
    name = "flutter-starter-bundle";
    path = ./build/linux/x64/release/bundle;
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  buildInputs = [
    pkgs.glib
    pkgs.gtk3
    pkgs.pango
    pkgs.cairo
    pkgs.atk
    pkgs.gdk-pixbuf
    pkgs.libepoxy
    pkgs.libsecret

    pkgs.libx11
    pkgs.libxext
    pkgs.libxcursor
    pkgs.libxi
    pkgs.libxrandr
    pkgs.libxinerama
  ];

  installPhase = ''
    mkdir -p $out/lib/flutter-starter
    cp -r ./* $out/lib/flutter-starter/

    mkdir -p $out/bin
    ln -s $out/lib/flutter-starter/flutter_starter \
      $out/bin/flutter-starter
  '';
}