local seconds_in_a_day = 86400
local seconds_in_a_month = 31 * seconds_in_a_day
local _ = {
  add_year = function(ts, years)
    if ts == nil then
      ts = os.time()
    end
    if years == nil then
      years = 1
    end
    local old_dt = os.date("*t", ts)
    return os.time({
      year = old_dt.year + years,
      month = old_dt.month,
      day = old_dt.day,
      hour = old_dt.hour,
      min = old_dt.min,
      sec = old_dt.sec
    })
  end
}
_ = {
  add_day = function(ts, days)
    if ts == nil then
      ts = os.time()
    end
    if days == nil then
      days = 1
    end
    return ts + days * seconds_in_a_day
  end
}
_ = {
  add_one_month = function(ts, add)
    if ts == nil then
      ts = os.time()
    end
    if add == nil then
      add = false
    end
    local multiple = add and 1 or -1
    local old_dt = os.date("*t", ts)
    local new_ts = os.time({
      year = old_dt.year,
      month = old_dt.month,
      day = 1
    })
    new_ts = new_ts + multiple * seconds_in_a_month
  end
}
_ = {
  add_month = function(ts, months)
    if ts == nil then
      ts = os.time()
    end
    if months == nil then
      months = 1
    end
    local add = (months > 0)
    local new_ts = ts
    for i = 1, math.abs(months) do
      new_ts = add_one_month(new_ts, (months > 0))
    end
    return new_ts
  end
}
return {
  add_day = add_day,
  add_month = add_month,
  add_year = add_year
}
