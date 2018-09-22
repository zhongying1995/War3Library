
--这些配置都是可选的
local function optional_config()

    --伤害系统的马甲[ndog]
    SYS_DAMAGE_DUMMY_UNIT_ID = nil

    --特效系统的马甲[nalb]
    SYS_EFFECT_DUMMY_UNIT_ID = nil

    --英雄模块的额外属性技能[Aamk]
    SYS_HERO_ATTRIBUTE_ABIL_ID = nil
    
    --英雄模块的英雄变身技能[AEme]
    SYS_HERO_TRANSFORM_ABIL_ID = nil

    --物品模块的占位物品[ches]
    SYS_ITEM_PLACEHOLDER_ID = nil

    --单位模块的飞行技能[Arav]
    SYS_UNIT_FLYING_ABIL_ID = nil

end

--这些数据必须配置好
local function indispensable_config()
    --地图名字，用于日志生成路径
	SYS_MAP_NAME = 'JustForLiving'
	
	--一个无模型的单位id，使用于Framework层的mover、path_block模块
    SYS_NO_MODEL_UNIT_ID = 'eZ00'

    --尸体骨头衰退时间，由物编的平衡常数确定，用于单位的移除
    SYS_BONE_DECAY_TIME = 88

    --视野技能[AIsi]，用于增加单位视野
    SYS_SIGHT_ABILITY = 'AZ00'

    --幻象权杖[AIil]，用于单位模块创建幻象
    SYS_ILLUSION_ABILITY = 'AZ01'

    --ac.dummy单位马甲
    SYS_AC_UNIT_DUMMY_ID = 'eZ01'

    --攻击之爪[AItx],单位绿色攻击的技能，用于单位属性模块
    SYS_UNIT_ATTRIBUTE_ADD_ATTACK_ABILITY_ID = 'AZ02'

    --单位允许的极值移动速度，往往由物编确定，用于单位属性模块
    SYS_UNIT_MIN_MOVE_SPEED = 150
    SYS_UNIT_MAX_MOVE_SPEED = 522
end

--底层需要的一些数据
local function config()
    indispensable_config()
    optional_config()
end


local function init()
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