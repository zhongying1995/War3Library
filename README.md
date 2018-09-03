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


-一些全局的字段
    -ac：方便使用
    -Rount：路由，可获取所有的底层模块
    -War3：用于创建war3触发
    -Log：log信息功能
    -Base：整数id与字符串id转换