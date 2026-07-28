{
  fusuma = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "19pw97h6mjr0xxm066jcgm62pxcczjq7zlxv2l9cdc4p4x9ba591";
      type = "gem";
    };
    version = "3.12.0";
  };
  fusuma-plugin-appmatcher = {
    dependencies = [ "fusuma" "rexml" "ruby-dbus" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0ip25c7kz6lpnmjpdmxxaballjnml79p3gvhrqabppk29bmrgqrh";
      type = "gem";
    };
    version = "0.12.0";
  };
  fusuma-plugin-keypress = {
    dependencies = [ "fusuma" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "sha256-NBrLjKexZ+w5gAbjtC4Y2XntTvGLFUP3Qiv5koxsmpk=";
      type = "gem";
    };
    version = "0.11.0";
  };
  fusuma-plugin-sendkey = {
    dependencies = [ "fusuma" "revdev" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1gy0gz2kyavfvq4sfqvybzaah8hiajfzi2mlcizv2n834vy9lwhj";
      type = "gem";
    };
    version = "0.14.0";
  };
  logger = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  revdev = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1b6zg6vqlaik13fqxxcxhd4qnkfgdjnl4wy3a1q67281bl0qpsz9";
      type = "gem";
    };
    version = "0.2.1";
  };
  rexml = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0hninnbvqd2pn40h863lbrn9p11gvdxp928izkag5ysx8b1s5q0r";
      type = "gem";
    };
    version = "3.4.4";
  };
  ruby-dbus = {
    dependencies = [ "logger" "rexml" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0528x9jm3frq3r10ilf1fkhsy3m5w2gkr93pa5xcixv1daliqhzy";
      type = "gem";
    };
    version = "0.25.0";
  };
}
