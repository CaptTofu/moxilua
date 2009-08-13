require('protocol_memcached/test_base')
require('protocol_memcached/client')

------------------------------------------

location = arg[1] or '127.0.0.1:11211'

host, port, c = connect(location)
c:settimeout(nil)

------------------------------------------

p("connected", host, port, c)

fresh()
assert(memcached_client_ascii.flush_all(c, got))
expected("OK")

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c"}))
expected()

fresh()
assert(memcached_client_ascii.set(c, got, {"a", "0", "0", "5"}, "hello"))
expected("STORED")

fresh()
assert(memcached_client_ascii.get(c, got, {"a"}))
expected({"VALUE a",
          "hello"})

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c"}))
expected({"VALUE a",
          "hello"})

fresh()
assert(memcached_client_ascii.set(c, got, {"b", "0", "0", "5"}, "world"))
expected("STORED")

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c"}))
expected({"VALUE a",
          "hello"},
         {"VALUE b",
          "world"})

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c", "a", "b", "c"}))
expected({"VALUE a",
          "hello"},
         {"VALUE b",
          "world"},
         {"VALUE a",
          "hello"},
         {"VALUE b",
          "world"})

fresh()
assert(memcached_client_ascii.delete(c, got, {"b"}))
expected("DELETED")

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c"}))
expected({"VALUE a",
          "hello"})

fresh()
assert(memcached_client_ascii.flush_all(c, got))
expected("OK")

fresh()
assert(memcached_client_ascii.get(c, got, {"a", "b", "c"}))
expected()

p("done!")
