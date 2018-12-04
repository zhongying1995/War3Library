local Unit = require 'war3library.libraries.types.unit'

local Stun = {}

function Stun.init( )
    Stun.damage_trg = ac.game:event '单位-即将造成伤害效果'(function(trg, damage)
        local atker = damage.source
        if atker:is_enable_stun() and damage:is_attack() then
            if atker:get_stun_probability() >= math.random(1, 100) then
                if atker:get_stun_attendant_damage() > 0 then
                    atker:damage{
                        target = damage.target,
                        damage = atker:get_stun_attendant_damage(),
                        damage_type = '魔法',
                    }
                end
                damage.target:add_buff('晕眩'){
                    time = atker:get_stun_duration(),
                    skill = atker,
                }
            end
        end
    end)
end


--单位允许击晕
function Unit.__index:is_enable_stun(  )
    return self:get_stun_probability() > 0 and self:get_stun_duration() > 0
end

Unit.__index._stun_probability = 0
--获得单位击晕概率
function Unit.__index:get_stun_probability()
    return self._stun_probability
end

--设置单位的击晕概率
function Unit.__index:set_stun_probability( prob )
    self._stun_probability = prob
end

--增加单位的击晕概率
function Unit.__index:add_stun_probability( prob )
    self:set_stun_probability(self:get_stun_probability()+prob)
end

Unit.__index._stun_attendant_damage = 0
--获得单位击晕额外伤害
function Unit.__index:get_stun_attendant_damage()
    return self._stun_attendant_damage
end

--设置单位的击晕额外伤害
function Unit.__index:set_stun_attendant_damage( dmg )
    self._stun_attendant_damage = dmg
end

--增加单位的击晕额外伤害
function Unit.__index:add_stun_attendant_damage( dmg )
    self:set_stun_attendant_damage(self:get_stun_attendant_damage()+dmg)
end

Unit.__index._stun_duration = 0
--获得单位击晕持续时间
function Unit.__index:get_stun_duration()
    return self._stun_duration
end

--设置单位的击晕持续时间
function Unit.__index:set_stun_duration( time )
    self._stun_duration = time
end

--增加单位的击晕持续时间
function Unit.__index:add_stun_duration( time )
    self:set_stun_duration(self:get_stun_duration()+time)
end


return Stun