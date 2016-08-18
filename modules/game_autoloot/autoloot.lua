autoLootWindow = nil
updateButton = nil
slotCurrent = nil
itemsView = {}
autoLootSettings = {}


local opcode_autoloot = 102

function init()

	g_ui.importStyle('lootedItem')
	autoLootWindow = g_ui.loadUI('autoloot', modules.game_interface.getMapPanel())
	autoLootWindow:setVisible(false)

	updateButton = autoLootWindow:getChildById("updateButton")
	moneyCheckBox = autoLootWindow:getChildById("moneyCheckBox")
	stonesCheckBox = autoLootWindow:getChildById("stonesCheckBox")
	
	mouseGrabberWidget = g_ui.createWidget('UIWidget')
	mouseGrabberWidget:setVisible(false)
	mouseGrabberWidget:setFocusable(false)
	mouseGrabberWidget.onMouseRelease = onChooseItemMouseRelease

	ProtocolGame.registerExtendedOpcode(opcode_autoloot, parseOpcode)

	load()
	connect(g_game, { onGameStart = load })
end

function terminate()
	autoLootWindow:destroy()
	mouseGrabberWidget:destroy()

	ProtocolGame.unregisterExtendedOpcode(opcode_autoloot, parseOpcode)

	disconnect(g_game, { onGameStart = load })


end

function toggle()
	if autoLootWindow:isVisible() then
		autoLootWindow:hide()
	else
		autoLootWindow:show()
	end
end

function startChooseItem(id)
	slotCurrent = autoLootWindow:getChildById(id)

	if g_ui.isMouseGrabbed() then return end
	mouseGrabberWidget:grabMouse()
	g_mouse.pushCursor('target')
end

function onChooseItemMouseRelease(self, mousePosition, mouseButton)
	local item = nil
	if mouseButton == MouseLeftButton then
		local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
		if clickedWidget and clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
			item = clickedWidget:getItem()
		end
	end
	if item then
		slotCurrent:setItemId(item:getId())
	end

	updateButton:enable()

	g_mouse.popCursor('target')
	self:ungrabMouse()
	return true
end

function clearAll()
	for i = 1, 10 do 
		local item = autoLootWindow:getChildById("slot"..i)
		item:clearItem()
	end

	moneyCheckBox:setChecked(false)
	stonesCheckBox:setChecked(false)
	table.clear(autoLootSettings)
	updateButton:enable()
end

function setStone()
	updateButton:enable()
	stonesCheckBox:setChecked(not stonesCheckBox:isChecked())
end

function setMoney()
	updateButton:enable()
	moneyCheckBox:setChecked(not moneyCheckBox:isChecked())
end

function save()
	autoLootSettings = g_settings.getNode('game_autoloot') or {}
	settings = autoLootSettings
	local char = g_game.getCharacterName()
	if not settings[char] then
		settings[char] = {}
	end

	settings = settings[char]
	table.clear(settings)
	for slot = 1, 10 do 
		settings["slot"..slot] = autoLootWindow:getChildById("slot"..slot):getItemId()
	end

	settings["moneyCheckBox"] = moneyCheckBox:isChecked()
	settings["stonesCheckBox"] = stonesCheckBox:isChecked()

	g_settings.setNode('game_autoloot', autoLootSettings)
  	g_settings.save()

  	autoLootSettings = settings
end

function load()
	autoLootSettings = g_settings.getNode('game_autoloot') or {}

	local char = g_game.getCharacterName()
	if char and autoLootSettings[char] then
		autoLootSettings = autoLootSettings[char]
		for slot=1,10 do
			autoLootWindow:getChildById("slot"..slot):setItemId(autoLootSettings["slot"..slot])
		end

		moneyCheckBox:setChecked(autoLootSettings.moneyCheckBox)
		stonesCheckBox:setChecked(autoLootSettings.stonesCheckBox)
	end
	 if g_game.isOnline() then
  updateList()
 end
end

function updateList()
	save()

	local items = {}

	for i=1, 10 do 
		local itemid = autoLootSettings["slot"..i]
		if type(itemid) == "number" and itemid > 0 then
			items[i] = itemid
	    end
	end
	local items_str = table.concat(items, "|")
	local buffer = "<" .. (items_str:len() > 0 and  items_str or "null").. ">\n<" .. tostring(autoLootSettings.moneyCheckBox) .. "><" .. tostring(autoLootSettings.stonesCheckBox)..">"
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(opcode_autoloot, buffer)
	end

	updateButton:disable()
end

function parseOpcode(protocol, opcode, buffer)
	local msg = InputMessage.create()
	msg:setBuffer(buffer)

	local size = msg:getMessageSize()/3
	
	local items = {}
	for i = 1, size do
		local itemid = msg:getU16()
		local count = msg:getU8()
		table.insert(items, {itemid = itemid, count = count})
	end

	local itemsViewSize = 0
	for _, bool in pairs(itemsView) do 
		if bool then 
			itemsViewSize = itemsViewSize + 1
		end
	end

	local countItems = itemsViewSize + #items
	local window_width = modules.game_interface.getMapPanel():getWidth()
	local total_size = countItems * 32
	local margin = (window_width - total_size)/2 - 16
	if modules.game_interface.getLeftPanel():isOn() then
		margin = margin + modules.game_interface.getLeftPanel():getWidth()
	end

	local it = 1
	for widgetID, status in pairs(itemsView) do 
		if status then
			local item = modules.game_interface.getRootPanel():recursiveGetChildById(widgetID)
			item:move(margin + 32 * (it-1), 0)

			it = it + 1
		end
	end 

	for _, data in pairs(items) do 
		local itemid  = data.itemid
		local count = data.count
		local item = g_ui.createWidget('LootedItem', modules.game_interface.getMapPanel())
		itemsView[item:getId()] = true
		item:move(margin + 32 * (it-1), 0)
		item:setItemId(itemid)
		item:setItemCount(count)
		g_effects.fadeOut(item, 6000)
		scheduleEvent(function()
			itemsView[item:getId()] = nil
			item:destroy()
		end, 6000)

		it = it + 1
	end

end