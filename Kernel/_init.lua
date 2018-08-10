print('------------------')
print('hello, here is kernel floor')
print('------------------')
local std_print = print

function print(...)
	std_print(('[%.3f]'):format(os.clock()), ...)
end

local function main()

	require 'Kernel.util._init'
	require 'Kernel.war3._init'
	print('->_<-加载基层库完毕！')

end

main()
