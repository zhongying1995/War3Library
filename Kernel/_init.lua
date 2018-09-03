print('------------------')
print('hello, here is kernel floor')
print('------------------')
local std_print = print

function print(...)
	std_print(('[%.3f]'):format(os.clock()), ...)
end

local function init()

	require 'Kernel.init'
	require 'Kernel.util._init'
	require 'Kernel.war3._init'
	print('->_<-Kernel层库加载完毕！->_<-')

end

init()
