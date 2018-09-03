

--有些数据必须配置好，底层需要这些全局数据
local function config(  )

	--地图名字，用于日志生成路径
	MAP_NAME = 'JustForLiving'
	
	--一个无模型的单位id，使用于Framework层的mover、path_block模块
    NO_MODEL_UNIT_ID = nil
    
end


local function init(  )
    print('------------------')
    print('开始加载底层库代码')
    print('++++++++++++++++++')

    config()

    require 'kernel._init'
    require 'libraries._init'
    require 'framework._init'
    print('++++++++++++++++++')
    print('底层库代码加载完毕')
    print('------------------')
end
init()