#!/bin/bash

# Builds a macOS install pkg.
#
#    bash build_installer.sh
#
# NOTE: Line spacing is done so methods line up with corresponding methods in
#       the Ubuntu installer

# Configuration Variables and Parameters

# Whether or not to create an installer which adds the service to systemd for
# auto-start (true) or as a login item (false)
ADD_TO_STARTUP="false"

### Directory names

BUILD_DIRNAME="build"
PACKAGE_DIRNAME="package"
STAGING_DIRNAME="staging"
TEMPLATES_DEST_DIRNAME="templates"
INSTALLER_DIRNAME="installer"


### Parameters

# The location of the root of the server repo relative to this script
repo_base="../../CodeProject.AI-Server-Dev"
pushd "$repo_base" > /dev/null
repo_base="$(pwd)"
popd > /dev/null

# This script
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The path, relative to the root of the install, used to launch the application
# eg "myapp" or "server/myserver". A shortcut to /usr/local/bin will be created
APPLICATION_FILE_PATH="server/CodeProject.AI.Server.dll"

# Product and version (version passed in)
PRODUCT="CodeProject.AI Server"

DOTNET_VERSION="9.0"

# We're building for the current server version
MAJOR=$(grep -o '"Major"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
MINOR=$(grep -o '"Minor"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
PATCH=$(grep -o '"Patch"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Utilities
source "${repo_base}/src/scripts/utils.sh"

# For places where we need no spaces (eg identifiers)
PRODUCT_ID="${PRODUCT// /-}"

# An ID used to identify the package in the OS service list (eg application.company.product)
SERVICE_ID="application.com.codeproject.ai.server"

# An ID used to identify the package in the OS package list (eg company.product)
PACKAGE_ID="com.codeproject.ai.server.pkg.${VERSION}"

# The Apple dev certificate ID. Used for signing the installer (passed in)
APPLE_DEVELOPER_CERTIFICATE_ID=${2}

ARCH_SHORT="${architecture}"
if [ "${ARCH_SHORT}" = "x86_64" ]; then ARCH_SHORT="x64"; fi

### Names and Locations

# Location in /Library
PRODUCT_DIRNAME="${PRODUCT}"


# Directory we place everything in prep for package build
BUILD_DIRECTORY="$SCRIPT_PATH/${BUILD_DIRNAME}"

# Where application will be copied
APPLICATION_DIRECTORY="${BUILD_DIRECTORY}/${STAGING_DIRNAME}/Library/${PRODUCT}/${VERSION}"

# Directory where the output .deb installer will be saved
INSTALLER_DIRECTORY="${BUILD_DIRECTORY}/${INSTALLER_DIRNAME}"

# Name of the installer packages
INSTALLER_FILENAME="${PRODUCT_ID}_${VERSION}_macOS_${ARCH_SHORT}.pkg"
INSTALLER_FILENAME_SIGNED="${PRODUCT_ID}_${VERSION}_macOS_${ARCH_SHORT}-signed.pkg"


# Parameter validation

if [[ "${VERSION}" =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
    echo
    echo "Building installer for ${PRODUCT} ${VERSION}"
    echo
else
    echo
    echo "Please check the version info in /src/server/version.json"
    echo
    exit 1
fi

# Functions
go_to_dir() {
    pushd $1 >/dev/null 2>&1
}

log_info() {
    writeLine "$1" $color_info
}

log_warn() {
    writeLine "$1" $color_warn
}

log_error() {
    writeLine "$1" $color_error
}

deleteBuildDirectory() {
    log_info "Cleaning $BUILD_DIRECTORY directory."
    rm -rf "$BUILD_DIRECTORY"  >/dev/null 2>&1

    if [[ $? != 0 ]]; then
        log_error "Failed to clean $BUILD_DIRECTORY directory" $?
        exit 1
    fi
}

# Create the build directory: this is the staging area for the package
createBuildDirectory() {
    if [ -d "${BUILD_DIRECTORY}" ]; then
        deleteBuildDirectory
    fi
    log_info "Creating $BUILD_DIRECTORY directory."
    mkdir -pv "$BUILD_DIRECTORY"  >/dev/null 2>&1

    if [[ $? != 0 ]]; then
        log_error "Failed to create ${BUILD_DIRECTORY} directory" $?
        exit 1
    fi

    mkdir -p "${BUILD_DIRECTORY}/${STAGING_DIRNAME}"
    chmod -R 755 "${BUILD_DIRECTORY}/${STAGING_DIRNAME}"

    mkdir -p "${BUILD_DIRECTORY}/${PACKAGE_DIRNAME}"
    chmod -R 755 "${BUILD_DIRECTORY}/${PACKAGE_DIRNAME}"  
}

# Copy the templates into the build directory and adjust their values
copyTemplatesDirectory(){

    cp -r "$SCRIPT_PATH/templates" "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}"

    chmod -R 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts"
    chmod -R 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Resources"
    chmod 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution"

    # handle slashes in paths
    exe_path="${APPLICATION_FILE_PATH//\//\/}"
    exe_path="${exe_path//\./\\.}"

    # echo "$APPLICATION_FILE_PATH"
    # echo "$exe_path"

    log_info "Configuring postinstall script"
    sed -i '' -e "s/__VERSION__/${VERSION}/g"                 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__DOTNET_VERSION__/${DOTNET_VERSION}/g"   "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__PRODUCT__/${PRODUCT}/g"                 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__SERVICE_ID__/${SERVICE_ID}/g"           "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__APPLICATION_FILE_PATH__/${exe_path}/g"  "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    sed -i '' -e "s/__ADD_TO_STARTUP__/${ADD_TO_STARTUP}/g"   "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"
    chmod -R 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts/postinstall"

    log_info "Configuring Distribution"
    sed -i '' -e "s/__VERSION__/${VERSION}/g"       "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution"
    sed -i '' -e "s/__PRODUCT_NAME__/${PRODUCT}/g"  "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution"
    sed -i '' -e "s/__PRODUCT_ID__/${PRODUCT_ID}/g" "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution"
    chmod -R 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution"

    log_info "Configuring HTML resources"
    sed -i '' -e "s/__VERSION__/${VERSION}/g"       "${BUILD_DIRECTORY}"/${TEMPLATES_DEST_DIRNAME}/Resources/*.html
    sed -i '' -e "s/__PRODUCT__/${PRODUCT}/g"       "${BUILD_DIRECTORY}"/${TEMPLATES_DEST_DIRNAME}/Resources/*.html
    sed -i '' -e "s/__PLATFORM__/${PLATFORM}/g"     "${BUILD_DIRECTORY}"/${TEMPLATES_DEST_DIRNAME}/Resources/*.html
    sed -i '' -e "s/__ARCH_SHORT__/${ARCH_SHORT}/g" "${BUILD_DIRECTORY}"/${TEMPLATES_DEST_DIRNAME}/Resources/*.html
    chmod -R 755 "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Resources/"
}


# Copy our application into the build directory (under /usr/bin/product in the build dir)
copyApplicationDirectory() {

    # Copy application to /usr/bin/product_version
    mkdir -p "${APPLICATION_DIRECTORY}"

    # 1. Build server
    log_info "Building Application"
    dotnet build ${repo_base}/src/server /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary -c Release > /dev/null

    # 2. Move files to the Staging area
    log_info "Copying application into build directory"

    mkdir -p "${APPLICATION_DIRECTORY}/server"
    cp -r "${repo_base}/src/server/bin/Release/net${DOTNET_VERSION}/." "${APPLICATION_DIRECTORY}/server/"
    cp "${repo_base}/LICENCE.md" "${APPLICATION_DIRECTORY}"

    mkdir -p "$APPLICATION_DIRECTORY/SDK"
    cp -r "${repo_base}/src/SDK/Python"     "${APPLICATION_DIRECTORY}/SDK/Python/"

    mkdir -p "$APPLICATION_DIRECTORY/devops/utils"
    cp ${repo_base}/devops/utils/*.sh "${APPLICATION_DIRECTORY}/devops/utils"
    cp -r "${repo_base}/src/scripts"  "${APPLICATION_DIRECTORY}/scripts/"

    cp "${repo_base}/src/server/install.sh" "${APPLICATION_DIRECTORY}/server/"

    cp "${repo_base}/src/setup.sh" "${APPLICATION_DIRECTORY}/"

    # Quick cleanup
    find "${APPLICATION_DIRECTORY}" -name __pycache__ -type d -exec rm -rf {} \; >/dev/null 2>&1

    # Create directories
    log_info "Creating placeholder directories"

    mkdir -p "${APPLICATION_DIRECTORY}/runtimes"
    mkdir -p "${APPLICATION_DIRECTORY}/models"
    mkdir -p "${APPLICATION_DIRECTORY}/modules"
    mkdir -p "${APPLICATION_DIRECTORY}/downloads"

    chmod -R 755 "${APPLICATION_DIRECTORY}"
}


# run the package builder
function buildPackage() {
    log_info " 1. Application installer package building started."

    pkgbuild --identifier "${PACKAGE_ID}" \
             --version "${VERSION}" \
             --scripts "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/scripts" \
             --root "${BUILD_DIRECTORY}/${STAGING_DIRNAME}" \
             "${BUILD_DIRECTORY}/${PACKAGE_DIRNAME}/${PRODUCT_ID}.pkg" >/dev/null 2>&1
}

# run the product builder
function buildProduct() {
    log_info " 2. Application installer product building started."

    rm -rf "${INSTALLER_DIRECTORY}"
    mkdir -p "${INSTALLER_DIRECTORY}"
    chmod -R 755 "${INSTALLER_DIRECTORY}"

    productbuild --distribution "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Distribution" \
                 --resources "${BUILD_DIRECTORY}/${TEMPLATES_DEST_DIRNAME}/Resources" \
                 --package-path "${BUILD_DIRECTORY}/${PACKAGE_DIRNAME}" \
                 "${INSTALLER_DIRECTORY}/${INSTALLER_FILENAME}" > /dev/null 2>&1
}

function signProduct() {

    # while true; do
    #     read -p "Do you wish to sign the installer (You should have Apple Developer Certificate) [y/N]?" answer
    #     [[ $answer == "y" || $answer == "Y" ]] && FLAG=true && break
    #     [[ $answer == "n" || $answer == "N" || $answer == "" ]] && log_info "  (Skipped signing process)" && FLAG=false && break
    #     echo "Please answer with 'y' or 'n'"
    # done
    # [[ $FLAG != "true" ]] && exit

    # If you want to force things
    # if [ "${APPLE_DEVELOPER_CERTIFICATE_ID}" == "" ]; then
    #    read -p "Please enter the Apple Developer Installer Certificate ID:" APPLE_DEVELOPER_CERTIFICATE_ID
    # fi

    if [ "${APPLE_DEVELOPER_CERTIFICATE_ID}" != "" ]; then
        log_info " 3. Application installer signing process started."

        mkdir -pv "${INSTALLER_DIRECTORY}-signed"
        chmod -R 755 "${INSTALLER_DIRECTORY}-signed"

        productsign --sign "Developer ID Installer: ${APPLE_DEVELOPER_CERTIFICATE_ID}" \
                    "${INSTALLER_DIRECTORY}/${INSTALLER_FILENAME}" \
                    "${INSTALLER_DIRECTORY}-signed/${INSTALLER_FILENAME_SIGNED}"

        pkgutil --check-signature "${INSTALLER_DIRECTORY}-signed/${INSTALLER_FILENAME_SIGNED}"
    else
        log_info " 3. Application installer signing process skipped."
    fi
}

# Add an uninstaller to the application dir in the build dir
function addUninstallerToApp(){
    cp "$SCRIPT_PATH/templates/Resources/uninstall.sh" "${APPLICATION_DIRECTORY}"
    sed -i '' -e "s/__VERSION__/${VERSION}/g"          "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i '' -e "s/__PRODUCT__/${PRODUCT}/g"          "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i '' -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"    "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i '' -e "s/__SERVICE_ID__/${SERVICE_ID}/g"    "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i '' -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${APPLICATION_DIRECTORY}/uninstall.sh"
}

# Add the launcherd file
function addLauncherdInfoToApp(){

    # handle slashes in paths
    exe_path="${APPLICATION_FILE_PATH//\//\\/}"

    cp "$SCRIPT_PATH/templates/launchd.plist" "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist"
    sed -i -e "s/__VERSION__/${VERSION}/g"                "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist"
    sed -i -e "s/__SERVICE_ID__/${SERVICE_ID}/g"          "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist"
    sed -i -e "s/__APPLICATION_FILE_PATH__/${exe_path}/g" "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist"
    rm "${APPLICATION_DIRECTORY}/${SERVICE_ID}.plist-e"
}

# Add the launch shortcut
function addLaunchShortcutToApp() {
    log_info "Creating application launch script"

    rm "${APPLICATION_DIRECTORY}/${PRODUCT}.command"  >/dev/null 2>&1
    cat > "${APPLICATION_DIRECTORY}/${PRODUCT}.command" <<EOF
#!/bin/bash

cd "/Library/${PRODUCT}/${VERSION}/server"
dotnet CodeProject.AI.Server.dll &
sleep 5
open http://localhost:32168 &
while true; do sleep 86400; done
EOF
    chmod a+x "${APPLICATION_DIRECTORY}/${PRODUCT}.command"
    bash setIcon.sh "${repo_base}/src/server/codeproject125x125.png" "${APPLICATION_DIRECTORY}/${PRODUCT}.command"
    # mv "${APPLICATION_DIRECTORY}/${PRODUCT}.command" "${APPLICATION_DIRECTORY}/${PRODUCT}.app"
    # bash setIcon.sh "${repo_base}/src/server/codeproject125x125.png" "${APPLICATION_DIRECTORY}/${PRODUCT}.app"
}

# run the package builder, product builder, and product signer
function createInstaller() {
    log_info "Application installer generation process started (3 Steps)"

    buildPackage
    buildProduct
    signProduct

    log_info "Application installer generation steps finished."
}

function moveInstallPackage(){
    mv "${INSTALLER_DIRECTORY}/${INSTALLER_FILENAME}" . > /dev/null 2>&1
    if [ "${APPLE_DEVELOPER_CERTIFICATE_ID}" != "" ]; then
        mv "${INSTALLER_DIRECTORY}-signed/${INSTALLER_FILENAME_SIGNED}" . > /dev/null 2>&1
    fi
}

function cleanDirectories(){
    # rm -rf "${BUILD_DIRECTORY}"
    echo
}



# Let's begin
log_info "Installer generating process started."

createBuildDirectory
copyTemplatesDirectory
copyApplicationDirectory
addUninstallerToApp
addLauncherdInfoToApp
addLaunchShortcutToApp
createInstaller
moveInstallPackage
cleanDirectories

log_info "Zipping up installer."
zip "${INSTALLER_FILENAME%.*}.zip" "${INSTALLER_FILENAME}"

echo
log_info "DONE! Installer is in ${INSTALLER_FILENAME}"
echo
echo "To install,   double-click ${INSTALLER_FILENAME}"
echo "To uninstall, run: sudo bash '/Library/${PRODUCT}/${VERSION}/uninstall.sh'"
echo

exit 0
