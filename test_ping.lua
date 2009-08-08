apo = require('actor_post_office')

function player(self_addr, name)
  while true do
    ball = apo.recv()
    print(name .. " got ball, hits " .. ball.hits)
    apo.send(ball.from, { from = self_addr, hits = ball.hits + 1 })
  end
end

mike_addr = apo.spawn(player, "Mike")
mary_addr = apo.spawn(player, "Mary")

apo.send(mike_addr, { from = mary_addr, hits = 1})

