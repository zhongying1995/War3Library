
local std_print = print

function print(...)
	std_print(('[%.3f]'):format(os.clock()), ...)
end

local function init()

	print('------------------')
	print('>>>>>>>>开始加载Kernel层库代码')
	require 'war3library.kernel.init'
	require 'war3library.kernel.util._init'
	require 'war3library.kernel.war3._init'
	print('Kernel层库代码加载完毕<<<<<<<<')
	print('------------------')

end

init()
