local table_insert = table.insert
local Player = require 'war3library.libraries.ac.player'
local jass = require 'jass.common'
local table = table

local Dialog = {}

setmetatable(Dialog, Dialog)

local mt = {}
Dialog.__index = mt

mt.type = 'dialog'

function Dialog:new( data )
    setmetatable(data, data)
    data.__index = self

    data.handle = jass.DialogCreate()
    
    data:set_title()
    if data.life then
        data:set_life()
    end
    
    if data.buttons then
        data:set_buttons(data.buttons)
        data:set_default_button(data.buttons[1])
    end
    
    return data
end

function mt:set_title(title)
    title = title or self.title or ''
    jass.DialogSetMessage(self.handle, title)
    return self
end

mt.pulse = 1
--设置对话框时长
--  时长
--  频率
function mt:set_life(life, pulse)
    self.life = math.ceil(life or self.life)
    self.pulse = math.ceil( (pulse or self.pulse) * 100) / 100
    return self
end

function mt:get_style_title()
    if self.title_style then
        return self:title_style()
    else
        return self:get_default_style_title()
    end
end

function mt:set_style_title(style)
    self.title_style = style
    return self
end

function mt:get_default_style_title()
    return ('%s  [剩%.f秒]'):format(self.title, self.life or 0)
end

function mt:run()
    if not self.life or not self.pulse then
        return
    end
    if self.timer then
        self.life_timer:resume()
        return
    end
    self.life_timer = ac.loop(self.pulse * 1000, function(t)
        self.life = self.life - self.pulse
        if self.life <= 0 then
            local on_click = self:get_default_button().on_click
            local show_players = self:get_show_players_table()
            for _, player in pairs(show_players) do
                on_click(self, player)
            end
            t:pause()
        end
        self:set_title( self:get_style_title() )
    end)
    self.life_timer:on_timer()
    return self
end

function mt:pause()
    if self.life_timer then
        self.life_timer:pause()
        return true
    end
    return false
end

function mt:set_default_button(button)
    if button then
        self.default_button = button
    end
    return self
end

function mt:get_default_button()
    return self.default_button
end

function mt:get_show_players_table()
    if not self._show_players then
        self._show_players = {}
    end
    return self._show_players
end

function mt:add_button(button)
    local title = button.title or ''
    local old_on_click = button.on_click
    local key = button.key or 0
    if type(key) == 'string' then
        key = key:upper()
        title = title .. '[' .. key .. ']'
        key = key:byte()
    end
    local button_handle = jass.DialogAddButton(self.handle, title, key)
    if old_on_click then
        local on_click = function(self, player)
            old_on_click(self, player)
            self:show(player, false)
            local show_players = self:get_show_players_table()
            if table.getn(show_players) == 0 then
                self.life_timer:pause()
            end
        end
        button.on_click = on_click
        local j_trg = War3.CreateTrigger(function()
            local player = Player[jass.GetTriggerPlayer()]
            on_click(self, player)
        end)
        jass.TriggerRegisterDialogButtonEvent(j_trg, button_handle)
        if not self.buttons_trg then
            self.buttons_trg = {}
        end
        table_insert(self.buttons_trg, j_trg)
    end
    return self
end

function mt:set_buttons(buttons)
    if buttons then
        for _, button in pairs(buttons) do
            self:add_button(button)
        end
    end
    self.buttons = buttons
    return self
end

--对某玩家显示/隐藏对话框
function mt:show(player, is_show)
    if is_show == nil then
        is_show = true
    end
    
    if player == nil then
        player = Player.self
        for i = 1, 13 do
            if Player[i]:is_player() then
                local player = Player[i]
                local show_players = self:get_show_players_table()
                show_players[player] = player
            end
        end
    else
        local show_players = self:get_show_players_table()
        if is_show then
            if show_players then
                show_players[player] = player
            end
        else
            show_players[player] = nil
        end
    end
    jass.DialogDisplay(player.handle, self.handle, is_show and true)
    return self
end

--刷新多面板的显示，一般是因为增加了button
function mt:refresh()
    for p, _ in pairs(self:get_show_players_table()) do
        self:show(p, true)
    end
end

function mt:remove()
    if self.is_removed then
        return
    end
    self.is_removed = true
    if self.buttons_trg then
        for _, j_trg in pairs(self.buttons_trg) do
            jass.DestroyTrigger(j_trg)
        end
    end
    if self.life_timer then
        self.life_timer:remove()
    end
    jass.DialogDestroy(self.handle)
end

return Dialog