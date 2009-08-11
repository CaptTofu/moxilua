-- Integration of actor post office with sockets.
--
local socket = require("socket")

function actor_socket_create()

local reading = {} -- Array of sockets for next select().
local writing = {} -- Array of sockets for next select().

local reverse_r = {} -- Reverse lookup from socket to reading/writing index.
local reverse_w = {} -- Reverse lookup from socket to reading/writing index.

local waiting_actors = {} -- Keyed by socket, value is actor addr.

------------------------------------------

local function skt_unwait(skt, sockets, reverse)
  waiting_actors[skt] = nil
  local cur = reverse[skt]
  if cur then
    reverse[skt] = nil
    local num = #sockets
    local top = sockets[num]
    sockets[num] = nil
    if cur < num then
      sockets[cur] = top
      reverse[top] = cur
    end
  end
end

local function skt_wait(skt, sockets, reverse, actor_addr)
  waiting_actors[skt] = actor_addr
  table.insert(sockets, skt)
  reverse[skt] = #sockets
end

------------------------------------------

local function awake_actor(skt)
  local actor_addr = waiting_actors[skt]

  skt_unwait(skt, reading, reverse_r)
  skt_unwait(skt, writing, reverse_w)

  if actor_addr then
    apo.send_later(actor_addr, skt)
  end
end

local function process_ready(ready, name)
  for i = 1, #ready do
    awake_actor(ready[i])
  end
end

local function step(timeout)
  if (#reading + #writing) <= 0 then
    return nil
  end

  local readable, writable, err = socket.select(reading, writing, timeout)

  process_ready(readable, "r")
  process_ready(writable, "w")

  if err == "timeout" and (#readable + #writable) > 0 then
    return nil
  end

  return err
end

------------------------------------------

local function recv(actor_addr, skt, pattern, part)
  local s, err

  repeat
    skt_unwait(skt, reading, reverse_r)

    s, err, part = skt:receive(pattern, part)
    if s or err ~= "timeout" then
      return s, err, part
    end

    skt_wait(skt, reading, reverse_r, actor_addr)

    coroutine.yield()
  until false
end

local function send(actor_addr, skt, data, from, to)
  from = from or 1
  local lastIndex = from - 1

  repeat
    skt_unwait(skt, writing, reverse_w)

    local s, err, lastIndex = skt:send(data, lastIndex + 1, to)
    if s or err ~= "timeout" then
       return s, err, lastIndex
    end

    skt_wait(skt, writing, reverse_w, actor_addr)

    coroutine.yield()
  until false
end

local function loop_accept(actor_addr, skt, handler, timeout)
  skt:settimeout(timeout or 0)

  repeat
    skt_unwait(skt, reading, reverse_r)

    local client_skt, err = skt:accept()
    if client_skt then
      handler(client_skt)
    end

    skt_wait(skt, reading, reverse_r, actor_addr)

    coroutine.yield()
  until false
end

local function send_recv(self_addr, conn, msg, recv_callback)
  local ok = asock.send(self_addr, conn, msg)
  if not ok then
    return nil
  end

  local rv = asock.recv(self_addr, conn)
  if rv and recv_callback then
    recv_callback(rv)
  end

  return rv
end


------------------------------------------

return {
  step = step,
  recv = recv,
  send = send,
  send_recv = send_recv,
  loop_accept = loop_accept
}

end

------------------------------------------

return actor_socket_create()

