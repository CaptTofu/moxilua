apo = require('actor_post_office')

p = print

function a1(self_addr, a, b, c)
  print("a1", self_addr, a, b, c)

  while true do
    x, y, z = apo.recv()
    p("a1 recv'ed ", x, y, z)
  end
end

a1_addr = apo.spawn(a1, 111, 222, 333)

apo.send(a1_addr, 1, 2, 3)
apo.send(a1_addr, 2, 3, 4)

------------------------------------------

function a2(self_addr)
  print("a2", self_addr)

  while true do
    times = apo.recv()

    for i = 1, times do
      apo.send(self_addr, -1)
    end

    while times > 0 do
      delta = apo.recv()
      p("a2 countdown ", times)
      times = times + delta
    end

    p("a2 down to zero!")
  end
end

a2_addr = apo.spawn(a2)

apo.send(a2_addr, 5)

------------------------------------------

function a3(self_addr)
  print("a3", self_addr)

  times = apo.recv()
  p("a3 times", times)
  apo.send(a2_addr, times)

  a3(self_addr)
end

a3_addr = apo.spawn(a3)

apo.send(a3_addr, 5)
apo.send(a3_addr, 6)

------------------------------------------

function a4(self_addr, name)
  print("a4", self_addr)

  while true do
    times = apo.recv()
    a4_child = apo.spawn(a3)
    apo.send(a4_child, times)
  end
end

a4_addr = apo.spawn(a4, "mary")

apo.send(a4_addr, 3)
apo.send(a4_addr, 2)

------------------------------------------

apo.loop_until_empty()

p("DONE")
