{config,lib,...}:
let
	cfgName = "skyg.nixos.desktop.stylix";
	cfg = config."${cfgName}";
	in
{
	options = {
		"${cfgName}" = {
			enable = lib.mkEnableOption
        "Enable Stylix";
		};
	};
	 config = lib.mkIf cfg.enable {
			stylix.enable = true;
		  stylix.polarity = "dark";
	};
}
