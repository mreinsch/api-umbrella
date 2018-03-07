local flatten_headers = require "api-umbrella.utils.flatten_headers"
local log_utils = require "api-umbrella.proxy.log_utils"
local zlib = require 'zlib'

local ngx_ctx = ngx.ctx
local ngx_var = ngx.var

if log_utils.ignore_request(ngx_ctx, ngx_var) then
  return
end

ngx.ctx.max_chunk_size = 10240
ngx.ctx.max_body_size = 10240

function inflate_body(data)
  local stream = zlib.inflate()
  local buffer = ""
  local chunk = ""

  for index = 0, data:len(), ngx.ctx.max_chunk_size do
    chunk = string.sub(data, index, index + ngx.ctx.max_chunk_size - 1)
    local status, output, eof, bytes_in, bytes_out = pcall(stream, chunk)

    if not status then
      -- corrupted chunk
      ngx.log(ngx.ERR, output)
      return buffer
    end

    buffer = buffer .. output

    if bytes_out > ngx.ctx.max_body_size then
      return buffer
    end
  end

  return buffer
end


local data, eof = ngx.arg[1], ngx.arg[2]

local content_encoding = flatten_headers(ngx.resp.get_headers())["content-encoding"]
if content_encoding == "gzip" then
  data = inflate_body(data)
end

local resp_body = (ngx.ctx.resp_log_buffer or "") .. string.sub(data, 1, 10240)
if eof then
  ngx.ctx.resp_log_buffer = nil
  ngx.var.resp_body_for_logging = resp_body
else
  ngx.ctx.resp_log_buffer = resp_body
end
