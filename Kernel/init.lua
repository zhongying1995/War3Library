--ac:全局表，用于方便使用某些功能
ac = {}
setmetatable(ac, {__index = function ( self, key )
    Log.error('尝试在ac中访问不存在的值:' .. key)
end})
--Router：全局表，用于返回核心层的模块、framework层的模块，而不是通过require来获取
Router = {}
setmetatable(Router, {__index = function ( self, key )
    Log.error('尝试在Rount中访问不存在的值:' .. key)
end})