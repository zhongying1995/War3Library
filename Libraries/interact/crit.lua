local Unit = require 'libraries.types.unit'

local Crit = {}


local function init()
    Crit.attack_trg = ac.game:event '单位-攻击'(function(trg, atker, atked)
        local probability = math.max(0, atker:get_crit_probability())
        if probability >= math.random(0, 100) or atker:is_crit() then
            atker:set_animation('attack slam')
            atker:set_crit(true)
        end
    end)
    Crit.damage_trg = ac.game:event '单位-即将造成伤害'(function(trg, damage)
        local atker = damage.source
        if atker:is_crit() and damage:is_attack() then
            atker:set_crit(false)
            local rate = math.max(100, atker:get_crit_rate())
            damage.before_crit_damage = damage.damage
            damage.damage = damage.damage * rate
            local atk = atker:get_attack()
            local show_damage = atk*rate
            ac.texttag:new{
                text = ('%.f !'):format(show_damage),
                player = atker:get_owner(),
                angle = 90,
                speed = 28,
                size = 12,
                red = 255,
                blue = 0,
                green = 0,
                show = ac.texttag.SHOW_ALL,
                point = atker:get_point() - {90, 50},
            }
        end
    end)
end

--下一次伤害是否是暴击
function Unit.__index:is_crit()
    return self._is_crit
end

function Unit.__index:set_crit(flag)
    if flag == nil then
        flag = true
    end
    self._is_crit = flag
end

--暴击概率
Unit.__index._crit_probability = 0
function Unit.__index:get_crit_probability()
    return self._crit_probability
end

function Unit.__index:set_crit_probability(probability)
    self.self._crit_probability = probability
end

function Unit.__index:add_crit_probability(probability)
    self:set_crit_probability(self:get_crit_probability() + probability)
end

--暴击伤害倍率,百分比
Unit.__index._crit_rate = 100
function Unit.__index:get_crit_rate()
    return self._crit_rate
end

function Unit.__index:set_crit_rate(rate)
    self.self._crit_rate = rate
end

function Unit.__index:add_crit_rate(rate)
    self:set_crit_rate(self:get_crit_rate() + rate)
end

init()

return Crit