-- actor_post_office
--
-- simple erlang-like, concurrent-lua-like system,
-- enabling cooperative actor-like application programming.
--
-- for local process only (not distributed), single main thread,
-- based on lua coroutines, with a trampoline-based design.

----------------------------------------

function actor_post_office_create()

local last_addr = 0

-- Map actor addresses to actor coroutines and vice-versa.

local map_addr_to_coro = {} -- table, key'ed by addr.
local map_coro_to_addr = {} -- table, key'ed by coro.

local envelopes = {}

----------------------------------------

local main_todos = {} -- array of funcs/closures, to be run on main thread.

local function run_main_todos(force)
  -- Check first if we're the main thread.
  if (coroutine.running() == nil) or force then
    local todo = nil
    repeat
      todo = table.remove(main_todos, 1)
      if todo then
        todo()
      end
    until todo == nil
  end
end

----------------------------------------

local function next_addr()
  local curr_addr

  repeat
    last_addr = last_addr + 1
    curr_addr = tostring(last_addr)
  until map_addr_to_coro[curr_addr] == nil

  return curr_addr
end

local function unregister(addr)
  local coro = map_addr_to_coro[addr]
  if coro then
    map_addr_to_coro[addr] = nil
    map_coro_to_addr[coro] = nil
  end
end

local function register(coro)
  unregister(map_coro_to_addr[coro])

  local curr_addr = next_addr()

  map_addr_to_coro[curr_addr] = coro
  map_coro_to_addr[coro] = curr_addr

  return curr_addr
end

----------------------------------------

local function deliver_envelope(envelope)
  -- Must be invoked on main thread.
  if envelope then
    local coro = map_addr_to_coro[envelope.dest_addr]
    if coro and coroutine.status(coro) ~= 'dead' then
      coroutine.resume(coro, unpack(envelope.msg))
    end
    return true
  end
  return false
end

local function step()
  -- Must be invoked on main thread.
  run_main_todos()

  return deliver_envelope(table.remove(envelopes, 1))
end

local function loop_until_empty(force)
  -- Check first if we're the main thread.
  if (coroutine.running() == nil) or force then
    local go = true
    while go do
      go = step()
    end
  end
end

local function loop()
  while true do
    loop_until_empty()
  end
end

----------------------------------------

-- Asynchronous send of a msg table.
--
local function send_msg(dest_addr, msg)
  table.insert(envelopes, { dest_addr = dest_addr, msg = msg })
end

-- Asynchronous send of variable args as a message.
--
local function send_later(dest_addr, ...)
  send_msg(dest_addr, arg)
end

-- Asynchronous send of variable args as a message.
--
-- Unlike send_later(), a send() might opportunistically,
-- process the message immediately before returning.
--
local function send(dest_addr, ...)
  send_msg(dest_addr, arg)

  loop_until_empty()
end

local function recv()
  if coroutine.running() then
    return coroutine.yield()
  end

  return nil
end

----------------------------------------

local function spawn_with(spawner, f, ...)
  local child_coro = nil
  local child_addr = nil
  local child_arg = arg
  local child_fun = function()
                      f(child_addr, unpack(child_arg))
                      unregister(child_addr)
                    end

  child_coro = spawner(child_fun)
  child_addr = register(child_coro)

  table.insert(main_todos,
    function()
      coroutine.resume(child_coro)
    end)

  run_main_todos()

  return child_addr
end

local function spawn(f, ...)
  return spawn_with(coroutine.create, f, ...)
end

----------------------------------------

return {
  recv       = recv,
  send       = send,
  send_later = send_later,
  step       = step,
  spawn      = spawn,
  spawn_with = spawn_with,
  register   = register,
  unregister = unregister,
  loop             = loop,
  loop_until_empty = loop_until_empty
}

end

----------------------------------------

return actor_post_office_create()
