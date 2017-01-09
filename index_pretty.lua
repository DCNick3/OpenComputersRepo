return {
 ["test-library"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={} },
  description="Test useless package fot testing library downloading",
 },
 ["test-program"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={"test-library-1.0"} },
  description="Test useless package fot testing library downloading",
 },
 ["libtar"]={versions={"1.0"},author="???",dependencies={
  ["1.0"]={} },
  description="A pure-lua implementation of tar format. Used source from luarocks and edited for OC by DCNick3~",
 },
 ["libserprint"]={versions={"1.0"},author="pkulchenko",dependencies={
  ["1.0"]={} },
  description="Lua serializer and pretty printer.",
 },
 ["libvar_dump"]={versions={"1.0"},author="lunixbochs",dependencies={
  ["1.0"]={} },
  description="Simple and useful function for debugging programs",
 },
 ["libpacket-manager"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={"libtar-1.0", "libvar_dump-1.0", "libserprint-1.0"} },
  description="Packet manager helper library",
 },
 ["packet-manager"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={"libpacket-manager-1.0"} },
  description="Packet manager",
 },
 ["libmapped-screen"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={"libvar_dump-1.0"} },
  description="Simple library for mapping screen. Useful for showing various infomation.",
 },
 ["eventcat"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={"libserprint-1.0"} },
  description="Simple program for viewing signals",
 },
 ["movement-logger"]={versions={"1.0"},author="DCNick3",dependencies={
  ["1.0"]={} },
  description="Simple program for movement sensor to log, which players were detected",
 },
 ["tar"]={versions={"1.0"},author="DCNick3",dependencies={
 ["1.0"]={"libtar-1.0"} },
  description="Simple program to unpack tar archives",
 },
 ["shrun"]={versions={"1.0"},author="DCNick3",dependencies={
 ["1.0"]={} },
  description="Simple program for executing shell scripts",
 },
 ["libbinser"]={versions={"1.0"},author="Calvin Rose",dependencies={
 ["1.0"]={} },
  description="There already exists a number of serializers for Lua, each with their own uses, limitations, and quirks. binser is yet another robust, pure Lua serializer that specializes in serializing Lua data with lots of userdata and custom classes and types. binser is a binary serializer and does not serialize data into human readable representation or use the Lua parser to read expressions. This makes it safe and moderately fast, especially on LuaJIT. binser also handles cycles, self-references, and metatables.",
 },
}
