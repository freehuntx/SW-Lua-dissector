require 'stringutil'
local inspect       = require 'inspect'
local summonCrypt   = require 'summoncrypt'
debug("sw_chat_proto postdissector loaded")

sw_chat_proto = Proto("sw_chat_proto", "SW Chat Protocol")

local packet_types = {
  [1003] = "ping_req", [1004] = "ping_ack",
  [1005] = "channel_join_req", [1006] = "channel_join_ack",
  [1007] = "chat_message_req", [1008] = "chat_message_ack",
  [1010] = "chat_message",
  [1017] = "login_req", [1018] = "login_ack"
}

local f = sw_chat_proto.fields
-- Main fields
f.packet_size = ProtoField.uint16("sw_chat_proto.packet_size", "Size", base.DEC)
f.packet_type = ProtoField.uint16("sw_chat_proto.packet_type", "Type", base.DEC)
-- Login fields
f.login_req_unkn1 = ProtoField.uint32("sw_chat_proto.login.req.unkn1", "Unkn1", base.DEC)
f.login_req_hive_id = ProtoField.uint64("sw_chat_proto.login.req.hive_id", "hive_id", base.DEC)
f.login_req_game_server_id = ProtoField.uint32("sw_chat_proto.login.req.game_server_id", "Gameserver id", base.DEC)
f.login_req_login_key = ProtoField.uint32("sw_chat_proto.login.req.login_key", "Login key", base.DEC)
f.login_req_unkn4 = ProtoField.bytes("sw_chat_proto.login.req.unkn4", "Unkn4", base.HEX)

f.login_ack_unkn1 = ProtoField.uint32("sw_chat_proto.login.ack.unkn1", "Unkn1", base.DEC)
f.login_ack_unkn2 = ProtoField.uint32("sw_chat_proto.login.ack.unkn2", "Unkn2", base.DEC)
f.login_ack_unkn3 = ProtoField.uint32("sw_chat_proto.login.ack.unkn3", "Unkn3", base.DEC)
f.login_ack_unkn4 = ProtoField.bytes("sw_chat_proto.login.ack.unkn4", "Unkn4", base.HEX)
-- Message fields
f.message_content_size = ProtoField.uint16("sw_chat_proto.message.content_size", "Content size", base.DEC)
f.message_req_hive_id = ProtoField.uint64("sw_chat_proto.message.req.hive_id", "hive_id", base.DEC)
f.message_req_unkn1 = ProtoField.uint32("sw_chat_proto.message.req.unkn1", "Unkn1", base.DEC)
f.message_req_unkn2 = ProtoField.uint32("sw_chat_proto.message.req.unkn2", "Unkn2", base.DEC)
f.message_req_content_size = ProtoField.uint16("sw_chat_proto.message.req.content_size", "Content size", base.DEC)
f.message_ack_return_code = ProtoField.uint32("sw_chat_proto.message.ack.return_code", "Returncode", base.DEC)
-- Ping fields
f.ping_req_hive_id = ProtoField.uint64("sw_chat_proto.ping.req.hive_id", "hive_id", base.DEC)
f.ping_req_unkn1 = ProtoField.uint32("sw_chat_proto.ping.req.unkn1", "Unkn1", base.DEC)
f.ping_req_unkn2 = ProtoField.uint32("sw_chat_proto.ping.req.unkn2", "Unkn2", base.DEC)
f.ping_req_unkn3 = ProtoField.uint32("sw_chat_proto.ping.req.unkn3", "Unkn3", base.DEC)
f.ping_ack_return_code = ProtoField.uint32("sw_chat_proto.ping.ack.return_code", "Returncode", base.DEC)
-- Channel join fields
f.channel_join_req_hive_id = ProtoField.uint64("sw_chat_proto.channel_join.req.hive_id", "hive_id", base.DEC)
f.channel_join_req_unkn1 = ProtoField.uint32("sw_chat_proto.channel_join.req.unkn1", "Unkn1", base.DEC)
f.channel_join_req_unkn2 = ProtoField.uint32("sw_chat_proto.channel_join.req.unkn2", "Unkn2", base.DEC)
f.channel_join_req_channel = ProtoField.uint32("sw_chat_proto.channel_join.req.channel", "Channel", base.DEC)
f.channel_join_ack_returncode = ProtoField.uint32("sw_chat_proto.channel_join.ack.returncode", "Returncode", base.DEC)
f.channel_join_ack_channel = ProtoField.uint32("sw_chat_proto.channel_join.ack.channel", "Channel", base.DEC)


function sw_chat_proto.dissector(buffer, pinfo, tree)
  local packet_size = buffer(0, 2):uint()
  local packet_type = buffer(2, 2):uint()
  local packet_name = (packet_types[packet_type] and packet_types[packet_type] or "UNKNOWN")
    
  pinfo.cols.protocol = "SW Chat"
    
  local root = tree:add(buffer(0), 'SW Chat Protocol')
  root:add(f.packet_size, buffer(0, 2), packet_size, f.packet_size)
  root:add(f.packet_type, buffer(2, 2), packet_type, f.packet_type, "("..packet_name..")")
   
  local handlers = {
  	[1003] = function()
      local hive_id = buffer(4, 8):uint64()
      local unkn1 = buffer(12, 4):uint()
      local unkn2 = buffer(16, 4):uint()
      local unkn3 = buffer(20, 4):uint()
      local ping_req_node = root:add(sw_c2_proto, buffer(4), "Ping request")
      
      ping_req_node:add(f.ping_req_hive_id, buffer(4, 8), hive_id)
      ping_req_node:add(f.ping_req_unkn1, buffer(12, 4), unkn1)
      ping_req_node:add(f.ping_req_unkn2, buffer(16, 4), unkn2)
      ping_req_node:add(f.ping_req_unkn3, buffer(20, 4), unkn3)
    end,
    [1004] = function()
      local returncode = buffer(4, 4):uint()
      local ping_ack_node = root:add(sw_c2_proto, buffer(4), "Ping acknowledge")
      
      ping_ack_node:add(f.ping_ack_return_code, buffer(4, 4), returncode)
    end,
    [1005] = function()
      local hive_id = buffer(4, 8):uint64()
      local unkn1 = buffer(12, 4):uint()
      local unkn2 = buffer(16, 4):uint()
      local channel = buffer(20, 4):uint()
      local channel_join_req_node = root:add(sw_c2_proto, buffer(4), "Channel join request")
      
      channel_join_req_node:add(f.channel_join_req_hive_id, buffer(4, 8), hive_id)
      channel_join_req_node:add(f.channel_join_req_unkn1, buffer(12, 4), unkn1)
      channel_join_req_node:add(f.channel_join_req_unkn2, buffer(16, 4), unkn2)
      channel_join_req_node:add(f.channel_join_req_channel, buffer(20, 4), channel)
    end,
    [1006] = function()
      local returncode = buffer(4, 4):uint()
      local channel = buffer(8, 4):uint()
      local channel_join_ack_node = root:add(sw_c2_proto, buffer(4), "Channel join acknowledge")
      
      channel_join_ack_node:add(f.channel_join_ack_returncode, buffer(4, 4), returncode)
      channel_join_ack_node:add(f.channel_join_ack_channel, buffer(8, 4), channel)
    end,
    [1007] = function()
      local hive_id = buffer(4, 8):uint64()
      local unkn1 = buffer(12, 4):uint()
      local unkn2 = buffer(16, 4):uint()
      local b64_size = buffer(20, 2):uint()
      local b64_encoded = buffer(22, b64_size):stringz()
      local message_req_node = root:add(sw_c2_proto, buffer(4), "Message request")
      
      message_req_node:add(f.message_req_hive_id, buffer(4, 8), hive_id)
      message_req_node:add(f.message_req_unkn1, buffer(12, 4), unkn1)
      message_req_node:add(f.message_req_unkn2, buffer(16, 4), unkn2)
      message_req_node:add(f.message_req_content_size, buffer(20, 2), b64_size)
      
          
      local encrypted_node = message_req_node:add(sw_chat_proto, buffer(22, b64_size), "Encrypted")
      for k,v in pairs(string.splitBySize(b64_encoded, 100)) do
        encrypted_node:add(buffer(22, b64_size), v)
      end
          
      local decrypted = summonCrypt.decryptV1(b64_encoded)
      local decrypted_node = message_req_node:add(sw_chat_proto, buffer(22, b64_size), "Decrypted")
          
      for k,v in pairs(string.splitByBreak(decrypted)) do
        decrypted_node:add(buffer(22, b64_size), v)
      end
    end,
    [1008] = function()
      local returncode = buffer(4, 4):uint()
      local message_ack_node = root:add(sw_c2_proto, buffer(4), "Message acknowledge")
      
      message_ack_node:add(f.message_ack_return_code, buffer(4, 4), returncode)
    end,
    [1010] = function()
      local b64_size = buffer(4, 2):uint()
      local b64_encoded = buffer(6, b64_size):stringz()
      local chat_message_node = root:add(sw_chat_proto, buffer(4), "Chat message")
          
      chat_message_node:add(f.message_content_size, buffer(4, 2), b64_size)
          
      local encrypted_node = chat_message_node:add(sw_chat_proto, buffer(6, b64_size), "Encrypted")
      for k,v in pairs(string.splitBySize(b64_encoded, 100)) do
        encrypted_node:add(buffer(6, b64_size), v)
      end
          
      local decrypted = summonCrypt.decryptV1(b64_encoded)
      local decrypted_node = chat_message_node:add(sw_chat_proto, buffer(6, b64_size), "Decrypted")
          
      for k,v in pairs(string.splitByBreak(decrypted)) do
        decrypted_node:add(buffer(6, b64_size), v)
      end
    end,
    [1017] = function()
      local unkn1         = buffer(4, 4):uint()
      local hive_id  = buffer(8, 8):uint64()
      local game_server_id         = buffer(16, 4):uint()
      local login_key         = buffer(20, 4):uint()
      local unkn4         = buffer(24, 12):bytes()
      local login_req_node = root:add(sw_c2_proto, buffer(4), "Login request")
      
      login_req_node:add(f.login_req_unkn1, buffer(4, 4), unkn1)
      login_req_node:add(f.login_req_hive_id, buffer(8, 8), hive_id)
      login_req_node:add(f.login_req_game_server_id, buffer(16, 4), game_server_id)
      login_req_node:add(f.login_req_login_key, buffer(20, 4), login_key)
      login_req_node:add(f.login_req_unkn4, buffer(24, 12))
    end,
    [1018] = function()
      local unkn1         = buffer(4, 4):uint()
      local unkn2         = buffer(8, 4):uint()
      local unkn3         = buffer(12, 4):uint()
      local unkn4         = buffer(16, 8):bytes()
      local login_ack_node = root:add(sw_c2_proto, buffer(4), "Login acknowledge")
          
      login_ack_node:add(f.login_ack_unkn1, buffer(4, 4), unkn1)
      login_ack_node:add(f.login_ack_unkn2, buffer(8, 4), unkn2)
      login_ack_node:add(f.login_ack_unkn3, buffer(12, 4), unkn3)
      login_ack_node:add(f.login_ack_unkn4, buffer(16, 8))
    end
  }
   
  if handlers[packet_type] ~= nil then
    handlers[packet_type]() -- Call the handelr for the packet type
  else
    -- No handler for this packet type
  end
end

tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(11011, sw_chat_proto)
