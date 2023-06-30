# devenv-neos

This package is a library for [devenv](https://devenv.sh), which helps building reproducible dev environments
without Docker based on Nix.

[devenv](https://devenv.sh) provides a reproducible and declarative local development environment for Neos projects.
It uses the Nix package system to provide native packages for all our required services.

**Status: Alpha** - this is an experiment right now in replacing our Docker based development setup with Nix on Mac OS
at sandstorm. Pull Requests welcome.

## Features

**Supported on Mac OS only** right now.

- fully reproducible dev environment based on https://devenv.sh and the Nix package manager.
- compatible with the modern way to write nix, a.k.a. nix-flakes.
- everything running fully locally; no containers involved. This makes debugging etc. a lot easier, and
  improves performance.
- Deep Neos integration:
  - mysql auto-configured
  - VIPS for image handling auto-configured
  - `Configuration/Settings.yaml` correctly generated
- PHPStorm / IntelliJ auto-configured
  - Database Connection auto-configured
  - Neos plugin auto-activated


## Installation of Nix and devenv.sh

You need the Nix package manager set up; alongside with devenv.sh.

1. Install Nix via [nix-installer](https://github.com/DeterminateSystems/nix-installer#usage): 
   
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Ensure your `nix` installation survives OSX Updates (because of [this OSX behavior](https://github.com/NixOS/nix/issues/3616#issuecomment-903869569)): Place the following snippet at the beginning of your `~/.zshrc`:
   
   ```bash
   # Nix
   if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
     source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
   fi
   ```

3. Install [devenv.sh](https://devenv.sh/getting-started/#__tabbed_1_2). If you follow how we do it at [Sandstorm](https://sandstorm.de/de/blog/post/my-first-steps-with-nix-on-mac-osx-as-homebrew-replacement.html) via Nix Flakes and Nix profiles, you can use `Advanced (declaratively with flakes)` method described.

## Set up your Neos project

1. run `devenv init` in your Neos project.
2. Update your `devenv.yaml` to look as follows:

  ```
  inputs:
    nixpkgs:
      # or, for stable, use github:NixOS/nixpkgs
      url: github:NixOS/nixpkgs/nixpkgs-unstable

    # This part must be added:
    devenv-neos:
      url: git+https://github.com/sandstorm/devenv-neos
      flake: false
  imports:
    # this line actually runs devenv-neos and ensures you can use these properties.
    - devenv-neos
  ```

3. Update your `devenv.nix` to look as follows:

   ```nix
   { pkgs, ... }:

   {
     # Enable Neos support (auto-configures database etc.)
     neos.enable = true;
     # add further configuration here
   }
   ```

You can use [**every** devenv.sh configuration](https://devenv.sh/reference/options/) directly in the `devenv.nix` file above.

## Neos Configuration Options

### Mysql (default: true)

`neos.mysql = false` to not configure mysql.

### VIPS (default: true)

`neos.vips = false` to not configure mysql.

### IDE configuration (default: true)

`neos.jetbrainsIdeConfig = false` to not configure mysql.

## common Devenv configuration options

### add Node.JS environment (for building assets)

### custom file watcher (e.g. for asset compilation)

### add Elasticsearch support

### add Redis support


