parallel = require "mooncrafts.parallel"
util     = require "mooncrafts.util"
socket   = require "socket"
log      = require "mooncrafts.log"

describe "mooncrafts.parallel", ->
  it "complete all parallel functions", ->
    sleep = (sec) ->
        socket.sleep(sec)

    tasks = {}
    taskCount = 3
    expected  = taskCount * taskCount
    executed  = 0

    for i=1, taskCount
      tasks[i] = () ->
        --print "function " .. i
        for j=1, taskCount
          executed += 1
          time = math.random()
          --print i .. ' - sleep ' .. time
          sleep(time)
          coroutine.yield!
        i

    actual = parallel.list(tasks)
    -- print util.to_json(actual)
    assert.same expected, executed
    assert.same taskCount, #actual
