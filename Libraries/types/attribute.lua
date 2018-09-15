local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'libraries.types.unit'

local math = math
local string_gsub = string.gsub

local mt = Unit.__index

--当前生命
function mt:get_life()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_LIFE)
end

function mt:set_life(life)
    japi.SetUnitState(self.handle, jass.UNIT_STATE_LIFE, life)
end

function mt:add_life(life)
    self:set_life(self:get_life() + life)
end

--最大生命
function mt:get_max_life()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MAX_LIFE)
end

function mt:set_max_life(life)
    local current_life = self:get_life()
    local max_life = self:get_max_life()
    jass.SetUnitState(self.handle, jass.UNIT_STATE_MAX_LIFE, life)
    self:set_life( life * current_life / max_life )
end

function mt:add_max_life(life)
    return self:set_max_life(self:get_max_life()+life)
end

--魔法
function mt:get_mana()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MANA)
end

function mt:set_mana(mana)
    return japi.SetUnitState(self.handle, jass.UNIT_STATE_MANA, mana)
end

function mt:add_mana(mana)
    self:set_mana(self:get_mana()+mana)
end

--最大魔法
function mt:get_max_mana()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MAX_MANA)
end

function mt:set_max_mana(mana)
    local current_mana = self:get_mana()
    local max_mana = self:get_max_mana()
    jass.SetUnitState(self.handle, jass.UNIT_STATE_MAX_MANA, mana)
    self:set_mana( mana * current_mana / max_mana )
end

function mt:add_max_mana(mana)
    return self:set_mana(self:get_mana()+mana)
end

--攻击
function mt:get_attack()
    return japi.GetUnitState(self.handle, 0x12)
end

function mt:set_attack(atk)
    return japi.SetUnitState(self.handle, 0x12, atk)
end

function mt:add_attack(atk)
    return self:set_attack(self:get_attack()+atk)
end

--额外攻击（绿色攻击）
function mt:get_add_attack()
    return japi.GetUnitState(self.handle, 0x13)
end

function mt:set_add_attack(atk)
    return japi.SetUnitState(self.handle, 0x13, atk)
end

function mt:add_add_attack(atk)
    return self:set_add_attack(self:get_add_attack(), atk)
end

--攻击范围
function mt:get_attack_range()
    return jass.GetUnitState(self.handle, jass.ConvertUnitState(0x16))
end

function mt:set_attack_range(atk)
    return japi.SetUnitState(self.handle, jass.ConvertUnitState(0x16), atk)
end

function mt:add_attack_range(atk)
    return self:set_attack_range(self:get_attack_range(), atk)
end

--攻击速度
function mt:get_attack_speed()
    return japi.GetUnitState(self.handle, 0x51)
end

function mt:set_attack_speed(spd)
    return japi.SetUnitState(self.handle, 0x51, spd)
end

function mt:add_attack_speed(spd)
    return self:set_attack_speed(self:get_attack_speed()+spd)
end

--攻击间隔
function mt:get_attack_rate()
    return japi.GetUnitState(self.handle, 0x25)
end

function mt:set_attack_rate(rate)
    return japi.SetUnitState(self.handle, 0x25, rate)
end

function mt:add_attack_rate(rate)
    return self:set_attack_rate(self:get_attack_rate()-rate)
end

--防御
function mt:get_defence()
    return japi.GetUnitState(self.handle, 0x20)
end

function mt:set_defence(def)
    return japi.SetUnitState(self.handle, 0x20, def)
end

function mt:add_defence(def)
    return self:set_defence(self:get_defence()+def)
end

--移动速度
--  @单位的默认移动速度
function mt:get_base_move_speed()
    return jass.GetUnitDefaultMoveSpeed(self.handle)
end

--  @当前单位的移动速度，计算光环等效果
function mt:get_move_speed()
    return jass.GetUnitMoveSpeed(self.handle)
end

--@增加的移动速度
mt._add_move_speed = 0
function mt:get_add_move_speed()
    return self._add_move_speed
end

--该接口不应该被外界调用
local function set_add_move_speed(self, speed)
    self._add_move_speed = speed
end

--该接口不应该被外界调用
local function add_add_move_speed(self, speed)
    set_add_move_speed(self, self:get_add_move_speed() + speed)
end

--  @不计算单位光环的加成，即基础速度+额外速度
--注：该数值可能大于522，但单位速度不会大于522
function mt:get_pure_move_speed()
    return self:get_base_move_speed() + self:get_add_move_speed()
end

function mt:set_move_speed(speed)
    jass.SetUnitMoveSpeed(self.handle , speed)
end

--溢出的移动速度
mt._overflow_move_speed = 0

--增加单位的移动速度
--注：当需要增加单位移动速度时，应该使用该接口
function mt:add_move_speed(speed)
    if not speed or speed == 0 then
        return
    end
    local overflow = self._overflow_move_speed
	if overflow > 0 then
		if speed > 0 then
			self._overflow_move_speed = self._overflow_move_speed + speed
			return
		else
			overflow = overflow + speed
			if overflow >= 0 then
				self._overflow_move_speed = overflow
				return
			else
				self._overflow_move_speed = 0
				speed = overflow
			end
		end
	end
	local current_move = self:get_pure_move_speed()
	if current_move + speed > 522 then
		self._overflow_move_speed = current_move + speed - 522
		speed = 522 - self:get_pure_move_speed()
	end
    add_add_move_speed(self, speed)
    self:set_move_speed(self:get_pure_move_speed())
end
