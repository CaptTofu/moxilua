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
  packet_types = [=[#   Name                Magic  Type
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
    RES = {}
  },
  Worker = {
    REQ = {},
    RES = {}
  }
}

for id, name, type, sides in
      string.gfind(protocol_gearman.packet_types,
                  "%s*(%d+)%s+([%u_]+)%s+([%u]+)%s+([%a%/]+)") do
  for side in string.gfind(sides,
                           "(%a+)") do
    protocol_gearman[side][type][id] = {
      id = id, name = name, type = type, side = side
    }
  end
end

for id, name, type, sides, type2, sides2 in
      string.gfind(protocol_gearman.packet_types,
                  "%s*(%d+)%s+([%u_]+)%s+([%u]+)%s+([%a%/]+)" ..
                                     "%s+([%u]+)%s+([%a%/]+)") do
  for side in string.gfind(sides2,
                           "(%a+)") do
    protocol_gearman[side][type2][id] = {
      id = id, name = name, type = type2, side = side
    }
  end
end

if false then
  print('--------------')
  for k, v in pairs(protocol_gearman.Client.REQ) do
    print(k, v)
  end
  print('---------')
  for k, v in pairs(protocol_gearman.Client.RES) do
    print(k, v)
  end
  print('--------------')
  for k, v in pairs(protocol_gearman.Worker.REQ) do
    print(k, v)
  end
  print('---------')
  for k, v in pairs(protocol_gearman.Worker.RES) do
    print(k, v)
  end
end

