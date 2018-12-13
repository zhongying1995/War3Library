local jass = require 'jass.common'
local japi = require 'jass.japi'
local Unit = require 'war3library.libraries.types.unit'

local math = math
local string_gsub = string.gsub

local mt = Unit.__index

--获得当前生命
function mt:get_life()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_LIFE)
end

--设置当前生命
function mt:set_life(life)
    if self:is_removed() then
        return
    end
    jass.SetUnitState(self.handle, jass.UNIT_STATE_LIFE, life)
end

--增加当前生命
function mt:add_life(life)
    self:set_life(self:get_life() + life)
end

--获得最大生命
function mt:get_max_life()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MAX_LIFE)
end

--设置最大生命
function mt:set_max_life(life)
    if self:is_removed() then
        return
    end
    local current_life = self:get_life()
    local max_life = self:get_max_life()
    japi.SetUnitState(self.handle, jass.UNIT_STATE_MAX_LIFE, life)
    self:set_life( life * current_life / max_life )
end

--增加最大生命
function mt:add_max_life(life)
    return self:set_max_life(self:get_max_life()+life)
end

--获得生命恢复
mt._life_recovery = 0
mt._life_recovery_percent = 0
function mt:get_life_recovery()
    return self._life_recovery, self._life_recovery_percent
end

--设置生命恢复
--  生命回复固定值
--  生命回复百分比
function mt:set_life_recovery(rec, perc)
    self._life_recovery = rec
    self._life_recovery_percent = prec
end

--增加生命回复
--  生命回复固定值
--  生命回复百分比
function mt:add_life_recovery(rec, perc)
    local old_rec, old_perc = self:get_life_recovery()
    old_rec = (rec or 0) + old_rec
    old_perc = (perc or 0) + old_perc
    self:set_life_recovery(old_rec, old_perc)
end

--获得脱战生命恢复
mt._inactive_life_recovery = 0
mt._inactive_life_recovery_percent = 0
function mt:get_inactive_life_recovery()
    return self._inactive_life_recovery, self._inactive_life_recovery_percent
end

--设置脱战生命恢复
--  生命回复固定值
--  生命回复百分比 
function mt:set_inactive_life_recovery(rec, perc)
    self._inactive_life_recovery = rec
    self._inactive_life_recovery_percent = perc
end

--增加脱战生命恢复
--  生命回复固定值
--  生命回复百分比
function mt:add_inactive_life_recovery(rec, perc)
    local old_rec, old_perc = self:get_inactive_life_recovery()
    old_rec = (rec or 0) + old_rec
    old_perc = (perc or 0) + old_perc
    self:set_inactive_life_recovery(old_rec, old_perc)
end

--获得当前魔法值
function mt:get_mana()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MANA)
end

--设置当前魔法
function mt:set_mana(mana)
    if self:is_removed() then
        return
    end
    return jass.SetUnitState(self.handle, jass.UNIT_STATE_MANA, mana)
end

--增加当前魔法
function mt:add_mana(mana)
    self:set_mana(self:get_mana()+mana)
end

--获得最大魔法
function mt:get_max_mana()
    return jass.GetUnitState(self.handle, jass.UNIT_STATE_MAX_MANA)
end

--设置最大魔法
function mt:set_max_mana(mana)
    if self:is_removed() then
        return
    end
    local current_mana = self:get_mana()
    local max_mana = self:get_max_mana()
    japi.SetUnitState(self.handle, jass.UNIT_STATE_MAX_MANA, mana)
    self:set_mana( mana * current_mana / max_mana )
end

--增加最大魔法
function mt:add_max_mana(mana)
    return self:set_max_mana(self:get_max_mana()+mana)
end

--获得魔法恢复
mt._mana_recovery = 0
function mt:get_mana_recovery()
    return self._mana_recovery
end

--设置魔法恢复
function mt:set_mana_recovery(rec)
    self._mana_recovery = rec
end

--增加魔法恢复
function mt:add_mana_recovery(rec)
    self:set_mana_recovery(self:get_mana_recovery() + rec)
end

--获得脱战魔法恢复
mt._inactive_mana_recovery = 0
function mt:get_inactive_mana_recovery()
    return self._inactive_mana_recovery
end

--设置脱战魔法恢复
function mt:set_inactive_mana_recovery(rec)
    self._inactive_mana_recovery = rec
end

--增加脱战魔法恢复
function mt:add_inactive_mana_recovery(rec)
    self:set_inactive_mana_recovery(self:get_inactive_mana_recovery() + rec)
end

--获得最大攻击
function mt:get_max_attack()
    return japi.GetUnitState(self.handle, 0x15)
end

--获得最小攻击
function mt:get_min_attack()
    return japi.GetUnitState(self.handle, 0x14)
end

--获得基础攻击
function mt:get_attack()
    return japi.GetUnitState(self.handle, 0x12)
end

--设置基础攻击
function mt:set_attack(atk)
    if self:is_removed() then
        return
    end
    return japi.SetUnitState(self.handle, 0x12, atk)
end

--增加基础攻击
function mt:add_attack(atk)
    return self:set_attack(self:get_attack()+atk)
end

local _add_attack_ability = config.SYS_UNIT_ATTRIBUTE_ADD_ATTACK_ABILITY_ID
--获得额外攻击（绿色攻击）
mt._extra_attack = 0
function mt:get_add_attack()
    return self._extra_attack
end

--设置额外攻击
function mt:set_add_attack(atk)
    if self:is_removed() then
        return
    end
    self._extra_attack = atk
    self:remove_ability(_add_attack_ability)
    self:add_ability(_add_attack_ability)
    local abil = japi.EXGetUnitAbility(self.handle, base.string2id(_add_attack_ability))
    japi.EXSetAbilityDataReal(abil, 2, 108, atk)
    jass.SetUnitAbilityLevel( self.handle, base.string2id(_add_attack_ability), 2)
end

--增加基础攻击
function mt:add_add_attack(atk)
    return self:set_add_attack(self:get_add_attack() + atk)
end

--获得攻击范围
function mt:get_attack_range()
    return japi.GetUnitState(self.handle, jass.ConvertUnitState(0x16))
end

--设置攻击范围
function mt:set_attack_range(range)
    if self:is_removed() then
        return
    end
    return japi.SetUnitState(self.handle, jass.ConvertUnitState(0x16), range)
end

--增加攻击范围
function mt:add_attack_range(range)
    return self:set_attack_range(self:get_attack_range()+range)
end

--获得攻击速度
function mt:get_attack_speed()
    return japi.GetUnitState(self.handle, 0x51)
end

--设置攻击速度
function mt:set_attack_speed(spd)
    if self:is_removed() then
        return
    end
    japi.SetUnitState(self.handle, 0x51, spd)
end

--增加攻击速度
--  攻速，百分比
function mt:add_attack_speed(spd)
    local spd = (spd or 0) / 100
    if spd == 0 then
        return
    end
    return self:set_attack_speed(self:get_attack_speed()+spd)
end

--获得攻击间隔
function mt:get_attack_rate()
    return japi.GetUnitState(self.handle, 0x25)
end

--设置攻击间隔
function mt:set_attack_rate(rate)
    if self:is_removed() then
        return
    end
    return japi.SetUnitState(self.handle, 0x25, rate)
end

--增加攻击间隔
mt._complementary_attack_rate = 0
--单位的攻击间隔最小为0.1，使用补差来调控过多降低单位的攻击间隔
function mt:add_attack_rate(rate)
    local rate = (rate or 0) / 100
    if rate == 0 then
        return
    end
    if self._complementary_attack_rate > 0 then
    	if rate > 0 then
    		self._complementary_attack_rate = self._complementary_attack_rate + rate
    		return
    	else
    		rate = self._complementary_attack_rate + rate
    		if rate < 0 then
    			self._complementary_attack_rate = 0
    		else
    			self._complementary_attack_rate = rate
    			return
    		end
    	end
    end
    local current_rate = self:get_attack_rate()
    if rate > 0 then
    	if current_rate - rate < 0.1 then
    		local difference = current_rate - 0.1
    		self._complementary_attack_rate = rate - difference
    		rate = difference
    	end
    end
    self:set_attack_rate(current_rate - rate)
end


--获得防御
function mt:get_defence()
    return japi.GetUnitState(self.handle, 0x20)
end

--设置防御
function mt:set_defence(def)
    return japi.SetUnitState(self.handle, 0x20, def)
end

--增加防御
function mt:add_defence(def)
    return self:set_defence(self:get_defence()+def)
end

local _add_defence_ability = config.SYS_UNIT_ATTRIBUTE_ADD_DEFENCE_ABILITY_ID
--获得额外护甲（绿色护甲）
mt._extra_defence = 0
function mt:get_add_defence()
    return self._extra_defence
end

--设置额外护甲
function mt:set_add_defence(def)
    if self:is_removed() then
        return
    end
    self._extra_defence = def
    self:remove_ability(_add_defence_ability)
    self:add_ability(_add_defence_ability)
    local abil = japi.EXGetUnitAbility(self.handle, base.string2id(_add_defence_ability))
    japi.EXSetAbilityDataReal(abil, 2, 108, def)
    jass.SetUnitAbilityLevel( self.handle, base.string2id(_add_defence_ability), 2)
end

--增加额外护甲
function mt:add_add_defence(def)
    return self:set_add_defence(self:get_add_defence() + def)
end

--移动速度
--  @单位的默认移动速度
function mt:get_default_move_speed()
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
function mt:get_base_move_speed()
    return self:get_default_move_speed() + self:get_add_move_speed()
end

function mt:set_move_speed(speed)
    if self:is_removed() then
        return
    end
    jass.SetUnitMoveSpeed(self.handle , speed)
end

--极值移动速度
_MIN_MOVE_SPEED = config.SYS_UNIT_MIN_MOVE_SPEED or 150
_MAX_MOVE_SPEED = config.SYS_UNIT_MAX_MOVE_SPEED or 522

--溢出的移动速度
mt._overflow_move_speed = 0
--补差的移动速度
mt._complementary_move_speed = 0

--增加单位的移动速度
--  固定值
--  百分比
--注：当需要增加单位移动速度时，应该使用该接口
function mt:add_move_speed(speed, speed_rate)
    local speed = speed or 0
    if speed_rate then
        speed = speed + self:get_base_move_speed() * speed_rate / 100
    end
    if speed == 0 then
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

	local complementary = self._complementary_move_speed
	if complementary > 0 then
		if speed < 0 then
			complementary = complementary - speed
			self._complementary_move_speed = complementary
			return
		else
			if complementary > speed then
				complementary = complementary - speed
				self._complementary_move_speed = complementary
				return
			else
				speed = speed - complementary
				self._complementary_move_speed = 0
			end
		end
	end

	local current_move = self:get_base_move_speed()
	local temp = current_move + speed
	if temp > 522 then
		self._overflow_move_speed = current_move + speed - 522
		speed = 522 - self:get_base_move_speed()
	elseif temp < _MIN_MOVE_SPEED then
		local difference = current_move - _MIN_MOVE_SPEED
		self._complementary_move_speed = math.abs(speed + difference)
		speed = -difference
	end
    add_add_move_speed(self, speed)
    self:set_move_speed(self:get_base_move_speed())
    return speed
end
