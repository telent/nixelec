# Just enough NixOS for Kodi

This is a NixOS configuration for an [Odroid
C2](https://wiki.odroid.com/odroid-c2/odroid-c2) that turns it into a
Kodi appliance. It is intended for cross-compilation on a x86-64
machine, as the device is a bit too underpowered to build its own
kernel in any reasonable timeframe.

The NixOS install is based on the description in the [NixOS
Wiki](https://nixos.wiki/wiki/NixOS_on_ARM/ODROID-C2) but a bit more
automated.

## What does it do

* it boots, it starts Kodi, it plays videos
* audio has been kludged a bit to make 44.1kHz rates work, and might not work at other rates
* it hangs when I ask it to reboot
* various cross-compile fixes need to be pushed upstream

My media is stored elsewhere and accessed over a password-protected
HTTP server. If yours is similar, copy `secrets.nix-example` to
`secrets.nix`, and edit that and `configuration.nix` to specify your
sources and passwords and stuff. If not, you'll need to edit more
extensively.

Once you have built everything and booted the system, you will have to
['set content'](https://kodi.wiki/view/Adding_video_sources#Set_Content)
interactively for each source before it can be scanned. This is not
easily automatable, sadly.

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
NIX_PATH=nixpkgs=$NIXPKGS_FOR_NIXELEC nix-build -A build.sdImage
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
that nixos-rebuild would take: build the `toplevel` derivation, copy
it and its closure to the target machine, and run
`bin/switch-to-configuration`

```
# build the system
NIX_PATH=nixpkgs=$NIXPKGS_FOR_NIXELEC nix-build -A build.toplevel

# copy it to the target device
nix-copy-closure --to root@odroid.lan -v --include-outputs \
   ./result && ssh root@odroid.lan \
   `readlink result`/bin/switch-to-configuration switch
```
