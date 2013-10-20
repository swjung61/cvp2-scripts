#!/bin/bash
case $1 in
	*.tar.gz) INPUT_FILE_NAME=`basename $1 .tar.gz`;;
	*.tar.xz) INPUT_FILE_NAME=`basename $1 .tar.xz`;;
esac

BASE_DIR=${HOME}/work/sources
BUILD_DIR=${BASE_DIR}/build
EXTRACT_DIR=${BASE_DIR}/extract
COMBINED_DIR=${BASE_DIR}/combined
BINARY_TARGET_DIR=${BASE_DIR}/output/binaries
SOURCE_TARGET_DIR=${BASE_DIR}/output/sources
SOURCE_DIRECTORY_NAME=${INPUT_FILE_NAME}-src

BINARY_TARBALL_NAME=${INPUT_FILE_NAME}-bin.tar.gz
SOURCE_TARBALL_NAME=${INPUT_FILE_NAME}-src.tar.gz

DESTDIR=${BUILD_DIR}/${INPUT_FILE_NAME}
PREFIX=/

mkdir -p ${BINARY_TARGET_DIR}
mkdir -p ${SOURCE_TARGET_DIR}
mkdir -p ${DESTDIR}
mkdir -p ${COMBINED_DIR}
mkdir -p ${BUILD_DIR}
mkdir -p ${EXTRACT_DIR}

export ACLOCAL_FLAGS="-I /usr/share/aclocal"
export CFLAGS="-I${COMBINED_DIR}/include"
export CPPFLAGS="-I${COMBINED_DIR}/include"
export LDFLAGS="-L${COMBINED_DIR}/lib"
export LD_LIBRARY_PATH="${COMBINED_DIR}/lib"
export PKG_CONFIG_LIBDIR="${COMBINED_DIR}/lib/pkgconfig"
export PKG_CONFIG_PATH="${COMBINED_DIR}/lib/pkgconfig:${COMBINED_DIR}/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"
export PATH="${COMBINED_DIR}/bin:${PATH}"

#export PERL5LIB="${COMBINED}/share/automake-1.13"

tar xvf ${BASE_DIR}/$1 -C ${EXTRACT_DIR}
cd ${EXTRACT_DIR}
mv ${INPUT_FILE_NAME} ${SOURCE_DIRECTORY_NAME}

tar czvf ${SOURCE_TARGET_DIR}/${SOURCE_TARBALL_NAME} ${SOURCE_DIRECTORY_NAME}
cd ${SOURCE_DIRECTORY_NAME}

echo "Running configure --prefix=${PREFIX} $2"
./configure --prefix=${PREFIX} $2

make

echo "Running make DESTDIR=$DESTDIR install"
make DESTDIR=${DESTDIR} install

tar czvf ${BINARY_TARGET_DIR}/${BINARY_TARBALL_NAME} -C ${DESTDIR} .

tar xvf ${BINARY_TARGET_DIR}/${BINARY_TARBALL_NAME} -C ${COMBINED_DIR} .

