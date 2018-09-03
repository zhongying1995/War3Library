local jass = require 'jass.common'
local debug = require 'jass.debug'

War3 = {}
--返回war的trg
function War3.CreateTrigger(call_back)
	local j_trg = jass.CreateTrigger()
	debug.handle_ref(j_trg)
	jass.TriggerAddAction(j_trg, call_back)
	return j_trg
end

function War3.DestroyTrigger(j_trg)
	jass.DestroyTrigger(j_trg)
	debug.handle_unref(j_trg)
end
