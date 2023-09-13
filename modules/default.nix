# localFlake and withSystem allow passing flake to the module through importApply
# See https://flake.parts/define-module-in-separate-file.html
{ localFlake, withSystem }:
{ pkgs, lib, config, ... }:
let
  cfg = config.services.xremap;
  packages' = localFlake.packages.${pkgs.stdenv.hostPlatform.system};
in
with lib; {
  imports = [
    ./user-service.nix
    ./system-service.nix
  ];
  options.services.xremap = {
    serviceMode = mkOption {
      type = types.enum [ "user" "system" ];
      default = "system";
      description = ''
        The mode the service will run as.

        Using user serviceMode:
        * Adds user to input group
        * Adds udev rule so that /dev/uinput device is owned by input group
        * Does not set niceness

        Using system serviceMode:
        * Runs xremap as root in a hardened systemd service
        * Sets niceness to -20
      '';
    };
    withSway = mkEnableOption "support for Sway";
    withGnome = mkEnableOption "support for Gnome";
    withX11 = mkEnableOption "support for X11";
    withHypr = mkEnableOption "support for Hyprland";
    package = mkOption {
      type = types.package;
      default =
        if cfg.withSway then
          packages'.xremap-sway
        else if cfg.withGnome then
          packages'.xremap-gnome
        else if cfg.withX11 then
          packages'.xremap-x11
        else if cfg.withHypr then
          packages'.xremap-hypr
        else
          packages'.xremap
      ;
    };
    config = mkOption {
      type = types.attrs;
      description = "Xremap configuration. See xremap repo for examples. Cannot be used together with .yamlConfig";
      default = { };
      example = ''
        {
          modmap = [
            {
              name = "Global",
              remap = {
                CapsLock = "Esc";
                Ctrl_L = "Esc";
              };
            }
          ];
          keymap = [
            {
              name = "Default (Nocturn, etc.)",
              application = {
              not = [ "Google-chrome", "Slack", "Gnome-terminal", "jetbrains-idea"];
              };
              remap = {
                # Emacs basic
                "C-b" = "left";
                "C-f" = "right";
              };
            }
          ];
        }
      '';
    };
    yamlConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        The text of yaml config file for xremap. See xremap repo for examples. Cannot be used together with .config.
      '';
      example = ''
        modmap:
          - name: Except Chrome
            application:
              not: Google-chrome
            remap:
              CapsLock: Esc
        keymap:
          - name: Emacs binding
            application:
              only: Slack
            remap:
              C-b: left
              C-f: right
              C-p: up
              C-n: down
      '';
    };
    userId = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID that would run Sway IPC socket";
    };
    userName = mkOption {
      type = types.str;
      description = "Name of user logging into graphical session";
    };
    deviceName = mkOption {
      type = types.str;
      default = "";
      description = "Device name which xremap will remap. If not specified - xremap will remap all devices.";
    };
    mouse = mkEnableOption "Include mice when .deviceName is not specified.";
    watch = mkEnableOption "running xremap watching new devices";
  };
}
