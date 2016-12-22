#!/bin/sh
NAME=$1
mkdir $NAME-1.0
cat >$NAME-1.0/package_manifest.lua <<EOF
local manifest = {
	files = {
	},
}
return manifest
EOF
sed -i '$ d' index_pretty.lua
cat >> index_pretty.lua <<EOF
 ["$NAME"]={versions={"1.0"},author="DCNick3",dependencies={
 },
  description="Your description here",
 },
}
EOF
