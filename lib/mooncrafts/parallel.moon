-- for running stuff in parallel

coroutine = require("coroutine")

local *

co_create  = coroutine.create
co_yield   = coroutine.yield
co_running = coroutine.running
co_resume  = coroutine.resume
co_status  = coroutine.status
unpack     = table.unpack

list = (args, limit) ->
  -- check args
  fn_list = args
  for i=1, #fn_list
    if type(fn_list[i]) ~= "function" then
      return 0, "arg must #{i} be function"

  num     = #fn_list
  limit   = num unless limit ~= nil and limit > num
  results = {}
  tasks   = {}
  context = {
    remain_count: num
    error_count: 0
    results: {}
    caller_coroutine: co_running!
    exec_count: 0
  }

  -- create our threads
  for i=1, num
    -- create async handler
    tasks[i] = co_create( (index, fn) ->
      -- print 'starting ' .. index
      ok, result = pcall fn  -- use pcall to handle error
      -- print 'ending ' .. index

      -- pack result
      context.results[index] = {
        ok: ok
        result: result
      }

      -- decrement running threads count
      context.remain_count -= 1

      -- finally, exit if no remaining thread
      if context.remain_count == 0
        -- resume caller thread if it's not dead
        if co_status(context.caller_coroutine) ~= 'dead'
          co_resume(context.caller_coroutine)
    )

  -- loop while any task is suspended or limit has not reached
  while true
    -- now execute any suspended task
    for i=1, num
      task = tasks[i]
      if co_status(task) == 'suspended' then co_resume(task, i, fn_list[i])

    -- this prevent infinit loop based on limit
    context.exec_count += 1

    -- we've reached our limit, get out
    if context.remain_count <= 0 or context.exec_count > limit
      -- make sure we're not waiting for it externally
      context.remain_count = 0
      break

  -- externally, make sure to wait for all threads to finish
  -- if we somehow got here by excessive inner thread yields
  if context.remain_count > 0
    co_yield!

  context.results

{ :list }
