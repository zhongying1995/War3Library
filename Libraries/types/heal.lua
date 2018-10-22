
local Unit = require 'war3library.libraries.types.unit'
local Texttag = require 'war3library.libraries.types.texttag.texttag'

local Heal = {}
setmetatable(Heal, Heal)

--伤害结构
local mt = {}
Heal.__index = mt

--类型
mt.type = 'heal'

--来源
mt.source = nil

--目标
mt.target = nil

--原因
mt.reason = '未知'

--治疗
mt.heal = 0

--关联技能
mt.skill = nil

--创建漂浮文字
local function text(heal)
	
	local x, y = heal.target:get_point():get()
	local z = heal.target:get_point():getZ()
	local size = math.min( 16, 10 + (heal.heal ^ 0.5) / 5)
	local tag = Texttag:new{
		text = ('+ %.f'):format(heal.heal),
		size = size,
		point = ac.point(x - 60, y, z - 30),
		show = Texttag.SHOW_ALL,
		speed = 86,
		angle = math.random(360),
		red = 0,
		green = 255,
		blue = 0,
	}
	
end

--创建治疗
function Heal:__call(heal)
	if not heal.target or heal.heal == 0 then
		return
	end

	if heal.skill == nil then
		Log.warnning('治疗没有关联技能')
		Log.warnning(debug.traceback())
	end
	
	setmetatable(heal, self)

	heal.source:event_notify('单位-给予治疗开始', heal)
	if heal.target:event_dispatch('单位-受到治疗开始', heal) then
		return heal
	end

	if heal.heal < 0 then
		heal.heal = 0
	end
	
	--进行治疗
	heal.target:add_life(heal.heal)

	--创建漂浮文字
	text(heal)

	heal.source:event_notify('单位-给予治疗效果', heal)
	heal.target:event_notify('单位-受到治疗效果', heal)

	return heal
end

--进行治疗
function Unit.__index:heal(data)
	data.source = self
	if not data.target then
		data.target = self
	end
	return Heal(data)
end

return Heal