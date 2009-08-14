memcached_server_binary_dict = {}

local msbd = memcached_server_binary_dict
local mpb  = memcached_protocol_binary
local pack = mpb.pack

msbd[mpb.command.GET] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.SET] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.ADD] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.REPLACE] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.DELETE] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.INCREMENT] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.DECREMENT] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.QUIT] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.FLUSH] =
  function(dict, skt, req, key, ext, data)
    dict.tbl = {}
    local res = pack.create_response_simple(mpb.command.FLUSH,
                                            mpb.response_status.SUCCESS,
                                            pack.opaque(req, 'request'))
    sock_send(skt, res)
  end

msbd[mpb.command.GETQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.NOOP] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.VERSION] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.GETK] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.GETKQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.APPEND] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.PREPEND] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.STAT] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.SETQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.ADDQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.REPLACEQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.DELETEQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.INCREMENTQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.DECREMENTQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.QUITQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.FLUSHQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.APPENDQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.PREPENDQ] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.SASL_LIST_MECHS] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.SASL_AUTH] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.SASL_STEP] =
  function(dict, skt, req, key, ext, data)
  end

msbd[mpb.command.BUCKET] =
  function(dict, skt, req, key, ext, data)
  end

