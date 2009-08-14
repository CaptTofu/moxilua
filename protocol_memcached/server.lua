function upstream_session_memcached_ascii(self_addr, specs, go_data, upstream_skt)
  local req = true
  while req do
    req = asock.recv(self_addr, upstream_skt, "*l")
    if req then
      local itr = string.gfind(req, "%S+")
      local cmd = itr()
      if cmd then
        local spec = specs[cmd]
        if spec then
          if not spec(go_data, upstream_skt, itr) then
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

function upstream_session_memcached_binary(self_addr, specs, go_data, upstream_skt)
  local mpb = memcached_binary_protocol
  local req = true
  while req do
    req, err, key, ext, data = mpb.pack.recv_request(upstream_skt)
    if req then
      local opcode = mpb.pack.opcode(req)
      local spec = specs[opcode]
      if spec then
        if not spec(go_data, upstream_skt, req, key, ext, data) then
          req = nil
        end
      else
        local unknown =
          mpb.pack.create_response(opcode, nil, nil, 0,
                                   mpb.response_status.UNKNOWN_COMMAND)

        asock.send(self_addr, upstream_skt, unknown)
      end
    end
  end

  upstream_skt:close()
end

