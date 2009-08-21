function upstream_session_memcached_ascii(self_addr, env, upstream_skt)
  local req = true
  while req do
    req = asock.recv(self_addr, upstream_skt, "*l")
    if req then
      local itr = string.gfind(req, "%S+")
      local cmd = itr()
      if cmd and string.len(cmd) > 1 then
        local spec = env.specs[cmd]
        if spec then
          if not spec(env.data, upstream_skt, cmd, iter_array(itr)) then
            req = nil
          end
        else
          asock.send(self_addr, upstream_skt, "ERROR\r\n")
        end
      end
    end
  end

  upstream_skt:close()
end

------------------------------------------------------

function upstream_session_memcached_binary(self_addr, env, upstream_skt)
  local mpb = memcached_protocol_binary
  local req = true
  local err, key, ext, data

  while req do
    req, err, args = mpb.pack.recv_request(upstream_skt)
    if req then
      local opcode = mpb.pack.opcode(req, 'request')
      local spec = env.specs[opcode]
      if spec then
        if not spec(env.data, upstream_skt, req, args) then
          req = nil
        end
      else
        local err_unknown =
          mpb.pack.create_response(opcode, {
            status = mpb.response_status.UNKNOWN_COMMAND,
            opaque = pack.opaque(req, 'request')
          })

        asock.send(self_addr, upstream_skt, err_unknown)
      end
    end
  end

  upstream_skt:close()
end

