local mt = ac.buff['减速']{}

mt.cover_type = 1
mt.cover_max = 1

mt.control = 2
mt.debuff = true
mt.effect = nil
mt.ref = 'origin'
mt.model = [[Abilities\Spells\Human\slow\slowtarget.mdl]]

function mt:on_add()
	self.effect = self.target:add_effect(self.model, self.ref)
	self.target:add_move_speed(- self.move_speed)
end

function mt:on_remove()
	self.effect:remove()
	self.target:add_move_speed(self.move_speed)
end

function mt:on_cover(new)
	return new.move_speed > self.move_speed
end
