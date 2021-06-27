# Just enough NixOS for Kodi

This is a NixOS configration for an [Odroid
C2](https://wiki.odroid.com/odroid-c2/odroid-c2) that turns it into a
Kodi appliance. It is intended for cross-compilation on a x86-64
machine, as the device is a bit too underpowered to build its own
kernel in any reasonable timeframe.

The NixOS install is based on the description in the [NixOS
Wiki](https://nixos.wiki/wiki/NixOS_on_ARM/ODROID-C2) but a bit more
automated.

## Status: WIP

* it boots, it starts Kodi and it plays video fast enough to keep up
* audio does not work well - it's slightly too fast and it glitches. I
  think it is sending  44.1kHz PCM to a 48kHz without resampling.
* configuration of Kodi itself is all done through the UI, which I do not prefer. Would like to specify sources etc declaratively through Nix
* it hangs when I ask it to reboot
* various cross-compile fixes need to be pushed upstream

## Nixpkgs pinning

It needs Nixpkgs unstable

    $ git clone git@github.com:nixos/nixpkgs nixpkgs-for-nixelec
	$ cd nixpkgs-for-nixelec
	$ git checkout 34e5bf44fb04c6bb524e1af77c190cd810afb1cf
    $ git cherry-pick ad8133892f24c8604cce397bc94b83cedec05dfe
	$ export NIXPKGS_FOR_NIXELEC=`pwd`

Earlier or later versions will most likely also work, perhaps with
minor adjustments, but that's the one I'm using right now.


## To build an initial image

The board has some weird requirement to install a binary blob and an
U-boot image in a very specific part of the storage medium, meaning
that you can't install it from the NixOS generic aarch64 image without
some manual steps. This configuration automates that bit: run

```
NIX_PATH=nixpkgs=$NIXPKGS_FOR_NIXELEC:nixos-config=`pwd`/configuration.nix \
 nix-build -E 'let pkgs = (import <nixpkgs>) {};
 in (pkgs.pkgsCross.aarch64-multiplatform.nixos <nixos-config>)
 .config.system.build.sdImage'
```

and then find the output in
`result/sd-image/nixos-sd-image-21.11pre-git-aarch64-linux.img` -
again, Your Pathnames May Vary. `dd` this to whatever device
corresponds to the SD card you plan to insert into the Odroid machine
and you should be good to go. It *should* install a valid SSH key for the
root user, but it would be as well to check.


## Updating the configuration

Once you have a running Odroid machine, you can update it in place
without reflashing the whole disk, by executing manually the steps
that nixos-rebuild would take:

```
# build the system
NIX_PATH=nixpkgs=$NIXPKGS_FOR_NIXELEC:nixos-config=`pwd`/configuration.nix \
 nix-build -E 'let pkgs = (import <nixpkgs>) {};
 in (pkgs.pkgsCross.aarch64-multiplatform.nixos <nixos-config>)
 .config.system.build.toplevel'

# copy it to the target device
nix-copy-closure --to root@odroid.lan -v --include-outputs \
   ./result && ssh root@odroid.lan \
   `readlink result`/bin/switch-to-configuration switch
```
