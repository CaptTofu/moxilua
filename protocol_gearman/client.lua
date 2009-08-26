-- gearman client...
--
require('protocol_util')

require('protocol_gearman/protocol_gearman')

local pru = protocol_util
local pgm = protocol_gearman

local network_bytes                  = pru.network_bytes
local network_bytes_string_to_number = pru.network_bytes_string_to_number

------------------------------------------------

local function create_request_handler(name)
  local spec        = assert(pgm.client.request_by_name[name])
  local spec_params = spec.params or {}

  local function h(conn, recv_callback, args)
    local size = 0
    for i = 1, #spec_params do
      local spec_param = spec_params[i]
      local data_param = assert(args[spec_param.name], spec_param.name)

      size = size + string.len(data_param)
      if param.null_terminated then
        size = size + 1
      end
    end

    local buf_magic = pgm.magic_req
    local buf_type  = string.char(network_bytes(spec.id, 4))
    local buf_size  = string.char(network_bytes(size, 4))
  end

  return h
end

------------------------------------------------

gearman_client = {
  ECHO_REQ =
    create_request_handler("ECHO_REQ"),
  SUBMIT_JOB =
    create_request_handler("SUBMIT_JOB"),
  SUBMIT_JOB_BG =
    create_request_handler("SUBMIT_JOB_BG"),
  SUBMIT_JOB_LOW =
    create_request_handler("SUBMIT_JOB_LOW"),
  SUBMIT_JOB_LOW_BG =
    create_request_handler("SUBMIT_JOB_LOW_BG"),
  SUBMIT_JOB_HIGH =
    create_request_handler("SUBMIT_JOB_HIGH"),
  SUBMIT_JOB_HIGH_BG =
    create_request_handler("SUBMIT_JOB_HIGH_BG"),
  SUBMIT_JOB_EPOCH =
    create_request_handler("SUBMIT_JOB_EPOCH"),
  SUBMIT_JOB_SCHED =
    create_request_handler("SUBMIT_JOB_SCHED"),
  OPTION_REQ =
    create_request_handler("OPTION_REQ"),
  GET_STATUS =
    create_request_handler("GET_STATUS")
}
