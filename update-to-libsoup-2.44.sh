#!/bin/sh

# Script for updating libsoup to 2.44 and updating the vala/valadoc to use it/
#  expose the updated vapi files. Should only be used for updating old envs. 
#  new envs should be setup using bootstrap/gradle script

bailout()
{
    local message="$1"

    echo "*** Script stopped prematurely: ${message}" 2>&1 | tee -a ${log_file}
    echo "*** (see details above)" 2>&1 | tee -a ${log_file}
    exit 1
}

status()
{
    echo ""
    echo "*****************************************"
    echo "* $1"
    echo "*****************************************"
    echo ""
}

# check env vars
if [ -z ${CVP2_GIT} ]; then
   bailout "\${CVP2_GIT} not set. Is your build environment setup?"
fi

if [ -z ${CVP2_ROOT} ]; then
   bailout "\${CVP2_ROOT} not set. Is your build environment setup?"
fi

status "Downloading libsoup-2.44..."
mkdir -p "$CVP2_BUILD/packages"
cd "$CVP2_BUILD/packages"
wget -c "http://ftp.gnome.org/pub/GNOME/sources/libsoup/2.44/libsoup-2.44.0.tar.xz" || bailout "Failed download of libsoup"
cd "$CVP2_BUILD/src"

status "Extracting libsoup-2.44..."
tar xf ../packages/libsoup-2.44.0.tar.xz || bailout "Failed to extract libsoup"

status "Uninstalling vala..."
cd "$CVP2_BUILD"/src/vala-* || bailout "Couldn't cd to $CVP2_BUILD/src/vala-*"
make uninstall
make clean

status "Uninstalling valadoc..."
cd "$CVP2_GIT/valadoc" || bailout "Couldn't cd to $CVP2_GIT/valadoc..."
make uninstall
make clean

status "Pulling vala from git..."
cd "$CVP2_GIT"
git clone "git://git.gnome.org/vala" || bailout "Error cloning git://git.gnome.org/vala"
cd vala || bailout "Couldn't cd to vala directory"
# the version I've been testing with
git checkout "b05fa3325" || bailout "Error checking out revision b05fa3325" 

status "Updating valadoc..."
cd "$CVP2_GIT/valadoc"
# the version I've been testing with
git fetch || bailout "Error updating valadoc"
git checkout "98e3eb82" || bailout "Error checking out revision 98e3eb820"

status "Building libsoup-2.44..."
cd "$CVP2_BUILD/src/libsoup-2.44.0" || bailout "Couln't cd to libsoup-2.44.0"
./configure --prefix=$CVP2_ROOT --enable-introspection || bailout "Error autogen libsoup-2.44.0"
make || bailout "Error building libsoup-2.44.0"
make install || bailout "Error installing libsoup-2.44.0"

status "Building vala..."
cd "$CVP2_GIT/vala" || bailout "Couln't cd to $CVP2_BUILD/src/vala"
./autogen.sh --prefix=$CVP2_ROOT || bailout "Error autogen vala"
make || bailout "Error building vala"
make install || bailout "Error installing vala"

status "Building valadoc..."
cd "$CVP2_GIT/valadoc" || bailout "Couln't cd to $CVP2_BUILD/src/valadoc"
./autogen.sh --prefix=$CVP2_ROOT || bailout "Error autogen valadoc"
make || bailout "Error building valadoc"
make install || bailout "Error installing valadoc"

status "libsoup/vala successfully upgraded.\n Rebuild your dependant CVP2 project(s) to use the new version"

