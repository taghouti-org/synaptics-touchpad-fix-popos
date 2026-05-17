#!/bin/bash
# ============================================================
# Synaptics Touchpad Tap-to-Click Fix for Pop!_OS 24.04
# ============================================================

set -e

echo "============================================"
echo " Synaptics Touchpad Fix - Pop!_OS 24.04"
echo "============================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash fix-touchpad-popos.sh"
    exit 1
fi

# Step 1 - Install synaptics driver
echo ""
echo "[1/5] Installing Synaptics driver..."
apt install -y xserver-xorg-input-synaptics

# Step 2 - Add kernel parameters using kernelstub (Pop!_OS uses systemd-boot)
echo ""
echo "[2/5] Adding kernel parameters via kernelstub..."

PARAMS="i8042.nomux=1 i8042.reset=1 i8042.nopnp=1 i8042.noloop=1 psmouse.synaptics_intertouch=1"
CURRENT_PARAMS=$(kernelstub -p 2>/dev/null | grep "Kernel Boot Options" | cut -d: -f2-)

if echo "$CURRENT_PARAMS" | grep -q "i8042.nomux"; then
    echo "Kernel parameters already present, skipping..."
else
    kernelstub -a "$PARAMS"
    echo "Kernel parameters added."
fi

# Step 3 - Create Xorg Synaptics config
echo ""
echo "[3/5] Creating Xorg Synaptics config..."

mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/70-synaptics.conf << 'EOF'
Section "InputClass"
    Identifier "touchpad"
    Driver "synaptics"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Option "TapButton1" "1"
    Option "TapButton2" "2"
    Option "VertEdgeScroll" "1"
    Option "VertTwoFingerScroll" "1"
    Option "HorizTwoFingerScroll" "1"
    Option "SHMConfig" "on"
EndSection
EOF
echo "Xorg config created."

# Step 4 - Check and fix blacklist
echo ""
echo "[4/5] Checking blacklist config..."

BLACKLIST_FILE="/etc/modprobe.d/blacklist.conf"
if [ -f "$BLACKLIST_FILE" ]; then
    sed -i 's/^blacklist i2c_hid/#blacklist i2c_hid/' $BLACKLIST_FILE
    sed -i 's/^blacklist hid_multitouch/#blacklist hid_multitouch/' $BLACKLIST_FILE
    echo "Blacklist updated."
else
    echo "No blacklist file found, skipping..."
fi

# Step 5 - Create sleep/resume hook
echo ""
echo "[5/5] Creating suspend/resume hook..."

cat > /lib/systemd/system-sleep/touchpad.sh << 'EOF'
#!/bin/bash
if [ "$1" = "post" ]; then
    sleep 2
    USER_NAME=$(logname 2>/dev/null || echo $SUDO_USER)
    XAUTH=$(find /home/$USER_NAME -name ".Xauthority" 2>/dev/null | head -1)
    su $USER_NAME -c "DISPLAY=:0 XAUTHORITY=$XAUTH synclient TapButton1=1 TapButton2=2 VertTwoFingerScroll=1 HorizTwoFingerScroll=1" 2>/dev/null || true
fi
EOF
chmod +x /lib/systemd/system-sleep/touchpad.sh
echo "Sleep hook created."

echo ""
echo "============================================"
echo " All done! Please reboot your system."
echo " sudo reboot"
echo "============================================"