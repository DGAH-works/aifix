--[[
	太阳神三国杀游戏工具扩展包·AI修复（AI部分）
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
]]--
--接入AI系统·途径A
local system_filterEvent = SmartAI.filterEvent
function SmartAI:filterEvent(event, player, data)
	--启动
	AIFixStart(self.room)
	--正常工作
	system_filterEvent(self, event, player, data)
end
--接入AI系统·途径B
sgs.ai_event_callback[sgs.GameStart].aifix = function(self, player, data)
	--启动
	AIFixStart(self.room)
end
--启动AI修复系统
function AIFixStart(room)
	--防止再次启动
	SmartAI.filterEvent = system_filterEvent
	sgs.ai_event_callback[sgs.GameStart].aifix = nil
	--检查本扩展包是否已被启用
	local banPackages = sgs.Sanguosha:getBanPackages()
	for _,pack in ipairs(banPackages) do
		if pack == "aifix" then
			AIFixClear()
			return false
		end
	end
	--检查人类玩家是否唯一
	local alives = room:getAlivePlayers()
	local source = nil
	for _,player in sgs.qlist(alives) do
		if player:getState() ~= "robot" then
			if source then
				return false
			else
				source = player
			end
		end
	end
	--启用AI修复系统
	if source then
		initAIFix(room, source)
		source:speak("AI修复系统已成功启动！")
	end
	return true
end
--启用AI修复系统
function initAIFix(room, source)
	room:acquireSkill(source, "aifixmain")
end
--系统函数修正
local system_getDefense = sgs.getDefense
function sgs.getDefense(player)
	if player and sgs.aifix_converge_target then
		if player:objectName() == sgs.aifix_converge_target:objectName() then
			return 0.00001
		end
	end
	return system_getDefense(player)
end
local system_getDefenseSlash = sgs.getDefenseSlash
function sgs.getDefenseSlash(player, self)
	if player and sgs.aifix_converge_target then
		if player:objectName() == sgs.aifix_converge_target:objectName() then
			return 0.00001
		end
	end
	return system_getDefenseSlash(player, self)
end
local system_getPriorTarget = SmartAI.getPriorTarget
function SmartAI:getPriorTarget()
	local target = sgs.aifix_converge_target
	if target and target:isAlive() and self:isEnemy(target) then
		return target
	end
	return system_getPriorTarget(self)
end
--移除AI修复系统
function AIFixClear()
	sgs.getDefense = system_getDefense
	sgs.getDefenseSlash = system_getDefenseSlash
	SmartAI.getPriorTarget = system_getPriorTarget
end
--AI修复过程
sgs.ai_event_callback[sgs.NonTrigger].aifix = function(self, player, data)
	local cmd = data:toString()
	if cmd == "ResetRoleJudge" then
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("aifix_select_target") then
				if p:isLord() then
					sgs.role_evaluation[p:objectName()] = {lord = 99999, rebel = 0, loyalist = 99999, renegade = 0}
					sgs.ai_role[p:objectName()] = "loyalist"
				else
					sgs.role_evaluation[p:objectName()] = {rebel = 0, loyalist = 0, renegade = 0}
					sgs.ai_role[p:objectName()] = "neutral"
				end
				local msg = sgs.LogMessage()
				msg.type = "#aifix_ResetRoleJudge"
				msg.from = p
				self.room:sendLog(msg) --发送提示信息
			end
		end
		self:updatePlayers(false, true)
	elseif cmd == "ShowFriends" then
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("aifix_select_target") then
				local ai = sgs.ais[p:objectName()] 
				local f_num, e_num = #ai.friends_noself, #ai.enemies
				if f_num == 0 then
					local msg = sgs.LogMessage()
					msg.type = "#aifix_NoFriends"
					msg.from = p
					self.room:sendLog(msg) --发送提示信息
				else
					local msg = sgs.LogMessage()
					msg.type = "#aifix_FriendsNoself"
					msg.from = p
					msg.arg = f_num
					self.room:sendLog(msg) --发送提示信息
					msg = sgs.LogMessage()
					msg.type = "#aifix_ShowTarget"
					for index, friend in ipairs(ai.friends_noself) do
						msg.from = friend
						msg.arg = index
						self.room:sendLog(msg) --发送提示信息
					end
				end
				if e_num == 0 then
					local msg = sgs.LogMessage()
					msg.type = "#aifix_NoEnemies"
					msg.from = p
					self.room:sendLog(msg) --发送提示信息
				else
					local msg = sgs.LogMessage()
					msg.type = "#aifix_Enemies"
					msg.from = p
					msg.arg = e_num
					self.room:sendLog(msg) --发送提示信息
					msg = sgs.LogMessage()
					msg.type = "#aifix_ShowTarget"
					for index, enemy in ipairs(ai.enemies) do
						msg.from = enemy
						msg.arg = index
						self.room:sendLog(msg) --发送提示信息
					end
				end
			end
		end
	elseif cmd == "PublishRoles" then
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("aifix_select_target") then
				local role = p:getRole()
				if role == "lord" then
					sgs.role_evaluation[p:objectName()] = {lord = 99999, rebel = -9999, loyalist = 99999, renegade = 0}
					sgs.ai_role[p:objectName()] = "loyalist"
				elseif role == "loyalist" then
					sgs.role_evaluation[p:objectName()] = {rebel = -9999, loyalist = 9999, renegade = 0}
					sgs.ai_role[p:objectName()] = "loyalist"
				elseif role == "renegade" then
					sgs.role_evaluation[p:objectName()] = {rebel = 0, loyalist = 0, renegade = 9999}
					sgs.ai_role[p:objectName()] = "renegade"
					sgs.explicit_renegade = true
				elseif role == "rebel" then
					sgs.role_evaluation[p:objectName()] = {rebel = 9999, loyalist = -9999, renegade = 0}
					sgs.ai_role[p:objectName()] = "rebel"
				end
			end
		end
		for _,p in sgs.qlist(alives) do
			local ai = sgs.ais[p:objectName()]
			ai:updatePlayers(true, true)
		end
	elseif cmd == "FireConverge" then
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("aifix_select_target") then
				sgs.aifix_converge_target = p
				local msg = sgs.LogMessage()
				msg.type = "#aifix_FireConverge"
				msg.from = player
				msg.to:append(p)
				self.room:sendLog(msg) --发送提示信息
				break
			end
		end
	end
end