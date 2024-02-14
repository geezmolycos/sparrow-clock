#!/bin/sh

LOVE_DIR="$1"

zip -9 -r build/SparrowClock.love . -x ".git**" -x ".vscode**" -x "build**" -x "images**" -x .gitignore -x build.sh 

cp user.lua build/user_external.lua

mkdir build/modules

echo "${LOVE_DIR}"

if [ "${LOVE_DIR}" = "" ]; then
    echo "no love dir specified, exiting"
    exit
fi

cat "${LOVE_DIR}/love.exe" build/SparrowClock.love > build/SparrowClock.exe

declare -a COPY_DLLS=("SDL2" "love" "lua51" "msvcp120" "msvcr120" "mpg123" "OpenAL32")
for i in "${COPY_DLLS[@]}"
do
   cp "${LOVE_DIR}/$i.dll" "build/$i.dll"
done
cp "${LOVE_DIR}/license.txt" "build/license.txt"
