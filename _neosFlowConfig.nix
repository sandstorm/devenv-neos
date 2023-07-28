# Module: Neos/Flow Config Settings.yaml generation

{ pkgs, lib, config, ... }:
with lib;

let
  cfg = config.neos;
  yamlFormatter = pkgs.formats.yaml {};

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

in
{
  config = lib.mkIf cfg.enable {

    # Setup and Documentation
    enterShell = ''
      ${if cfg.flowConfig then ''
          mkdir -p ./${cfg.distributionDir}/Configuration
          cp ${ConfigurationSettingsYaml} ./${cfg.distributionDir}/Configuration/Settings.yaml
          chmod 644 ./${cfg.distributionDir}/Configuration/Settings.yaml
      '' else ""}
    '';

    scripts.flow.exec = ''
      olddir=`pwd`
      cd ${config.env.DEVENV_ROOT}/${cfg.distributionDir}
      ./flow $@
      cd "$olddir"
    '';
  };
}
