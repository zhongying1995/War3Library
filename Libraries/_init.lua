print('------------------')
print('>>>>>>>>开始加载Libraries层库代码')
print('开始加载ac层库代码')

require 'war3library.libraries.ac._init'

print('ac层库代码加载完毕')
print('开始加载types层库代码')

require 'war3library.libraries.types._init'

print('types层库代码加载完毕')

require 'war3library.libraries.interact._init'
require 'war3library.libraries.test._init'

print('Libraries层库代码加载完毕<<<<<<<<')
print('------------------')