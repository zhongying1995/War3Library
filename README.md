# War3Library
-开发需知
    -本库的主要目的是快速开发，不追求对全地图进行模拟
    -能同时适配lua与war3

-kernel:
    -war3/util层作为工具层，不能随意改动
-Libraries:
    -ac层的模块相互独立，删除任意一个不会影响同级层,只会对其上层造成影响
    -types:核心层的上层
    -register：核心层注册层，该层注册了所有跟war3事件相关的接口
-Framework:
    -该层表示应用框架层，本质上属于Libraries的上层，也属于地图内业务逻辑层
        的真子集；
    -用于抽象某种通用性极强的逻辑功能，例如发兵，寻路，野怪刷新等
    -该层的模块应该由业务逻辑层去加载


-一些全局的字段
    -ac：方便使用
    -Rount：路由，可获取所有的底层模块
    -War3：用于创建war3触发
    -Log：log信息功能
    -Base：整数id与字符串id转换

-使用须知：
    在介入本库时，_init文件中有一个config方法，里面的一些全局字段需要被配置，而有一些
        字段，系统会赋予默认值，若不想使用自带的默认值，则需要自行配置

-开发文档：
    -关于ac：
        -注册：
            -事例：
                ac.buff[name]{}
                ac.skill[name]{ [war3_id == xx] }
                ac.unit[name]{war3_id = xx}
                ac.hero[name]{war3_id = xx}
                ac.item[name]{war3_id = xx}
            -以上方式用于注册相关的具体类，其中unit/hero/item注册时必须要传入war3_id字段，
                skill的则为可选项（传入war3_id时，单位添加该skill技能，会添加对应的魔兽技能）
            -5者设计相同，如ac.buff[name]返回一个注册函数，该函数的参数为数据表，执行注册函数后，
                会返回对应的具体类，该类继承自Buff，当单位添加一个指定的Buff时，会根据对应的名字去查找
                对应的具体类，若没有找到Buff则抛出异常  
        -方便使用：
            -事例：
                ac.point(x, y)
                ac.timer(time, times, function() end)
                ac.loop(time, function(t) end)
                ac.wait(time, function() end)
                ac.player[x]
                ac.mover.line{}
                ac.mover.target{}
           
