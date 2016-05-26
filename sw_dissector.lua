require 'stringutil'
local inspect       = require 'inspect'
local httpEx        = require 'httpEx'
local summonCrypt   = require 'summoncrypt'
local JSON          = require 'JSON'
debug("sw_proto postdissector loaded")

sw_proto = Proto("sw_proto", "SW Protocol")

local request_internal_port = {} -- Used to identify, if a response belongs to a request

local f_tcp_srcport     = Field.new("tcp.srcport")
local f_tcp_dstport     = Field.new("tcp.dstport")

function sw_proto.dissector(buffer, pinfo, tree)
    if not httpEx.init() then return end
    
    function render()
        pinfo.cols.protocol = "SW"
        local root = tree:add(sw_proto, "SW Protocol")
        
        if httpEx.http_body_size > 0 then
            local b64 = httpEx.http_body:gsub("\r?\n", "")
            
            local encrypted_node = root:add(sw_proto, "Encrypted")
            for k,v in pairs(string.splitBySize(b64, 100)) do
                encrypted_node:add(v)
            end
            
            local decrypted_node = root:add(sw_proto, "Decrypted")
            local decrypted = summonCrypt.decryptActiveUser(httpEx.http_header["REQ-TIMESTAMP"], b64)
            decrypted = JSON:encode_pretty(JSON:decode(decrypted))
            for k,v in pairs(string.splitByBreak(decrypted)) do
                decrypted_node:add(v)
            end
        end
    
        --[[pinfo.cols.protocol = "SW C2"
        local root = tree:add(sw_proto, 'SW C2 Protocol')
        
        if httpEx.http_body_size > 0 then
            if httpEx.http_header['SmonTmVal'] then
                root:add("SmonTmVal: ", httpEx.http_header['SmonTmVal'])
            end
            if httpEx.http_header['SmonChecker'] then
                root:add("SmonChecker: ", httpEx.http_header['SmonChecker'])
            end
            
            local encrypted_node = root:add(sw_proto, "Encrypted")
            local b64 = httpEx.http_body
            for k,v in pairs(string.splitBySize(b64, 100)) do
                encrypted_node:add(v)
            end
            
            local decrypted_node = root:add(sw_proto, "Decrypted")
            local decrypted = summonCrypt.decryptV2(httpEx.http_body, httpEx.http_response)
            decrypted = JSON:encode_pretty(JSON:decode(decrypted))
            for k,v in pairs(string.splitByBreak(decrypted)) do
                decrypted_node:add(v)
            end
        end]]--
    end
    
    if httpEx.http_request then
        if string.match(httpEx.http_request_uri, "gateway.php") then
            if httpEx.http_header["REQ-TIMESTAMP"] then
                request_internal_port[tostring(f_tcp_srcport().value)] = true;
                
                render()
            end
        end
    else
        if request_internal_port[tostring(f_tcp_dstport().value)] ~= nil then
            render()
        end
    end
end

register_postdissector(sw_proto)
