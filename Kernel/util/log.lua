
log = require 'jass.log'
local log = log

local function split(str, p)
	local rt = {}
	string.gsub(str, '[^]' .. p .. ']+', function (w) table.insert(rt, w) end)
	return rt
end

local map_name = MAP_NAME or '未知的地图'

log.path = map_name .. '\\日志\\' .. split(log.path, '\\')[2]

local std_print = print
function print(...)
	log.info(...)
	return std_print(...)
end

local log_error = log.error
function log.error(...)
	local trc = debug.traceback()
	log_error(...)
	log_error(trc)
	std_print(...)
	std_print(trc)
end
