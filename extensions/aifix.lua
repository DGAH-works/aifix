--[[
	太阳神三国杀游戏工具扩展包·AI修复
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
]]--
module("extensions.aifix", package.seeall)
extension = sgs.Package("aifix")
--技能暗将
AnJiang = sgs.General(extension, "aifixAnJiang", "god", 5, true, true, true)
--翻译信息
sgs.LoadTranslationTable{
	["aifix"] = "AI修复",
}
--[[
	功能：出牌阶段，你可以选择一项：
		1、重置AI
		2、重置AI身份判断结果
		3、显示AI关系表
		4、公布角色身份
		5、指定AI集火目标
]]--
aifixselect = sgs.CreateSkillCard{
	name = "aifixselect",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("aifix_limit")
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:setPlayerFlag(p, "aifix_select_target")
		end
	end,
}
aifixcard = sgs.CreateSkillCard{
	name = "aifixcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local choices = {
			"ResetAI", 
			"ResetRoleJudge", 
			"ShowFriends",
			"PublishRoles", 
			"FireConverge",
			"cancel"
		}
		choices = table.concat(choices, "+")
		local choice = room:askForChoice(source, "aifix", choices)
		local alives = room:getAlivePlayers()
		if choice == "cancel" then
			return 
		--重置AI
		elseif choice == "ResetAI" then
			room:setPlayerMark(source, "aifix_limit", 10)
			room:askForUseCard(source, "@@aifix", "@aifix-ResetAI")
			for _,p in sgs.qlist(alives) do
				if p:hasFlag("aifix_select_target") then
					room:resetAI(p)
					local msg = sgs.LogMessage()
					msg.type = "#aifix_ResetAI"
					msg.from = p
					room:sendLog(msg) --发送提示信息
				end
			end
		--重置AI身份判断结果
		elseif choice == "ResetRoleJudge" then
			room:setPlayerMark(source, "aifix_limit", 10)
			room:askForUseCard(source, "@@aifix", "@aifix-ResetRoleJudge")
			room:getThread():trigger(sgs.NonTrigger, room, source, sgs.QVariant("ResetRoleJudge"))
		--显示AI关系表
		elseif choice == "ShowFriends" then
			room:setPlayerMark(source, "aifix_limit", 10)
			room:askForUseCard(source, "@@aifix", "@aifix-ShowFriends")
			room:getThread():trigger(sgs.NonTrigger, room, source, sgs.QVariant("ShowFriends"))
		--公布角色身份
		elseif choice == "PublishRoles" then
			room:setPlayerMark(source, "aifix_limit", 10)
			room:askForUseCard(source, "@@aifix", "@aifix-PublishRoles")
			for _,p in sgs.qlist(alives) do
				if p:hasFlag("aifix_select_target") then
					room:broadcastProperty(p, "role")
					local msg = sgs.LogMessage()
					msg.type = "#aifix_PublishRoles"
					msg.from = p
					msg.arg = p:getRole()
					room:sendLog(msg) --发送提示信息
				end
			end
			room:getThread():trigger(sgs.NonTrigger, room, source, sgs.QVariant("PublishRoles"))
		--指定AI集火目标
		elseif choice == "FireConverge" then
			room:setPlayerMark(source, "aifix_limit", 1)
			room:askForUseCard(source, "@@aifix", "@aifix-FireConverge")
			room:getThread():trigger(sgs.NonTrigger, room, source, sgs.QVariant("FireConverge"))
		end
		room:setPlayerMark(source, "aifix_limit", 0)
		for _,p in sgs.qlist(alives) do
			room:setPlayerFlag(p, "-aifix_select_target")
		end
	end,
}
aifixvs = sgs.CreateViewAsSkill{
	name = "aifixmain",
	n = 0,
	case = 0,
	view_as = function(self, cards)
		if case == 0 then
			return aifixcard:clone()
		elseif case == 1 then
			return aifixselect:clone()
		end
	end,
	enabled_at_play = function(self, player)
		case = 0
		return player:getState() ~= "robot"
	end,
	enabled_at_response = function(self, player, pattern)
		case = 1
		return pattern == "@@aifix"
	end,
}
aifixmain = sgs.CreateTriggerSkill{
	name = "aifixmain",
	frequency = sgs.Skill_NotFrequent,
	events = {},
	view_as_skill = aifixvs,
	on_trigger = function(self, event, player, data)
	end,
}
--添加功能
AnJiang:addSkill(aifixmain)
--翻译信息
sgs.LoadTranslationTable{
	["aifixmain"] = "AI修复",
	[":aifixmain"] = "点击以修复AI",
	["aifix:ResetAI"] = "重置AI",
	["aifix:ResetRoleJudge"] = "重置AI身份判断结果",
	["aifix:ShowFriends"] = "显示AI关系表",
	["aifix:PublishRoles"] = "公布角色身份",
	["aifix:FireConverge"] = "指定AI集火目标",
	["aifix:cancel"] = "取消",
	["aifixselect"] = "AI修复",
	["@aifix-ResetAI"] = "请选择要重置AI的目标角色",
	["@aifix-ResetRoleJudge"] = "请选择要重新判断的目标角色，AI将重置对其的身份判断结果",
	["@aifix-ShowFriends"] = "请选择要显示关系表的目标角色",
	["@aifix-PublishRoles"] = "请选择要公开身份的目标角色",
	["@aifix-FireConverge"] = "请指定要集火的目标角色",
	["#aifix_ResetAI"] = "%from 重置了AI",
	["#aifix_ResetRoleJudge"] = "AI重置了对 %from 的身份判断",
	["#aifix_ShowTarget"] = "%arg：%from",
	["#aifix_FriendsNoself"] = "%from 认为自己有 %arg 个队友：",
	["#aifix_NoFriends"] = "%from 还没有认定的队友！",
	["#aifix_Enemies"] = "%from 认为自己有 %arg 个对手：",
	["#aifix_NoEnemies"] = "%from 还没有认定的对手！",
	["#aifix_PublishRoles"] = "通知：%from 的身份为 %arg。",
	["#aifix_FireConverge"] = "%from 发出了对 %to 的集火指令！",
}