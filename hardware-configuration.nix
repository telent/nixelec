# FIXME - I am not sure if this is actually used - or correct
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "usb_storage" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/e68ac2e2-58a9-44a1-bf6a-2f3a80366d67";
  #     fsType = "ext4";
  #   };

  swapDevices = [ { device = "/dev/mmcblk0p2";}  ];

}
