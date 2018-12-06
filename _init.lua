


local function init()
    print('------------------')
    print('开始加载底层库代码')
    print('++++++++++++++++++')

    config = require 'war3library.config'

    require 'war3library.kernel._init'
    require 'war3library.libraries._init'
    print('++++++++++++++++++')
    print('底层库代码加载完毕')
    print('------------------')
end
init()