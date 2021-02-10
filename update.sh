#!/bin/bash
# World Possible DCYF-WA update script
# This script may be run multiple times, so all operations need to be idempotent

mydir=$(readlink -f $(dirname $0))
if [[ "$EUID" != 0 ]]; then
	echo "Requesting root privileges"
	exec sudo bash $(readlink -f $0)
	exit 1
fi

error_handler() {
	echo "Failure on line ${LINENO}"
	exit 1
}
trap error_handler ERR

echo "Enabling remote access via SSH"
mkdir -p /etc/systemd/system-preset
cat <<EOF >/etc/systemd/system-preset/40-ssh.preset
enable ssh.service
EOF
systemctl preset ssh.service
systemctl start ssh.service

pkexec --user Debian-gdm dbus-run-session gsettings set org.gnome.shell password-reset-allowed disable &>/dev/null

bash $mydir/content-cleanup.sh

echo "Starting WiFi setup..."
bash $mydir/setup-wifi.sh

echo "Disabling automatic OS updates"
mkdir -p /etc/systemd/system-preset
cat <<EOF >/etc/systemd/system-preset/40-disable-automatic-os-updates.preset
disable eos-autoupdater.timer
disable eos-autoupdater.service
EOF
systemctl preset eos-autoupdater.timer
systemctl stop eos-autoupdater.timer
systemctl preset eos-autoupdater.service
systemctl mask --now eos-updater.service

echo "Disabling app updates"
gsettings set org.gnome.software download-updates false

# Remove the rollback ostree deployment, if needed
deployed_versions=()
for v in $(ostree admin status | awk '/Version/ { print $2 }') ; do
	deployed_versions+=( $v )
done
echo "Deployed ostree versions: ${deployed_versions[@]}"

if [ ${#deployed_versions[@]} -gt 1 ] ; then
	echo "Found more than one deployed ostree, ${deployed_versions[1]} is set to be removed."
	echo "If this is not the version that should be removed, please reboot"
	echo "into the correct OS version and re-run this script. Do you want to continue?"
	select yn in "Yes" "No"; do
		case $yn in
			Yes ) break;;
			No ) exit 0;;
		esac
	done
	echo "Removing rollback ostree ${deployed_versions[1]}"
	ostree admin undeploy 1
fi
