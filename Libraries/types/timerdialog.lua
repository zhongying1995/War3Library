local jass = require 'jass.common'
local Player = require 'war3library.libraries.ac.player'

local Timerdialog = {}
setmetatable(Timerdialog, Timerdialog)

local mt = {}
Timerdialog.__index = mt

--handle
mt.handle = 0

--timer handle
mt.timer_handle = 0

--最小触发计时器到期事件
mt.min_time = 0

--帧数,默认秒
mt.frame = 1*1000

--倍率
mt.time_rate = 1

--当前的时间
mt.current_time = 0

--结束的时间，默认采用倒序的最小 0
mt.finish_time = 0

--新建计时器窗口
function mt:new( time, title )
    local j_timer = jass.CreateTimer()
    local j_dialog = jass.CreateTimerDialog(j_timer)
    
    local o = {}
    setmetatable(o, o)
    o.__index = self
    
    o.timer_handle = j_timer
    o.handle = j_dialog
    o:set_time( time )
    if title then
        o:set_title(title)
    end

    return o
end

--设置标题
function mt:set_title( title )
    self.title = title
    jass.TimerDialogSetTitle(self.handle, title)
    return self
end

--设置标题文字颜色
--  rgba 三原色代码，使用百分比
function mt:set_title_color( r, g, b, a )
    local r = math.min(255, math.max(r or 255, 0))
    local g = math.min(255, math.max(g or 201, 0))
    local b = math.min(255, math.max(b or 51, 0))
    local a = math.min(255, math.max(a or 255, 0))
    jass.TimerDialogSetTitleColor(self.handle, r, g, b, a)
    return self
end

--设置计时器窗口背景色
--  rgba 三原色代码，使用百分比
function mt:set_bg_color( r, g, b, a )
    local r = math.min(255, math.max(r or 255, 0))
    local g = math.min(255, math.max(g or 201, 0))
    local b = math.min(255, math.max(b or 51, 0))
    local a = math.min(255, math.max(a or 255, 0))
    jass.TimerDialogSetTimeColor(self.handle, r, g, b, a)
    return self
end

--显示计时器创建
--  [显示/隐藏]
--  [目标玩家/全玩家]
function mt:show( is_show, player )
    if is_show == nil then
        is_show = true
    end
    if player then
        if Player.self == player then
            jass.TimerDialogDisplay(self.handle, is_show)
        end
    else
        jass.TimerDialogDisplay(self.handle, is_show)
    end
    return self
end

--设置当前的运行时间
function mt:set_time( time )
    self.current_time = math.max(0, time or 0)
    jass.TimerStart(self.timer_handle, self.current_time, false, nil)
    jass.PauseTimer(self.timer_handle)
    return self
end

--获取当前的运行时间
function mt:get_time()
    return self.current_time
end

--获取结束时间
function mt:get_finish_time()
    return self.finish_time
end

--获取剩余的时间
function mt:get_remaining_time()
    return math.abs(self:get_finish_time() - self:get_time())
end

--计时器窗口开始运行
--  结束时间,默认为0，执行倒序
function mt:run( finish_time )
    self.finish_time = math.ceil(math.max(0, finish_time or 0))

    --顺序执行
    if self.finish_time > self.current_time then
        self.is_reciprocal = false
    elseif self.finish_time < self.current_time then
    --倒序执行
        self.is_reciprocal = true
    else
        self.is_reciprocal = true
        if self.on_pulse then
            self:on_pulse()
        end
        if self.on_expire then
            self:on_expire()
        end
        return self
    end
    if self.life_timer then
        self.life_timer:resume()
        return self
    end
    
    self.life_timer = ac.loop(self.frame / self.time_rate, function(t)
        if self.on_pulse then
            self:on_pulse()
        end
        if self.is_reciprocal then
            self.current_time = self.current_time - 1
        else
            self.current_time = self.current_time + 1
        end
        jass.TimerStart(self.timer_handle, self.current_time, false, null)
        jass.PauseTimer(self.timer_handle)
        if self.current_time == self.finish_time then
            self.life_timer:pause()
            if self.on_expire then
                self:on_expire()
            end
        end
    end)
    self.life_timer:on_timer()
    return self
end

--暂停计时器
--  暂停/继续
function mt:pause(pause)
    if self.life_timer then
        if pause == nil or pause then
            self.life_timer:pause()
        else
            self.life_timer:resume()
        end
        return true
    end
    return false
end

--需要重写的方法
mt.on_expire = nil

--设置到期后的回调
function mt:set_on_expire_listener( f )
    self.on_expire = f
    return self
end

--需要重写的方法
mt.on_pulse = nil

--设置每一帧的回调
function mt:set_on_pulse_listener( f )
    self.on_pulse = f
    return self
end

--移除
function mt:remove(  )
    if self.is_removed then
        return
    end
    self.is_removed = true
    jass.DestroyTimer(self.timer_handle)
    jass.DestroyTimerDialog(self.handle)
end


return Timerdialog