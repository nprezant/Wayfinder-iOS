#!/bin/sh

local SCRIPT_DIR="$(dirname $0)"

local inkscapeBin="/Applications/Inkscape.app/Contents/MacOS/inkscape"
local saveDir="$SCRIPT_DIR/appIcons"
local inkscapeFile="$SCRIPT_DIR/AppIcon.svg"

mkdir $saveDir

echo Inkscape binary: $inkscapeBin
echo Save directory: $saveDir

# App Store
$inkscapeBin -o $saveDir/AppIcon-1024x1024@1x.png -h 1024 $inkscapeFile

# iPhone Notification
$inkscapeBin -o $saveDir/AppIcon-20x20@2x.png -h 40 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-20x20@3x.png -h 60 $inkscapeFile

# iPhone Settings
$inkscapeBin -o $saveDir/AppIcon-29x29@2x.png -h 58 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-29x29@3x.png -h 87 $inkscapeFile

# iPhone Spotlight
$inkscapeBin -o $saveDir/AppIcon-40x40@2x.png -h 80 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-40x40@3x.png -h 120 $inkscapeFile

# iPhone App
$inkscapeBin -o $saveDir/AppIcon-60x60@2x.png -h 120 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-60x60@3x.png -h 180 $inkscapeFile

# iPad Notifications
$inkscapeBin -o $saveDir/AppIcon-20x20@1x.png -h 20 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-20x20@2x.png -h 40 $inkscapeFile

# iPad Settings
$inkscapeBin -o $saveDir/AppIcon-29x29@1x.png -h 29 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-29x29@2x.png -h 58 $inkscapeFile

# iPad Spotlight
$inkscapeBin -o $saveDir/AppIcon-40x40@1x.png -h 40 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-40x40@2x.png -h 80 $inkscapeFile

# iPad Pro (12.9 inch) App
$inkscapeBin -o $saveDir/AppIcon-83.5x40@2x.png -h 167 $inkscapeFile

# iPad App
$inkscapeBin -o $saveDir/AppIcon-76x76@1x.png -h 76 $inkscapeFile
$inkscapeBin -o $saveDir/AppIcon-76x76@2x.png -h 152 $inkscapeFile
