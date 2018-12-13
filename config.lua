return{
--这些配置都是可选的

    --伤害系统的马甲[ndog]
    SYS_DAMAGE_DUMMY_UNIT_ID = nil,

    --英雄模块的额外属性技能[Aamk]
    SYS_HERO_ATTRIBUTE_ABIL_ID = nil,
    
    --英雄模块的英雄变身技能[AEme]
    SYS_UNIT_TRANSFORM_ABIL_ID = nil,

    --物品模块的占位物品[ches]
    SYS_ITEM_PLACEHOLDER_ID = nil,

    --单位模块的飞行技能[Arav]
    SYS_UNIT_FLYING_ABIL_ID = nil,

    --行为限制,攻击[Agho]
    SYS_RESTRICTION_ATTACK_ABIL_ID = nil,

--这些数据必须配置好
    --地图名字，用于日志生成路径
	SYS_MAP_NAME = 'JustForLiving',
	
	--一个无模型的单位id，使用于types层的mover、path_block模块
    SYS_NO_MODEL_UNIT_ID = 'eZ00',

    --尸体骨头衰退时间，由物编的平衡常数确定，用于单位的移除
    SYS_BONE_DECAY_TIME = 88,

    --视野技能[AIsi]，用于增加单位视野
    SYS_SIGHT_ABILITY = 'AZ00',

    --幻象权杖[AIil]，用于单位模块创建幻象
    SYS_ILLUSION_ABILITY = 'AZ01',

    --ac.dummy单位马甲
    SYS_AC_UNIT_DUMMY_ID = 'eZ01',

    --攻击之爪[AItx],单位绿色攻击的技能，用于单位属性模块
    SYS_UNIT_ATTRIBUTE_ADD_ATTACK_ABILITY_ID = 'AZ02',

    --指环[AId2],单位绿色护甲的技能，用于单位属性模块
    SYS_UNIT_ATTRIBUTE_ADD_DEFENCE_ABILITY_ID = 'AZ05',

    --单位允许的极值移动速度，往往由物编确定，用于单位属性模块
    SYS_UNIT_MIN_MOVE_SPEED = 150,
    SYS_UNIT_MAX_MOVE_SPEED = 522,

    --特效系统的马甲
    SYS_EFFECT_DUMMY_UNIT_ID = 'eZ02',

    --单位行为限制，隐身，Agho
    SYS_RESTRICTION_STEALTH_ABIL_ID = 'AZ03',

    --单位行为限制，魔法免疫，Amim
    SYS_RESTRICTION_SPELLED_ABIL_ID = 'AZ04',

    --单位行为限制，无敌的，Az06
    SYS_RESTRICTION_GOD_ABIL_ID = 'AZ06',
}