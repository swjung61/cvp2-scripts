#!/bin/bash

# To deal with the tees...
set -o pipefail

default_build=~/cvp2

default_branch=cbl_master/plugfest36

# Setup logging and environment files
env_file="$default_build/env_setup"
echo "$env_file"

# Set environment
source ${env_file}

install_dtcp_lib()
{
    echo "*** Processing dtcp-rygel Repository: ${1}" 2>&1

    local repo_url="$1"
    local repo_branch="$2"
    local repo_base=$(basename ${repo_url} .git)

    echo "*** Installing ${repo_base}..." 2>&1
    cd ${CVP2_GIT} || bailout "Couldn't cd to ${CVP2_GIT}"
    git clone ${repo_url} | tee -a ${log_file} || bailout "Couldn't clone ${repo_base}"
    cd ${repo_base} || bailout "Couldn't cd to ${repo_base} directory"
    git checkout ${repo_branch}

    echo "*** Installing dtcp library files"
    cp include/dtcpip.h $dtcpip_header
    cp lib/libdtcpip.so $dtcpip_lib
    cp vapi/dtcpip.vapi ${CVP2_ROOT}/share/vala/vapi
    echo "*** Done copying dtcp library files."
}

# Setup dtcpip env variables
dtcp_rygel_repo="git@bitbucket.org:cvp2ri/dtcp-rygel.git"
dtcpip_lib="${CVP2_ROOT}/lib/libdtcpip.so"
dtcpip_header="${CVP2_ROOT}/include/dtcpip.h"
dtcpip_vapi="${CVP2_ROOT}/vapi/dtcpip.vapi"
install_dtcp_lib "$dtcp_rygel_repo" "$default_branch"

dtcpip_pc="${CVP2_ROOT}/lib/pkgconfig/dtcpip.pc"

echo "*** Creating dtcpip.pc file."
echo $dtcpip_pc
# creating dtcpip.pc file
cat > $dtcpip_pc << EndOfFile
prefix=${CVP2_ROOT}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include
datarootdir=\${prefix}/share
datadir=\${datarootdir}

Name: dtcpip
Description: DTCP
Version: 1.0
Requires:
Libs: -L\${libdir} -ldtcpip
Cflags: -I\${includedir}
EndOfFile

# Log environment
cat ${dtcpip_pc}

echo "NOTE: Dtcp libraries are installed}'"
echo "Done."
