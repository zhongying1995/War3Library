local Unit = require 'war3library.libraries.types.unit'

local Cleave = {}


function Cleave.init(  )
    Cleave.damage_trg = ac.game:event '单位-即将造成伤害效果'(function(trg, damage)
        local atker = damage.source
        if atker:is_enable_cleave() and damage:is_attack() then
            local range = atker:get_cleave_range()
            local rate = atker:get_cleave_rate()
            local dmg = damage:get_original_damage() * rate / 100
            for _, u in ac.selector()
                :in_range(damage.target, range)
                :is_enemy(atker)
                :ipairs()
            do
                atker:damage{
                    target = u,
                    damage = dmg,
                    damage_type = '魔法',
                }
            end
        end
    end)
end

--单位允许溅射
function Unit.__index:is_enable_cleave(  )
    return self:get_cleave_range() > 0 and self:get_cleave_rate() > 0
end

Unit.__index._cleave_range = 0
--获得溅射范围
function Unit.__index:get_cleave_range(  )
    return self._cleave_range
end

--设置溅射范围
function Unit.__index:set_cleave_range( range )
    self._cleave_range = range
end

--增加溅射范围
function Unit.__index:add_cleave_range(range)
    self:set_cleave_range(self:get_cleave_range() + range)
end


Unit.__index._cleave_rate = 0
--获得溅射比例
function Unit.__index:get_cleave_rate(  )
    return self._cleave_rate
end

--设置溅射比例
function Unit.__index:set_cleave_rate( rate )
    self._cleave_rate = rate
end

--增加溅射比例
function Unit.__index:add_cleave_rate(rate)
    self:set_cleave_rate(self:get_cleave_rate() + rate)
end



return Cleave