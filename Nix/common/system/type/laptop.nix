################################################################################
##                                                                            ##
##                         Configuration for laptops                          ##
##                                                                            ##
################################################################################

{ config, lib, pkgs, ... }:

{
  ############################################################################
  ##                                Hardware                                ##
  ############################################################################

  hardware = {
    brightnessctl.enable = true;
  };

  ############################################################################
  ##                                Services                                ##
  ############################################################################

  services = {
    tlp.enable = true;
  };
}
