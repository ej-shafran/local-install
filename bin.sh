#!/usr/bin/env bash
NC='\033[0m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

path="$1"
basicname=$(sed -nr '/"name":/ s/.*"name": "(.+)",.*/\1/p' $path/package.json)
version=$(sed -nr '/"version":/ s/.*"version": "(.+)",.*/\1/p' $path/package.json)
packagename=${basicname/\@/}
finalname="${packagename//\//-}-$version.tgz"

echo -e "packing ${GREEN}$path${NC} into ${YELLOW}$finalname${NC}..." &&
  npm pack $path 2>/dev/null &&
  echo -e "\ninstalling dependencies, along with ${GREEN}$basicname${NC}..." &&
  npm i "$finalname" 2>/dev/null &&
  echo -e "removing ${YELLOW}$finalname${NC}..." &&
  rm "$finalname";

