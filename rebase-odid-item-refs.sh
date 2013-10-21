#/bin/sh
# Note: This script is assumed to be in the odid directory containing 
#       the "item-refs" and "media" subdirectories. For convenience, 
#       include this script with redistributable odid trees (at least
#       until we can get rid of abolute paths and/or .item files...)

scriptdir=$(dirname $0)
# note: $0 (and scriptdir) may be relative - need to make it absolute...
cd "$scriptdir"

# $basedir will be absolute
basedir="$PWD"

if [ ! -d item-refs ]; then
   echo "Couldn't find directory 'item-refs'. Make sure this script is an odid base directory."
   exit 1
fi

if [ ! -d media ]; then
   echo "Couldn't find directory 'media'. Make sure this script is an odid base directory."
   exit 2
fi

echo "Rebasing odid item references to $basedir/odid/media..."

for file in item-refs/* 
do 
   sed -i "s|//.*/odid/media/|//$basedir/media/|g" "$file"
   echo "   $file"
done
