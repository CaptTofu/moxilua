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

