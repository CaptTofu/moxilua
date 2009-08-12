-- generated from 'lua protocol_binary_h2lua.lua'
--
local function uint_t(size, name)
  return { name = name, size = n }
end

protocol_binary = {
  magic = {
    REQ = 0x80,
    RES = 0x81
  },
  response_status = {
    SUCCESS = 0x00,
    KEY_ENOENT = 0x01,
    KEY_EEXISTS = 0x02,
    E2BIG = 0x03,
    EINVAL = 0x04,
    NOT_STORED = 0x05,
    DELTA_BADVAL = 0x06,
    AUTH_ERROR = 0x20,
    UNKNOWN_COMMAND = 0x81,
    ENOMEM = 0x82
  },
  command = {
    GET = 0x00,
    SET = 0x01,
    ADD = 0x02,
    REPLACE = 0x03,
    DELETE = 0x04,
    INCREMENT = 0x05,
    DECREMENT = 0x06,
    QUIT = 0x07,
    FLUSH = 0x08,
    GETQ = 0x09,
    NOOP = 0x0a,
    VERSION = 0x0b,
    GETK = 0x0c,
    GETKQ = 0x0d,
    APPEND = 0x0e,
    PREPEND = 0x0f,
    STAT = 0x10,
    SETQ = 0x11,
    ADDQ = 0x12,
    REPLACEQ = 0x13,
    DELETEQ = 0x14,
    INCREMENTQ = 0x15,
    DECREMENTQ = 0x16,
    QUITQ = 0x17,
    FLUSHQ = 0x18,
    APPENDQ = 0x19,
    PREPENDQ = 0x1a,
    SASL_LIST_MECHS = 0x20,
    SASL_AUTH = 0x21,
    SASL_STEP = 0x22,
    BUCKET = 0x2a
  },
  datatypes = {
    RAW_BYTES = 0x00
  },
  request_header = {
    request = {
      uint_t(8, 'magic'),
      uint_t(8, 'opcode'),
      uint_t(16, 'keylen'),
      uint_t(8, 'extlen'),
      uint_t(8, 'datatype'),
      uint_t(16, 'reserved'),
      uint_t(32, 'bodylen'),
      uint_t(32, 'opaque'),
      uint_t(64, 'cas'),
    },
    uint_t(8, 'bytes[24]'),
  },
  response_header = {
    response = {
      uint_t(8, 'magic'),
      uint_t(8, 'opcode'),
      uint_t(16, 'keylen'),
      uint_t(8, 'extlen'),
      uint_t(8, 'datatype'),
      uint_t(16, 'status'),
      uint_t(32, 'bodylen'),
      uint_t(32, 'opaque'),
      uint_t(64, 'cas'),
    },
    uint_t(8, 'bytes[24]'),
  },
  request_no_extras = {
    message = {
      header = 'request_header',
    },
    uint_t(8, 'bytes[sizeof(request_header)]'),
  },
  response_no_extras = {
    message = {
      header = 'response_header',
    },
    uint_t(8, 'bytes[sizeof(response_header)]'),
  },
  request_get = 'request_no_extras',
  request_getq = 'request_no_extras',
  request_getk = 'request_no_extras',
  request_getkq = 'request_no_extras',
  response_get = {
    message = {
      header = 'response_header',
      body = {
        uint_t(32, 'flags'),
      },
    },
    uint_t(8, 'bytes[sizeof(response_header) + 4]'),
  },
  response_getq = 'response_get',
  response_getk = 'response_get',
  response_getkq = 'response_get',
  request_delete = 'request_no_extras',
  response_delete = 'response_no_extras',
  request_flush = {
    message = {
      header = 'request_header',
      body = {
        uint_t(32, 'expiration'),
      },
    },
    uint_t(8, 'bytes[sizeof(request_header) + 4]'),
  },
  response_flush = 'response_no_extras',
  request_set = {
    message = {
      header = 'request_header',
      body = {
        uint_t(32, 'flags'),
        uint_t(32, 'expiration'),
      },
    },
    uint_t(8, 'bytes[sizeof(request_header) + 8]'),
  },
  request_add = 'request_set',
  request_replace = 'request_set',
  response_set = 'response_no_extras',
  response_add = 'response_no_extras',
  response_replace = 'response_no_extras',
  request_noop = 'request_no_extras',
  response_noop = 'response_no_extras',
  request_incr = {
    message = {
      header = 'request_header',
      body = {
        uint_t(64, 'delta'),
        uint_t(64, 'initial'),
        uint_t(32, 'expiration'),
      },
    },
    uint_t(8, 'bytes[sizeof(request_header) + 20]'),
  },
  request_decr = 'request_incr',
  response_incr = {
    message = {
      header = 'response_header',
      body = {
        uint_t(64, 'value'),
      },
    },
    uint_t(8, 'bytes[sizeof(response_header) + 8]'),
  },
  response_decr = 'response_incr',
  request_quit = 'request_no_extras',
  response_quit = 'response_no_extras',
  request_append = 'request_no_extras',
  request_prepend = 'request_no_extras',
  response_append = 'response_no_extras',
  response_prepend = 'response_no_extras',
  request_version = 'request_no_extras',
  response_version = 'response_no_extras',
  request_stats = 'request_no_extras',
  response_stats = 'response_no_extras',
}
