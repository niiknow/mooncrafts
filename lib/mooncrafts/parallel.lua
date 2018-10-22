local coroutine = require("coroutine")
local co_create, co_yield, co_running, co_resume, co_status, unpack, list
co_create = coroutine.create
co_yield = coroutine.yield
co_running = coroutine.running
co_resume = coroutine.resume
co_status = coroutine.status
unpack = table.unpack
list = function(args, limit)
  local fn_list = args
  for i = 1, #fn_list do
    if type(fn_list[i]) ~= "function" then
      return 0, "arg must " .. tostring(i) .. " be function"
    end
  end
  local num = #fn_list
  if not (limit ~= nil and limit > num) then
    limit = num
  end
  local results = { }
  local tasks = { }
  local context = {
    remain_count = num,
    error_count = 0,
    results = { },
    caller_coroutine = co_running(),
    exec_count = 0
  }
  for i = 1, num do
    tasks[i] = co_create(function(index, fn)
      local ok, result = pcall(fn)
      context.results[index] = {
        ok = ok,
        result = result
      }
      context.remain_count = context.remain_count - 1
      if context.remain_count == 0 then
        if co_status(context.caller_coroutine) ~= 'dead' then
          return co_resume(context.caller_coroutine)
        end
      end
    end)
  end
  while true do
    for i = 1, num do
      local task = tasks[i]
      if co_status(task) == 'suspended' then
        co_resume(task, i, fn_list[i])
      end
    end
    context.exec_count = context.exec_count + 1
    if context.remain_count <= 0 or context.exec_count > limit then
      context.remain_count = 0
      break
    end
  end
  if context.remain_count > 0 then
    co_yield()
  end
  return context.results
end
return {
  list = list
}
