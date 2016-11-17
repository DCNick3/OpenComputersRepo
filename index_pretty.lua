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
}