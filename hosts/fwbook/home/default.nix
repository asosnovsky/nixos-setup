{ ... }:
let
  zshFWBook = builtins.filterSource (p: t: true) ../../scripts/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
in
{
  programs.zsh.initContent = ''
    source ${zshFunctions}
  '';
  services.blueman-applet.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/about" = "chromium-browser.desktop";
    "x-scheme-handler/chrome" = "chromium-browser.desktop";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
    "x-scheme-handler/unknown" = "chromium-browser.desktop";
    "x-scheme-handler/geo" = "google-maps-geo-handler.desktop";
    "x-scheme-handler/mailto" = "chromium-browser.desktop";
    "x-scheme-handler/sgnl" = "signal.desktop";
    "x-scheme-handler/signalcaptcha" = "signal.desktop";
    "x-scheme-handler/slack" = "slack.desktop";
    "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    "application/pdf" = "chromium-browser.desktop";
    "application/xhtml+xml" = "chromium-browser.desktop";
    "text/html" = "chromium-browser.desktop";
    "application/x-terminal-emulator" = "com.mitchellh.ghostty.desktop";
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "image/avif" = "org.gnome.eog.desktop";
    "image/bmp" = "org.gnome.eog.desktop";
    "image/gif" = "org.gnome.eog.desktop";
    "image/heif" = "org.gnome.eog.desktop";
    "image/jpeg" = "org.gnome.eog.desktop";
    "image/png" = "org.gnome.eog.desktop";
    "image/svg+xml" = "org.gnome.eog.desktop";
    "image/tiff" = "org.gnome.eog.desktop";
    "image/webp" = "org.gnome.eog.desktop";
    "application/x-matroska" = "vlc.desktop";
    "audio/aac" = "vlc.desktop";
    "audio/flac" = "vlc.desktop";
    "audio/m4a" = "vlc.desktop";
    "audio/mpeg" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/wav" = "vlc.desktop";
    "audio/x-flac" = "vlc.desktop";
    "video/avi" = "vlc.desktop";
    "video/mp4" = "vlc.desktop";
    "video/mpeg" = "vlc.desktop";
    "video/ogg" = "vlc.desktop";
    "video/quicktime" = "vlc.desktop";
    "video/webm" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "application/javascript" = "code.desktop";
    "application/json" = "nvim.desktop";
    "application/x-docbook+xml" = "nvim.desktop";
    "application/x-httpd-php3" = "dev.zed.Zed.desktop";
    "application/x-httpd-php4" = "dev.zed.Zed.desktop";
    "application/x-httpd-php5" = "dev.zed.Zed.desktop";
    "application/x-m4" = "dev.zed.Zed.desktop";
    "application/x-php" = "dev.zed.Zed.desktop";
    "application/x-ruby" = "dev.zed.Zed.desktop";
    "application/x-shellscript" = "nvim.desktop";
    "application/x-yaml" = "nvim.desktop";
    "application/xml" = "nvim.desktop";
    "text/css" = "dev.zed.Zed.desktop";
    "text/markdown" = "nvim.desktop";
    "text/plain" = "nvim.desktop";
    "text/turtle" = "dev.zed.Zed.desktop";
    "text/x-c++hdr" = "dev.zed.Zed.desktop";
    "text/x-c++src" = "dev.zed.Zed.desktop";
    "text/x-chdr" = "dev.zed.Zed.desktop";
    "text/x-cmake" = "dev.zed.Zed.desktop";
    "text/x-csharp" = "dev.zed.Zed.desktop";
    "text/x-csrc" = "dev.zed.Zed.desktop";
    "text/x-diff" = "dev.zed.Zed.desktop";
    "text/x-dsrc" = "dev.zed.Zed.desktop";
    "text/x-fortran" = "dev.zed.Zed.desktop";
    "text/x-java" = "dev.zed.Zed.desktop";
    "text/x-makefile" = "dev.zed.Zed.desktop";
    "text/x-pascal" = "dev.zed.Zed.desktop";
    "text/x-perl" = "dev.zed.Zed.desktop";
    "text/x-python" = "dev.zed.Zed.desktop";
    "text/x-sql" = "dev.zed.Zed.desktop";
    "text/x-vb" = "dev.zed.Zed.desktop";
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";
    "text/csv" = "onlyoffice-desktopeditors.desktop";
  };
  xdg.mimeApps.associations.added = {
    "application/json" = "nvim.desktop;dev.zed.Zed.desktop;";
    "application/pdf" = "chromium-browser.desktop;onlyoffice-desktopeditors.desktop;";
    "audio/mpeg" = "vlc.desktop;mpv.desktop;";
    "image/png" = "org.gnome.eog.desktop;gimp.desktop;";
    "text/plain" = "dev.zed.Zed.desktop;nvim.desktop;code.desktop;";
    "video/mp4" = "vlc.desktop;mpv.desktop;";
  };
}
