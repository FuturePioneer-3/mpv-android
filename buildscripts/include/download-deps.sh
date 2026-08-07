#!/bin/bash -e

. ./include/depinfo.sh

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET=wget

mkdir -p deps && cd deps

# mbedtls
if [ ! -d mbedtls ]; then
	git clone --depth 1 --branch mbedtls-$v_mbedtls https://github.com/Mbed-TLS/mbedtls mbedtls
fi

# dav1d
[ ! -d dav1d ] && git clone https://github.com/videolan/dav1d

# ffmpeg
if [ ! -d ffmpeg ]; then
	args=(--depth=1)
	[ $IN_CI -eq 1 ] && args+=(--branch "$v_ci_ffmpeg")
	git clone https://github.com/FFmpeg/FFmpeg ffmpeg "${args[@]}"
fi

# freetype2
[ ! -d freetype2 ] && git clone --depth 1 --shallow-submodules --recurse-submodules https://github.com/freetype/freetype freetype2 -b VER-${v_freetype//./-}

# fribidi
if [ ! -d fribidi ]; then
	git clone --depth 1 --branch v$v_fribidi https://github.com/fribidi/fribidi fribidi
fi

# harfbuzz
if [ ! -d harfbuzz ]; then
	git clone --depth 1 --branch $v_harfbuzz https://github.com/harfbuzz/harfbuzz harfbuzz
fi

# unibreak
if [ ! -d unibreak ]; then
	git clone --depth 1 --branch libunibreak_${v_unibreak//./_} https://github.com/adah1972/libunibreak unibreak
fi

# libxml2
if [ ! -d libxml2 ]; then
	git clone --depth 1 --branch v${v_libxml2} https://github.com/GNOME/libxml2 libxml2
fi

# fontconfig
if [ ! -d fontconfig ]; then
	mkdir fontconfig
	$WGET https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/${v_fontconfig}/fontconfig-${v_fontconfig}.tar.gz -O - | \
		tar -xz -C fontconfig --strip-components=1
fi

# libass
[ ! -d libass ] && git clone https://github.com/libass/libass

# lua
if [ ! -d lua ]; then
	mkdir lua
	$WGET https://www.lua.org/ftp/lua-$v_lua.tar.gz -O - | \
		tar -xz -C lua --strip-components=1
fi

# libplacebo
[ ! -d libplacebo ] && git clone --depth 1 --shallow-submodules --recursive https://github.com/haasn/libplacebo

# curl
if [ ! -d curl ]; then
	mkdir curl
	$WGET https://curl.se/download/curl-$v_curl.tar.gz -O - | \
		tar -xz -C curl --strip-components=1
fi

# mpv
[ ! -d mpv ] && git clone https://github.com/mpv-player/mpv

cd ..
