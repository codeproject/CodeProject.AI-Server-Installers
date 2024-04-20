#!/bin/bash

# Generate application uninstallers for macOS.

log_info() {
    echo "[INFO]" $1
}

log_warn() {
    echo "[WARN]" $1
}

log_error() {
    echo "[ERROR]" $1
}

#Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

echo "Welcome to the __PRODUCT__ Uninstaller"
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
PRODUCT_HOME="/Library/__PRODUCT__/__VERSION__"
PRODUCT_ID="${PRODUCT// /-}"
PACKAGE_ID="__PACKAGE_ID__"
SERVICE_ID="__SERVICE_ID__"
PRODUCT_SHORTCUT="__PRODUCT_SHORTCUT__"

echo "Application uninstalling process started"

# Remove as service
launchctl stop ${SERVICE_ID}
launchctl remove ${SERVICE_ID}
# Could be either. Try both
rm /Library/LaunchAgents/${SERVICE_ID}.plist > /dev/null 2>&1
rm /Library/LaunchDaemons/${SERVICE_ID}.plist > /dev/null 2>&1
rm "/Library/StartupItems/${PRODUCT}.command" > /dev/null 2>&1

# remove link to shorcut file
rm "/usr/local/bin/${PRODUCT_SHORTCUT}"
if [ $? -eq 0 ]
then
  echo "[1/3] [DONE] Successfully deleted shortcut links"
else
  echo "[1/3] [ERROR] Could not delete shortcut links" >&2
fi

login_item_name="YourApp"

# Remove the Login Item using AppleScript
osascript <<EOD
tell application "System Events"
    delete login item "${PRODUCT}.command"
end tell
EOD

#forget from pkgutil
pkgutil --forget "${PACKAGE_ID}" > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo "[2/3] [DONE] Successfully deleted application information"
else
  echo "[2/3] [ERROR] Could not delete application information" >&2
fi

# remove application source distribution
[ -e "${PRODUCT_HOME}" ] && rm -rf "${PRODUCT_HOME}"
if [ $? -eq 0 ]
then
  echo "[3/3] [DONE] Successfully deleted application"
else
  echo "[3/3] [ERROR] Could not delete application" >&2
fi

# HACK: For CodeProject
while true; do
    read -p "Do you wish to remove application settings [y/n]?" clean_up
    [[ $clean_up == "y" || $answer == "Y" || $clean_up == "" ]] && break
    [[ $clean_up == "n" || $clean_up == "N" ]] && echo "Application uninstall process finished" && exit 0
    echo "Please answer with 'y' or 'n'"
done

rm -rf "/Library/Application Support/CodeProject/AI"

echo "Application uninstall process finished"
exit 0
