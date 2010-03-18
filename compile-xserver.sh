#!/bin/bash

CONFOPT="--disable-xquartz --disable-launchd --enable-kdrive --disable-xsdl --enable-xnest --enable-xvfb"

#CONFOPT="--enable-standalone-xpbproxy"
#CONFOPT="--disable-glx"
#CONFOPT="--disable-shave --without-dtrace"
#CONFOPT="--enable-standalone-xpbproxy --without-dtrace"


# Parallel Make.  Change $MAKE if you don't have gmake installed
MAKE="gnumake"
MAKE_OPTS="-j3"
 
. ~/src/strip.sh

#PREFIX=/usr/X11
PREFIX=/opt/X11

ACLOCAL="aclocal -I ${PREFIX}/share/aclocal -I /usr/local/share/aclocal"

CFLAGS="-Wall -pipe -DNO_ALLOCA"
CFLAGS="$CFLAGS -O0 -ggdb3"
CFLAGS="$CFLAGS -arch i386 -arch x86_64 -arch ppc"

LDFLAGS="$CFLAGS"

#CPPFLAGS="$CPPFLAGS -F/Applications/Utilities/XQuartz.app/Contents/Frameworks"
#LDFLAGS="$LDFLAGS -F/Applications/Utilities/XQuartz.app/Contents/Frameworks"
#CONFOPT="$CONFOPT --with-apple-application-name=XQuartz --with-launchd-id-prefix=org.macosforge.xquartz"

export ACLOCAL CPPFLAGS CFLAGS LDFLAGS

PKG_CONFIG_PATH=${PREFIX}/share/pkgconfig:${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
PATH=${PREFIX}/bin:$PATH

die() {
	echo "${@}" >&2
	exit 1
}

docomp() {
	autoreconf -fvi || die
	./configure --prefix=${PREFIX} ${CONFOPT} --disable-dependency-tracking --enable-maintainer-mode --enable-xcsecurity --enable-record "${@}" || die "Could not configure xserver"
	${MAKE} clean || die "Unable to make clean"
	${MAKE} ${MAKE_OPTS} || die "Could not make xserver"
}

doinst() {
	${MAKE} install DESTDIR="$(pwd)/../dist" || die "Could not install xserver"
}

dosign() {
	/opt/local/bin/gmd5sum $1 > $1.md5sum
	/opt/local/bin/gsha1sum $1 > $1.sha1sum
	DISPLAY="" /opt/local/bin/gpg2 -b $1
}

dodist() {
	${MAKE} dist
	dosign xorg-server-$1.tar.bz2

	cp hw/xquartz/mach-startup/X11.bin X11.bin-$1
	bzip2 X11.bin-$1
	dosign X11.bin-$1.bz2 
}

docomp `[ -f conf_flags ] && cat conf_flags`
#doinst
[[ -n $1 ]] && dodist $1

exit 0
