local attributesWindow = nil
local attributesToggleButton = nil
local extended_opcode = 108

local SKILL = {
    FIRST = 1;
	CRITICAL = 1;
	REGEN = 2;
	DODGE = 3;
	DRAIN = 4;
	LAST = 4;
}

local params = {
	[SKILL.CRITICAL] 	= { 50, 05, { 1, 2, 4, 6, 8, 10, 12, 14, 16, 20 }, "skillCritical"};
	[SKILL.REGEN] 			= { 50, 05, { 1, 2, 4, 6, 8, 10, 12, 14, 16, 20 }, "skillRegen"};
	[SKILL.DODGE] 		= { 50, 05, { 1, 2, 4, 6, 8, 10, 12, 14, 16, 20 }, "skillDodge"};
	[SKILL.DRAIN] 		= { 50, 05, { 1, 2, 4, 6, 8, 10, 12, 14, 16, 20 }, "skillDrain"};	
}

function init()
	attributesWindow = g_ui.loadUI('attributes', modules.game_interface.getRightPanel())
	attributesToggleButton = modules.client_topmenu.addRightGameToggleButton('attributesToggleButton', tr('Attributes Window'), '/images/topbuttons/attributes', toggle)
   	attributesToggleButton:setOn(false)

	connect(g_game, {onGameStart = requestInfo})

	ProtocolGame.registerExtendedOpcode(extended_opcode, parseOpcode)
	
	if g_game.isOnline() then
		requestInfo()
	end 
    attributesWindow:setup()
	attributesWindow:disableResize()
end

function terminate()

	ProtocolGame.unregisterExtendedOpcode(extended_opcode, parseOpcode)
	disconnect(g_game, {onGameStart = requestInfo})
	attributesWindow:destroy()
	attributesWindow = nil
end

function toggle()
 	if attributesToggleButton:isOn() then
 		attributesToggleButton:setOn(false)
 		attributesWindow:hide()
 	else 
 		attributesWindow:show()
 		attributesToggleButton:setOn(true)
 	end
 end
 
 function onMiniWindowClose()
  	attributesToggleButton:setOn(false)
end

function requestInfo()
	-- 0x00 - request info opcode
	local msg = OutputMessage.create()
	msg:addU8(0x00)
	
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(extended_opcode, msg:getBuffer())
	end		
end

function sendIncreaseAttribute( attributes )
	-- 0x01 - increase attributes opcode
	local protocol = g_game.getProtocolGame()
	if protocol then
		local msg = OutputMessage.create()
		msg:addU8(0x01)
		msg:addU8(#attributes)

		for key, value in pairs(attributes) do 
			msg:addU8(key)
			msg:addU8(value)
		end

		protocol:sendExtendedOpcode(extended_opcode, msg:getBuffer())
	end
end

function parseOpcode(protocol, opcode, buffer)
	local msg = InputMessage.create()
	msg:setBuffer(buffer)

	local infos = msg:getStrTable()
	for i, v in pairs(infos) do
		local widget = attributesWindow:recursiveGetChildById(params[i] and params[i][4] or i)
		if i == "points" then
			widget:setText(string.format(widget.baseText, v))
		else 
			local current = widget:getChildById('currentSkill')
			current.value = v
			current:setText(v)
			current:setTooltip(buildTooltipMessage(i, v))
		end
	end
end

function calculateTotalCost()
	local total = 0
	for i = SKILL.FIRST, SKILL.LAST do 
		total = total + calculateCost(i)
	end
	local costLabel = attributesWindow:recursiveGetChildById('cost')
	costLabel:setText(string.format(costLabel.baseText, total))
end

function calculateCost(type)
	local total = 0
	local widget = attributesWindow:recursiveGetChildById(params[type][4])
	local currentSkill = widget:getChildById('currentSkill')
	local addSkill = widget:getChildById('addSkill')
	local skill = tonumber(currentSkill:getText())
	for i = skill + 1, skill + addSkill.value do
		total = total + params[type][3][math.ceil(i/params[type][2])]
	end

	return math.max(0, total)
end

function incrementSkill(self)
	local skillWidget = self:getParent()
	local addSkill = skillWidget:getChildById('addSkill')
	local current = skillWidget:getChildById('currentSkill')
	addSkill.value = math.min(params[skillWidget.type][1] - current.value, addSkill.value + 1)
	if addSkill.value == 0 then 
		return 
	end 
	addSkill:setText("+"..addSkill.value)
	addSkill:setTooltip(buildTooltipMessage(skillWidget.type, addSkill.value))
	calculateTotalCost()
end

function decrementSkill(self)
	local skillWidget = self:getParent()
	local addSkill = skillWidget:getChildById('addSkill')
	addSkill.value = math.max(0, addSkill.value - 1)
	if addSkill.value == 0 then
		addSkill:setText("")
		addSkill:setTooltip("")
	else
		addSkill:setText("+".. addSkill.value)
		addSkill:setTooltip(buildTooltipMessage(skillWidget.type, addSkill.value))
	end
	calculateTotalCost()
end

function applyAttributes()
	if not canUpgrade() then
		return 
	end
	local attributes = {}
	for i = SKILL.FIRST, SKILL.LAST do
		local widget = attributesWindow:recursiveGetChildById(params[i][4])
		local addSkill = widget:getChildById('addSkill')
		attributes[i] = addSkill.value
	end 
	sendIncreaseAttribute(attributes)
	clearAll()
end

function clearAll()
	for i = SKILL.FIRST, SKILL.LAST do
		local widget = attributesWindow:recursiveGetChildById(params[i][4])
		local addSkill = widget:getChildById('addSkill')
		addSkill.value = 0
		addSkill:setText("")
	end
	local costLabel = attributesWindow:recursiveGetChildById('cost')
	costLabel:setText(string.format(costLabel.baseText, 0))

end

function canUpgrade()
	local costLabel = attributesWindow:recursiveGetChildById('cost')
	local pointsLabel = attributesWindow:recursiveGetChildById('points')
	local cost = tonumber(costLabel:getText():match("(%d+)"))
	local points = tonumber(pointsLabel:getText():match("(%d+)"))
	return points >= cost 
end

function buildTooltipMessage(type, value)
	local tip = ""

	if value == 0 then
		return ""
	end 

	if type == SKILL.CRITICAL then
		tip = string.format("Critical: +%d%%\nCritical Level: +%d", 0.5 * value, value)
	elseif type == SKILL.REGEN then
		tip = string.format("Regen: +%d%%\nRegen Level: +%d", 0.5 * value, value)	
	elseif type == SKILL.DODGE then
		tip = string.format("Dodge: +%d%%\nDodge Level: +%d", 0.5 * value, value)
	elseif type == SKILL.DRAIN then
		tip = string.format("Drain: +%d%%\nDrain Level: +%d", 0.5 * value, value)			
	end
	return tip
end
