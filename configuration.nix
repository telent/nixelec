# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {

      atk = super.atk.overrideAttrs(o: {
        nativeBuildInputs = o.nativeBuildInputs ++
                            [ self.pkg-config self.buildPackages.stdenv.cc ];
      });

      # gobject-introspection =
      #   let moreCross = builtins.toFile "cross-exe-wrapper.conf" ''
      #       [binaries]
      #       exe_wrapper = '/nix/store/4s5s0bgp6708nnyl9zbc7fa6s8c5xh59-qemu-6.0.0/bin/qemu-aarch64'
      #     '';
      #       d = super.gobject-introspection.overrideAttrs(o: {
      #         mesonFlags =  [ "-Dcairo=disabled"
      #                         "-Ddoctool=disabled"
      #                         "--cross-file=${moreCross}" ];
      #         nativeBuildInputs = o.nativeBuildInputs ++
      #                             [ self.buildPackages.stdenv.cc ];
      #       });
      #   in d.override {
      #     x11Support = false;
      #     # python38 fails on aarch64, "No module named 'giscanner._giscanner'"
      #     python3 = self.python37;
      #   };

      gdk-pixbuf= (super.gdk-pixbuf.overrideAttrs(o:{
        preInstall = "mkdir -p $out/share/doc $installedTests/foo";
        mesonFlags = o.mesonFlags ++ [
          "-Dgtk_doc=false"
        ];
      })).override { doCheck = false; gobject-introspection = null;};

      harfbuzz = (super.harfbuzz.overrideAttrs(o: {
        doCheck = false;
        mesonFlags = ["-Dgobject=disabled"
                      "-Dicu=disabled"
                       "-Dintrospection=disabled"
                     ];
      })).override({gobject-introspection = null;});

      kodi = let k = super.kodi.overrideAttrs(o:{

        preConfigure = ''
          cmakeFlagsArray+=("-DCORE_PLATFORM_NAME=gbm")
          # Need these tools on the build system when cross compiling,
          # hacky, but have found no other way.
          CXX=$CXX_FOR_BUILD LD=ld make -C tools/depends/native/JsonSchemaBuilder
          cmakeFlags+=" -DWITH_JSONSCHEMABUILDER=$PWD/tools/depends/native/JsonSchemaBuilder/bin"
          CXX=$CXX_FOR_BUILD LD=ld make EXTRA_CONFIGURE= -C tools/depends/native/TexturePacker
          cmakeFlags+=" -DWITH_TEXTUREPACKER=$PWD/tools/depends/native/TexturePacker/bin"
        '';

      }); in
               k.override {
        x11Support  = false;
        dbusSupport  = false;
        joystickSupport = false;
        nfsSupport = false;
        pulseSupport  = false;
        sambaSupport  = false;
        udevSupport = false;
        usbSupport = false;
        vdpauSupport = false;
        gbmSupport = true;

        jre_headless = self.buildPackages.adoptopenjdk-openj9-bin-11 ;
        lirc = null;
      };

      # kodi = kodiUnwrapped.passthru.withPackages
      #   (kodiPkgs: with kodiPkgs; [ ]);

      libcec = super.libcec.overrideAttrs(o:{
        cmakeFlags =  [ "-DHAVE_LINUX_API=1" ];
      });

      linuxPackages = super.linuxPackages_latest.extend (lpself: lpsuper: {
        kernel = super.linuxPackages_latest.kernel.override {
          extraConfig = ''
             STAGING y
             STAGING_MEDIA y
             VIDEO_MESON_VDEC m
          '';
        };
      });

      mesa =
        (super.mesa.overrideAttrs (o:{
          mesonFlags =
            let moreCross = self.writeText "cross-exe-wrapper.conf" ''
            [binaries]
            llvm-config = '${self.llvmPackages_11.llvm.dev}/bin/llvm-config'
            cmake = '${self.buildPackages.cmake}/bin/cmake'
            exe_wrapper = '/nix/store/4s5s0bgp6708nnyl9zbc7fa6s8c5xh59-qemu-6.0.0/bin/qemu-aarch64'
        ''; in
              ["-Dgallium-drivers=[lima,panfrost]"
               "--cross-file=${moreCross}"
              ] ++ o.mesonFlags;
        }));

      pango = null;

      # make-tarball is hardcoded to use pixz, but waqnts a host
      # version not a build version
      pixz = super.buildPackages.pixz;

      rtmpdump = super.rtmpdump.overrideAttrs(o:{
        makeFlags = o.makeFlags ++ [
          "CC=${self.stdenv.cc.targetPrefix}cc"
          "AR=${self.stdenv.cc.targetPrefix}ar"
        ];
      });

      tdb = super.tdb.overrideAttrs(o: {
        nativeBuildInputs = o.nativeBuildInputs ++ [ self.python3 ];
      });
    })
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # need this for deploying to the odroid
      <nixpkgs/nixos/modules/installer/sd-card/sd-image.nix>
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  sdImage.populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  sdImage.populateFirmwareCommands = "";
  sdImage.compressImage = false;
  sdImage.postBuildCommands =
    let u = pkgs.ubootOdroidC2;
        bl1 = "${u}/bl1.bin.hardkernel";
        uboot = "${u}/u-boot.gxbb"; in
      # https://archlinuxarm.org/packages/aarch64/uboot-odroid-c2-mainline/files/sd_fusing.sh?raw
      ''
        dd if=${bl1} of=$img conv=fsync,notrunc bs=1 count=442
        dd if=${bl1} of=$img conv=fsync,notrunc bs=512 skip=1 seek=1
        dd if=${uboot} of=$img conv=fsync,notrunc bs=512 seek=97
      '';

  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 0;
  };

  boot.blacklistedKernelModules = [ "meson_gxbb_wdt" ] ;

  # override systemd core file processing, which grinds the box to a
  # halt (load av > 11)
  boot.kernel.sysctl."kernel.core_pattern" = "/dev/null";

  environment.systemPackages = [ pkgs.libcec ];

  networking.hostName = "odroid"; # Define your hostname.

  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  systemd.services.kodi = {
    wantedBy = [ "multi-user.target"];
    serviceConfig = {
      WorkingDirectory = "/home/kodi";
      User = "kodi";
      ExecStart = ''
        ${pkgs.kodi}/bin/kodi  --windowing=gbm
        '';
    };
  };


  # Enable sound.
  sound.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [ "weston-launch" "wheel" "video" "audio"]; # Enable ‘sudo’ for the user.
  };

  users.users.kodi = {
    isNormalUser = true;
    extraGroups = [ "input" "video" "audio"];
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    "${builtins.getEnv "HOME"}/.ssh/authorized_keys"
    "${builtins.getEnv "HOME"}/.ssh/id_rsa.pub"
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "21.05"; # Did you read the comment?

  hardware.opengl = { enable = true; driSupport = true; };

  networking.firewall = {
    # for the Kodi web interface
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };

}
