# Synaptics touchpad tap-to-click fix for Pop!_OS 24.04

A script for laptops whose Synaptics touchpad does not register taps, or stops working after suspend, on
Pop!_OS 24.04 with an Xorg session.

## Use

```sh
sudo bash fix-touchpad-popos.sh
sudo reboot
```

## What it changes

1. Installs `xserver-xorg-input-synaptics`.
2. Adds `i8042.nomux=1 i8042.reset=1 i8042.nopnp=1 i8042.noloop=1 psmouse.synaptics_intertouch=1` to the kernel
   boot options with `kernelstub` (Pop!_OS boots with systemd-boot, not GRUB).
3. Writes `/etc/X11/xorg.conf.d/70-synaptics.conf` with tap-to-click and two-finger scrolling enabled.
4. Comments out `blacklist i2c_hid` and `blacklist hid_multitouch` in `/etc/modprobe.d/blacklist.conf`, if present.
5. Adds `/lib/systemd/system-sleep/touchpad.sh`, which re-applies the tap settings after resume.

The Xorg configuration has no effect in a Wayland session.

For Ubuntu, which uses GRUB, see
[synaptics-touchpad-fix-ubuntu](https://github.com/taghouti-org/synaptics-touchpad-fix-ubuntu).
