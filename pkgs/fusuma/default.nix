{ lib
, ruby
, bundlerEnv
, runCommand
, makeWrapper
, ...
}:

let
  env = bundlerEnv {
    name = "fusuma-3.12.0";
    inherit ruby;
    gemdir = ./.;
  };

  pluginLib = "${../fusuma-plugin-niri-appmatcher}/lib";
in
runCommand "fusuma-3.12.0" {
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p $out/bin
  makeWrapper ${env}/bin/fusuma $out/bin/fusuma \
    --set RUBYLIB "${pluginLib}:$RUBYLIB"
''
