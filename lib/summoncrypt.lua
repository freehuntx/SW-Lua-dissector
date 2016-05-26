local Array = require("lockbox.util.array")
local Stream = require("lockbox.util.stream")
local Digest = require("lockbox.digest.md5");
local Base64 = require("lockbox.util.base64")
local CBCMode = require("lockbox.cipher.mode.cbc")
local PKCS7Padding = require("lockbox.padding.pkcs7");
local PKCS7Ex = require("lockbox.padding.pkcs7Ex");
local AES128Cipher = require("lockbox.cipher.aes128")
local deflate = require("compress.deflatelua")
local inspect = require 'inspect'

local M = {}
local activeUser = {
  ["iv"] = "00000000000000000000000000000000"
}
local version1 = {
  ["iv"] = "00000000000000000000000000000000",
  ["key"] = ""
}
local version2 = {
  ["iv"] = "00000000000000000000000000000000",
  ["key"] = ""
}

function M.decryptAes(b64, key, iv, uncompress)
  uncompress = uncompress or false
  
  local decipher = CBCMode.Decipher()
    .setKey(Array.fromString(key))
    .setBlockCipher(AES128Cipher)
    .setPadding(PKCS7Padding)
    
  local decrypted = decipher
    .init()
    .update(Stream.fromHex(iv))
    .update(Base64.toStream(b64))
    .finish()
    .asBytes()
    
  local decrypted = PKCS7Ex.parse(decrypted)
    
  if uncompress then
    local input = Array.toString(decrypted)
    local output = {}
    
    deflate.inflate_zlib{
      input = input,
      output = function(byte) output[#output+1] = string.char(byte) end
    }
    
    return table.concat(output)
  else
    return Array.toString(decrypted)
  end
end

function M.decryptActiveUser(timestamp, b64, uncompress)
  local key = Digest()
    .update(Stream.fromString(timestamp))
		.finish()
    .asHex()
  key = string.sub(key, 0, 16)
  
  return M.decryptAes(b64, key, activeUser['iv'], uncompress)
end

function M.decryptV1(b64, uncompress)
  return M.decryptAes(b64, version1['key'], version1['iv'], uncompress)
end

function M.decryptV2(b64, uncompress)
  return M.decryptAes(b64, version2['key'], version2['iv'], uncompress)
end

return M
