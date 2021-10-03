#!/bin/zsh

local SCRIPT_DIR="$(dirname $0)"

local inkscapeBin="/Applications/Inkscape.app/Contents/MacOS/inkscape"
local saveDir="$SCRIPT_DIR/Assets.xcassets/AppIcon.appiconset"
local inkscapeFile="$SCRIPT_DIR/AppIcon.svg"
local commandFile="$SCRIPT_DIR/exportCmds.txt"

mkdir $saveDir

# Display script info
echo Inkscape binary: $inkscapeBin
echo Save directory: $saveDir

# To prevent inkscape from opening and closing with every call,
# open it in --shell mode and pass commands through standard input
# Exporting a single file looks like this:
#     $inkscapeBin -o $saveDir/AppIcon-1024x1024@1x.png -h 1024 $inkscapeFile
# In shell mode it looks like this:
#     export-filename: asdf.png; export-height: 100; export-do;
# https://inkscape.org/doc/inkscape-man.html

# Clear/create the command file
echo -n > $commandFile

# Function to add an export command of a particular size at a particular scale
# append_export_command <height> <scale>
function append_export_command () {
    readonly idiom=${1:?"The idiom must be specified."}
    readonly height=${2:?"The export height must be specified."}
    readonly scale=${3:?"The export scale be specified."}
    echo "export-filename: $saveDir/AppIcon-${idiom}-${height}x${height}@${scale}x.png; export-height: $(($height * $scale)); export-do;" >> $commandFile
}

# App Store
append_export_command ios-marketing 1024 1

# iPhone Notification
append_export_command iphone 20 2
append_export_command iphone 20 3

# iPhone Settings
append_export_command iphone 29 2
append_export_command iphone 29 3

# iPhone Spotlight
append_export_command iphone 40 2
append_export_command iphone 40 3

# iPhone App
append_export_command iphone 60 2
append_export_command iphone 60 3

# iPad Notifications
append_export_command ipad 20 1
append_export_command ipad 20 2

# iPad Settings
append_export_command ipad 29 1
append_export_command ipad 29 2

# iPad Spotlight
append_export_command ipad 40 1
append_export_command ipad 40 2

# iPad Pro (12.9 inch) App
append_export_command ipad 83.5 2

# iPad App
append_export_command ipad 76 1
append_export_command ipad 76 2

# Call inkscape
$inkscapeBin --shell $inkscapeFile < $commandFile

# Clean up export commands
rm $commandFile
