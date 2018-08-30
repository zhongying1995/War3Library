
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local Unit = require 'Libraries.types.unit'
local Player = require 'Libraries.ac.player'
local slk = require 'jass.slk'
local math = math

local Hero = {}
setmetatable(Hero, Hero)

--结构
local mt = {}
Hero.__index = mt

--hero继承unit
setmetatable(mt, Unit)

--单位类型
mt.unit_type = 'hero'

--英雄属性的技能马甲
local ATTRIBUTE_ABIL_ID = 'Aamk'

--当前经验值
mt.xp = 0


--获得经验值
function mt:addXp(xp, show)
	jass.SetHeroXP(self.handle, jass.GetHeroXP(self.handle) + xp, show and true)
	self.xp = jass.GetHeroXP(self.handle)
end


function mt:get_level()
	return jass.GetHeroLevel(self.handle)
end

function mt:set_level(lv)
	local old_lv = self:get_level()
	if lv > old_lv then
		jass.SetHeroLevel(self.handle, lv)
	else
		jass.UnitStripHeroLevel(self.handle, old_lv - lv)
	end
end

function mt:add_level(lv)
	self:set_level(self:get_level() + lv)
end


function mt:get_str(is_all)
	return jass.GetHeroStr(self.handle, is_all and true)
end

function mt:set_str(n)
	jass.SetHeroStr(self.handle, n, true)
end

function mt:add_str(n)
	self:set_str(self:get_str()+n)
end


function mt:get_agi(is_all)
	return jass.GetHeroAgi(self.handle, is_all and true)
end

function mt:set_agi(n)
	jass.SetHeroAgi(self.handle, n, true)
end

function mt:add_agi(n)
	self:set_agi(self:get_agi()+n)
end


function mt:get_int(is_all)
	return jass.GetHeroInt(self.handle, is_all and true)
end

function mt:set_int(n)
	jass.SetHeroInt(self.handle, n, true)
end


function mt:add_int(n)
	self:set_int(self:get_int()+n)
end

function mt:get_extra_str()
	return self:get_str(true) - self:get_str()
end

mt._add_str = 0
function mt:get_add_str()
    return self._add_str
end

function mt:set_add_str(str)
	self._add_str = str
	local agi = self:get_add_agi()
	local int = self:get_add_int()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 108, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 109, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 110, int)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_str(str)
	self:set_add_str(self:get_add_str() + str)
end


function mt:get_extra_agi()
	return self:get_agi(true) - self:get_agi()
end

mt._add_agi = 0
function mt:get_add_agi()
    return self._add_agi
end

function mt:set_add_agi(agi)
	self._add_agi = agi
	local str = self:get_add_str()
	local int = self:get_add_int()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 108, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 109, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 110, int)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_agi(agi)
	self:set_add_agi(self:get_add_agi() + agi)
end


function mt:get_extra_int()
	return self:get_int(true) - self:get_int()
end

mt._add_int = 0
function mt:get_add_int()
    return self._add_int
end

function mt:set_add_int(int)
	self._add_int = int
	local str = self:get_add_str()
	local agi = self:get_add_agi()
	self:remove_ability(ATTRIBUTE_ABIL_ID)
	self:add_ability(ATTRIBUTE_ABIL_ID)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 108, str)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 109, agi)
	japi.EXSetAbilityDataReal(japi.EXGetUnitAbility(self.handle, ATTRIBUTE_ABIL_ID), 2, 110, int)
	self:set_ability_level(ATTRIBUTE_ABIL_ID, 2)
end

function mt:add_add_int(int)
	self:set_add_int(self:get_add_int() + int)
end


--复活英雄
function mt:revive(where)
	if self:is_alive() then
		return
	end
	if not where then
		where = self:get_born_point()
	end
	local origin = self:get_point()
	jass.ReviveHero(self.handle, where:get_point():get())
	self._is_alive = true
	if self.wait_to_transform_id then
		local target = self.wait_to_transform_id
		self.wait_to_transform_id = nil
		self:transform(target)
	end
	self:event_notify('单位-复活', self)
end

-- 变身
local dummy
function mt:transform(target_id)
	if not self:is_alive() then
		--死亡状态无法变身
		self.wait_to_transform_id = target_id
		return
	end

	if not dummy then
		dummy = ac.dummy
		dummy:add_ability 'AEme'
	end
	--变身
	japi.EXSetAbilityDataInteger(japi.EXGetUnitAbility(dummy.handle, base.string2id 'AEme'), 1, 117, base.string2id(self:get_type_id()))
	self:add_ability 'AEme'
	japi.EXSetAbilityAEmeDataA(japi.EXGetUnitAbility(self.handle, base.string2id 'AEme'), base.string2id(target_id))
	self:remove_ability 'AEme'

	--修改ID
	self.id = target_id

	--可以飞行
	self:add_ability 'Arav'
	self:remove_ability 'Arav'
	self:set_high(self:get_high())

	--动画混合时间
	jass.SetUnitBlendTime(self.handle, self:get_slk('blend', 0))

    -- 恢复特效
    if self._effect_list then
        for _, eff in ipairs(self._effect_list) do
            if eff.handle then
                jass.DestroyEffect(eff.handle)
                dbg.handle_unref(eff.handle)
                eff.handle = jass.AddSpecialEffectTarget(eff.model, self.handle, eff.socket or 'origin')
                dbg.handle_ref(eff.handle)
            end
        end
    end
end

--创建单位
--	id:单位id(字符串)
--	where:创建位置(type:point;type:circle;type:rect;type:unit)
--	face:面向角度
function player.__index:create_hero(name, where, face)
	local hero_data = Hero.hero_list[name].data
	local u = self:create_unit(hero_data.id, where, face)
	setmetatable(u, hero_data)
	--英雄物品栏
	u:add_ability 'AInv'
	u.hero_data = hero_data

	return u
end
--[=[
	ac.hero.create '丹特丽安'
{
	--物编中的id
	id = 'H010',
	production = '丹特丽安的书架',
	model_source = '全明星战役(水银灯)',
	hero_designer = 'actboy168',
	hero_scripter = '最萌小汐',
	show_animation = 'attack',
	--技能数量
	skill_count = 4,
	skill_names = '妖精之书 雷神之书 冥界之书 明日之诗',
	attribute = {
		['生命上限'] = 800,
		['魔法上限'] = 959,
		['生命恢复'] = 4,
		['魔法恢复'] = 2,
		['攻击']    = 31,
		['护甲']    = 10,
		['移动速度'] = 340,
		['攻击间隔'] = 1.2,
		['攻击范围'] = 600,
	},
	upgrade = {
		['生命上限'] = 110,
		['魔法上限'] = 65,
		['生命恢复'] = 0.26,
		['魔法恢复'] = 0.3,
		['攻击']    = 3.1,
		['护甲']    = 1.1,
	},
	weapon = {
		['弹道模型'] = [[Abilities\Weapons\ProcMissile\ProcMissile.mdl]],
		['弹道速度'] = 2000,
		['弹道弧度'] = 0.15,
		['弹道出手'] = {15, 0, 66},
	},
	difficulty = 5,
	--选取半径
	selected_radius = 32,
	--妹子
	yuri = true,
	--平胸
	pad = true,
	--萝莉
	loli = true,
}
]=]--
function Hero.create(name)
	return function(data)
		Hero.hero_datas[name] = data
		--继承英雄属性
		setmetatable(data, Hero)
		data.__index = data

        function data:__tostring()
            local player = self:get_owner()
            return ('[%s|%s|%s]'):format('hero', self:get_name(), player.base_name)
        end
		
		--注册技能
		data.skill_datas = {}
		if type(data.skill_names) == 'string' then
			for name in data.skill_names:gmatch '%S+' do
				table.insert(data.skill_datas, ac.skill[name])
			end
		elseif type(data.skill_names) == 'table' then
			for _, name in ipairs(data.skill_names) do
				table.insert(data.skill_datas, ac.skill[name])
			end
		end
		return data
	end
end

function Hero.get_all_heros()
	return Hero.all_heros
end

function Hero.register_jass_triggers()
	--英雄升级事件
	local j_trg = war3.CreateTrigger(function()
		local hero = Unit(jass.GetTriggerUnit())
		local new_lv = jass.GetHeroLevel(hero.handle)
		local old_lv = hero.level
		for i = hero.level + 1, new_lv do
			hero.level = i
			hero:event_notify('单位-英雄升级', hero)
		end

	end)
	for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_HERO_LEVEL, nil)
	end
end


function Hero.init()
	--注册英雄
	Hero.hero_datas = {}
	
	Hero.register_jass_triggers()

	--记录英雄
	local heros = {}
	Hero.all_heros = heros
	ac.game:event '玩家-注册英雄' (function(_, _, hero)
		heros[hero] = true
		hero:loop(100, function()
			hero:update_active()
		end)
	end)
end

ac.hero = Hero

return Hero
