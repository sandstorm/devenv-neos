# Module: PHP with extensions (VIPS etc)

{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.neos;

  ######################
  # Installing VIPS (image handling)
  ######################
  phpVipsExt = cfg.phpPackage.buildPecl {
    pname = "vips";
    version = "1.0.13";
    sha256 = "TmVYQ+XugVDJJ8EIU9+g0qO5JLwkU+2PteWiqQ5ob48=";
    buildInputs = [ pkgs.vips pkgs.pkg-config ];
  };

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

    # Setup and Documentation
    enterShell = ''
      ${if cfg.vips then ''
        pushd ./${cfg.distributionDir}

        if ! grep rokka/imagine-vips composer.json; then
          composer require rokka/imagine-vips
        fi
        popd
      '' else ""}
    '';

    scripts.help-spx.exec = ''
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

    languages.php.fpm.pools = {
      appPool = {
        settings = {
          "pm" = "dynamic";
          "pm.max_children" = 75;
          "pm.start_servers" = 10;
          "pm.min_spare_servers" = 5;
          "pm.max_spare_servers" = 20;
          "pm.max_requests" = 500;
        };
      };
    };

    neos.caddyDefaultVhostConfig = lib.mkIf config.services.caddy.enable ''
      php_fastcgi unix/${config.languages.php.fpm.pools.appPool.socket}
      file_server
      log
    '';

  };
}
