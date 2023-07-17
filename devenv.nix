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
  yamlFormatter = pkgs.formats.yaml {};

  shellColors = ''
    # https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
    bold=$(tput bold)
    green=$(tput setaf 2)
    normal=$(tput sgr0)
  '';

  ######################
  # Neos/Flow configuration
  ######################
  ConfigurationSettings = {
    Neos = {
      Flow = {
        persistence = {
          backendOptions = {
            driver = "pdo_mysql";
            charset = "utf8mb4";
            host = "127.0.0.1";
            port = toString config.services.mysql.settings.mysqld.port;
            user = (head config.services.mysql.ensureUsers).name;
            # no password configured
            # password = "password";
            dbname = (head config.services.mysql.initialDatabases).name;
          };

        };
      };
      # if VIPS is configured, also add it to the config.
      # // merges two attribute-sets (non-recursively)
    } // (optionalAttrs cfg.vips {
      Imagine = {
        driver = "Vips";
        enabledDrivers = {
          Vips = true;
          Gd = true;
          Imagick = true;
        };
      };

      Media = {
        image = {
          defaultOptions = {
            # The Vips driver does not support interlace
            interlace = null;
          };
        };
      };
    });
  };
  ConfigurationSettingsYaml = yamlFormatter.generate "Settings.yaml" ConfigurationSettings;

  ######################
  # Installing VIPS (image handling)
  ######################
  phpVipsExt = cfg.phpPackage.buildPecl {
    pname = "vips";
    version = "1.0.13";
    sha256 = "TmVYQ+XugVDJJ8EIU9+g0qO5JLwkU+2PteWiqQ5ob48=";
    buildInputs = [ pkgs.vips pkgs.pkg-config ];
  };

  # not sure why we need to read and write it again; but we had problems with stale contents of this script otherwise
  ideConfigOptions = pkgs.writeTextFile { name = "ideConfigUpdates.php"; text = (builtins.readFile ./ide-config-updates.php); };

  ######################
  # Installing PHP-SPX (profiler)
  ######################
  # version SHA1 to install
  phpSpxExtVersionHash = "855c7b2f52314648deb73d47bfc54e02659137c8";
  phpSpxExt = cfg.phpPackage.buildPecl {
    pname = "spx";
    version = phpSpxExtVersionHash;
    src = pkgs.fetchFromGitHub {
      owner = "NoiseByNorthwest";
      repo = "php-spx";
      rev = phpSpxExtVersionHash;
      # this needs to be updated when the version hash changes.
      sha256 = "sha256-4+gX9daG0TqSBXQhShyvMNI0QAI4WWRyH8rMQeIvPec=";
    };
    # php-spx needs zlib headers
    buildInputs = [ pkgs.zlib pkgs.pkg-config ];
    configureFlags = [ "--with-zlib-dir=${pkgs.zlib.dev}" ];
    # I trial-and-errored the correct INSTALL_ROOT value: https://github.com/NoiseByNorthwest/php-spx/blob/855c7b2f52314648deb73d47bfc54e02659137c8/Makefile.frag#L2
    makeFlags = [ "INSTALL_ROOT=$(out)" "EXTENSION_DIR=/lib/php/extensions" ];
  };
in
{
  ########################################################################################
  ########################################################################################
  # CONFIG definition
  #
  # Reference: https://devenv.sh/reference/options/
  ########################################################################################
  ########################################################################################
  config = lib.mkIf cfg.enable {
    # Neos needs PHP :)
    languages.php.enable = true;

    # we manually need to specify the PHP package, as we want to activate our custom VIPS and SPX extension if needed
    languages.php.package = cfg.phpPackage.buildEnv {
      extensions = { all, enabled }: with all;
        enabled
        ++ optionals cfg.vips [phpVipsExt]
        ++ optionals cfg.spx [phpSpxExt]
        # NOTE: to not break languages.php.extensions, we need to add the configured list from
        # "languages.php.extensions", basically copying this line: https://github.com/cachix/devenv/blob/main/src/modules/languages/php.nix#L23
        ++ attrValues (getAttrs config.languages.php.extensions cfg.phpPackage.extensions);

      extraConfig =
        ''
          memory_limit = 1024M
          ; Neos still has minor errors with PHP 8.2
          error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
        ''
        # if SPX is enabled, we add the corresponding config to php.ini
        + optionalString cfg.spx ''
          spx.http_enabled=1
          spx.http_key="dev"
          spx.http_ip_whitelist="127.0.0.1"
        ''
        # also we want to support custom PHP ini config https://github.com/cachix/devenv/blob/main/src/modules/languages/php.nix#L24
        + config.languages.php.ini;
    };

    # configure mysql with DB "neos" and user "neos" (empty password)
    services.mysql = lib.mkIf cfg.mysql {
      # DB migrations on mariadb M1 Mac are painfully slow (40 secs), so we switch to Mysql.
      package = pkgs.mysql80;
      enable = true;
      initialDatabases = [
        { name = "neos"; }
      ];
      ensureUsers = [
        {
          name = "neos";
          ensurePermissions = {
            "neos.*" = "ALL PRIVILEGES";
          };
        }
      ];
      # we use a non standard port by default, to not clash with the default one. To override, you can set another one
      # via services.mysql.settings.mysqld.port = 12345;
      settings.mysqld.port = mkDefault 4406;
    };

    # Setup and Documentation
    enterShell = ''
      ${shellColors}

      cp ${ConfigurationSettingsYaml} Configuration/Settings.yaml
      ${if cfg.jetbrainsIdeConfig then ''
        mkdir -p .idea

        DB_USER=${(head config.services.mysql.ensureUsers).name} DB_PORT=${toString config.services.mysql.settings.mysqld.port} DB_NAME=${(head config.services.mysql.initialDatabases).name} php ${ideConfigOptions}
      '' else ""}

      ${if cfg.vips then ''
        composer require rokka/imagine-vips
      '' else ""}

      echo ""
      echo "''${green}=============================================''${normal}"
      echo "''${bold}FINISHED: ''${green}Your Neos environment is ready!''${normal}"
      echo ""
      echo " - ''${green}PHP ${cfg.phpPackage.version}''${normal} installed"
      echo " - Neos ''${green}Configuration/Settings.yaml''${normal} written"
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
  '';

  scripts.help-spx.exec = ''
    ${shellColors}

    echo ""
    echo "''${bold}Profiling web requests:''${normal}"
    echo " - UI: http://127.0.0.1:<port>/''${green}?SPX_UI_URI=/&SPX_KEY=dev''${normal}"
    echo " - Then, toggle the ''${green}Enabled''${normal} checkbox to start profiling."
    echo ""
    echo "''${bold}Profiling CLI requests:''${normal}"
    echo " - ''${green}SPX_ENABLED=1''${normal} php ..."
    echo "   for quick CLI profiling"
    echo " - ''${green}SPX_ENABLED=1 SPX_FP_LIVE=1''${normal} php ..."
    echo "   for quick CLI profiling with live redraw"
    echo " - ''${green}SPX_ENABLED=1 SPX_REPORT=full''${normal} php ..."
    echo "   for CLI profiling which can be analyzed in the web UI"
  '';
  };


  ########################################################################################
  ########################################################################################
  # SCHEMA: defining which properties/options the user can set.
  ########################################################################################
  ########################################################################################
  options.neos = {
    enable = mkEnableOption "Neos Addon";

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
  };
}
