othersButton = nil
othersMenu = nil
senseWindow = nil

function init()
  othersButton = modules.client_topmenu.addLeftGameButton('othersButton', tr('Others'), '/images/topbuttons/others', toggle)
  othersMenu = g_ui.loadUI('others', rootWidget)
  othersMenu:setVisible(false)

  local topMenu = modules.client_topmenu.getTopMenu()
  local count = topMenu:getChildById('leftButtonsPanel'):getChildCount() + topMenu:getChildById('leftGameButtonsPanel'):getChildCount()
  othersMenu:move(count * 22, 35)

  connect(g_game, {onGameEnd = destroyOthers})
end

function terminate()
  disconnect(g_game, {onGameEnd = destroyOthers})
  destroyOthers()
  othersButton:destroy()
  othersMenu:destroy()
end

function destroyOthers()
  if othersMenu:isOn() then
    toggle()
  end
  if senseWindow then
    senseWindow:destroy()
    senseWindow = nil
  end
end
function toggle()
  if othersMenu:isOn() then
    othersMenu:setVisible(false)
    othersMenu:setOn(false)
  else
    othersMenu:setVisible(true)
    othersMenu:setOn(true)
  end
end

function openSenseWindow()
  senseWindow = g_ui.createWidget('SenseWindow', modules.game_interface.getRootPanel())
end

function sense()
  local nick = senseWindow:getChildById('player'):getText() or ""
  g_game.talk("sense \"".. nick .. "\"")
  senseWindow:destroy()
  senseWindow = nil
end