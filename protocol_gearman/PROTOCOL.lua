-- Generated from PROTOCOL_2lua.lua
--
gearman_protocol = {
  request = {},
  response = {}
}

local request  = gearman_protocol.request;
local response = gearman_protocol.response;

local x = {{
},
{
},
{
}}
request['Client/Worker'] = {{
},
{
},
{ 'ECHO_REQ',
  {'Opaque data that is echoed back in response.'},
}}
response['Client/Worker'] = {{
},
{
},
{ 'ECHO_RES',
  {'Opaque data that is echoed back in response.'},
},
{ 'ERROR',
  {'NULL byte terminated error code string.'},
  {'Error text.'},
}}
request['Client'] = {{
},
{
},
{ 'SUBMIT_JOB, SUBMIT_JOB_BG,',
},
{ 'SUBMIT_JOB_HIGH, SUBMIT_JOB_HIGH_BG,',
},
{ 'SUBMIT_JOB_LOW, SUBMIT_JOB_LOW_BG',
  {'NULL byte terminated function name.'},
  {'NULL byte terminated unique ID.'},
  {'Opaque data that is given to the function as an argument.'},
},
{ 'SUBMIT_JOB_SCHED',
  {'NULL byte terminated function name.'},
  {'NULL byte terminated unique ID.'},
  {'NULL byte terminated minute (0-59).'},
  {'NULL byte terminated hour (0-23).'},
  {'NULL byte terminated day of month (1-31).'},
  {'NULL byte terminated month (1-12).'},
  {'NULL byte terminated day of week (0-6, 0 = Monday).'},
  {'Opaque data that is given to the function as an argument.'},
},
{ 'SUBMIT_JOB_EPOCH',
  {'NULL byte terminated function name.'},
  {'NULL byte terminated unique ID.'},
  {'NULL byte terminated epoch time.'},
  {'Opaque data that is given to the function as an argument.'},
},
{ 'GET_STATUS',
  {'Job handle that was given in JOB_CREATED packet.'},
},
{ 'OPTION_REQ',
  {'Name of the option to set. Possibilities are:'},
}}
response['Client'] = {{
},
{
},
{ 'JOB_CREATED',
  {'Job handle assigned by server.'},
},
{ 'WORK_DATA, WORK_WARNING, WORK_STATUS, WORK_COMPLETE,',
},
{ 'WORK_FAIL, WORK_EXCEPTION',
},
{ 'STATUS_RES',
  {'NULL byte terminated job handle.'},
  {'NULL byte terminated known status, this is 0 (false) or 1 (true).'},
  {'NULL byte terminated running status, this is 0 (false) or 1'},
  {'NULL byte terminated percent complete numerator.'},
  {'Percent complete denominator.'},
},
{ 'OPTION_RES',
  {'Name of the option that was set, see OPTION_REQ for possibilities.'},
}}
request['Worker'] = {{
},
{
},
{ 'CAN_DO',
  {'Function name.'},
},
{ 'CAN_DO_TIMEOUT',
  {'NULL byte terminated Function name.'},
  {'Timeout value.'},
},
{ 'CANT_DO',
  {'Function name.'},
},
{ 'RESET_ABILITIES',

},
{ 'PRE_SLEEP',

},
{ 'GRAB_JOB',

},
{ 'GRAB_JOB_UNIQ',

},
{ 'WORK_DATA',
  {'NULL byte terminated job handle.'},
  {'Opaque data that is returned to the client.'},
},
{ 'WORK_WARNING',
  {'NULL byte terminated job handle.'},
  {'Opaque data that is returned to the client.'},
},
{ 'WORK_STATUS',
  {'NULL byte terminated job handle.'},
  {'NULL byte terminated percent complete numerator.'},
  {'Percent complete denominator.'},
},
{ 'WORK_COMPLETE',
  {'NULL byte terminated job handle.'},
  {'Opaque data that is returned to the client as a response.'},
},
{ 'WORK_FAIL',
  {'Job handle.'},
},
{ 'WORK_EXCEPTION',
  {'NULL byte terminated job handle.'},
  {'Opaque data that is returned to the client as an exception.'},
},
{ 'SET_CLIENT_ID',
  {'Unique string to identify the worker instance.'},
},
{ 'ALL_YOURS',

}}
response['Worker'] = {{
},
{
},
{ 'NOOP',

},
{ 'NO_JOB',

},
{ 'JOB_ASSIGN',
  {'NULL byte terminated job handle.'},
  {'NULL byte terminated function name.'},
  {'Opaque data that is given to the function as an argument.'},
},
{ 'JOB_ASSIGN_UNIQ',
  {'NULL byte terminated job handle.'},
  {'NULL byte terminated function name.'},
  {'NULL byte terminated unique ID.'},
  {'Opaque data that is given to the function as an argument.'},
},
{


  {'Function name.'},
  {'Optional maximum queue size.'},
  {'Optional "graceful" mode.'},

},
{
}}
