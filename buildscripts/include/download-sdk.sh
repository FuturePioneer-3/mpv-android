#!/bin/bash -e

. ./include/depinfo.sh

. ./include/path.sh # load $os var

[ -z "$IN_CI" ] && IN_CI=0 # skip steps not required for CI?
[ -z "$WGET" ] && WGET=wget # possibility of calling wget differently

if [ "$os" == "linux" ]; then
	if [ $IN_CI -eq 0 ]; then
		if hash yum &>/dev/null; then
			sudo yum install autoconf pkgconfig libtool ninja-build \
				unzip wget meson gperf
		elif apt-get -v &>/dev/null; then
			sudo apt-get install autoconf pkg-config libtool ninja-build \
				unzip wget meson gperf
		else
			echo "Note: dependencies were not installed, you have to do that manually."
		fi
	fi

	if ! javac -version &>/dev/null; then
		echo "Error: missing Java Development Kit."
		hash yum &>/dev/null && \
			echo "Install it using e.g. sudo yum install java-latest-openjdk-devel"
		apt-get -v &>/dev/null && \
			echo "Install it using e.g. sudo apt-get install default-jre-headless"
		exit 255
	fi

	os_ndk="linux"
elif [ "$os" == "mac" ]; then
	if [ $IN_CI -eq 0 ]; then
		if ! hash brew 2>/dev/null; then
			echo "Error: brew not found. You need to install Homebrew: https://brew.sh/"
			exit 255
		fi
		brew install \
			automake autoconf libtool pkg-config \
			coreutils gnu-sed wget meson ninja gperf
	fi
	if ! javac -version &>/dev/null; then
		echo "Error: missing Java Development Kit. Install it manually."
		exit 255
	fi
fi

mkdir -p sdk && cd sdk

MIRROR="https://mirrors.cloud.tencent.com/AndroidSDK"

# Android SDK
if [ ! -d "android-sdk-${os}" ]; then
	echo "Android SDK not found. Downloading commandline tools."
	$WGET "$MIRROR/commandlinetools-${os}-${v_sdk}.zip"
	mkdir "android-sdk-${os}"
	unzip -q -d "android-sdk-${os}" "commandlinetools-${os}-${v_sdk}.zip"
	rm "commandlinetools-${os}-${v_sdk}.zip"
fi

# Android platform & build-tools (downloaded manually, mirror has no sdkmanager-friendly repo)
if [ ! -d "android-sdk-$os/platforms/android-${v_sdk_platform}" ]; then
	echo "Downloading platform android-${v_sdk_platform}."
	$WGET "$MIRROR/platform-${v_sdk_platform}_r02.zip"
	mkdir -p "android-sdk-$os/platforms"
	unzip -q -d "android-sdk-$os/platforms" "platform-${v_sdk_platform}_r02.zip"
	mv "android-sdk-$os/platforms/android-${v_sdk_platform}"* "android-sdk-$os/platforms/android-${v_sdk_platform}"
	rm "platform-${v_sdk_platform}_r02.zip"
fi
if [ ! -d "android-sdk-$os/build-tools/${v_sdk_build_tools}" ]; then
	echo "Downloading build-tools ${v_sdk_build_tools}."
	$WGET "$MIRROR/build-tools_r${v_sdk_build_tools}_linux.zip"
	mkdir -p "android-sdk-$os/build-tools"
	unzip -q -o -d "android-sdk-$os/build-tools" "build-tools_r${v_sdk_build_tools}_linux.zip"
	rm "build-tools_r${v_sdk_build_tools}_linux.zip"
	# new-style zips extract to an API-codename dir (e.g. android-15)
	cd "android-sdk-$os/build-tools"
	for d in android-*; do
		[ -d "$d" ] && mv "$d" "${v_sdk_build_tools}"
	done
	cd -
fi
if [ ! -d "android-sdk-$os/extras/android/m2repository" ]; then
	echo "Downloading android m2repository."
	$WGET "$MIRROR/android_m2repository_r47.zip"
	mkdir -p "android-sdk-$os/extras/android"
	unzip -q -d "android-sdk-$os/extras/android" "android_m2repository_r47.zip"
	rm "android_m2repository_r47.zip"
fi

# Android NDK (either standalone or installed by SDK)
if [ -d "android-ndk-${v_ndk}" ]; then
	echo "Android NDK directory found."
elif [ -d "android-sdk-$os/ndk/${v_ndk_n}" ]; then
	echo "Creating NDK symlink to SDK."
	ln -s "android-sdk-$os/ndk/${v_ndk_n}" "android-ndk-${v_ndk}"
else
	echo "Downloading NDK."
	$WGET "$MIRROR/android-ndk-${v_ndk}-${os_ndk}.zip"
	unzip -q "android-ndk-${v_ndk}-${os_ndk}.zip"
	rm "android-ndk-${v_ndk}-${os_ndk}.zip"
fi
if ! grep -qF "${v_ndk_n}" "android-ndk-${v_ndk}/source.properties"; then
	echo "Error: NDK exists but is not the correct version (expecting ${v_ndk_n})"
	exit 255
fi

# gas-preprocessor
mkdir -p bin
$WGET "https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl" \
	-O bin/gas-preprocessor.pl
chmod +x bin/gas-preprocessor.pl

cd ..
