local MapShaders = {
	["default"] = { path = "/data/shaders/default.frag" };
	["temple_effect"] = { path = "/data/shaders/temple_effect.frag" };
	["red_alert"] = {path = "/data/shaders/red_alert.frag"};
	["challenge_effect"] = {path = "/data/shaders/challenge_effect.frag"};
	["test1"] = {path = "/data/shaders/test1.frag"};
	["test2"] = {path = "/data/shaders/test2.frag"};
	["test3"] = {path = "/data/shaders/test3.frag"};
	["test4"] = {path = "/data/shaders/test4.frag"};
	["test5"] = {path = "/data/shaders/test5.frag"};
	["test6"] = {path = "/data/shaders/test6.frag"};
	["test7"] = {path = "/data/shaders/test7.frag"};
	["test8"] = {path = "/data/shaders/test8.frag"};
	["test9"] = {path = "/data/shaders/test9.frag"};
	["test10"] = {path = "/data/shaders/test10.frag"};
	["test11"] = {path = "/data/shaders/test11.frag"};

}

local function parseShader(protocol, opcode, buffer)

	local msg = InputMessage.create()
	msg:setBuffer(buffer)

	local packet = msg:getStrTable()
	if not g_graphics.canUseShaders() then return end

	local map = modules.game_interface.getMapPanel()
	if packet.action == "active" then
		local shader = g_shaders.getShader(packet.name)
		if shader then
			map:setMapShader(shader)
		end
		return
	end
	map:setMapShader(g_shaders.getDefaultMapShader())
 	modules.game_healthinfo.checkHealthAlert()
end

function init()
	ProtocolGame.registerExtendedOpcode(ExtendedIds.MapShader, parseShader)

	for name, opts in pairs(MapShaders) do
    	local shader = g_shaders.createFragmentShader(name, opts.path)
    	if opts.tex1 then
    		shader:addMultiTexture(opts.tex1)
    	end
    	if opts.tex2 then
    		shader:addMultiTexture(opts.tex2)
    	end
    	if opts.tex3 then
    		shader:addMultiTexture(opts.tex3)
    	end
    end
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(ExtendedIds.MapShader, parseShader)
end