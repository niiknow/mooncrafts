-- allow for month calculation

seconds_in_a_day   = 86400
seconds_in_a_month = 31 * seconds_in_a_day
math_abs           = math.abs

-- easiest thing is to add year
add_year: (ts=os.time(), years=1) ->
  old_dt = os.date("*t", ts)
  os.time { year: old_dt.year + years, month: old_dt.month, day: old_dt.day, hour: old_dt.hour, min: old_dt.min, sec: old_dt.sec }

-- add days is to add seconds
add_day: (ts=os.time(), days=1) ->
  ts + days * seconds_in_a_day

-- add month is the hardest
-- to guarantee processing of exact month
-- this function will result in first day of next/previous month
add_one_month: (ts=os.time(), add=false) ->
  multiple = add and 1 or -1
  old_dt = os.date("*t", ts)
  new_ts = os.time { year: old_dt.year, month: old_dt.month, day: 1 }
  new_ts = new_ts + multiple * seconds_in_a_month

-- loop and add one month at a time
add_month: (ts=os.time(), months=1) ->
  add      = (months > 0)
  new_ts   = ts
  monthval = math_abs(months)
  for i = 1, monthval do new_ts = add_one_month(new_ts, (months > 0))
  new_ts

{ :add_day, :add_month, :add_year }
