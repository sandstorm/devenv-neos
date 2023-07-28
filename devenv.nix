# my first endeavours with reusable NIX.
#
# Learnings:
#
# - everything is super-lazy by default. Thus, variables (defined after let) will only be evaluated when necessary.
# - this includes side-effects (e.g. building derivations) or downloading from github like pkgs.fetchFromGitHub
# - lib.mkIf cannot be used everywhere
# - lib.mkDefault makes a value overridable; lib.mkForce now.

{ pkgs, lib, config, ... }:

# we can simply write mkIf instead of lib.mkIf.
with lib;

########################################################################################
########################################################################################
# Variable declarations (can reference other variables declared beforehand.)
########################################################################################
########################################################################################
let
  cfg = config.neos;

  shellColors = ''
    # https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
    bold=$(tput bold)
    green=$(tput setaf 2)
    normal=$(tput sgr0)
  '';
in
{
  imports = [
    ./_neosFlowConfig.nix
    ./_phpAndExtensions.nix
    ./_mysql.nix
    ./_ideConfig.nix
  ];
  ########################################################################################
  ########################################################################################
  # CONFIG definition
  #
  # Reference: https://devenv.sh/reference/options/
  ########################################################################################
  ########################################################################################
  config = lib.mkIf cfg.enable {
    # Setup and Documentation
    enterShell = ''
      ${shellColors}

      echo ""
      echo "''${green}=============================================''${normal}"
      echo "''${bold}FINISHED: ''${green}Your PHP environment is ready!''${normal}"
      echo ""
      echo " - ''${green}PHP ${cfg.phpPackage.version}''${normal} installed"
      ${if cfg.flowConfig then ''
        echo " - Neos ''${green}Configuration/Settings.yaml''${normal} written"
      '' else ""}

      ${if cfg.vips then ''
        echo " - ''${green}VIPS''${normal} activated"
      '' else ""}
      ${if cfg.spx then ''
        echo " - ''${green}SPX''${normal} profiler activated. URL: ''${green}http://127.0.0.1:<port>/?SPX_UI_URI=/&SPX_KEY=dev''${normal}"
        echo "   For further help, see ''${bold}help-spx''${normal}"
      '' else ""}
      ${if cfg.jetbrainsIdeConfig then ''
        echo " - ''${green}IntelliJ/PHPStorm''${normal} configured:"
        echo "   - ''${green}Data Source''${normal} (Password: empty)"
        echo "   - ''${green}PHP Interpreter''${normal} set up"
      '' else ""}
      echo "''${green}=============================================''${normal}"

      cd ${cfg.distributionDir}
    '';
  };


  ########################################################################################
  ########################################################################################
  # SCHEMA: defining which properties/options the user can set.
  ########################################################################################
  ########################################################################################
  options.neos = {
    enable = mkEnableOption "Neos Addon";

    distributionDir = mkOption {
      type = types.str;
      default = ".";
      description = "the Neos distribution directory (e.g. where composer.json and ./flow is located)";
    };

    phpPackage = mkOption {
      type = types.package;
      default = pkgs.php81;
      defaultText = literalExpression "pkgs.php81";
      description = ''
        The PHP package to use, e.g. pkgs.php81 or pkgs.php82.

        You are NOT allowed to specify languages.php.package, or languages.php.version; because we want to configure Neos with VIPS support.
      '';
    };

    mysql = mkOption {
      type = types.bool;
      description = "Should configure Mysql DB?";
      default = true;
    };

    vips = mkOption {
      type = types.bool;
      description = "Should configure VIPS?";
      default = true;
    };

    spx = mkOption {
      type = types.bool;
      description = "Should configure SPX Profiler?";
      default = true;
    };

    jetbrainsIdeConfig = mkOption {
      type = types.bool;
      description = "Should generate .idea/datasources.xml and .idea/php.xml ? (for use in PHPStorm or IntelliJ)";
      default = true;
    };

    flowConfig = mkOption {
       type = types.bool;
       description = "Should generate Configuration/Settings.yaml";
       default = true;
     };
  };
}
