#Wireshark Dissector

##Setup dissector initialization
1. Open the file: {Wireshark_path}/init.lua
2. Make sure "disable_lua" is not true
3. Add this line to the end of the lua file:
```
dofile("<Path to the dissector init>")
```
e.g.
```
dofile("E:/Bibliotheken/Desktop/sw_packetstuff/wireshark/init.lua")
```
---
##Setup dissector
1. Open Wireshark -> Edit -> Preferences -> Protocols -> DLT_USER
2. Click on "Edit..."
3. Click on "New"
4. Use this Options:
```
DLT: User 0 (DLT=147)
Payload protocol: sw_chat_proto (Or whatever the Proto is called. Look in its lua file)
Header size: 0
Header protocol:
Trailer size: 0
Trailer protocol: 
```
5. Apply everything and restart Wireshark.
6. To turn the dissector on/off, go to: "Analyze -> Enabled Protocols..."