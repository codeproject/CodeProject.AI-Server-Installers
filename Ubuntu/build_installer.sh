#!/bin/bash

# Builds an Ubuntu install .deb package.
#
#    bash build_installer.sh
#
# NOTE: Line spacing is done so methods line up with corresponding methods in
#       the macOS installer

# Configuration Variables and Parameters

# Whether or not to create an installer which adds the service to systemd for
# auto-start (true) or as manual startup (false)
ADD_TO_STARTUP="true"

### Directory names

BUILD_DIRNAME="build"
INSTALLER_DIRNAME="installer"





### Parameters

# The location of the root of the server repo relative to this script
repo_base="../../CodeProject.AI-Server"
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

# We're building for the current server version
MAJOR=$(grep -o '"Major"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
MINOR=$(grep -o '"Minor"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
PATCH=$(grep -o '"Patch"\s*:\s*[^,}]*' "${repo_base}/src/server/version.json" | sed 's/.*: \(.*\)/\1/')
VERSION="${MAJOR}.${MINOR}.${PATCH}"

DOTNET_VERSION="9.0"

# Utilities
source "${repo_base}/src/scripts/utils.sh"

# For places where we need no spaces (eg identifiers)
PRODUCT_ID="${PRODUCT// /-}"

# in macos script,
# this has the service ID

# An ID used to identify the package in the OS package list (eg company.product)
PACKAGE_ID=`echo $PRODUCT_ID | tr '[:upper:]' '[:lower:]'`

# in macos script,
# this has the certificate info

ARCH_SHORT="${architecture}"
if [ "${ARCH_SHORT}" = "x86_64" ]; then ARCH_SHORT="x64"; fi

### Names and Locations

# Location in /usr/bin, /usr/local/bin
PRODUCT_DIRNAME=`echo "${PACKAGE_ID}-${VERSION}" | tr '[:upper:]' '[:lower:]'`
PRODUCT_DIRNAME="${PACKAGE_ID}-${VERSION}"

# Directory we place everything in prep for package build
BUILD_DIRECTORY="$SCRIPT_PATH/${BUILD_DIRNAME}"

# Where application will be copied
APPLICATION_DIRECTORY="${BUILD_DIRECTORY}/usr/bin/${PRODUCT_DIRNAME}"

# Directory where the output .deb installer will be saved
INSTALLER_DIRECTORY="$SCRIPT_PATH/${INSTALLER_DIRNAME}"

# Name of the installer packages (according to dpkg-deb docs)
GENERATED_INSTALLER_FILENAME="${PACKAGE_ID}_${VERSION}_all.deb"
INSTALLER_FILENAME="${PACKAGE_ID}_${VERSION}_Ubuntu_${ARCH_SHORT}.deb"


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
    log_info "Creating Build directory."
    mkdir -pv "$BUILD_DIRECTORY"  >/dev/null 2>&1

    if [[ $? != 0 ]]; then
        log_error "Failed to create ${BUILD_DIRECTORY} directory" $?
        exit 1
    fi
}







# Copy the templates into the build directory and adjust their values
copyTemplatesDirectory(){

    cp -r "${SCRIPT_PATH}/templates/DEBIAN/" "${BUILD_DIRECTORY}/"

    chmod -R 755 "${BUILD_DIRECTORY}/DEBIAN/"
    chmod a+rw ${BUILD_DIRECTORY}/DEBIAN/postinst
    chmod a+rw ${BUILD_DIRECTORY}/DEBIAN/prerm
    chmod a+rw ${BUILD_DIRECTORY}/DEBIAN/control

    # handle slashes in paths
    exe_path="${APPLICATION_FILE_PATH//\//\\/}"

    log_info "Configuring post-install script"
    sed -i -e "s/__VERSION__/${VERSION}/g"                 "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__DOTNET_VERSION__/${DOTNET_VERSION}/g"   "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                 "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__APPLICATION_FILE_PATH__/${exe_path}/g"  "${BUILD_DIRECTORY}/DEBIAN/postinst"
    sed -i -e "s/__ADD_TO_STARTUP__/${ADD_TO_STARTUP}/g"   "${BUILD_DIRECTORY}/DEBIAN/postinst"
    chmod 755 "${BUILD_DIRECTORY}/DEBIAN/postinst"

    log_info "Configuring pre-removal script"
    sed -i -e "s/__VERSION__/${VERSION}/g"                 "${BUILD_DIRECTORY}/DEBIAN/prerm"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                 "${BUILD_DIRECTORY}/DEBIAN/prerm"
    sed -i -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${BUILD_DIRECTORY}/DEBIAN/prerm"
    sed -i -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${BUILD_DIRECTORY}/DEBIAN/prerm"
    sed -i -e "s/__APPLICATION_FILE_PATH__/${exe_path}/g"  "${BUILD_DIRECTORY}/DEBIAN/prerm"
    chmod 755 "${BUILD_DIRECTORY}/DEBIAN/prerm"

    log_info "Configuring control meta data"
    sed -i -e "s/__VERSION__/${VERSION}/g"                 "${BUILD_DIRECTORY}/DEBIAN/control"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                 "${BUILD_DIRECTORY}/DEBIAN/control"
    sed -i -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${BUILD_DIRECTORY}/DEBIAN/control"
    chmod 755 "${BUILD_DIRECTORY}/DEBIAN/control"
}





# Copy our application into the build directory (under /usr/bin/product in the build dir)
copyApplicationDirectory() {

    # Copy application to /usr/bin/product_version
    mkdir -p "${APPLICATION_DIRECTORY}"

    # 1. Build server
    log_info "Building Application"
    dotnet build ${repo_base}/src/server /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary -c Release > /dev/null # 2>&1

    # 2. Move files to the Staging area
    log_info "Copying application into build directory"

    mkdir -p "${APPLICATION_DIRECTORY}/server"
    cp -r "${repo_base}/src/server/bin/Release/net${DOTNET_VERSION}/." "${APPLICATION_DIRECTORY}/server/"
    cp "${repo_base}/LICENCE.md" "${APPLICATION_DIRECTORY}"

    mkdir -p "$APPLICATION_DIRECTORY/SDK"
    cp -r "${repo_base}/src/SDK/Python" "${APPLICATION_DIRECTORY}/SDK/Python/"

    mkdir -p "$APPLICATION_DIRECTORY/devops/utils"
    cp ${repo_base}/devops/utils/*.sh "${APPLICATION_DIRECTORY}/devops/utils"
    cp -r "${repo_base}/src/scripts"  "${APPLICATION_DIRECTORY}/scripts/"

    cp "${repo_base}/src/SDK/install.sh" "${APPLICATION_DIRECTORY}/SDK/"
    cp "${repo_base}/src/server/install.sh" "${APPLICATION_DIRECTORY}/server/"

    cp "${repo_base}/src/setup.sh" "${APPLICATION_DIRECTORY}/"

    # Quick cleanup
    find "${APPLICATION_DIRECTORY}" -name __pycache__ -type d -exec rm -rf {} \;  >/dev/null 2>&1

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
    log_info "Application installer package building started."
    
    rm -rf "${INSTALLER_DIRECTORY}"
    mkdir -p "${INSTALLER_DIRECTORY}"
    chmod -R 755 "${INSTALLER_DIRECTORY}"

    dpkg-deb --build "${BUILD_DIRECTORY}" "${INSTALLER_DIRECTORY}" >/dev/null
}

# "buildProduct" in macOS installer













# "signProduct" in macOS installer






























# Add an uninstaller to the application dir in the build dir
function addUninstallerToApp(){
    cp "$SCRIPT_PATH/templates/Resources/uninstall.sh"      "${APPLICATION_DIRECTORY}"
    sed -i -e "s/__VERSION__/${VERSION}/g"                 "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                 "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${APPLICATION_DIRECTORY}/uninstall.sh"
    sed -i -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${APPLICATION_DIRECTORY}/uninstall.sh"
}


# Add the systemd file
function addSystemdInfoToApp(){

    # handle slashes in paths
    exe_path="${APPLICATION_FILE_PATH//\//\\/}"

    cp "$SCRIPT_PATH/templates/systemd.service" "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
    sed -i -e "s/__PRODUCT__/${PRODUCT}/g"                 "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
    sed -i -e "s/__VERSION__/${VERSION}/g"                 "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
    sed -i -e "s/__PACKAGE_ID__/${PACKAGE_ID}/g"           "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
    sed -i -e "s/__PRODUCT_DIRNAME__/${PRODUCT_DIRNAME}/g" "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
    sed -i -e "s/__APPLICATION_START_SCRIPT__/start.sh/g"  "${APPLICATION_DIRECTORY}/${PACKAGE_ID}.service"
}

# Add the launch shortcut
function addLaunchShortcutToApp() {
    log_info "Creating application launch script"

    rm "${APPLICATION_DIRECTORY}/start.sh" >/dev/null 2>&1
    cat > "${APPLICATION_DIRECTORY}/start.sh" <<EOF
cd "/usr/bin/${PRODUCT_DIRNAME}/server"
dotnet CodeProject.AI.Server.dll &
sleep 5
open http://localhost:32168 &
while true; do sleep 86400; done
EOF
    chmod a+x "${APPLICATION_DIRECTORY}/start.sh"
}






# run the package builder
function createInstaller() {
    log_info "Application installer generation process started."

    buildPackage

    log_info "Application installer generation finished."
}



function moveInstallPackage(){
    mv "${INSTALLER_DIRECTORY}/${GENERATED_INSTALLER_FILENAME}" "${INSTALLER_FILENAME}"
}




function cleanDirectories(){
    rm -rf "${BUILD_DIRECTORY}"
    rm -rf "${INSTALLER_DIRECTORY}"
}


# Let's begin
log_info "Installer generating process started."

createBuildDirectory
copyTemplatesDirectory
copyApplicationDirectory
addUninstallerToApp
addSystemdInfoToApp
addLaunchShortcutToApp
createInstaller
moveInstallPackage
cleanDirectories

log_info "Zipping up installer."
sudo apt-get install zip > /dev/null
zip "${INSTALLER_FILENAME%.*}.zip" "${INSTALLER_FILENAME}"

writeLine
log_info "DONE! Installer is in ${INSTALLER_FILENAME}"
writeLine
log_info "To install,   run: sudo dpkg -i ${INSTALLER_FILENAME}"
log_info "To uninstall, run: sudo dpkg -r ${PACKAGE_ID}"
writeLine


exit 0
