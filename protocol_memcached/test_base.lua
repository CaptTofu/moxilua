socket = require('socket')
apo    = require('actor_post_office')
asock  = require('actor_socket')

require 'util'

p = print

function printa(a, prefix)
  prefix = prefix or ""
  if type(a) == 'table' then
    for i, v in pairs(a) do
      if i ~= 'n' then
        if type(v) == 'table' then
          if #v == 0 then
            p(prefix .. i .. ' {}')
          else
            p(prefix .. i .. ' {')
            printa(v, prefix .. '  ')
            p(prefix .. '}')
          end
        else
          p(prefix .. i .. ' ' .. v)
        end
      end
    end
  elseif a == nil then
    p(prefix .. "[nil]")
  else
    p(prefix .. a)
  end
end

pa = printa

------------------------------------------

got_list = {}
function fresh()
  p('-------------------------')
  got_list = {}
end

function got(...)
  got_list[#got_list + 1] = arg
  pa(arg)
end

------------------------------------------

function tree_match(expect, actual)
  assert(type(expect) == type(actual),
         "type mismatch, " .. type(expect) .. " " .. type(actual))

  if type(expect) == 'string' then
    if not string.find(actual, "^" .. expect) then
      p("expected", expect, "actual", actual)
      assert(false)
    end
    return
  end

  if type(expect) ~= 'table' then
    assert(expect == actual, "unequal " .. expect .. " " .. actual)
    return
  end

  assert(#expect == #actual,
         "table size mismatch, " .. #expect .. " " .. #actual)

  for i = 1, #expect do
    tree_match(expect[i], actual[i])
  end
end

function expected(...)
  local expect = arg
  if #expect == 1 and type(expect[1]) == 'string' then
    expect = {expect}
  end

  if false then
    p("--------------")
    p("expect")
    pa(expect)

    p("actual")
    pa(got_list)
  end

  tree_match(expect, got_list)
end

