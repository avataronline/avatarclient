spellWindow = nil
radioSpells = nil
spellsPanel = nil
selectedSpell = nil
learnAllButton = nil
moneyLabel = nil
playerMoney = 0
initialized = false

function init()

	spellWindow = g_ui.displayUI('learn')
  	spellWindow:setVisible(false)
  	spellsPanel = spellWindow:recursiveGetChildById('spellsPanel')

  	learnAllButton = spellWindow:recursiveGetChildById('learnAllButton')
  	learnButton = spellWindow:recursiveGetChildById('learnButton')
  	moneyLabel = spellWindow:recursiveGetChildById('money')

	connect(g_game, { onGameEnd = hide,
                    onOpenNpcTrade = onOpenNpcTrade,
                    onCloseNpcTrade = onCloseNpcTrade,
                    onPlayerGoods = onPlayerGoods } )

	initialized = true
end

function terminate()
  spellWindow:destroy()
  disconnect(g_game, {  onGameEnd = hide,
                        onOpenNpcTrade = onOpenNpcTrade,
                        onCloseNpcTrade = onCloseNpcTrade,
                        onPlayerGoods = onPlayerGoods } )
end

function hide()
	spellWindow:hide()
end

function onOpenNpcTrade(items)
	
	for key,item in pairs(items) do
		local spell = string.match(item[2], "|SPELL|(.+)")
		if spell == "null" then
 			table.remove(items, key)
end
		if not spell then
	    	return
		end
	end
	selectedSpell = nil
	spellWindow:setVisible(true)
	spellsPanel:destroyChildren()

	if radioSpells then
		radioSpells:destroy()
	end

	radioSpells = UIRadioGroup.create()
	table.sort(items, function (a, b) return b[4] > a[4] end)
	for key, item in pairs(items) do 
		local spellBox = g_ui.createWidget('SpellBox', spellsPanel)

		local spell = string.match(item[2], "|SPELL|(.+)")
		local price = item[5]
		local level = item[4]
		local itemPtr = item[1]
		spellBox.spell = item

		local text = ''
		text = text .. spell .. string.format("\n(L.%d)", level)
		text = text .."\n" .. price  .. " coppers"
		spellBox:setText(text)

		local spellWidget = spellBox:getChildById('item')
		spellWidget:setItem(itemPtr)

		local bool = canLearn(level, price)
		spellBox:setOn(bool)
		spellBox:setEnabled(bool)
		spellWidget:setOn(bool)
		spellWidget:setEnabled(bool)

		radioSpells:addWidget(spellBox)
	end
 end 

function learnSpell()
	g_game.buyItem(selectedSpell[1], 1, true, false)
end

function learnAllSpells()
	local items = spellsPanel:getChildCount()
	for i=1,items do
		local spellBox = spellsPanel:getChildByIndex(i)
		if spellBox:isOn() then
			local item = spellBox.spell
			if item then
				g_game.buyItem(item[1], 1, true, false)
			end
		end
	end
end

function selectSpell( widget )
	if widget:isChecked() then
		selectedSpell = widget.spell
		learnButton:setEnabled(true)
	end
end

function canLearn(level, price)
	local player = g_game.getLocalPlayer()
	local ret = true
	if player:getLevel() < level then
		ret = false
	elseif playerMoney < price then
		ret = false
	end 
	return ret
end

function onPlayerGoods(money, items)
	playerMoney = money
	moneyLabel:setText(string.format(moneyLabel.baseText, money))
	refreshPlayerGoods()
end

function refreshPlayerGoods()
	if not initialized then return end

	local items = spellsPanel:getChildCount()
	for i=1,items do
		local spellBox = spellsPanel:getChildByIndex(i)
		local item = spellBox.spell
		local spellWidget = spellBox:getChildById('item')

		local bool = canLearn(item[4], item[5])
		spellBox:setOn(bool)
		spellBox:setEnabled(bool)
		spellWidget:setOn(bool)
		spellWidget:setEnabled(bool)
	end
end

function closeNpcTrade()
	g_game.closeNpcTrade()
	hide()
end

function onCloseNpcTrade()
	hide()
end