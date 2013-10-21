#/bin/sh
# Note: This script is assumed to be in the odid directory containing 
#       the "item-refs" and "media" subdirectories. For convenience, 
#       include this script with redistributable odid trees (at least
#       until we can get rid of abolute paths and/or .item files...

scriptdir=$(dirname $0)
# note: $0 (and scriptdir) may be relative - need to make it absolute...
cd "$scriptdir"

# $basedir will be absolute
basedir="$PWD"

echo "Rebasing odid item references to $basedir/odid/media..."

for file in item-refs/* 
do 
   sed -i "s|//.*/odid/media/|//$basedir/media/|g" "$file"
   echo "   $file"
done
