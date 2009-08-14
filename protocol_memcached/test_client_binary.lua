require('protocol_memcached/test_base')
require('protocol_memcached/client')

client = memcached_client_binary

------------------------------------------

location = arg[1] or '127.0.0.1:11211'

host, port, c = connect(location)
c:settimeout(nil)

------------------------------------------

p("connected", host, port, c)

fresh()
assert(client.flush_all(c, got) == "OK")
expected(".+")

fresh()
assert(client.get(c, got, {"a", "b", "c"}) == "END")
expected()

fresh()
assert(client.set(c, got, {"a", 0, 0}, "hello") == "STORED")
expected(".+")

fresh()
assert(client.get(c, got, {"a"}) == "END")
expected({".+", nil, "a", ".+", "hello"})

fresh()
assert(client.get(c, got, {"a", "b", "c"}) == "END")
expected({".+", nil, "a", ".+", "hello"})

fresh()
assert(client.set(c, got, {"b", 0, 0}, "world"))
expected(".+")

fresh()
assert(client.get(c, got, {"a", "b", "c"}) == "END")
expected({".+", nil, "a", ".+", "hello"},
         {".+", nil, "b", ".+", "world"})

fresh()
assert(client.get(c, got, {"a", "b", "c", "a", "b", "c"}) == "END")
expected({".+", nil, "a", ".+", "hello"},
         {".+", nil, "b", ".+", "world"},
         {".+", nil, "a", ".+", "hello"},
         {".+", nil, "b", ".+", "world"})

print("-----------")

fresh()
assert(client.delete(c, got, {"b"}) == "DELETED")
expected("DELETED")

fresh()
assert(client.get(c, got, {"a", "b", "c"}) == "END")
expected({"VALUE a",
          "hello"})

fresh()
assert(client.flush_all(c, got) == "OK")
expected("OK")

fresh()
assert(client.get(c, got, {"a", "b", "c"}))
expected()

p("done!")

