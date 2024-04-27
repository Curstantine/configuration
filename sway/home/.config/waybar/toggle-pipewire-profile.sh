if pactl get-default-source | grep -q "analog-stereo"; then
	pactl set-card-profile alsa_card.pci-0000_00_1b.0 output:hdmi-stereo
else
	pactl set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo
fi

