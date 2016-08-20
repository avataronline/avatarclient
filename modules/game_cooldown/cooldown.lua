cooldownBar = nil
cooldownBarTop = nil
icons = {}
local opcode = 101

function init()
	cooldownBar = g_ui.loadUI('cooldown', modules.game_interface.getRightPanel())
	cooldownBarTop = modules.client_topmenu.addRightGameToggleButton('cooldownBarTop', tr('Cooldown Window'), '/images/topbuttons/cooldowns', toggle)

	connect(g_game, { onGameEnd = hide, 
						onGameStart = requestInfo })
	connect(LocalPlayer, { onLevelChange = onLevelChange })

	ProtocolGame.registerExtendedOpcode(opcode, parseOpcode)
	if g_game.isOnline() then
		requestInfo()
	end

	cooldownBar:setup()
	cooldownBar:disableResize()

end

function terminate()
	cooldownBar:destroy()

	disconnect(g_game, {onGameEnd = clean})
	disconnect(LocalPlayer, { onLevelChange = onLevelChange })

	ProtocolGame.unregisterExtendedOpcode(opcode, parseOpcode)
end

function hide()
	cooldownBar:setVisible(false)
end

function show()
	cooldownBar:setVisible(true)
end

function toggle()
	if cooldownBarTop:isOn() then
   		hide()
    	cooldownBarTop:setOn(false)
  	else
    	show()
    	cooldownBarTop:setOn(true)
  	end
end

function requestInfo()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(opcode, "")
	end
end

function onLevelChange(player, value, percent)
	local level = player:getLevel()
	for i = 1, #icons do 
		local progress = icons[i].proWid
		if not icons[i].event then
			if not (icons[i].spellname == "Buy" or icons[i].spellname == "Secret") then
				if level >= icons[i].level then
					progress.onClick = function () g_game.talk(icons[i].spellname) end
					progress:setPercent(100)
					progress:setColor("#FFFFFF")
					progress:setText("")
				else 
					progress:setPercent(0)
					progress:setColor('#FF00FF')
					progress.onClick = function () end
					progress:setText("L"..icons[i].level)
				end
			end
		end
	end
end

function parseOpcode(protocol, opcode, buffer)
	local key = string.match(buffer, "key=|(.-)|\n")
	buffer = string.gsub(buffer, "key=|"..key.."|\n", "")
	if key == "allcds" then
		createIcons(buffer)
	elseif key == "set" then
		local spellname = string.match(buffer, "cd=|(.-)|\n")
		for _, ico in pairs(icons) do 
			if ico.spellname == spellname then
				local time = tonumber(ico.time)
				local ticks = time > 99 and 1000 or 100
				--local perc = time > 99 and 100/time or 10/time
				local perc = time > 99 and 0/time or 0/time
				startCooldown(ico.proWid, time, perc, ticks, true)
			end
		end
	elseif key == "unlock" then
		local index, spellname = string.match(buffer, "spell=|(%d+)|(.-)|\n")
		index = tonumber(index)
		if icons[index] then
			local progress = icons[index].proWid
			icons[index].spellname = spellname
			progress.onClick = function () g_game.talk(spellname) end
			progress:setPercent(100)
			progress:setColor("#FFFFFF")
			progress:setText("")
			
		end
	end
end

function startCooldown(widget, time, perc, ticks, start)
	local id = tonumber(widget:getId():match("(%d+)"))
	if start then
		widget:setPercent(0)
		widget.onClick = function() end
		if icons[id].event then
			removeEvent(icons[id].event)
			icons[id].event = nil
		end
	else 
		widget:setPercent(widget:getPercent() + perc)
	end 

	if time > 0 then
		widget:setText(string.format((time % 1 ~= 0) and "%.1f" or "%d", time))

		if time < 99 and ticks == 1000 then
			ticks = 100
			--perc = 10/icons[id].time
		end

		time = time - (ticks/1000)
		icons[id].event = scheduleEvent(function() startCooldown(widget, time, perc, ticks) end, ticks)
	else
		widget.onClick = function ()
			g_game.talk(icons[id].spellname)
		end
		icons[id].event = nil
		widget:setPercent(100)
		widget:setText("")
	end
	return icons[id].event
end

function createIcons(buffer)
	if cooldownBar then
		cooldownBar:getChildById('content'):destroyChildren()
		icons = {}
	end

	local pattern = "|(.-)|(%d+)|(%d+)|(%d+)|(.-)|\n"
	local i = 1
	for spellname, time, icon, level, desc in string.gmatch(buffer, pattern) do
		icons[i] = {spellname = spellname, time = time, icon = icon, level = tonumber(level), icoWId = nil, proWid = nil, desc = desc}
		i = i + 1
	end

	for i = 1, #icons do 
		local icon = g_ui.createWidget('SpellIcon', cooldownBar:getChildById('content'))
		local progress = g_ui.createWidget('SpellProgress', icon)
		icons[i].icoWid, icons[i].proWid = icon, progress
		icon:setId('I'..i)
		icon:setItemId(icons[i].icon)
		progress:setId('P'..i)
		progress:fill(icon:getId())
		progress:setTooltip(icons[i].desc)

		local player = g_game.getLocalPlayer()

		if player:getLevel() >= icons[i].level then
			progress.onClick = function () g_game.talk(icons[i].spellname) end
		else 
			progress:setPercent(0)
			progress:setColor('#FF00FF')
			progress.onClick = function () end
			progress:setText("L"..icons[i].level)
		end

		if icons[i].spellname == "Buy" or icons[i].spellname == "Secret" then
			progress:setPercent(0)
			progress:setColor('#FF00FF')
			progress.onClick = function () end
			progress:setText(icons[i].spellname == "Buy" and "BUY" or "?")
		end
	end

	--cooldownBar:setHeight(50 + math.ceil(#icons/4) * 37)
	cooldownBar:setHeight(37 + math.ceil(#icons/4) * 37)
	show()
	cooldownBarTop:setOn(true)
end