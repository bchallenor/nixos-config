{ config, lib, pkgs, ... }:

# Used instead of services.redshift because:
# a) it assumes you want a provider, but we don't
# b) it does not let you specify a config file, but dawn/dusk time can only be set from a config file

let
  configFile = pkgs.writeText "redshift.conf" ''
    [redshift]
    temp-day=6500
    temp-night=3700
    dawn-time=08:00
    dusk-time=18:00
  '';
in
{
  nixpkgs.overlays = [
   (self: super: {
      redshift = super.redshift.override {
        # Avoid dep on network-manager
        # TODO(19.03) withGeolocation
        withGeoclue = false;
      };
    })
  ];

  environment.systemPackages = with pkgs; [ redshift ];

  systemd.user.services.redshift =
  {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.redshift}/bin/redshift -c ${configFile}
      '';
      ProtectSystem = "strict";
      Restart = "always";
    };
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
  };
}
