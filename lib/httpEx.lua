local M = {}

local f_frame       = Field.new("frame")
local f_tcp_len     = Field.new("tcp.len")
local f_tcp_port    = Field.new("tcp.port")
local f_tcp_srcport = Field.new("tcp.srcport")
local f_tcp_dstport = Field.new("tcp.dstport")
local f_http        = Field.new("http")
local f_http_request        = Field.new("http.request")
local f_http_response_code  = Field.new("http.response.code")
local f_http_request_method = Field.new("http.request.method")
local f_http_request_uri    = Field.new("http.request.uri")

function M.init()
    if not f_http() then return false end

    local frame             = f_frame()
    local tcp_size          = f_tcp_len().value
    local http_frame        = frame.range(frame.len - tcp_size, tcp_size)
    local http_size         = frame.len-tcp_size
    local http_request          = false
    local http_response         = false
    local http_request_method   = (f_http_request_method() and f_http_request_method().value or "")
    local http_request_uri      = (f_http_request_uri() and f_http_request_uri().value or "")
    local http_result_code      = (f_http_response_code() and f_http_response_code().value or nil)
    
    if f_http_request() then
        http_request = true
    else
        http_response = true
    end
    
    -- First parse header
    local http_header       = {}
    local http_frame_string = http_frame:string()
    local http_header_size = string.find(http_frame_string, "\r\n\r\n") or string.find(http_frame_string, "\n\n\n\n")
    
    if http_header_size ~= nil then
        http_header_size = http_header_size + 3 -- Ignore new lines normally +4, but find returns index, so its -1
    else
        return false
    end
    
    for line in http_frame(0, http_header_size):string():gmatch('([^\n]*)\r\n') do
        local key = string.match(line, "^([^:]+):.*$")
        local value = string.match(line, "^[^:]+: (.*)$")
        
        if key ~= nil and value ~= nil then
            http_header[key] = value
        end
    end
    
    -- Next parse body
    local http_body_size    = http_frame:len() - http_header_size
    local http_body         = nil
    
    if http_body_size > 0 then
        http_body = http_frame(http_frame:len()-http_body_size, http_body_size):string()
    end
    
    -- Now we set the accessible member
    M.http_header = http_header
    M.http_body = http_body
    M.http_body_size = http_body_size
    M.http_request_method = http_request_method
    M.http_request_uri = http_request_uri
    M.http_result_code = http_result_code
    M.http_request = http_request
    M.http_response = http_response
    
    return true
end

return M
