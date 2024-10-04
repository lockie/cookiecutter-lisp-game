#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "USAGE: $0 <package flavor>"
    exit 1
fi

export VERSION=${GITHUB_REF_NAME:-$(git describe --always --tags --dirty=+ --abbrev=6)}

function do_build () {
    CL_SOURCE_REGISTRY=$(pwd) sbcl --dynamic-space-size 2048 --disable-debugger --quit --load package/build.lisp
}

case $1 in
    linux)
        do_build
        DEPLOY_GTK_VERSION=3 linuxdeploy --appimage-extract-and-run --executable=bin/{{cookiecutter.project_slug}} \
                    --custom-apprun=package/AppRun \
                    --icon-file=package/icon.png \
                    --desktop-file=package/{{cookiecutter.project_slug}}.desktop \
                    --plugin gtk \
                    --appdir=appimage $(find bin -name "lib*" -printf "-l%p ")
        cp bin/{{cookiecutter.project_slug}} appimage/usr/bin
        cp -R Resources appimage/usr
        appimagetool --appimage-extract-and-run --comp xz -g appimage "{{cookiecutter.project_slug}}-${VERSION}.AppImage"
        ;;

    windows)
        do_build
        {% if cookiecutter.backend != "raylib" %}
        ntldd -R bin/* | grep ucrt64 | awk -F '=> ' '{ print $2 }' | awk '{ print $1 }' | xargs -I deps cp deps bin
        {% endif %}
        makensis package/installer.nsi
        ;;

    macos)
        do_build
        bundle="{{cookiecutter.project_name}}.app"
        contents=$bundle/Contents
        mkdir -p "$contents/MacOS"
        cp -r Resources "$contents"
        cp package/Info.plist "$contents"
        cp package/icon.png "$contents/Resources"
        for library in bin/*.dylib; do
            dylibbundler -of -cd -b -p '@loader_path' -x "$library" -d "$contents/MacOS"
            cp "$library" "$contents/MacOS"
        done
        mv "$contents"/MacOS/libzstd* "$contents/MacOS/libzstd.1.dylib"

        # https://bugs.launchpad.net/sbcl/+bug/1869401
        replace_fr=$(echo -n  "/opt/local/lib/libzstd.1.dylib" | xxd -ps -c1 | tr -d '\n')
        replace_to=$(echo -en "@loader_path/libzstd.1.dylib\x00\x00" | xxd -ps -c1 | tr -d '\n')
        xxd -ps -c1 bin/{{cookiecutter.project_slug}} | tr -d '\n' | sed "s/$replace_fr/$replace_to/" | fold -w 2 | xxd -r -p > "$contents/MacOS/{{cookiecutter.project_slug}}"
        chmod +x "$contents/MacOS/{{cookiecutter.project_slug}}"

        hdiutil create -quiet -srcfolder "$bundle" out.dmg
        # NOTE: ULMO = lzma compression = Catalina+ only
        hdiutil convert -quiet out.dmg -format ULMO -o "{{cookiecutter.project_slug}}-${VERSION}.dmg"
        rm out.dmg
        ;;

    *)
        echo "Uknown package flavor: $1"
        exit 1
        ;;
esac
