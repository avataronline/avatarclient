function init()
  ProtocolGame.registerExtendedOpcode(ExtendedIds.Sound, parseSound)
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(ExtendedIds.Sound, parseSound)
end

function parseSound(protocol, opcode, buffer)

  local msg = InputMessage.create()
  msg:setBuffer(buffer)

  local packet = msg:getStrTable()
  if packet.action == "enqueue" then
    local channel = g_sounds.getChannel(packet.channel)
    local path = "/sounds/" .. packet.title
    g_sounds.preload(path)                                                                                                                      
    channel:enqueue(path, packet.fadetime)
                if packet.gain then
        channel:setGain(packet.gain)
                end
  elseif packet.action == "stop" then
    g_sounds.stopAll()
  end
end