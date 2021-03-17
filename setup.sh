#!/bin/bash
# World Possible DCYF-WA initial setup script
# This should only be run on newly flashed machines, as the operations are NOT
# idempotent.

mydir=$(readlink -f "$(dirname $0)")
if [[ "$EUID" != 0 ]]; then
	echo "Requesting root privileges"
	exec sudo bash "$(readlink -f $0)"
	exit 1
fi

error_handler() {
	echo "Failure on line ${LINENO}"
	exit 1
}
trap error_handler ERR

exec &> >(tee -a setup.log)

read -p "Please enter username for new student account (lastnamefirstinitial): " username
read -p "Please enter password for new student account (JRA number): " password

adduser --disabled-password --gecos '' $username
usermod -a -G lpadmin $username
echo "$username:$password" | chpasswd
passwd $username -n 10000

read -p "Please enter new jadmin password: " result
echo "jadmin:$result" | chpasswd

read -p "Please enter new shared account password: " result
# Not 100% sure which shared account username is used, so try 3
for username in shared SharedAccount sharedaccount; do
	id $username &>/dev/null || continue
	echo "$username:$result" | chpasswd
	echo "Changed password for $username"
done

userdel -r student || :

read -p "Please enter the current date (YYYYMMDD) : " userdate
read -p "Please enter the current time (HH:MM) : " usertime
date -s "$userdate $usertime"
