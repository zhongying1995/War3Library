
local jass = require 'jass.common'
local Player = require 'libraries.ac.player'
local dbg = require 'jass.debug'
local Point = require 'libraries.ac.point'

local Texttag = {}
setmetatable(Texttag, Texttag)
ac.texttag = Texttag

--创建漂浮文字
function Texttag.new( texttag )
	
	setmetatable(texttag, self)
	texttag.handle = jass.CreateTextTag()

	texttag:set_text()
	texttag:set_position()
	texttag:set_color()
	texttag:set_speed()
	texttag:set_life_time()
	texttag:set_permanent()

	if texttag.target then
		self.group[texttag] = true
	end
	
	texttag:set_show()
	
	return texttag
end

function Texttag:__call(texttag)
	return Texttag.new(texttag)
end

--结构
local mt = {}
Texttag.__index = mt

--可见性常量
mt.SHOW_NONE = 0
mt.SHOW_ALL = 1
mt.SHOW_SELF = 2
mt.SHOW_ALLY = 4
mt.SHOW_FOG = 8 --是否在迷雾内可见，默认为不可见

--类型
mt.type = 'texttag'

--句柄
mt.handle = 0

--玩家
mt.player = Player[16]

--文本内容
mt.string = '无文本'

--文本大小
mt.size = 10

--初始位置
mt.position = Point:new(0, 0)

--Z轴偏移（仅在绑定目标时有效）
mt.zoffset = 0

--速度
mt.speed = 0

--角度
mt.angle = 90

--颜色、百分比
mt.red = 100
mt.green = 100
mt.blue = 100
mt.alpha = 100

--生命周期
mt.life = 3

--淡化
mt.fade = 2

--永久性
mt.permanent = false

--可见性
mt.show = Texttag.SHOW_ALL

--绑定单位
mt.target = nil

--弹跳
mt.jump_size = 10
mt.jump_speed = 0
mt.jump_a = 0

--设置文本
function mt:set_text(string, size)
	if string then
		self.string = string
	end
	jass.SetTextTagText(self.handle, string or self.string, (size or self.size) * 0.0023)
end

--设置位置
function mt:set_position(position)
	jass.SetTextTagPos(self.handle, (position or self.position):get_point():get())
end

--设置颜色
function mt:set_color(red, green, blue, alpha)
	jass.SetTextTagColor(self.handle, (red or self.red) * 2.55, (green or self.green) * 2.55, (blue or self.blue) * 2.55, (alpha or self.alpha) * 2.55)
end

--设置速度
function mt:set_speed(angle, speed)
	local angle = angle or self.angle
	local speed = speed or self.speed
	jass.SetTextTagVelocity(self.handle, speed * 0.071 * math.cos(angle) / 128, speed * 0.071 * math.sin(angle) / 128)
end

--设置生命周期
function mt:set_life_time(fade, life)
	jass.SetTextTagFadepoint(self.handle, fade or self.fade)
	jass.SetTextTagLifespan(self.handle, life or self.life)
end

--设置永久性
function mt:set_permanent(permanent)
	jass.SetTextTagPermanent(self.handle, permanent or self.permanent)
end

--设置所有者
function mt:set_player(player)
	if player then
		self.player = player
	end
end

local function has_flag(flag, bit)
	return flag % (bit * 2) - flag % bit == bit
end

--设置可见性
function mt:set_show(show)
	local show = show or self.show
	local flag = false
	local function is_visible() 
		if self.target then 
			return self.target:is_visible(Player.self)
		else 
			return Player.self:is_visible(self.position)
		end
	end
	if has_flag(show, Texttag.SHOW_FOG) or is_visible() then
		if has_flag(show, Texttag.SHOW_ALL) then
			flag = true
		else
			if has_flag(show, Texttag.SHOW_SELF) and Player.self == self.player then
				flag = true
			else
				if has_flag(show, Texttag.SHOW_ALLY) and not self.player:is_enemy(Player.self) then
					flag = true
				end
			end
		end
	end
	if(show == Texttag.SHOW_NONE)then
		flag = false;
	end

	jass.SetTextTagVisibility(self.handle, flag)

	return flag
end

--移除漂浮文字
function mt:remove()
	if self.removed then
		return
	end
	self.removed = true
	jass.DestroyTextTag(self.handle)
	self.handle = nil

	Texttag.group[self] = nil
end

--文字弹跳，仅对绑定在单位的文字有效
function mt:jump(speed,a)
	self.jump_size = self.size
	self.jump_speed = speed 
	self.jump_a = a
end

function mt:move()
	local target = self.target
	if target then
		if self.jump_speed ~= 0 then
			self.jump_speed = self.jump_speed + self.jump_a
			self.jump_size = self.jump_size + self.jump_speed
			self:set_text(self.string,self.jump_size)
			self.zoffset = self.zoffset + self.jump_speed
			if self.jump_size < self.size then
				--停止弹跳
				self:set_text(self.string,self.size)
				self.jump_speed = 0
			end
		end
		local p = target:get_point() 
		p.z = self.zoffset
		self:set_position(p)

		self:set_show()
	end
end

function Texttag.reinit()
	for tt in pairs(Texttag.group) do
		tt:remove()
	end
end

function Texttag.init()
	Texttag.group = {}
end

function Texttag.update()
	for tt in pairs(Texttag.group) do
		tt:move()
	end
end

Texttag.init()

return Texttag