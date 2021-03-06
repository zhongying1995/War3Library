local Player = Router.player
local Texttag = Router.texttag
local Point = Router.point

local mt = Player.__index

--获得金钱
--	金钱数量
--	[漂浮文字显示位置]
--	[是否不增加玩家金钱],默认增加
function mt:add_gold_text(gold, where, flag)
	
	if not where or gold <= 0 then
		return
    end
    if flag == nil then
        flag = true
    end
    if flag then
        self:add_gold(gold)
    end
	if not where:is_visible(self) then
		where = self.hero
		if not where then
			return
		end
	end
	local x, y = where:get_point():get()
	local z = where:get_point():getZ()
	local position = Point:new(x - 30, y, z + 30)
	Texttag:new{
		text = '+' .. math.floor(gold),
		size = 12,
		point = position,
		speed = 86,
		red = 255,
		green = 255,
		blue = 50,
		player = self,
		show = Texttag.SHOW_SELF
	}
	if where.type == 'unit' then
		local model
		if self:is_self() then
			model = [[UI\Feedback\GoldCredit\GoldCredit.mdl]]
		else
			model = ''
		end
		where:add_effect(model, 'overhead'):remove()
	end
end

return Player