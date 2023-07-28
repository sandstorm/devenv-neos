# Module: Imagor Image Proxy

{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.services.imagor;

  imagor = pkgs.buildGoModule rec {
    pname = "imagor";
    version = "1.4.7";

    src = pkgs.fetchFromGitHub {
      owner = "cshum";
      repo = "imagor";
      rev = "v${version}";
      hash = "sha256-jX0oTWaxYWwwTw1Vh4MfEgqWssqo76pMk4TLGpy8oqM=";
    };

    vendorHash = "sha256-WA9/4ijWobUPRnuQh8xOehJOHOXUNroC/ktTMdD8XLI=";
    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [pkgs.vips];
    doCheck = false; # golden tests do not work on OSX
    CGO_CFLAGS_ALLOW = "-Xpreprocessor";
  };
in
{
  options.services.imagor = {
    enable = lib.mkEnableOption ''
      Imagor Image Resizer
    '';

    secret = lib.mkOption {
      type = lib.types.str;
      description = ''
        Imagor Secret
      '';
      default = "";
    };

    signerType = lib.mkOption {
      type = lib.types.str;
      description = ''
        the signer type to use, e.g. sha256
      '';
      default = "sha256";
    };

    signerTruncate = lib.mkOption {
      type = lib.types.str;
      description = ''
        signing truncate
      '';
      default = "40";
    };

    fileLoaderBaseDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        FileLoader Base Directory
      '';
      default = "";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8989;
      description = ''
        Imagor port
      '';
    };

    caddyAliasPath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Alias Path in Caddy Webserver
      '';
      default = "/dynamic-images";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ imagor ];

    env.IMAGOR_SECRET = cfg.secret;
    env.IMAGOR_SIGNER_TYPE = cfg.signerType;
    env.IMAGOR_SIGNER_TRUNCATE = cfg.signerTruncate;
    env.FILE_LOADER_BASE_DIR = cfg.fileLoaderBaseDir;

    scripts.imagor.exec = ''
      export PORT=${toString cfg.port}

      mkdir -p ${config.devenv.state}/imagor/cache
      export FILE_RESULT_STORAGE_BASE_DIR=${config.devenv.state}/imagor/cache
      ${imagor}/bin/imagor $@
    '';

    processes.imagor.exec = ''
      export PORT=${toString cfg.port}

      mkdir -p ${config.devenv.state}/imagor/cache
      export FILE_RESULT_STORAGE_BASE_DIR=${config.devenv.state}/imagor/cache
      ${imagor}/bin/imagor $@
    '';

    neos.caddyDefaultVhostConfig = ''
      handle_path ${cfg.caddyAliasPath}/* {
          reverse_proxy 127.0.0.1:${toString cfg.port}
      }
    '';
  };
}
