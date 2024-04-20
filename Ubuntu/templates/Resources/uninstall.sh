#!/bin/bash

#Generate application uninstallers for macOS.

#Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

echo "Welcome to Application Uninstaller"
echo "The following packages will be REMOVED:"
echo "  __PRODUCT__-__VERSION__"
while true; do
    read -p "Do you wish to continue [y/n]?" answer
    [[ $answer == "y" || $answer == "Y" || $answer == "" ]] && break
    [[ $answer == "n" || $answer == "N" ]] && exit 0
    echo "Please answer with 'y' or 'n'"
done


#Need to replace these with install preparation script
VERSION=__VERSION__
PRODUCT="__PRODUCT__"
PRODUCT_ID="${PRODUCT// /-}"
PACKAGE_ID="${PRODUCT_ID}"
PRODUCT_DIRNAME="__PRODUCT_DIRNAME__"

echo "Application uninstalling process started"

systemctl stop ${PACKAGE_ID}             2>/dev/null
systemctl disable ${PACKAGE_ID}          2>/dev/null
rm /etc/systemd/system/${PACKAGE_ID}     >/dev/null 2>&1 
rm /etc/systemd/system/${PACKAGE_ID}     >/dev/null 2>&1 # and symlinks that might be related
rm /usr/lib/systemd/system/${PACKAGE_ID} >/dev/null 2>&1 
rm /usr/lib/systemd/system/${PACKAGE_ID} >/dev/null 2>&1 # and symlinks that might be related
systemctl daemon-reload
echo " - Removed from systemd"

# remove application source distribution
[ -e "/usr/bin/${PRODUCT_DIRNAME}" ] && rm -rf "/usr/bin/${PRODUCT_DIRNAME}"
if [ $? -eq 0 ]
then
  echo " - Deleted application"
else
  echo " - [ERROR] Could not delete application" >&2
fi

# remove shortcut
rm "/usr/local/bin/${PRODUCT_DIRNAME}"
if [ $? -eq 0 ]
then
  echo " - Deleted shortcut links"
else
  echo " - [ERROR] Could not delete shortcut links" >&2
fi

# HACK: For CodeProject
while true; do
    read -p "Do you wish to remove application settings [y/n]?" clean_up
    [[ $clean_up == "y" || $answer == "Y" || $clean_up == "" ]] && break
    [[ $clean_up == "n" || $clean_up == "N" ]] && echo "Application uninstall process finished" && exit 0
    echo "Please answer with 'y' or 'n'"
done

rm -rf "/etc/codeProject/ai"

echo "Application uninstall process finished"
exit 0
