local partyWindow = nil
local radioMembers = nil
local membersPanel = nil
local actived = false

local max_partners = 6

function init()
	partyWindow = g_ui.loadUI('party', modules.game_interface.getRootPanel())
	membersPanel = partyWindow:getChildById('partyMembers')
	partyWindow:move(250, 250)

	connect(LocalPlayer, {onShieldChange = onShieldChange})

	ProtocolGame.registerOpcode(GameServerOpcodes.GameServerPartyMembers, parseMembers)	
end

function terminate()
	partyWindow:destroy()
	membersPanel = nil
	radioMembers = nil

	disconnect(LocalPlayer, {onShieldChange = onShieldChange})

	ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerPartyMembers, parseMembers)
end

function parseMembers(protocol, msg)
	local size = msg:getU8()
	local partyMembers = {}
	for i = 1, size do 
		local name = msg:getString()
		local healthPercent = msg:getU8()
		local manaPercent = msg:getU8()
		local level = msg:getU16()
		local vocation = msg:getU8()
		partyMembers[name] = {level = level, mana = manaPercent, health = healthPercent, name = name, vocation = vocation }
	end
	updateMembersList(partyMembers)
end

function updateMembersList(partyMembers)

	if radioMembers then
		radioMembers:destroy()
	end

	membersPanel:destroyChildren()

	if not actived then
		return
	end

	radioMembers = UIRadioGroup.create()

	local size = 0

	for name, attr in pairs(partyMembers) do
		local player = g_ui.createWidget('PartnerWidget', membersPanel)
		for key, value in pairs(attr) do
			local sub = player:getChildById(key)
			if key == "mana" or key == "health" then
				sub:setPercent(value)
			elseif key == "name" or key == "level" then
				sub:setText(value)
			elseif key == "vocation" then
				local path = getPath(value)
				player:setImageSource(path)
			end
		end
		size = size + 1
		radioMembers:addWidget(player)
	end
	local len = math.min(size, max_partners)
	partyWindow:resize(164, 20 + len*32)
	membersPanel:resize(164, len*32)
	show()
end

function getPath(vocation)
  if vocation > 4 and vocation < 9 then
    vocation = vocation - 4
  end

  local elements = { [1] = "p_wind" , [2] = "p_earth", [3] = "p_water", [4] = "p_fire", [9] = "p_avatar" }
  local path = "/images/game/elements/"

  return path .. elements[vocation]
end

function onShieldChange(player, shield)
	if shield == ShieldNone then
		actived = false
		hide()
	else
		actived = true
	end
end

function hide()
	partyWindow:hide()
end

function show()
	if not actived then return end

	partyWindow:show()
end

function toggleMembers( self )
	if self:isOn() then
		self:setImageSource('/images/ui/button_maximize')
		self:setOn(false)
		membersPanel:hide()
		partyWindow:resize(164, 20)
	else 
		self:setImageSource('/images/ui/button_minimize')
		self:setOn(true)
		membersPanel:show()
		partyWindow:resize(164, 20 + membersPanel:getHeight())
	end
end