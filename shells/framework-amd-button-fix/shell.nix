{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    name = "clear-fprint-shell";
    nativeBuildInputs = [
      pkgs.gobject-introspection
      pkgs.libfprint
      pkgs.fprintd
      pkgs.gusb
      pkgs.appimage-run
      pkgs.glibc
    ];
    buildInputs = [
      pkgs.gtk3
      pkgs.gst_all_1.gstreamer
      (pkgs.python3.withPackages (p: with p; [
        pygobject3 gst-python
      ]))
    ];
}