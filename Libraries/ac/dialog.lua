local table_insert = table.insert
local Player = require 'libraries.ac.player'
local jass = require 'jass.common'

local Dialog = {}

setmetatable(Dialog, Dialog)

local mt = {}
Dialog.__index = mt

function Dialog:new( data )
    setmetatable(data, data)
    data.__index = self

    data.handle = jass.DialogCreate()

    data:set_title()
    if data.buttons then
        data:add_buttons(data.buttons)
    end
    
    return data
end

function mt:set_title(title)
    self.title = title or self.title
    jass.DialogSetMessage(self.handle, self.title)
    return self
end

function mt:add_button(button)
    local title = button.title or ''
    local on_click = button.on_click
    local key = button.key or 0
    if type(key) == 'string' then
        key = key:upper()
        title = title .. '[' .. key .. ']'
        key = key:byte()
    end
    local button_handle = jass.DialogAddButton(self.handle, title, key)
    if on_click then
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

function mt:add_buttons(buttons)
    if buttons then
        for _, button in pairs(buttons) do
            self:add_button(button)
        end
    end
    return self
end

function mt:show(player, is_show)
    if is_show == nil then
        is_show = true
    end
    if player == nil then
        player = Player.self
    end
    jass.DialogDisplay(player.handle, self.handle, is_show and true)
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
    jass.DialogDestroy(self.handle)
end

return Dialog