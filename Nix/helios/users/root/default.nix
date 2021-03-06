################################################################################
##                                                                            ##
##                      User declaration for root@helios                      ##
##                                                                            ##
################################################################################

{ config, pkgs, ... }:

{
  users.users.root = {
    # Use `mkpasswd -m SHA-512` to generate a new password hash.
    hashedPassword = "***[ REDACTED ]***";
  };

  home-manager.users.root = import ./home.nix;
}
