spec_map = {
  get = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           for key in itr do
             data = map_data[key]
             if data then
               apo_socket.send(sess_addr, skt,
                               "VALUE " .. key .. "\r\n" .. data)
             end
           end
           apo_socket.send(sess_addr, skt, "END\r\n")
           return true
         end
  },
  set = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           local key  = itr()
           local flgs = itr()
           local expt = itr()
           local size = itr()
           if key and flgs and expt and size then
             size = tonumber(size)
             if size >= 0 then
               local data = apo_socket.recv(sess_addr, skt,
                                            tonumber(size) + 2)
               if data then
                 map_data[key] = data
                 apo_socket.send(sess_addr, skt, "OK\r\n")
                 return true
               end
             end
           end
           apo_socket.send(sess_addr, skt, "ERROR\r\n")
           return true
         end
  },
  delete = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           local key = itr()
           if key then
             if map_data[key] then
               map_data[key] = nil
               apo_socket.send(sess_addr, skt, "DELETED\r\n")
             else
               apo_socket.send(sess_addr, skt, "NOT_FOUND\r\n")
             end
           else
             apo_socket.send(sess_addr, skt, "ERROR\r\n")
           end
           return true
         end
  },
  quit = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           return false
         end
  }
}

