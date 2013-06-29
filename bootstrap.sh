#!/bin/bash

# To deal with the tees...
set -o pipefail

default_build=~/cvp2

prerequisite_packages=(
"git"
"g++"
"bison"
"flex"
"python-dev"
"gtk-doc-tools"
"graphviz-dev"
"graphviz"
"libxml-parser-perl"
"libdbus-1-dev"
"libasound2-dev"
"libx11-dev"
"yasm"
"cvs"
)

external_packages=(
"http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz" ""
"http://ftp.gnu.org/gnu/automake/automake-1.13.2.tar.xz" ""
"http://zlib.net/zlib-1.2.8.tar.xz" ""
"ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz" ""
"http://ftp.gnome.org/pub/GNOME/sources/glib/2.36/glib-2.36.3.tar.xz" ""
"http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz" ""
"https://www.kernel.org/pub/linux/utils/util-linux/v2.23/util-linux-2.23.tar.xz" "--without-ncurses --disable-use-tty-group --disable-bash-completion"
"http://ftp.gnu.org/pub/gnu/libtool/libtool-2.4.2.tar.xz" ""
"http://www.sqlite.org/2013/sqlite-autoconf-3071602.tar.gz" ""
"http://xmlsoft.org/sources/libxml2-sources-2.7.8.tar.gz" ""
"http://ftp.gnu.org/gnu/gmp/gmp-5.1.1.tar.xz" "ABI=32"
"http://www.lysator.liu.se/~nisse/archive/nettle-2.7.tar.gz" ""
"ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.0.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/gobject-introspection/1.36/gobject-introspection-1.36.0.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/vala/0.20/vala-0.20.1.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/gnome-common/3.7/gnome-common-3.7.4.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/intltool/0.40/intltool-0.40.6.tar.gz" ""
"http://ftp.gnu.org/gnu/gettext/gettext-0.18.tar.gz" ""
"http://ftp.gnome.org/pub/GNOME/sources/glib-networking/2.37/glib-networking-2.37.1.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/libsoup/2.43/libsoup-2.43.1.tar.xz" "--enable-introspection"
"http://ftp.gnome.org/pub/GNOME/sources/gupnp-vala/0.10/gupnp-vala-0.10.5.tar.xz" ""
"http://ftp.gnome.org/pub/GNOME/sources/libgee/0.8/libgee-0.8.6.tar.xz" "--enable-introspection"
"http://code.entropywave.com/download/orc/orc-0.4.17.tar.gz" ""
)

cvp2_repos=(
"http://anongit.freedesktop.org/git/gstreamer/gstreamer.git" "2f78e96299" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"git@bitbucket.org:cvp2ri/gst-plugins-base.git" "cbl_master/plugfest35" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"git@bitbucket.org:cvp2ri/gst-plugins-good.git" "cbl_master/plugfest35" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"git@bitbucket.org:cvp2ri/gst-plugins-bad.git" "cbl_master/plugfest35" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"git@bitbucket.org:cvp2ri/gst-plugins-ugly.git" "cbl_master/plugfest35" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"http://anongit.freedesktop.org/git/gstreamer/gst-libav.git" "5736513eb0" "--enable-introspection --disable-examples --enable-gtk-doc=no"
"git://git.gnome.org/valadoc" "5dde44de8" ""
"git@bitbucket.org:cvp2ri/gssdp.git" "cbl_master/plugfest35" "--enable-introspection --without-gtk"
"git@bitbucket.org:cvp2ri/gupnp.git" "cbl_master/plugfest35" "--enable-introspection"
"git@bitbucket.org:cvp2ri/gupnp-av.git" "cbl_master/plugfest35" "--enable-introspection"
"git@bitbucket.org:cvp2ri/gupnp-dlna.git" "cbl_master/plugfest35" "--enable-introspection --enable-gstreamer-metadata-backend"
"git@bitbucket.org:cvp2ri/rygel.git" "cbl_master/plugfest35" "--disable-tracker-plugin --enable-gst-launch-plugin --enable-vala"
"git@bitbucket.org:cvp2ri/dleyna-core.git" "cbl_master/plugfest35" ""
"git@bitbucket.org:cvp2ri/dleyna-server.git" "cbl_master/plugfest35"  "--enable-never-quit"
"git@bitbucket.org:cvp2ri/dleyna-renderer.git" "cbl_master/plugfest35"  "--enable-never-quit"
"git@bitbucket.org:cvp2ri/dleyna-connector-dbus.git" "cbl_master/plugfest35" ""
)

bailout()
{
    local message="$1"

    echo "*** Script stopped prematurely: ${message}" 2>&1 | tee -a ${log_file}
    echo "*** (see details above)" 2>&1 | tee -a ${log_file}
    exit 1
}

# Check for prerequisite toolchain packages
declare -a missing_packages=()

for i in "${prerequisite_packages[@]}"
do
   dpkg -s "$i" >/dev/null 2>&1 || missing_packages+=($i)
done

if [ "${#missing_packages[@]}" -gt "0" ]; then
	echo "" | tee -a ${log_file}
	echo "Missing prereqs run the following and try again." | tee -a ${log_file}
	echo "sudo apt-get install ${missing_packages[@]}" | tee -a ${log_file}
        exit 1
fi

# Setup directories if not defined in the environment
if [ -z $CVP2_BUILD ]; then
	echo "Enter the desired build directory [default: ${default_build}]:"
	read destDir
	if [ -n "$destDir" ]; then
    	CVP2_BUILD="$destDir"
   else
      CVP2_BUILD="$default_build"
   fi
fi

if [ -z $CVP2_ROOT ]; then
	echo "Enter the desired installation directory [default: ${CVP2_BUILD}/root]:"
	read destDir
	if [ -n "$destDir" ]; then
    	CVP2_ROOT="$destDir"
   else
		CVP2_ROOT="${CVP2_BUILD}/root"
	fi
fi

if [ -z $CVP2_GIT ]; then
	echo "Enter the desired git directory [default: ${CVP2_BUILD}/git]:"
	read destDir
	if [ -n "$destDir" ]; then
    	CVP2_GIT="$destDir"
   else
		CVP2_GIT="${CVP2_BUILD}/git"
	fi
fi

# Setup build directory
if [ ! -d ${CVP2_BUILD} ]; then
	mkdir -p ${CVP2_BUILD} || bailout "Couldn't create ${CVP2_BUILD}"
fi

# Setup logging and environment files
log_file="${CVP2_BUILD}/build_log.txt"
env_file="${CVP2_BUILD}/env_setup"

# clear the log file
echo "" | tee ${log_file}
echo "*** Install directory: ${CVP2_ROOT}" | tee -a ${log_file}

if [ ! -d ${CVP2_ROOT} ]; then
    mkdir -p ${CVP2_ROOT} || bailout "Couldn't create ${CVP2_ROOT}"
fi

if [ ! -d ${CVP2_BUILD}/packages ];then
    mkdir -p ${CVP2_BUILD}/packages || bailout "Couldn't create packages directory"
fi

if [ ! -d ${CVP2_BUILD}/src ];then
    mkdir -p ${CVP2_BUILD}/src || bailout "Couldn't create src directory"
fi

if [ ! -d ${CVP2_GIT} ];then
	mkdir -p ${CVP2_GIT} || bailout "Couldn't create ${CVP2_GIT} directory"
fi

# additional configure options
shared_config_opts="--prefix=${CVP2_ROOT}"

echo "*** Exporting environment variables..." | tee -a ${log_file}

# using custom prefix
cat > ${env_file} << EndOfFile
export CVP2_BUILD="${CVP2_BUILD}"
export CVP2_ROOT="${CVP2_ROOT}"
export CVP2_GIT="${CVP2_GIT}"
export RYGELDEV_BASE="${CVP2_BUILD}"
export RYGELDEV_INSTALL="${CVP2_ROOT}"
export ACLOCAL_FLAGS="-I /usr/share/aclocal"
export CFLAGS="-I${CVP2_ROOT}/include"
export CPPFLAGS="-I${CVP2_ROOT}/include"
export LDFLAGS="-L${CVP2_ROOT}/lib"
export LD_LIBRARY_PATH="${CVP2_ROOT}/lib"
export PKG_CONFIG_LIBDIR="${CVP2_ROOT}/lib/pkgconfig"
export PKG_CONFIG_PATH="${CVP2_ROOT}/lib/pkgconfig:${CVP2_ROOT}/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig"
export XDG_DATA_DIRS="${CVP2_ROOT}/share:$XDG_DATA_DIRS"
export PATH="${CVP2_ROOT}/bin:$PATH"
EndOfFile

# Log environment
cat ${env_file} | tee -a ${log_file}

# Set environment
source ${env_file}

# if this cache directory exists, it can cause problems
rm -r -f  ~/.cache/g-ir-scanner

process_package()
{
    local package_url="$1"
    local package_config_opts="$2"
    local package_filename=$(basename ${package_url})
	 local package_base=$(echo ${package_filename} | sed 's/.tar.gz//' | sed 's/.tar.xz//' | sed 's/libxml2-sources/libxml2/')
		
    echo "*** Installing ${package_base}..." 2>&1 | tee -a ${log_file}

    cd ${CVP2_BUILD} || bailout "Couldn't cd to ${CVP2_BUILD}"

    if [ ! -f packages/${package_filename} ]; then
        echo "*** Fetching source package ${package_filename}..." 2>&1 | tee -a ${log_file}
	(cd packages ; wget ${package_url}) 2>&1 | tee -a ${log_file} || bailout "Couldn't download ${package_filename}"
    fi

    # if the package source dir exists, delete it
    if [ -d src/${package_base} ]; then
        echo "*** Clearing source directory for ${package_base}..." 2>&1 | tee -a ${log_file}
	rm -r -f src/${package_base} || bailout "Error clearing src/${package_base}"
    fi
    (cd src ; tar xvf ../packages/${package_filename}) 2>&1 | tee -a ${log_file} || bailout "Couldn't extract ${package_filename}"

    # Build the source package
    echo "*** Entering source directory src/${package_base}" 2>&1 | tee -a ${log_file}
    cd src/${package_base} || bailout "Error entering ${package_filename} source directory"

    echo "*** Running configure for ${package_base}" | tee -a ${log_file}
    ./configure ${package_config_opts} ${shared_config_opts} 2>&1 | tee -a ${log_file} || bailout "Couldn't configure ${package_base}"
    
    echo "*** Starting build for ${package_base}" | tee -a ${log_file}
    make 2>&1 | tee -a ${log_file} || bailout "Couldn't make ${package_base}"
    make install 2>&1 | tee -a ${log_file} || bailout "Couldn't install ${package_base}"
}

process_repo()
{
	echo "*** Processing Repository: ${1}" 2>&1 | tee -a ${log_file}

	local repo_url="$1"
	local repo_branch="$2"
	local repo_opts="$3"
 	local repo_base=$(basename ${repo_url} .git)

	echo "*** Installing ${repo_base}..." 2>&1 | tee -a ${log_file}
	cd ${CVP2_GIT} || bailout "Couldn't cd to ${CVP2_GIT}"
	git clone ${repo_url} | tee -a ${log_file} || bailout "Couldn't clone ${repo_base}"
	cd ${repo_base} || bailout "Couldn't cd to ${repo_base} directory"
	git checkout ${repo_branch}
	
	echo "*** Running autogen for ${repo_base}" | tee -a ${log_file}
	./autogen.sh ${shared_config_opts} ${repo_opts} | tee -a ${log_file} || bailout "Couldn't autogen ${repo_base}"
	
	echo "*** Starting build for ${repo_base}" | tee -a ${log_file}
	make 2>&1 | tee -a ${log_file} || bailout "Couldn't make ${repo_base}"
	make install 2>&1 | tee -a ${log_file} || bailout "Couldn't install ${repo_base}"	
}

# This order is derived from the package dependancies...
num_ext_pkgs=${#external_packages[*]}
for ((i=0; i<=$(($num_ext_pkgs-1)); i++))
do
	process_package "${external_packages[i]}" "${external_packages[++i]}"
done

# CVP2 controlled repositories
num_cvp2_repos=${#cvp2_repos[*]}
for ((i=0; i<=$(($num_cvp2_repos-1)); i++))
do
		process_repo "${cvp2_repos[i]}" "${cvp2_repos[++i]}" "${cvp2_repos[++i]}"
done

# Custom build for XDMR
cd ${CVP2_GIT} || bailout "Couldn't cd to ${CVP2_GIT}"
git clone git@bitbucket.org:cvp2ri/cvp2-xdmr-controller.git || tee -a ${log_file} || bailout "Couldn't clone valadoc"
cd cvp2-xdmr-controller || bailout "Couldn't cd to the xdmr directory"
git checkout cbl_master/plugfest35
./build_lib.sh && cp dmp ${CVP2_ROOT}/bin

echo "NOTE: Environment variables for this prefix can be set via 'source ${env_file}'" | tee -a ${log_file}
echo "Done." | tee -a ${log_file}
