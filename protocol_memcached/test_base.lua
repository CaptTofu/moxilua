socket = require('socket')
apo    = require('actor_post_office')
asock  = require('actor_socket')

require 'util'

p = print

function printa(a)
  for i, v in ipairs(a) do
    p(i, v)
  end
end

pa = printa

------------------------------------------

got_list = {}
function fresh()
  got_list = {}
end

function got(...)
  got_list[#got_list + 1] = arg
  pa(arg)
end

function expected(...)
  assert(#got_list == #arg, "#got_list != #arg, " .. #got_list .. " " .. #arg)
  for i = 1, #arg do
    local expect = arg[i]
    if type(expect) == "string" then
      expect = {expect}
    end
    assert(#(got_list[i]) == #expect)
    for j = 1, #expect do
      if expect[j] == nil then
        assert(got_list[i][j] == nil)
      else
        if not string.find(got_list[i][j], "^" .. expect[j]) then
          p("expected", expect[j], "got", got_list[i][j])
          assert(false)
        end
      end
    end
  end
end

