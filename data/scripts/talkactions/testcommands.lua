local testExp = TalkAction("/exp")

function testExp.onSay(player, words, param)
	if tonumber(param) then
		player:addExperience(param, true)
		return true
	end
	return false
end

testExp:separator(" ")
testExp:register()

local testCapacity = TalkAction("/cap")

function testCapacity.onSay(player, words, param)
	if tonumber(param) then
		player:setCapacity(param*100)
		return true
	end
	return false
end

testCapacity:separator(" ")
testCapacity:register()

local testHp = TalkAction("/hp")

function testHp.onSay(player, words, param)
	if tonumber(param) then
		player:setMaxHealth(param)
		player:setHealth(param)
		return true
	end
	return false
end

testHp:separator(" ")
testHp:register()

local testMana = TalkAction("/mana")

function testMana.onSay(player, words, param)
	if tonumber(param) then
		player:setMaxMana(param)
		player:addMana(param)
		return true
	end
	return false
end

testMana:separator(" ")
testMana:register()

local testVoc = TalkAction("/vocation")

function testVoc.onSay(player, words, param)
	if Vocation(param) then
		player:setVocation(param)
		return true
	end
	return false
end

testVoc:separator(" ")
testVoc:register()

local function getSkillId(skillName)
	if skillName == "club" then
		return SKILL_CLUB
	elseif skillName == "sword" then
		return SKILL_SWORD
	elseif skillName == "axe" then
		return SKILL_AXE
	elseif skillName:sub(1, 4) == "dist" then
		return SKILL_DISTANCE
	elseif skillName:sub(1, 6) == "shield" then
		return SKILL_SHIELD
	elseif skillName:sub(1, 4) == "fish" then
		return SKILL_FISHING
	else
		return SKILL_FIST
	end
end

local function getExpForLevel(level)
	level = level - 1
	return ((50 * level * level * level) - (150 * level * level) + (400 * level)) / 3
end

local testSkill = TalkAction("/skill")

function testSkill.onSay(player, words, param)
	if param ~= "" then
		local split = param:splitTrimmed(",")

		local count = 1
		if split[2] then
			count = tonumber(split[2])
		end

		local ch = split[1]:sub(1, 1)
		for i = 1, count do
			if ch == "l" or ch == "e" then
				player:addExperience(getExpForLevel(player:getLevel() + 1) - player:getExperience(), false)
			elseif ch == "m" then
				player:addManaSpent(player:getVocation():getRequiredManaSpent(player:getBaseMagicLevel() + 1) - player:getManaSpent())
			else
				local skillId = getSkillId(split[1])
				player:addSkillTries(skillId, player:getVocation():getRequiredSkillTries(skillId, player:getSkillLevel(skillId) + 1) - player:getSkillTries(skillId))
			end
		end
		return true
	end
	return false
end

testSkill:separator(" ")
testSkill:register()

local function sendToPlayerLuaCallResult(player, ...)
   local n = select('#', ...)
   local result = setmetatable({ ... }, {
      __len = function()
         return n
      end,
   })

   local t = {}
   for i = 2, #result do
      local v = tostring(result[i])
      if v:len() > 0 then
         table.insert(t, v)
      end
   end

   if #t > 0 then
      player:sendTextMessage(MESSAGE_LOOT, table.concat(t, ', '))
   end
end

local testLua = TalkAction("/lua")

function testLua.onSay(player, words, param)
   if not player:getGroup():getAccess() then
      return false
   end

   if player:getAccountType() < ACCOUNT_TYPE_GOD then
      return false
   end

   sendToPlayerLuaCallResult(player, pcall(load(
      'local cid = ' .. player:getId() .. ' ' ..
         'local player = Player(cid) ' ..
         'local pos = player:getPosition() ' ..
         'local position = pos ' ..
         param
   )))

   return false
end

testLua:separator(" ")
testLua:register()
