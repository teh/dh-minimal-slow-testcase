# minimal testcase to illustrate slowness of RPC calls

How to run:

1. Open two shells, in the first

```
stack build
export DISTRIBUTED_PROCESS_TRACE_CONSOLE=y
export DISTRIBUTED_PROCESS_TRACE_FLAGS=pdnusrl
stack exec server
```

In 2nd:

```
export DISTRIBUTED_PROCESS_TRACE_CONSOLE=y
export DISTRIBUTED_PROCESS_TRACE_FLAGS=pdnusrl
stack exec client
```

Some example output running against `ts` (from moreutils) shows that we're losing ~300ms for a few simple RPC calls that I expect to take <1ms. I reproduced this on my laptop and a clean digital ocean machine.

```
[28.920343] Sun Feb  5 23:24:28 UTC 2017 [trace] MxSpawned pid://127.0.0.1:8002:0:8
[28.920459] Sun Feb  5 23:24:28 UTC 2017 [trace] MxSpawned pid://127.0.0.1:8002:0:9
[28.920526] Sun Feb  5 23:24:28 UTC 2017 [trace] MxProcessDied pid://127.0.0.1:8002:0:7 DiedNormal
[28.921277] Sun Feb  5 23:24:28 UTC 2017 [trace] MxRegistered pid://127.0.0.1:8002:0:8 "logger"
[28.921980] Sun Feb  5 23:24:28 UTC 2017 [trace] MxReceived pid://127.0.0.1:8002:0:9 [unencoded message] :: RegisterReply
[28.922134] Sun Feb  5 23:24:28 UTC 2017 [trace] MxRegistered pid://127.0.0.1:8002:0:8 "trace.logger"
[28.922318] Sun Feb  5 23:24:28 UTC 2017 [trace] MxReceived pid://127.0.0.1:8002:0:9 [unencoded message] :: RegisterReply
[28.922532] Sun Feb  5 23:24:28 UTC 2017 [trace] MxSpawned pid://127.0.0.1:8002:0:10
[28.922684] Sun Feb  5 23:24:28 UTC 2017 [trace] MxProcessDied pid://127.0.0.1:8002:0:9 DiedNormal
[29.014041] Sun Feb  5 23:24:29 UTC 2017 [trace] MxReceived pid://127.0.0.1:8002:0:10 "\NUL\NUL\NUL\NUL\NUL\NUL\NUL\NUL\NUL\NUL\NUL\DLE127.0.0.1:8001:0\212L\237u\NUL\NUL\NUL\v" :: (b2a4008dff1f644e,1943c171e552f5cf)
[29.102408] Sun Feb  5 23:24:29 UTC 2017 [trace] MxReceived pid://127.0.0.1:8002:0:10 "\SOH\NUL\NUL\NUL\NUL\NUL\NUL\NUL\DLE127.0.0.1:8001:0\212L\237u\NUL\NUL\NUL\n" :: (d2250ff2ed2ae03d,40a77540bd1bb7fb)
[29.145615] Sun Feb  5 23:24:29 UTC 2017 [trace] MxProcessDied pid://127.0.0.1:8001:0:11 DiedNormal
[29.146184] Sun Feb  5 23:24:29 UTC 2017 [trace] MxSent pid://127.0.0.1:8001:0:10 pid://127.0.0.1:8002:0:10 [unencoded message] :: Message Int Int
[29.233373] nid://127.0.0.1:8002:0
```
