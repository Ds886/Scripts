#!/bin/bash
#script_name->bg.sh
WallpaperFolder=''

 gsettings set org.mate.background picture-filename $'\''$WallpaperFolder/$(ls $WallpaperFolder | shuf -n 1)$'\''

