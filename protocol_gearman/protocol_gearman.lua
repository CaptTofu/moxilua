require 'test_base'

local function field(size, name)
  return { name = name, size = size }
end

protocol_gearman = {
  magic_req = "\0REQ",
  magic_res = "\0RES",
  packet_layout = {
    field(4, "magic"),
    field(4, "type"),
    field(4, "size")
  },
  packet_kinds = [=[#   Name                Magic  Type
                    1   CAN_DO              REQ    Worker
                    2   CANT_DO             REQ    Worker
                    3   RESET_ABILITIES     REQ    Worker
                    4   PRE_SLEEP           REQ    Worker
                    5   (unused)            -      -
                    6   NOOP                RES    Worker
                    7   SUBMIT_JOB          REQ    Client
                    8   JOB_CREATED         RES    Client
                    9   GRAB_JOB            REQ    Worker
                    10  NO_JOB              RES    Worker
                    11  JOB_ASSIGN          RES    Worker
                    12  WORK_STATUS         REQ    Worker
                                            RES    Client
                    13  WORK_COMPLETE       REQ    Worker
                                            RES    Client
                    14  WORK_FAIL           REQ    Worker
                                            RES    Client
                    15  GET_STATUS          REQ    Client
                    16  ECHO_REQ            REQ    Client/Worker
                    17  ECHO_RES            RES    Client/Worker
                    18  SUBMIT_JOB_BG       REQ    Client
                    19  ERROR               RES    Client/Worker
                    20  STATUS_RES          RES    Client
                    21  SUBMIT_JOB_HIGH     REQ    Client
                    22  SET_CLIENT_ID       REQ    Worker
                    23  CAN_DO_TIMEOUT      REQ    Worker
                    24  ALL_YOURS           REQ    Worker
                    25  WORK_EXCEPTION      REQ    Worker
                                            RES    Client
                    26  OPTION_REQ          REQ    Client/Worker
                    27  OPTION_RES          RES    Client/Worker
                    28  WORK_DATA           REQ    Worker
                                            RES    Client
                    29  WORK_WARNING        REQ    Worker
                                            RES    Client
                    30  GRAB_JOB_UNIQ       REQ    Worker
                    31  JOB_ASSIGN_UNIQ     RES    Worker
                    32  SUBMIT_JOB_HIGH_BG  REQ    Client
                    33  SUBMIT_JOB_LOW      REQ    Client
                    34  SUBMIT_JOB_LOW_BG   REQ    Client
                    35  SUBMIT_JOB_SCHED    REQ    Client
                    36  SUBMIT_JOB_EPOCH    REQ    Client]=],
  Client = {
    REQ = {},
    RES = {},
    REQ_by_name = {},
    RES_by_name = {}
  },
  Worker = {
    REQ = {},
    RES = {},
    REQ_by_name = {},
    RES_by_name = {}
  }
}

--------------------------------------------

local sides = {
  client = 'Client',
  worker = 'Worker'
}

local kinds = {
  request = "REQ",
  response = "RES"
}

for side, Side in pairs(sides) do
  protocol_gearman[side] = protocol_gearman[Side]

  for kind, kind_abbrev in pairs(kinds) do
    protocol_gearman[side][kind] =
      protocol_gearman[side][kind_abbrev]

    protocol_gearman[side][kind .. '_by_name'] =
      protocol_gearman[side][kind_abbrev .. '_by_name']
  end
end

--------------------------------------------

for id, name, kind, sides in
      string.gfind(protocol_gearman.packet_kinds,
                  "%s*(%d+)%s+([%u_]+)%s+([%u]+)%s+([%a%/]+)") do
  for side in string.gfind(sides,
                           "(%a+)") do
    protocol_gearman[side][kind][id] = {
      id = id, name = name, kind = kind, side = side
    }
    protocol_gearman[side][kind .. '_by_name'][name] =
      protocol_gearman[side][kind][id]
  end
end

for id, name, kind, sides, kind2, sides2 in
      string.gfind(protocol_gearman.packet_kinds,
                  "%s*(%d+)%s+([%u_]+)%s+([%u]+)%s+([%a%/]+)" ..
                                     "%s+([%u]+)%s+([%a%/]+)") do
  for side in string.gfind(sides2,
                           "(%a+)") do
    protocol_gearman[side][kind2][id] = {
      id = id, name = name, kind = kind2, side = side
    }
    protocol_gearman[side][kind2 .. '_by_name'][name] =
      protocol_gearman[side][kind2][id]
  end
end

--------------------------------------------

-- Post-processing on the protocol_gearman/PROTOCOL.lua tables
--
require 'protocol_gearman/PROTOCOL'

for kind, kind_abbrev in pairs(kinds) do
  for sides, v in pairs(PROTOCOL_gearman[kind]) do
    for side in string.gfind(sides, "(%a+)") do
      for x, y in pairs(v) do
        local cmds   = nil
        local params = {}

        local function cmds_emit()
          if cmds and #params > 0 then
            for cmd in string.gfind(cmds, "([%a_]+)") do
              local m = protocol_gearman[side][kind_abbrev .. '_by_name'][cmd]
              assert(m)
              assert(not m.params)
              m.params = params
            end
          end
        end

        for z, w in pairs(y) do
          if type(w) == 'table' then
            for j, param in pairs(w) do
              local param_desc = string.gsub(string.lower(param),
                                             "^(null byte terminated) (.*)",
                                             "%2 %1")

              local _, _, param_name = string.find(param_desc, "(%a+)")

              param_name = string.lower(param_name)

              if param_name == 'function' then
                param_name = 'name'
              end

              param_null = string.find(param_desc,
                                       "null byte terminated") ~= nil

              params[#params + 1 ] = {
                name = param_name,
                desc = param_desc,
                null_terminated = param_null
              }
            end
          else
            cmds_emit()
            cmds = w
          end
        end

        cmds_emit()
      end
    end
  end
end

--------------------------------------------

if false then
  require('test_base')

  print('------------------------------')
  printa(protocol_gearman.client)
  print('------------------------------')
  printa(protocol_gearman.worker)
end

