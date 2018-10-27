--转换256进制整数
--base在lua/base中创建
-- base = {}
base.id2s = {}
base.s2id = {}

local function id2string(a)
	local s1 = math.floor(a/256/256/256)%256
	local s2 = math.floor(a/256/256)%256
	local s3 = math.floor(a/256)%256
	local s4 = a%256
	local r = string.char(s1, s2, s3, s4)
	base.id2s[a] = r
	base.s2id[r] = a
	return r
end

function base.id2string(a)
	return base.id2s[a] or id2string(a)
end

local function string2id(a)
	local n1 = string.byte(a, 1) or 0
	local n2 = string.byte(a, 2) or 0
	local n3 = string.byte(a, 3) or 0
	local n4 = string.byte(a, 4) or 0
	local r = n1*256*256*256+n2*256*256+n3*256+n4
	base.s2id[a] = r
	base.id2s[r] = a
	return r
end

function base.string2id(a)
	return base.s2id[a] or string2id(a)
end