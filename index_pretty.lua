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
}
