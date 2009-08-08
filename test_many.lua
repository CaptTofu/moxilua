apo = require('actor_post_office')

times = 100000

function node(self_addr, next_addr, n)
  -- print("node " .. self_addr .. " --> " .. next_addr)

  while true do
    local msg = apo.recv()
    -- print("node " .. self_addr .. " recv'ed " .. msg)

    apo.send(next_addr, msg)
    -- print("msg forwarded")
  end
end

last_addr = nil

t_start = os.clock()

for i = 1, times do
  last_addr = apo.spawn(node, last_addr, 2)
end

t_spawned = os.clock()

apo.send(last_addr, "hi!")

t_sent = os.clock()

print("spawns/sec: ", times / (t_spawned - t_start))
print("msgs/sec:   ", times / (t_sent - t_spawned))

