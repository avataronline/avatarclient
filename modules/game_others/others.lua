othersButton = nil
othersMenu = nil
senseWindow = nil
 
function init()
  othersButton = modules.client_topmenu.addLeftGameButton('othersButton', tr('Others'), '/images/topbuttons/others', function () end)
  g_ui.importStyle('others')

  connect(g_game, {onGameEnd = destroyOthers})
  connect(othersButton, {onHoverChange = dropdownMenu})
end

function terminate()
  disconnect(g_game, {onGameEnd = destroyOthers})
  destroyOthers()
  
end

function destroyOthers()
  if senseWindow then
    senseWindow:destroy()
    senseWindow = nil
  end
  if othersButton then
    disconnect(othersButton, {onHoverChange = dropdownMenu})
    othersButton:destroy()
    othersButton = nil
  end 
  destroyOthersMenu()
end

function dropdownMenu( widget, hovered )
  if hovered then
    othersMenu = g_ui.createWidget('OthersPopup')
    connect(othersMenu, {onDestroy = function (self) othersMenu = nil end, 
              onHoverChange = function ( widget, hovered )
                if othersMenu and not othersMenu:containsPoint(g_window.getMousePosition()) then
                  othersMenu:destroy()
                end
              end })
    local pos = othersButton:getPosition()
    pos.y = pos.y + 30
    othersMenu:display(pos)
  else
    scheduleEvent(function()
      if othersMenu and not othersButton:containsPoint(g_window.getMousePosition()) and
        not othersMenu:containsPoint(g_window.getMousePosition()) then
        othersMenu:destroy()
      end
    end, 1000)

  end
end

function openSenseWindow()
  senseWindow = g_ui.createWidget('SenseWindow', modules.game_interface.getRootPanel())
end

function sense()
  local nick = senseWindow:getChildById('player'):getText() or ""
  g_game.talk("sense \"".. nick .. "\"")
  closeSenseWindow()
end

function closeSenseWindow()
  senseWindow:destroy()
  senseWindow = nil
end

function destroyOthersMenu()
  if othersMenu then
    othersMenu:destroy()
    othersMenu = nil
  end
end