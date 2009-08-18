-- Protocol util functions...
--
------------------------------------------------------

-- Creates array of bytes from an input integer x.
-- Highest order bytes comes first (network byte ordering).
--
local function network_bytes_array(x, num_bytes)
  local a = {}
  for i = num_bytes, 1, -1 do
    a[i] = math.mod(x, 0x0100) -- lua has no bitmask/shift operators.
    x = math.floor(x / 0x0100)
  end
  return a -- returns array of bytes numbers, highest order first.
end

-- Multiple return values of network ordered bytes from an input integer x.
-- Highest order bytes comes first (network byte ordering).
--
-- For example, you can: string.char(network_bytes(0x123, 4))
--
local function network_bytes(x, num_bytes)
  return unpack(network_bytes_array(x, num_bytes))
end

-- Converts array of network ordered bytes to a number.
--
local function network_bytes_array_to_number(arr, from, num_bytes)
  assert(num_bytes >= 1 and num_bytes <= 4)

  local x = 0

  for i = 1, num_bytes do
    x = x * 0x0100
    x = x + math.mod(arr[i + from - 1] or 0, 0x0100)
  end

  return x
end

-- Converts string of network ordered bytes to a number.
--
local function network_bytes_string_to_number(str, from, num_bytes)
  assert(num_bytes >= 1 and num_bytes <= 4)

  local x = 0

  for i = 1, num_bytes do
    x = x * 0x0100
    x = x + math.mod(string.byte(str, i + from - 1) or 0, 0x0100)
  end

  return x
end

------------------------------------------------------

local function print_bytes(s)
  local n = string.len(s)
  local i = 1
  while i < n do
    print("  " ..
          string.format('x%2x ', string.byte(s, i + 0) or 0) ..
          string.format('x%2x ', string.byte(s, i + 1) or 0) ..
          string.format('x%2x ', string.byte(s, i + 2) or 0) ..
          string.format('x%2x ', string.byte(s, i + 3) or 0))
    i = i + 4
  end
end

------------------------------------------------------

protocol_util = {
  network_bytes                  = network_bytes,
  network_bytes_array            = network_bytes_array,
  network_bytes_array_to_number  = network_bytes_array_to_number,
  network_bytes_string_to_number = network_bytes_string_to_number,

  print_bytes = print_bytes
}

------------------------------------------------------

function TEST_network_bytes()
  a, b, c, d = network_bytes(0x0faabbcc, 4)
  assert(a == 0x0f)
  assert(b == 0xaa)
  assert(c == 0xbb)
  assert(d == 0xcc)

  a, b, c, d = network_bytes(0x8faabbcc, 4) -- Test high bit.
  assert(a == 0x8f)
  assert(b == 0xaa)
  assert(c == 0xbb)
  assert(d == 0xcc)

  a = network_bytes_array(0, 4)
  assert(#a == 4)
  s = string.char(unpack(a))
  assert(string.len(s) == 4)

  x = 0
  assert(network_bytes_array_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x01
  assert(network_bytes_array_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x111
  assert(network_bytes_array_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x0faabbcc
  assert(network_bytes_array_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x8faabbcc
  assert(network_bytes_array_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x8faabbcc
  assert(network_bytes_array_to_number(network_bytes_array(x, 2), 1, 2) == 0xbbcc)
end

