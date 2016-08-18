local cauldronWindow = nil
local pos = nil
local recipesBox = nil
local cancelBox = nil
local recipes = {}

function init()

	connect(Container, { onOpen = onContainerOpen,
                       onClose = onContainerClose,
                       onSizeChange = onContainerChangeSize,
                       onUpdateItem = onContainerUpdateItem })
end

function terminate()
	disconnect(Container, { onOpen = onContainerOpen,
							onClose = onContainerClose,
							onSizeChange = onContainerChangeSize,
                          	onUpdateItem = onContainerUpdateItem })
	
	destroyCauldron()

end

function setRecipe( combobox, text, data )
	cauldronWindow:getChildById('potionName'):setText(text)
	cauldronWindow:getChildById('description'):setText(recipes[text].description)
	cauldronWindow:getChildById('quantityScroll'):setMaximum(tonumber(recipes[text].count))
end

function parseRecipes( protocol, opcode, buffer )
	local size = tonumber(buffer:match("size:<(%d+)>\n"))
	local pattern = "Count:<(%d+)>\nName:<(.-)>\nDescription:<(.-)>\n"
	local recipesBox = cauldronWindow:getChildById('recipesBox')
	recipesBox:clearOptions()
	recipes = {}
	for count, name, description in string.gmatch(buffer, pattern) do
		recipes[name] = {name = name, count = count, description = description} 
		recipesBox:addOption(name)
	end
	cauldronWindow:getChildById('make'):setEnabled(size > 0)
end

function parseOpcode(protocol, opcode, buffer)
	local x, y, z = string.match(buffer, "<(%d+)><(%d+)><(%d+)>")
	pos = {x = x, y = y, z = z, pos_str = buffer} 
end

function destroyCauldron()
	if cauldronWindow then
		cauldronWindow:destroy()
		cauldronWindow = nil
		disconnect(recipesBox, { onOptionChange = setRecipe })
		ProtocolGame.unregisterExtendedOpcode(105, parseOpcode)
		ProtocolGame.unregisterExtendedOpcode(106, parseRecipes)	
	
		recipesBox = nil
		recipes = {}
	end
end
function onContainerClose(container)
	if container and container:getName() == "cauldron" then
		destroyCauldron()
	end
end

function onContainerChangeSize( container, size )
	if container and container:getName() == "cauldron" then
		refreshContainerItems(container)
	end
end

function onContainerOpen( container, previous )

	if container and container:getName() == "cauldron" then
		destroyCauldron()
		cauldronWindow = g_ui.displayUI('potion')
		recipesBox = cauldronWindow:getChildById('recipesBox')

		connect(recipesBox, { onOptionChange = setRecipe })
		ProtocolGame.registerExtendedOpcode(105, parseOpcode)
		ProtocolGame.registerExtendedOpcode(106, parseRecipes)
		
		for slot=0,container:getCapacity()-1 do
			local itemWidget = cauldronWindow:getChildById("slot"..slot)
    		itemWidget:setItem(container:getItem(slot))
    		itemWidget.position = container:getSlotPosition(slot)
		end
	end
end

function onContainerUpdateItem(container, slot, item, oldItem)
	if container and container:getName() == "cauldron" then
		local itemWidget = cauldronWindow:getChildById('slot' .. slot)
		itemWidget:setItem(item)
	end
end

function refreshContainerItems(container)
	for slot=0,container:getCapacity()-1 do
		local itemWidget = cauldronWindow:getChildById('slot' .. slot)
		itemWidget:setItem(container:getItem(slot))
	end
end

function checkRecipes()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(105, pos.pos_str)
	end
end

function askToMake()

	local yesCallback = function()
		cancelBox:destroy()
		cancelBox = nil
		modules.game_potion.make()
  	end
  	local noCallback = function()
		cancelBox:destroy()
		cancelBox = nil
		cauldronWindow:getChildById('make'):setEnabled(true)
   		cauldronWindow:getChildById('check'):setEnabled(true)
   		recipesBox:setEnabled(true)
  	end
   	
   	cauldronWindow:getChildById('make'):setEnabled(false)
   	cauldronWindow:getChildById('check'):setEnabled(false)
   	recipesBox:setEnabled(false)
  	cancelBox = displayGeneralBox('Alerta', 'Ao prosseguir todos os items que estão no caldeirao serão removidos. Deseja prosseguir?', {{ text=tr('Sim'), callback=yesCallback }, { text=tr('Nao'), callback=noCallback }, anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
  	cancelBox:setParent(cauldronWindow)
end
function make()
	local name = recipesBox:getCurrentOption().text
	local count = cauldronWindow:getChildById('quantityScroll'):getValue()

	local protocol = g_game.getProtocolGame()
	if protocol then
		local str = string.format("<|%s|><|%d|><|%d|%d|%d|>", name, count, pos.x, pos.y, pos.z)
		protocol:sendExtendedOpcode(106, str)
	end
end