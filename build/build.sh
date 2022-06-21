#!/bin/bash

set -e

if [ "$1" == "--local-aapt" ];then
    export LD_LIBRARY_PATH=.
    export PATH=.:$PATH
    shift
fi

script_dir="$(dirname "$(readlink -f -- "$0")")"

if ! command -v aapt > /dev/null;then
    export LD_LIBRARY_PATH=.
    export PATH=$PATH:.
fi

if ! command -v aapt > /dev/null;then
    echo "Please install aapt (apt install aapt should do)"
    exit 1
fi

cd "$script_dir"
chmod +x aapt
mkdir output

build () {
    name=$1
    path="../${name}"
    aapt package -f -F "${name}-unsigned.apk" -M "$path/AndroidManifest.xml" -S "$path/res" -I android.jar
    LD_LIBRARY_PATH=./signapk/ java -jar signapk/signapk.jar keys/platform.x509.pem keys/platform.pk8 "${name}-unsigned.apk" "${name}.apk"
    rm -f "${name}-unsigned.apk"

    # make magisk module
    cp -r magisk-module magisk-tmp
    mkdir -p "magisk-tmp/system/app/${name}"
    mv "${name}.apk" "magisk-tmp/system/app/${name}/${name}.apk"
    cp "${path}/module.prop" "magisk-tmp/module.prop"

    cd magisk-tmp
    zip -r "../output/magisk-${name}.zip" ./*
    cd ..
    rm -rf magisk-tmp
}