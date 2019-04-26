#!/bin/bash
#script_name->bg.sh
WallpaperFolder='/home/dashvs/Pictures/wallpapers'

 gsettings set org.mate.background picture-filename $'\''$WallpaperFolder/$(ls ~/Pictures/wallpapers/ | shuf -n 1)$'\''

