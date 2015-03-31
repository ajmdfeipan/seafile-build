#!/bin/bash -ue

# Toolchain:
# vala 
# mingw32-gcc 
# mingw32-pkg-config 
# mingw32-glib2 
# mingw32-pthreads 
# mingw32-sqlite 
# mingw32-openssl

##############* Build Settings *############### 
#src packeage version
export LIBEVENT=libevent-2.0.22-stable
export JANSSON=jansson-2.6
export LIBSEARPC=libsearpc-3.0-latest
export CCNET=ccnet-4.1.0
export SEAFILE=seafile-4.1.0
export SEAFILECLIENT=seafile-client-4.1.0

#src packeages dir
export SRC=/work/src/seafile

#install prefix dir
export PREFIX=$(pwd)
###############################################

export HOST=i686-w64-mingw32
export BUILD=x86_64-redhat-linux-gnu
export TARGET=i686-w64-mingw32

#build temp dir
export BUILDROOT=build
mkdir -p $BUILDROOT

export THREADS=$(cat /proc/cpuinfo|grep cores|awk '{print $NF}'|head -1)

export PATH=$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export PKG_CONFIG=mingw32-pkg-config
export PKG_CONFIG_PATH=/usr/$TARGET/sys-root/mingw/lib/pkgconfig:$PREFIX/lib/pkgconfig
export CPPFLAGS="-I/usr/$TARGET/sys-root/mingw/include -I$PREFIX/include"
export CXXFLAGS="-I/usr/$TARGET/sys-root/mingw/include -I$PREFIX/include"
export LDFLAGS="-L/usr/$TARGET/sys-root/mingw/lib -L$PREFIX/lib"

cat >$PREFIX/Toolchain-cross-linux.cmake<<EOF
SET(CMAKE_SYSTEM_NAME Windows)
set(COMPILER_PREFIX "$TARGET")
find_program(CMAKE_RC_COMPILER NAMES \${COMPILER_PREFIX}-windres)
find_program(CMAKE_C_COMPILER NAMES \${COMPILER_PREFIX}-gcc)
find_program(CMAKE_CXX_COMPILER NAMES \${COMPILER_PREFIX}-g++)
SET(USER_ROOT_PATH $PREFIX)
SET(CMAKE_FIND_ROOT_PATH  /usr/\${COMPILER_PREFIX}/sys-root/mingw \${USER_ROOT_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

echo "###############Checking for libevent..."
if ! test -f $PREFIX/include/evutil.h; then
        echo "Building $LIBEVENT"
        pushd $BUILDROOT
	rm -rf $LIBEVENT
        tar xvf $SRC/$LIBEVENT.tar.*
        pushd $LIBEVENT
        ./configure --host=$HOST --build=$BUILD --target=$TARGET --prefix=$PREFIX

        make -j $THREADS
        make install

        popd
        popd
fi

echo "###############Checking for $JANSSON..."
if ! test -f $PREFIX/include/jansson.h; then
        echo "Building $JANSSON"
        pushd $BUILDROOT
        rm -rf $JANSSON
        tar xf $SRC/$JANSSON.tar.*
        pushd $JANSSON
        ./configure --host=$HOST --build=$BUILD --target=$TARGET --prefix=$PREFIX
        make -j $THREADS
        make install
        popd
        popd
fi

echo "###############Checking for $LIBSEARPC..."
if ! test -f $PREFIX/bin/searpc-codegen.py; then
        echo "Building $LIBSEARPC"
	pushd $BUILDROOT
	rm -rf $LIBSEARPC
	tar xf $SRC/$LIBSEARPC.tar.*
        pushd $LIBSEARPC
        bash autogen.sh
        ./configure --host=$HOST --build=$BUILD --target=$TARGET --prefix=$PREFIX
        make -j $THREADS
        make install
        popd
	popd
fi

echo "###############Checking for $CCNET..."
if ! test -d $PREFIX/include/ccnet; then
        echo "Building $CCNET"
	pushd $BUILDROOT
	rm -rf $CCNET
	tar xf $SRC/$CCNET.tar.*
        pushd $CCNET
	sed -i 's/Rpc.h/rpc.h/g' lib/utils.c
	sed -i 's/Rpc.h/rpc.h/g' lib/libccnet_utils.c
        sed -i 's/lRpcrt4/lrpcrt4/g' configure.ac
        bash autogen.sh
        ./configure --host=$HOST --build=$BUILD --target=$TARGET --prefix=$PREFIX --disable-python
        make -j $THREADS
        make install
        popd
	popd
fi

echo "###############Checking for $SEAFILE..."
if ! test -f $PREFIX/bin/seaf-daemon.exe ; then
        echo "Building $SEAFILE"
	pushd $BUILDROOT
	rm -rf $SEAFILE
	tar xf $SRC/$SEAFILE.tar.*
        pushd $SEAFILE
	sed -i 's/Rpc.h/rpc.h/g' lib/utils.c
        sed -i 's/lRpcrt4/lrpcrt4/g' configure.ac
	bash autogen.sh
        ./configure --host=$HOST --build=$BUILD --target=$TARGET --prefix=$PREFIX --disable-python  --disable-gui

        # For gui/win/Makefile
        export CC=$TARGET-gcc
        export RC=$TARGET-windres
        make -j $THREADS
        make install

        popd
	popd
fi

echo "###############Checking for $SEAFILECLIENT..."
if ! test -f $PREFIX/bin/seafile-applet.exe ; then
        echo "Building $SEAFILECLIENT"
        pushd $BUILDROOT
        rm -rf $SEAFILECLIENT
        tar xf $SRC/$SEAFILECLIENT.tar.*
        pushd $SEAFILECLIENT
	sed -i 's/ShlObj.h/shlobj.h/g' src/ui/init-seafile-dialog.cpp
	sed -i '1 i #include <stdint.h>\n#include <unistd.h>' src/ext-handler.cpp
	cmake  -DCMAKE_TOOLCHAIN_FILE=$PREFIX/Toolchain-cross-linux.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX .
        make -j $THREADS
        make install
        popd
        popd
fi

echo
echo "Some more EXEs and DLLs which might be required to run the applet are in ./bin"


