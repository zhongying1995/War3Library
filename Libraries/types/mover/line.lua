
local Mover = require 'libraries.types.mover.mover'

--直线运动
Mover.line = {}
setmetatable(Mover.line, Mover.line)

--结构
Mover.line.__index = {
	--类型
	mover_type = 'line',

	--检查是否击中目标
	check_hit = function(self)
		local speed = self.speed * Mover.FRAME * self.time_scale
		if self.distance < speed then
			local p1 = self.mover:get_point()
			local p2 = p1 - {self.angle, self.distance}
			self.mover:set_position(p2, self.path, self.super)
			if Mover.on_finish(self) then
				return
			end
		end
	end,

	--每个周期的运动
	next = function(self)
		
		local speed = self.speed * self.time_scale * Mover.FRAME
		local p1 = self.mover:get_point()
		
		self.distance = self.distance - speed

		if self.missile and self.angle then
			self.mover:set_facing(self.angle + self.off_angle)
		end
		
		--向前位移
		self.next_point = p1 - {self.angle, speed}
	end,

	create = function(self)
		if self.target then
			if not self.angle then
				self.angle = self.start:get_point() / self.target:get_point()
			end
			if not self.distance then
				self.distance = self.start:get_point() * self.target:get_point()
			end
		end
		self.target_high = self.target_high or self.high
		return self
	end,
	
}

setmetatable(Mover.line.__index, Mover)