{ pkgs, ... }:

{
  # This is the project devenv.sh configuration file for this project, specifying
  # all dependencies.
  #
  # USAGE
  #
  # - devenv shell: creates a shell environment for development.
  #     use ./flow server:run for running the Neos server then.
  # - devenv up: start all surrounding services (e.g. mysql)
  #
  #
  # REFERENCE
  #
  # See https://devenv.sh/reference/options/ for all options.

  ########################################
  # Neos CMS
  ########################################
  neos = {
    enable = true;

    # PHP Package version to use (default: pkgs.php81)
    #phpPackage = pkgs.php82;

    # MYSQL support and Flow/Neos auto-configuration (default: enabled)
    # by default, port 4406 is used - see below for overriding
    # user: neos
    # password: (empty)
    # database: neos
    #mysql = false;

    # VIPS PHP extension, composer package + Flow/Neos auto-configuration (default: enabled)
    #vips = false;

    # SPX profiler PHP extension (default: enabled)
    # to open the profiler, append: ?SPX_UI_URI=/&SPX_KEY=dev
    #spx = false;

    # Configure PHPStorm / IntelliJ correctly (default: enabled)
    # enables the Neos plugin, sets the correct PHP interpreter, adds a database connection
    #jetbrainsIdeConfig = false;
  };


  ########################################
  # additional PHP configuration
  ########################################

  # use the following line to enable xdebug; and you can also add additional extensions.
  #languages.php.extensions = [ "xdebug" ];


  ########################################
  # additional MySQL configuration
  ########################################

  # change the MYSQL port:
  #services.mysql.settings.mysqld.port = 12345;

  # change from mysql to mariadb (!warning: really slow migrations on OSX!)
  #services.mysql.package = pkgs.mariadb;

  # create multiple databases (the 1st one will be used for Neos)
  #services.mysql.initialDatabases = [
  #  { name = "neos"; },
  #  { name = "other-db"; },
  #];

  # create multiple users (the 1st one will be used for Neos)
  #services.mysql.ensureUsers = [
  #  {
  #    name = "neos";
  #    ensurePermissions = {
  #      "neos.*" = "ALL PRIVILEGES";
  #    };
  #  }
  #];

  ########################################
  # extra devenv.sh features
  ########################################

  # set env variables
  #env.GREET = "devenv";

  # add extra scripts, see: https://devenv.sh/scripts/
  #scripts.hello.exec = "echo hello from $GREET";

  # add extra nix packages:
  #packages = [ pkgs.git ];

  # enable other languages, e.g. Node JS:
  #languages.javascript.enable = true;

  # enable starship shell prompt:
  #starship.enable = true;

  # add extra processes to run during "devenv up" (e.g style compilation): https://devenv.sh/processes/
  #processes.ping.exec = "ping example.com";
}
