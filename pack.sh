PACKAGES=$(lua pack_lua_helper.lua list)

rm -f index.lua
for f in $PACKAGES
do
 rm -f $f.tar
 echo Packing $f...
 cd $f && tar -cf ../$f.tar * && cd ..
 s=$(stat --printf="%s" $f.tar)
 lua pack_lua_helper.lua size $f $s
done
