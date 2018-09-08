
local jass = require 'jass.common'
local dbg = require 'jass.debug'
local rect = require 'libraries.ac.rect'
local circle = require 'libraries.ac.circle'
local fogmodifier = require 'libraries.ac.fogmodifier'
local texttag
local mouse

local Player = {}
setmetatable(Player, Player)
ac.player = Player

function Player:__tostring()
    return ('玩家%02d|%s|%s'):format(self.id, self.base_name, jass.GetPlayerName(self.handle))
end

local mt = {}
Player.__index = mt

--类型
mt.type = 'player'

--句柄
mt.handle = 0

--id
mt.id = 0

--金钱
mt.gold = 0

--零钱
mt.gold_pool = 0


--获取玩家id
function mt:get()
	return self.id
end

--注册事件
function mt:event(name)
	return ac.event_register(self, name)
end

local ac_game = ac.game

--发起事件
function mt:event_dispatch(name, ...)
	local res = ac.event_dispatch(self, name, ...)
	if res ~= nil then
		return res
	end
	local res = ac.event_dispatch(ac_game, name, ...)
	if res ~= nil then
		return res
	end
	return nil
end

function mt:event_notify(name, ...)
	ac.event_notify(self, name, ...)
	ac.event_notify(ac_game, name, ...)
end

--获取玩家名字
function mt:get_name()
	return jass.GetPlayerName(self.handle)
end

--获取原始名字
function mt:get_base_name()
	return self.base_name
end

--设置玩家名字
function mt:set_name(name)
	jass.SetPlayerName(self.handle, name)
end

--是否是玩家
function mt:is_player()
	return jass.GetPlayerController(self.handle) == jass.MAP_CONTROL_USER and jass.GetPlayerSlotState(self.handle) == jass.PLAYER_SLOT_STATE_PLAYING
end

--是否是裁判
function mt:is_observer()
	return jass.IsPlayerObserver(self.handle)
end

--是否是本地玩家
function mt:is_self()
	return self == Player.self
end

--设置颜色
--	参数为颜色的id
function mt:set_color(this, c)
	jass.SetPlayerColor(this.handle, c - 1)
end

--结盟
function mt:set_alliance(dest, al, flag)
	return jass.SetPlayerAlliance(self.handle, dest.handle, al, flag)
end

function mt:set_alliance_simple(dest, flag)
	jass.SetPlayerAlliance(self.handle, dest.handle, 0, flag)		--ALLIANCE_PASSIVE结盟不侵犯
	jass.SetPlayerAlliance(self.handle, dest.handle, 1, false)	--ALLIANCE_HELP_REQUEST救援请求
	jass.SetPlayerAlliance(self.handle, dest.handle, 2, false)	--ALLIANCE_HELP_RESPONSE救援回应
	jass.SetPlayerAlliance(self.handle, dest.handle, 3, flag)		--ALLIANCE_SHARED_XP共享经验
	jass.SetPlayerAlliance(self.handle, dest.handle, 4, flag)		--ALLIANCE_SHARED_SPELLS盟友魔法锁定
	jass.SetPlayerAlliance(self.handle, dest.handle, 5, flag)		--ALLIANCE_SHARED_VISION共享视野
	--jass.SetPlayerAlliance(self, dest, 6, flag)	--ALLIANCE_SHARED_CONTROL共享单位
	--jass.SetPlayerAlliance(self, dest, 7, flag)	--ALLIANCE_SHARED_ADVANCED_CONTROL完全共享控制权
	--jass.SetPlayerAlliance(self, dest, 8, flag)	--ALLIANCE_RESCUABLE
	--jass.SetPlayerAlliance(self, dest, 9, flag)	--ALLIANCE_SHARED_VISION_FORCED
end

function mt:set_alliance_ally( dest, is_ally )
	if is_ally == nil then
		is_ally = true
	end
	self:set_alliance(dest, 0, is_ally)
	self:set_alliance(dest, 1, is_ally)
	self:set_alliance(dest, 2, is_ally)
	self:set_alliance(dest, 3, is_ally)
	self:set_alliance(dest, 4, is_ally)
	self:set_alliance(dest, 5, is_ally)
end

--队伍
--设置队伍
function mt:set_team(team_id)
	jass.SetPlayerTeam(self.handle, team_id - 1)
	self.team_id = team_id
end

--获取队伍
function mt:get_team()
	if not self.team_id then
		self.team_id = jass.GetPlayerTeam(self.handle) + 1
	end
	return self.team_id
end

--允许控制
--	[显示头像]
function mt:enable_control(dest, flag)
	jass.SetPlayerAlliance(dest.handle, self.handle, 6, true)
	if flag then
		jass.SetPlayerAlliance(dest.handle, self.handle, 7, true)
	end
end
	
--显示系统警告
--	警告内容
function mt:show_sys_warning(msg)
    local sys_sound = jass.CreateSoundFromLabel("InterfaceError", false, false, false, 10, 10)
    if(jass.GetLocalPlayer() == self.handle) then
        if (msg ~= '') and (msg ~= nil) then
            jass.ClearTextMessages()
            jass.DisplayTimedTextToPlayer(self.handle, 0.5, -1, 2, '|cffffcc00' .. msg .. '|r')
        end
        jass.StartSound(sys_sound)
    end
    jass.KillSoundWhenDone(sys_sound)
end

--小地图信号
--	信号位置
--	信号时间
--	[红色]
--	[绿色]
--	[蓝色]
function mt:ping_minimap(where, time, red, green, blue, flag)
	if self == Player.self then
		local x, y = where:get_point():get()
		jass.PingMinimapEx(x, y, time, red or 0, green or 255, blue or 0, not not flag)
	end
end

--可见性检查
--位置的可见性
--	目标位置
function mt:is_visible(where)
	local x, y = where:get_point():get()
	return jass.IsVisibleToPlayer(x, y, self.handle)
end

--是否是敌人
--	目标玩家
function mt:is_enemy(dest)
	return self:get_team() ~= dest:get_team()
end

--是否是友军
function mt:is_ally(dest)
	return self:get_team() == dest:get_team()
end

--获得金钱
--	金钱数量
--	[漂浮文字显示位置]
--	[不抛出加钱事件]
function mt:add_gold(gold, where, flag)
	if gold > 0 and not flag then
		local data = {player = self, gold = gold}
		self:event_notify('玩家-即将获得金钱', data)
		gold = data.gold
	end
	gold = gold + self.gold_pool
	self.gold_pool = gold % 1
	gold = math.floor(gold)
	self.gold = self.gold + gold
	jass.SetPlayerState(self.handle, 0x01, self.gold)
	if not where or gold <= 0 then
		return
	end
	if not where:is_visible(self) then
		where = self.hero
		if not where then
			return
		end
	end
	local x, y = where:get_point():get()
	local z = where:get_point():getZ()
	local position = ac.point(x - 30, y, z + 30)
	ac.texttag
	{
		string = '+' .. math.floor(gold),
		size = 12,
		position = position,
		speed = 86,
		red = 100,
		green = 100,
		blue = 20,
		player = self,
		show = ac.texttag.SHOW_SELF
	}
	if where.type == 'unit' then
		local model
		if self:is_self() then
			model = [[UI\Feedback\GoldCredit\GoldCredit.mdl]]
		else
			model = ''
		end
		where:add_effect('overhead', model):remove()
	end
end

--设置、获取、增加、玩家木材，金钱、可用人口、已使用人口
function mt:set_lumber( lumber )
	jass.SetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_LUMBER, lumber)
end

function mt:get_lumber()
	return jass.GetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_LUMBER)
end

function mt:add_lumber(lumber)
	self:set_lumber(self:get_lumber() + lumber)
end

function mt:set_gold( gold )
	jass.SetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_GOLD, gold)
end

function mt:get_gold()
	return jass.GetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_GOLD)
end

function mt:add_gold( gold )
	self:set_gold(self:get_gold() + gold)
end

function mt:set_food( food )
	jass.SetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_FOOD_CAP, food)
end

function mt:get_food()
	return jass.GetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_FOOD_CAP)
end

function mt:add_food(food)
	self:set_used_food(self:get_used_food() + food)
end

function mt:set_used_food( food )
	jass.SetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_FOOD_USED, food)
end

function mt:get_used_food()
	return jass.GetPlayerState(self.handle, jass.PLAYER_STATE_RESOURCE_FOOD_USED)
end

function mt:add_used_food(food)
	self:set_used_food(self:get_used_food() + food)
end

--禁用技能
function mt:enable_ability(ability_id)
	if ability_id then
		jass.SetPlayerAbilityAvailable(self.handle, Base.string2id(ability_id), true)
	end
end

function mt:disable_ability(ability_id)
	if ability_id then
		jass.SetPlayerAbilityAvailable(self.handle, Base.string2id(ability_id), false)
	end
end

--强制按键
--	按下的键(字符串'ESC'表示按下ESC键)
function mt:press_key(key)
	if self ~= Player.self then
		return
	end

	local key = key:upper()
	
	if key == 'ESC' then
		jass.ForceUICancel()
	else
		jass.ForceUIKey(key)
	end
end

--发送消息
--	消息内容
--	[持续时间]
function mt:send_msg(text, time)
	jass.DisplayTimedTextToPlayer(self.handle, 0, 0, time or 60, text)
end

--发送消息
--	消息内容
--	[持续时间]
function mt:send_warm_msg(text, time)
	jass.DisplayTimedTextToPlayer(self.handle, 0.5, -1, time or 60, text)
end

--	消息内容
--	[持续时间]
function mt:send_msg_to_force(text, time)
	if Player.self:get_team() == self:get_team() then
		Player.self:send_msg(text, time)
	end
end

--清空屏幕显示
function mt:clear_msg()
	if self == Player.self then
		jass.ClearTextMessages()
	end
end

--设置镜头位置
function mt:set_camera(where, time)
	if Player.self == self then
		local x, y
		if where then
			x, y = where:get_point():get()
		else
			x, y = jass.GetCameraTargetPositionX(), jass.GetCameraTargetPositionY()
		end
		if time then
			jass.PanCameraToTimed(x, y, time)
		else
			jass.SetCameraPosition(x, y)
		end
	end
end

--设置镜头属性
--	镜头属性
--	数值
--	[持续时间]
function mt:set_camera_field(key, value, time)
	if self == Player.self then
		jass.SetCameraField(jass[key], value, time or 0)
	end
end

--设置镜头高度
--	高度
--	改变镜头需要的时间
function mt:set_camera_height(height, duration)
	set_camera_field(self, 'CAMERA_FIELD_TARGET_DISTANCE', height, duration)
end

--获取镜头属性
--	镜头属性
function mt:get_camera_field(key)
	return math.deg(jass.GetCameraField(jass[key]))
end

--设置镜头目标
function mt:set_camera_target(target, x, y)
	if self == Player.self then
		jass.SetCameraTargetController(target and target.handle or 0, x or 0, y or 0, false)
	end
end

--旋转镜头
function mt:rotate_camera(p, a, time)
	if self == Player.self then
		local x, y = p:get_point():get()
		local a = math.rad(a)
		jass.SetCameraRotateMode(x, y, a, time)
	end
end

--允许UI,是否显示血条
function mt:enable_UI()
	if self == Player.self then
		jass.EnableUserUI(true)
	end
end

--禁止UI
function mt:disable_UI()
	if self == Player.self then
		jass.EnableUserUI(false)
	end
end

--显示界面,电影模式
--	[转换时间]
function mt:show_interface(time)
	if self == Player.self then
		jass.ShowInterface(true, time or 0)
	end
end

--隐藏界面
--	[转换时间]
function mt:hide_interface(time)
	if self == Player.self then
		jass.ShowInterface(false, time or 0)
	end
end

--禁止框选
function mt:disable_drag_select()
	if self == Player.self then
		jass.EnableDragSelect(false, false)
	end
end

--允许框选
function mt:enable_drag_select()
	if self == Player.self then
		jass.EnableDragSelect(true, true)
	end
end

local color_word = {}
--获得颜色
function mt:get_color_word()
	local i = self:get()
	return color_word[i]
end

local function init_color_word()
	color_word [1] = "|cFFFF0303"
    color_word [2] = "|cFF0042FF"
    color_word [3] = "|cFF1CE6B9"
    color_word [4] = "|cFF540081"
    color_word [5] = "|cFFFFFC01"
    color_word [6] = "|cFFFE8A0E"
    color_word [7] = "|cFF20C000"
    color_word [8] = "|cFFE55BB0"
    color_word [9] = "|cFF959697"
    color_word[10] = "|cFF7EBFF1"
    color_word[11] = "|cFFFFFC01"
    color_word[12] = "|cFF0042FF"
    color_word[13] = "|cFF282828"
    color_word[14] = "|cFF282828"
    color_word[15] = "|cFF282828"
    color_word[16] = "|cFF282828"
end

--获取镜头位置
function mt:get_camera()
	return ac.point(jass.GetCameraTargetPositionX(), jass.GetCameraTargetPositionY())
end

--设置镜头可用区域
function mt:set_camera_bounds(...)
	if self == Player.self then
		local minX, minY, maxX, maxY
		if select('#', ...) == 1 then
			local rct = rect.j_rect(...)
			minX, minY, maxX, maxY = rct:get()
		else
			minX, minY, maxX, maxY = ...
		end
		jass.SetCameraBounds(minX, minY, minX, maxY, maxX, maxY, maxX, minY)
	end
end

--创建可见度修整器
--	圆心
--	半径
--	[是否可见]
--	[是否共享]
--	[是否覆盖单位视野]
function mt:create_fogmodifier(p, r, ...)
	local cir = circle.create(p, r)
	return fogmodifier.create(self, cir, ...)
end

--滤镜
function mt:cinematic_filter(data)
	jass.SetCineFilterTexture(data.file or [[ReplaceableTextures\CameraMasks\DreamFilter_Mask.blp]])
	jass.SetCineFilterBlendMode(jass.BLEND_MODE_BLEND)
	jass.SetCineFilterTexMapFlags(jass.TEXMAP_FLAG_NONE)
	jass.SetCineFilterStartUV(0, 0, 1, 1)
	jass.SetCineFilterEndUV(0, 0, 1, 1)
	if data.start then
		jass.SetCineFilterStartColor(data.start[1] * 2.55, data.start[2] * 2.55, data.start[3] * 2.55, data.start[4] * 2.55)
	end
	if data.finish then
		jass.SetCineFilterEndColor(data.finish[1] * 2.55, data.finish[2] * 2.55, data.finish[3] * 2.55, data.finish[4] * 2.55)
	end
	jass.SetCineFilterDuration(data.time)
	if self == ac.player.self then
		jass.DisplayCineFilter(true)
	end

	local player = self
	function data:remove()
		if player == Player.self then
			jass.DisplayCineFilter(false)
		end
	end

	return data
end

-- 设置昼夜模型
local default_model = 'Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl'
function mt:set_day(model)
	if self == Player.self then
		jass.SetDayNightModels(model or default_model, 'Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl')
	end
end

--获得玩家指定位置技能id(War3中的id)
--	技能类型
--	技能位置
function mt:get_ability_id(type, slotid)
	local list = self.ability_list
	if not list then
		return nil
	end
	if not list[type] then
		return nil
	end
	return list[type][slotid]
end

--获取玩家
--	玩家索引
function Player:__call(i)
	return Player[i]
end

--清点在线玩家
function Player.count_alive()
	local count = 0
	for i = 1, 16 do
		if Player[i]:is_player() then
			count = count + 1
		end
	end
	return count
end

--一些常用事件
function Player.regist_jass_triggers()
	--玩家聊天事件
	local trg = War3.CreateTrigger(function()
		local player = Player(jass.GetTriggerPlayer())
		player:event_notify('玩家-聊天', player, jass.GetEventPlayerChatString())
	end)

	for i = 1, 16 do
		jass.TriggerRegisterPlayerChatEvent(trg, Player[i].handle, '', false)
	end

	--玩家离开事件
	local trg = War3.CreateTrigger(function()
		local p = Player(jass.GetTriggerPlayer())
		if p:is_player() then
			Player.count = Player.count - 1
		end
		p:event_notify('玩家-离开', p)
	end)

	for i = 1, 16 do
		jass.TriggerRegisterPlayerEvent(trg, Player[i].handle, jass.EVENT_PLAYER_LEAVE)
	end

	--玩家按下esc事件
	local trg = War3.CreateTrigger(function()
		local p = Player(jass.GetTriggerPlayer())
		p:event_notify('玩家-按下esc', p)
	end)

	for i = 1, 16 do
		jass.TriggerRegisterPlayerEvent(trg, Player[i].handle, jass.EVENT_PLAYER_END_CINEMATIC)
	end
end

--默认结盟
function Player.set_default_ally()
	for i = 1, 16 do
		Player[i]:set_alliance_simple(Player[16], true)
	end
end

--命令玩家选中单位
--	单位
function mt:select_unit(u)
	if self == Player.self then
		jass.ClearSelection()
		jass.SelectUnit(u.handle, true)
	end
end

--命令玩家添加选择某单位
--	单位
function mt:add_select(u)
	if self == Player.self then
		jass.SelectUnit(u.handle, true)
	end
end

--命令玩家取消选择某单位
--	单位
function mt:remove_select(u)
	if self == Player.self then
		jass.SelectUnit(u.handle, false)
	end
end

--创建玩家(一般不允许外部创建)
function Player.new(id, jPlayer)
	local p = {}
	setmetatable(p, Player)

	--初始化
	--句柄
	p.handle = jPlayer
	dbg.handle_ref(jPlayer)
	Player[jPlayer] = p
	
	--id
	p.id = id

	p.base_name = p:get_name()
	
	Player[id] = p
	return p
end

local function init()
	--存活玩家数
	Player.count = 0

	--预设玩家
	for i = 1, 16 do
		Player.new(i, jass.Player(i - 1))

		--是否在线
		if Player[i]:is_player() then
			Player.count = Player.count + 1
		end

	end

	--保留2个图标位置
	jass.SetReservedLocalHeroButtons(2)

	--结盟
	Player.set_default_ally()

	--本地玩家
	Player.self = Player(jass.GetLocalPlayer())

	--注册常用事件
	Player.regist_jass_triggers()

	init_color_word()

end

init()

return Player
