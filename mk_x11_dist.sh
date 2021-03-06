#!/bin/bash

. ~jeremy/src/strip.sh

unset CFLAGS OBJCFLAGS CPPFLAGS LDFLAGS C_INCLUDE_PATH OBJC_INCLUDE_PATH CPLUS_INCLUDE_PATH PKG_CONFIG_PATH

BUILDIT=~rc/bin/buildit
#BUILDIT=/usr/local/bin/buildit
#BUILDIT=./buildit

MERGE_DIRS="/"

if [[ $# -eq 2 ]] ; then
	MERGE_DIRS="${MERGE_DIRS} $(eval echo ~jeremy)/src/freedesktop/pkg/X11"

	VERSION_TXT=$1
	VERSION_TXT_SHORT=${VERSION_TXT%_*}
	VERSION=$2

	echo "User Version: ${VERSION_TXT}"
	echo "Base Version: ${VERSION_TXT_SHORT}"
	echo "Bundle Version: ${VERSION}"

	export X11_APP_VERSION=${VERSION}
	export X11_APP_VERSION_STRING=${VERSION_TXT}

	if [[ "${VERSION_TXT/beta/}" != "${VERSION_TXT}" ]] ; then
		BETA=YES
	else
		BETA=NO
	fi

	if [[ "${VERSION_TXT_SHORT}" == "${VERSION_TXT}" ]] ; then
		PRERELEASE=NO
	else
		PRERELEASE=YES
	fi
else
	BETA=YES
	PRERELEASE=YES
fi

if [[ "${BETA}" == "YES" ]] ; then
	MEMORY_HARDENING=YES
	export OPTIMIZATION_FLAGS="-O1 -fno-optimize-sibling-calls -fno-omit-frame-pointer"
	export STRIP_SYMBOLS=NO
else
	MEMORY_HARDENING=NO
	export OPTIMIZATION_FLAGS="-Os"
	export STRIP_SYMBOLS=YES
fi

#MACOSFORGE_BUILD_DOCS="YES"
MACOSFORGE_BUILD_DOCS="NO"

TRAIN="trunk"

### End Configuration ###

XPLUGIN="${XPLUGIN:-${TRAIN}}"
X11MISC="${X11MISC:-${TRAIN}}"
X11PROTO="${X11PROTO:-${TRAIN}}"
X11LIBS="${X11LIBS:-${TRAIN}}"
X11SERVER="${X11SERVER:-${TRAIN}}"
X11APPS="${X11APPS:-${TRAIN}}"
X11FONTS="${X11FONTS:-${TRAIN}}"

die() {
	echo "${@}" >&2
	exit 1
}

export MACOSFORGE_RELEASE=YES

export X11_PREFIX="/opt/X11"
export XPLUGIN_PREFIX="/opt/X11"
export X11_BUNDLE_ID_PREFIX="org.macosforge.xquartz"
export X11_APP_NAME="XQuartz"
export LAUNCHD_PREFIX="/Library"
export X11_PATHS_D_PREFIX="40"

if [[ "${PRERELEASE}" == "YES" ]] ; then
	export SPARKLE_FEED_URL="https://www.xquartz.org/releases/sparkle/beta.xml"
else
	export SPARKLE_FEED_URL="https://www.xquartz.org/releases/sparkle/release.xml"
fi

if [[ -n "${X11SERVER}" && -d /Applications/Utilities/XQuartz.app/Contents/Resources/zh_TW.lproj/main.nib ]] ; then
	die "You should delete /Applications/Utilities/XQuartz.app first or you will have merge issues."
fi

BUILDIT="${BUILDIT} -noverify -noverifydstroot -nocortex -nopathChanges -supportedPlatforms osx -sdkForPlatform osx=macosx10.11internal -deploymentTargetForPlatform osx=10.6 -platform osx"

export MACOSFORGE_BUILD_DOCS

if [[ ${MACOSFORGE_BUILD_DOCS} == "YES" ]] ; then
	export XMLTO=/opt/local/bin/xmlto
	export ASCIIDOC=/opt/local/bin/asciidoc
	export DOXYGEN=/opt/local/bin/doxygen
	export FOP=/opt/local/bin/fop
	export FOP_OPTS="-Xmx2048m -Djava.awt.headless=true"
	export GROFF=/opt/local/bin/groff
	export PS2PDF=/opt/local/bin/ps2pdf

	for f in "${XMLTO}" "${ASCIIDOC}" "${DOXYGEN}" "${FOP}" "${GROFF}" "${PS2PDF}" ; do
		[[ -z "${f}" || -x "${f}" ]] || die "Could not find ${f}"
		exit 1
	done
fi

ARCH_EXEC="-arch i386 -arch x86_64"
ARCH_ALL="${ARCH_EXEC}"
BUILDIT="${BUILDIT} -release Syrah"

export MACOSX_DEPLOYMENT_TARGET=10.6
if [[ "${MEMORY_HARDENING}" == "YES" ]] ; then
	export MACOSX_DEPLOYMENT_TARGET=10.8
fi

export EXTRA_XQUARTZ_CFLAGS="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
export EXTRA_XQUARTZ_LDFLAGS="-Wl,-macosx_version_min,${MACOSX_DEPLOYMENT_TARGET}"

OSS_CLANG_VERSION=3.9

if [[ -n "${OSS_CLANG_VERSION}" ]] ; then
	export CC="/opt/local/bin/clang-mp-${OSS_CLANG_VERSION}"
	export CXX="/opt/local/bin/clang++-mp-${OSS_CLANG_VERSION}"
	ASAN_DYLIB="/opt/local/libexec/llvm-${OSS_CLANG_VERSION}/lib/clang/${OSS_CLANG_VERSION}.0/lib/darwin/libclang_rt.asan_osx_dynamic.dylib"
else
	export CC="$(xcrun -find clang)"
	export CXX="$(xcrun -find clang++)"
	ASAN_DYLIB=$(echo $(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/*/lib/darwin/libclang_rt.asan_osx_dynamic.dylib)
fi

if [[ "${MEMORY_HARDENING}" == "YES" ]] ; then
	EXTRA_XQUARTZ_CFLAGS="${EXTRA_XQUARTZ_CFLAGS} -fsanitize=address"
	EXTRA_XQUARTZ_LDFLAGS="${EXTRA_XQUARTZ_LDFLAGS} -Wl,${ASAN_DYLIB},-rpath,/opt/X11/lib/asan"

	EXTRA_XQUARTZ_CFLAGS="${EXTRA_XQUARTZ_CFLAGS} -fstack-protector-all"
	EXTRA_XQUARTZ_LDFLAGS="${EXTRA_XQUARTZ_LDFLAGS} -fstack-protector-all"
	#EXTRA_XQUARTZ_CFLAGS="${EXTRA_XQUARTZ_CFLAGS} -fstack-protector-strong"
	#EXTRA_XQUARTZ_LDFLAGS="${EXTRA_XQUARTZ_LDFLAGS} -fstack-protector-strong"
else
	EXTRA_XQUARTZ_CFLAGS="${EXTRA_XQUARTZ_CFLAGS} -fstack-protector-strong"
	EXTRA_XQUARTZ_LDFLAGS="${EXTRA_XQUARTZ_LDFLAGS} -fstack-protector-strong"
	#EXTRA_XQUARTZ_CFLAGS="${EXTRA_XQUARTZ_CFLAGS} -fstack-protector"
	#EXTRA_XQUARTZ_LDFLAGS="${EXTRA_XQUARTZ_LDFLAGS} -fstack-protector"
fi

export OBJC="${CC}"

export XQUARTZ_CC="${CC}"

export PYTHON=/usr/bin/python2.6
export PYTHONPATH="${X11_PREFIX}/lib/python2.6:${X11_PREFIX}/lib/python2.6/site-packages"

BUILDRECORDS="$(/usr/bin/mktemp -d ${TMPDIR-/tmp}/X11roots.XXXXXX)"
chown jeremy "${BUILDRECORDS}"

bit() {
	local PROJECT="${1}" ; shift
	local SRCROOT="${1}" ; shift
	local EXTRA=""

	pushd "${SRCROOT}" || die

	[[ "$(basename $(pwd))" != "${PROJECT}" ]] && EXTRA="_$(basename $(pwd))"
	local DSTROOT="${BUILDRECORDS}/${PROJECT}${EXTRA}.roots/BuildRecords/${PROJECT}_install/Root"
	local SYMROOT="${BUILDRECORDS}/${PROJECT}${EXTRA}.roots/BuildRecords/${PROJECT}_install/Symbols"

	${BUILDIT} -rootsDirectory "${BUILDRECORDS}" -project "${PROJECT}" . "${@}" || die

	popd || die

	local MERGE_DIR
	echo ""
	for MERGE_DIR in ${MERGE_DIRS}; do
		echo "*** mk_x11_dist.sh ***: Merging into root: ${MERGE_DIR}" || die
		mkdir -p "${MERGE_DIR}" || die
		ditto "${DSTROOT}" "${MERGE_DIR}" || die

		if [[ -n "${MERGE_DIR}" && "${MERGE_DIR}" != "/" ]] ; then
			/bin/rm -rf "${MERGE_DIR}"/usr/local
			/bin/rmdir "${MERGE_DIR}"/usr >& /dev/null

			mkdir -p "${MERGE_DIR}.dSYMS"
			find "${SYMROOT}" -type d -name '*.dSYM' | while read dsym ; do
				local file_basename="${dsym##*/}"
				file_basename="${file_basename%.dSYM}"
				file=$(find "${DSTROOT}" -type f -name "${file_basename}")

				local dirname="${file#${DSTROOT}}"
				dirname="${dirname%/*}"

				ditto "${dsym}" "${MERGE_DIR}.dSYMS/${dirname}/${file_basename}.dSYM"
				if [[ -d "${MERGE_DIR}.dSYMS/usr" ]] ; then
					rm -rf "${MERGE_DIR}.dSYMS/usr"
				fi
			done
		fi
	done
}

bit_git() {
	proj=${1} ; shift
	branch=${1} ; shift
	[[ "${branch}" == "trunk" ]] && branch="master"

	if [[ -n "${branch}" && -d "${proj}" ]] ; then
		pushd "${proj}"
		git checkout "${branch}" || die "Unable to checkout ${branch}"
		bit "${proj}" . "${@}"
		popd
	fi
}

if [[ -n "${ASAN_DYLIB}" && "${MEMORY_HARDENING}" == "YES" ]] ; then
	mkdir -p /opt/X11/lib/asan || die "Unable to install the asan dylib"
	install -o root -g wheel -m 755 "${ASAN_DYLIB}" /opt/X11/lib/asan || die "Unable to install the asan dylib"

	if [[ -n ${VERSION} ]] ; then
		mkdir -p $(eval echo ~jeremy)/src/freedesktop/pkg/X11/opt/X11/lib/asan || die "Unable to install the asan dylib"
		install -o root -g wheel -m 755 "${ASAN_DYLIB}" $(eval echo ~jeremy)/src/freedesktop/pkg/X11/opt/X11/lib/asan || die "Unable to install the asan dylib"
	fi
fi

[[ -n ${XPLUGIN} ]]     && bit_git X11_Xplugin   "${XPLUGIN}"              ${ARCH_ALL}
[[ -n ${X11MISC} ]]     && bit     X11misc       X11misc/${X11MISC}        ${ARCH_ALL}
[[ -n ${X11PROTO} ]]    && bit     X11proto      X11proto/${X11PROTO}      ${ARCH_ALL}
[[ -n ${X11LIBS} ]]     && bit     X11libs       X11libs/${X11LIBS}        ${ARCH_ALL}
[[ -n ${X11SERVER} ]]   && bit     X11server     X11server/${X11SERVER}    ${ARCH_ALL}
[[ -n ${X11APPS} ]]     && bit     X11apps       X11apps/${X11APPS}        ${ARCH_ALL}
[[ -n ${X11FONTS} ]]    && bit     X11fonts      X11fonts/${X11FONTS}      ${ARCH_ALL}

if [[ -n ${VERSION} ]] ; then
	INFO_PLIST="$(eval echo ~jeremy)/src/freedesktop/pkg/X11/Applications/Utilities/XQuartz.app/Contents/Info.plist"

	defaults write "${INFO_PLIST}" CFBundleVersion "${VERSION}"
	defaults write "${INFO_PLIST}" CFBundleShortVersionString "${VERSION_TXT}"
	plutil -convert xml1 "${INFO_PLIST}"
	chmod 644 "${INFO_PLIST}"

	cd $(eval echo ~jeremy)/src/freedesktop/pkg

	find X11 -type f | while read file ; do
		if /usr/bin/file "${file}" | grep -q "Mach-O" ; then
			codesign -s "Developer ID Application: Apple Inc. - XQuartz (NA574AWV7E)" "${file}"

			if otool -L "${file}" | grep -q "/opt/local/lib" ; then
				die "=== ${file} links against an invalid library ==="
			fi

			if otool -L "${file}" | grep -q "/opt/buildX11/lib" ; then
				die "=== ${file} links against an invalid library ==="
			fi
		fi
	done

	codesign --deep --force -s "Developer ID Application: Apple Inc. - XQuartz (NA574AWV7E)" X11/Applications/Utilities/XQuartz.app

	if [[ -d X11.dSYMS ]] ; then
		cd X11.dSYMS
		tar cjf ../XQuartz-${VERSION_TXT}.dSYMS.tar.bz2 .
		cd ..
	fi

	./mkpmdoc.sh
	chown -R jeremy XQuartz-${VERSION_TXT}.pmdoc
	echo "Browse to the components tab and check the box to make XQuartz.app downgradeable"
	echo "<rdar://problem/10772627>"
	echo "Press enter when done"
	sudo -u jeremy open XQuartz-${VERSION_TXT}.pmdoc
	read IGNORE
	sudo -u jeremy /Applications/PackageMaker.app/Contents/MacOS/PackageMaker --verbose --doc XQuartz-${VERSION_TXT}.pmdoc --out XQuartz-${VERSION_TXT}.pkg
	sudo -u jeremy productsign --sign "Developer ID Installer: Apple Inc. - XQuartz (NA574AWV7E)" XQuartz-${VERSION_TXT}.pkg{,.s}
	mv XQuartz-${VERSION_TXT}.pkg{.s,}
	sudo -u jeremy ./mkdmg.sh XQuartz-${VERSION_TXT}.pkg ${VERSION} > XQuartz-${VERSION_TXT}.sparkle.xml
fi
