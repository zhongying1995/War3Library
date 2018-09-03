
local std_print = print

function print(...)
	std_print(('[%.3f]'):format(os.clock()), ...)
end

local function init()

	print('------------------')
	print('>>>>>>>>开始加载Kernel层库代码')
	require 'Kernel.init'
	require 'Kernel.util._init'
	require 'Kernel.war3._init'
	print('Kernel层库代码加载完毕<<<<<<<<')
	print('------------------')

end

init()
