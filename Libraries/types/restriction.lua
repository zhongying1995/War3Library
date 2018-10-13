local Unit = require 'libraries.types.unit'
local Player = require 'libraries.ac.player'

-- 行为限制

_RESTRICTION_ATTACK_ABIL_ID = SYS_RESTRICTION_ATTACK_ABIL_ID or 'Abun'
--攻击
local function restriction_attack(unit, flag)
	if flag then
		unit:add_ability(_RESTRICTION_ATTACK_ABIL_ID)
	else
		unit:remove_ability(_RESTRICTION_ATTACK_ABIL_ID)
	end
end

--物理免疫
local function restriction_attacked(unit, flag)
	if flag then
		jass.UnitAddType(unit.handle, jass.UNIT_TYPE_ANCIENT)
	else
		jass.UnitRemoveType(unit.handle, jass.UNIT_TYPE_ANCIENT)
	end
end

--魔法免疫
_RESTRICTION_SPELLED_ABIL_ID = SYS_RESTRICTION_SPELLED_ABIL_ID
local function restriction_spelled(unit, flag)
    if flag then
        unit:add_ability(_RESTRICTION_SPELLED_ABIL_ID)
    else
        unit:remove_ability(_RESTRICTION_SPELLED_ABIL_ID)
    end
end

--禁止显示魔法免疫技能
for i = 1, 16 do
    Player[i]:disable_ability(_RESTRICTION_SPELLED_ABIL_ID)
end

--免疫死亡
local function restriction_dead(unit, flag)
end

_RESTRICTION_STEALTH_ABIL_ID = SYS_RESTRICTION_STEALTH_ABIL_ID
--隐身
local function restriction_stealth(unit, flag)
	if flag then
		unit:add_ability(_RESTRICTION_STEALTH_ABIL_ID)
	else
		unit:remove_ability(_RESTRICTION_STEALTH_ABIL_ID)
	end
end

--隐藏
local function restriction_hide(unit, flag)
	jass.ShowUnit(unit.handle, not flag)
end

--阿卡林，高度
local function restriction_akari(unit, flag)
	if flag then
		jass.SetUnitFlyHeight(unit.handle, 999999, 0)
	else
		jass.SetUnitFlyHeight(unit.handle, unit.high, 0)
	end
end

--移动方式：飞行
local function restriction_fly(unit, flag)
    if flag then
        --飞行
        japi.EXSetUnitMoveType(unit.handle, 4)
    else
        if unit:has_restriction '幽灵' then
            --疾步风
        	japi.EXSetUnitMoveType(unit.handle, 16)
        else
            --步行
        	japi.EXSetUnitMoveType(unit.handle, 2)
    	end
    end
end

--移动方式：幽灵（疾步风）
local function restriction_collision(unit, flag)
    if unit:has_restriction '飞行' then
        return
    end
	if flag then
        japi.EXSetUnitMoveType(unit.handle, 16)
	else
        japi.EXSetUnitMoveType(unit.handle, 2)
	end
end

--眩晕
local function restriction_stun(self, flag)
	if flag then
		self:add_restriction '硬直'
	else
		self:remove_restriction '硬直'
	end
end

--硬直
local function restriction_hard(self, flag)
	if flag then
		if not self._ignore_order_list then
			self._ignore_order_list = {}
		end
		local order = self._current_issue_order
		if order and self._order_skills and self._order_skills[order] then
			table.insert(self._ignore_order_list, order)
		end
		japi.EXPauseUnit(self.handle, true)
	else
		japi.EXPauseUnit(self.handle, false)
		if self._recover_skill then
			local skill = self._recover_skill
			self._recover_skill = nil
			skill[1]:cast_by_client(skill[2])
		end
	end
end

--无敌，物免+魔免
local function restriction_god(self, flag)
	if flag then
		self:add_restriction '物免'
		self:add_restriction '魔免'
	else
		self:remove_restriction '物免'
		self:remove_restriction '魔免'
	end
end

local function restriction_constraint()
end

local restriction_type = {
	['缴械']	= restriction_attack,
	['物免']	= restriction_attacked,
	['魔免']	= restriction_spelled,
	['免死']	= restriction_dead,
	['隐身']	= restriction_stealth,
	['隐藏']	= restriction_hide,
	['阿卡林']	= restriction_akari,
	['飞行']	= restriction_fly,
	['幽灵']	= restriction_collision,
	['蝗虫']	= false,
	['晕眩']	= restriction_stun,
	['硬直']	= restriction_hard,
	['无敌']	= restriction_god,
	['禁锢']	= restriction_constraint,
}

function mt:add_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return 0
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	res[name] = (res[name] or 0) + 1
	if res[name] == 1 and restriction_type[name] then
		restriction_type[name](self, true)
	end
	return res[name]
end

function mt:remove_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return 0
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	res[name] = (res[name] or 0) - 1
	if res[name] == 0 and restriction_type[name] then
		restriction_type[name](self, false)
	end
	if res[name] == -1 then
		log.error('计数错误', name)
	end
	return res[name]
end

function mt:has_restriction(name)
	if not restriction_type[name] then
		log.error('错误的限制类型', name)
		return false
	end
	local res = self['限制']
	if not res then
		res = {}
		self['限制'] = res
	end
	return res[name] and res[name] > 0
end