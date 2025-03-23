-- GrisuDebug
--
-- @author  Grisu118 - VertexDezign.net
-- @history	    v1.0    - 2016-10-26 - Initial implementation
-- @history     v1.1    - 2017-09-15 - Add Off Level, add shorthand methods for logging, add support for closures
-- @history     v1.2    - 2024-11-19 - Add function to print table
-- @history     v1.3    - 2024-11-24 - Add support for string.format
-- @Descripion: Providing debug utils
-- @web: http://grisu118.ch or http://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

---@class GrisuDebug
GrisuDebug = {}
GrisuDebug.__index = GrisuDebug

GrisuDebug.TRACE = 1
GrisuDebug.DEBUG = 2
GrisuDebug.INFO = 3
GrisuDebug.WARNING = 4
GrisuDebug.ERROR = 5
GrisuDebug.OFF = 6

function GrisuDebug.parseLogLevel(txt)
  local lvl = GrisuDebug[txt]
  if lvl ~= nil and type(lvl) == "number" then
    return lvl
  else
    return GrisuDebug.INFO
  end
end

function GrisuDebug:create(name, id)
  local d = {} -- our new object
  setmetatable(d, GrisuDebug) -- make Account handle lookup
  d.name = name -- initialize our object
  d.id = id
  d.lvl = GrisuDebug.DEBUG
  return d
end

function GrisuDebug:setLogLvl(lvl)
  self.lvl = lvl
end

function GrisuDebug:trace(txt, ...)
  self:print(GrisuDebug.TRACE, txt, ...)
end

function GrisuDebug:debug(txt, ...)
  self:print(GrisuDebug.DEBUG, txt, ...)
end

function GrisuDebug:info(txt, ...)
  self:print(GrisuDebug.INFO, txt, ...)
end

function GrisuDebug:warn(txt, ...)
  self:print(GrisuDebug.WARNING, txt, ...)
end

function GrisuDebug:error(txt, ...)
  self:print(GrisuDebug.ERROR, txt, ...)
end

---@param name string The name of the table
---@param tbl table The table to print all members of
---@param recursive boolean
---@return void
function GrisuDebug:tPrint(name, tbl, recursive)
  self:info("Debug Table: '" .. name .. "'")
  print(self:_tprint(tbl, 0, recursive))
end

function GrisuDebug:print(lvl, txt, ...)
  if lvl < self.lvl then
    return
  end
  local level = "TRACE"
  if lvl == GrisuDebug.ERROR then
    level = "ERROR"
  elseif lvl == GrisuDebug.WARNING then
    level = "WARN"
  elseif lvl == GrisuDebug.INFO then
    level = "INFO"
  elseif lvl == GrisuDebug.DEBUG then
    level = "DEBUG"
  end

  local text
  if type(txt) == "function" then
    text = txt()
  else
    text = string.format(tostring(txt), ...)
  end

  if (self.id == nil) then
    print(self.name .. " - " .. level .. ": " .. text)
  else
    print(self.name .. " - " .. level .. ": (" .. id .. " - " .. getName(id) .. ") " .. text)
  end
end

---@param tbl table
---@param indent number
---@param recursive boolean
function GrisuDebug:_tprint (tbl, indent, recursive)
  if not indent then
    indent = 0
  end
  if tbl == nil then
    return string.rep(" ", indent) .. "nil"
  end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint .. k .. "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      if recursive and indent < 10 then
        toprint = toprint .. self:_tprint(v, indent + 2, recursive) .. ",\r\n"
      else
        toprint = toprint .. "table, \r\n"
      end
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent - 2) .. "}"
  return toprint
end