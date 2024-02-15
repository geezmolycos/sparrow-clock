#!/bin/bash

echo "Packaging game"

zip -9 -r build/SparrowClock.love . -x ".git**" -x ".vscode**" -x "build**" -x "images**" -x .gitignore -x build.sh 

echo "Copying config files"

cp user.lua build/user_external.lua

mkdir build/modules

echo "Making love executable"

echo "${LOVE_DIR}"

if [ "${LOVE_DIR}" = "" ]; then
    echo "no love dir specified, exiting"
    exit
fi

cat "${LOVE_DIR}/love.exe" "build/SparrowClock.love" > "build/SparrowClock_noicon.exe"

declare -a COPY_DLLS=("SDL2" "love" "lua51" "msvcp120" "msvcr120" "mpg123" "OpenAL32")
for i in "${COPY_DLLS[@]}"
do
   cp "${LOVE_DIR}/$i.dll" "build/$i.dll"
done
cp "${LOVE_DIR}/license.txt" "build/license.txt"

echo "Generating icon"

echo "${IMAGEMAGICK}"

if [ "${IMAGEMAGICK}" = "" ]; then
    echo "no imagemagick, exiting"
    exit
fi

"${IMAGEMAGICK}" convert "images/sparrow.png" -define icon:auto-resize=256,64,48,32,16 "build/icon.ico"

echo "Replacing icon"

echo "${RESOURCEHACKER}"

if [ "${RESOURCEHACKER}" = "" ]; then
    echo "no resource hacker, exiting"
    exit
fi

if "${RESOURCEHACKER}" \
   -open "build/SparrowClock_noicon.exe" \
   -save "build/SparrowClock.exe" \
   -action addoverwrite \
   -res "build/icon.ico" \
   -mask ICONGROUP,MAINICON, ; then
   echo "Icon replaced, removing intermediate files"
    rm build/SparrowClock_noicon.exe
    rm build/icon.ico
else
   echo "Failed to replace icon"
fi
