PACKAGES=$(lua pack_lua_helper.lua list)

rm -f index.lua
for f in $PACKAGES
do
 tar -cf $f.tar $f/*
 s=$(stat --printf="%s" $f.tar)
 lua pack_lua_helper.lua size $f $s
done
