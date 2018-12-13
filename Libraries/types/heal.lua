
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

--治疗的频率
mt.pulse = 0.1

--治疗持续时间
mt.duration = nil

--特效,默认显示
mt.effect = [[Abilities\Spells\Items\HealingSalve\HealingSalveTarget.mdl]]

--单位位置
mt.ref = 'origin'

--默认显示文字
mt.is_show = true

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

function Heal:remove(  )
	if self._removed then
		return
	end
	if self.on_remove then
		self:on_remove()
	end
	if self.duration_timer then
		self.duration_timer:remove()
	end
end

--立刻治疗一次
function mt:heal_start()
	self.source:event_notify('单位-给予治疗开始', self)
	if self.target:event_dispatch('单位-受到治疗开始', self) then
		return self
	end
	
	if self.heal < 0 then
		self.heal = 0
	end
	--进行治疗
	self.target:add_life(self.heal)
	
	if self.effect then
		self.target:add_effect(self.effect, self.ref):remove()
	end
	
	--创建漂浮文字
	if self.is_show then
		text(self)
	end
	
	self.source:event_notify('单位-给予治疗效果', self)
	self.target:event_notify('单位-受到治疗效果', self)
end

--创建治疗
function Heal:new(heal)
	if not heal.target or heal.heal == 0 then
		return
	end

	if heal.skill == nil then
		Log.warnning('治疗没有关联技能')
		Log.warnning(debug.traceback())
	end
	
	setmetatable(heal, self)


	if heal.duration then
		heal.elapsed_time = 0
		heal.heal = heal.heal * heal.pulse / heal.duration
		heal.duration_timer = ac.loop(heal.pulse*1000, function()
			if heal.elapsed_time > heal.duration then
				heal.duration_timer:remove()
				return
			end
			heal:heal_start()
			heal.elapsed_time = heal.elapsed_time + heal.pulse
		end)
		heal.duration_timer:on_timer()
	else
		heal:heal_start()
	end

	return heal
end

--进行治疗
function Unit.__index:heal(data)
	data.source = self
	if not data.target then
		data.target = self
	end
	return Heal:new(data)
end

return Heal