local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local config = {
    attackRadius = {x = 3, y = 3, targetDistance = 3, walkDistance = 5},
    attackPK = {value = true, skulls = {SKULL_WHITE, SKULL_RED}},
    attackMonster = {value = true, ignore = {"Cat", "Dog", "Chicken", "Pig", "Sheep", "Rabbit", "Deer", "Target", "Dummy"}, attackSummons = false},
    meleeDamageValue = {min = 100, max = 250}, -- this is ignored, manual % damage is set on line 69
	rangedDamageValue = {min = 50, max = 100}
}

-- Cache
local pvpNpcs = {}

-- Can target be attacked
local function isAttackable(self)
    if not self:isNpc() then -- Not NPC
        if self:isPlayer() and not self:getGroup():getAccess() then -- Player
            if config.attackPK.value and table.contains(config.attackPK.skulls, self:getSkull()) then -- Player has skull
				local playerTile = Tile(self:getPosition())
				if playerTile:hasFlag(TILESTATE_PROTECTIONZONE) == false and playerTile:hasFlag(TILESTATE_HOUSE) == false then -- if player not in PZ
					return true
				end
            end
        end
        if self:isMonster() and config.attackMonster.value then
            local master = self:getMaster()
			if not master then -- Monster
				if not table.contains(config.attackMonster.ignore, self:getName()) then
					return true
				end
			else -- Summon
				if master:isMonster() then -- always attack monster summons
					return true
				else
					if config.attackMonster.attackSummons then -- check for player summons
						return true
					end
				end
			end
        end
    end
    return false
end

-- Find target
local function searchTarget(npcId)
	local npc = Npc(npcId)
	if not npc then
		return false
	end
    local attackRadius = config.attackRadius
    for _, spectator in ipairs(Game.getSpectators(npc:getPosition(), false, false, attackRadius.x, attackRadius.x, attackRadius.y, attackRadius.y)) do
        if isAttackable(spectator) then
		-- if spectator:getPosition():isSightClear(npc:getPosition(), true)
			if npc:getPathTo(spectator:getPosition()) and spectator:getPosition():getDistance(pvpNpcs[npcId].spawnPosition) <= attackRadius.walkDistance then
				pvpNpcs[npcId].npcTarget = spectator:getId()
			end
		end
    end
end

-- We're stuck with 1000ms ticks, so make function that we can delay for better visuals
local function rangedAttack(npcId, targetId)
	local npc = Npc(npcId)
	local creature = Creature(targetId)
	if npc and creature then
		doTargetCombatHealth(npcId, targetId, COMBAT_PHYSICALDAMAGE, -config.rangedDamageValue.min, -config.rangedDamageValue.max, CONST_ME_NONE)
		npc:getPosition():sendDistanceEffect(creature:getPosition(), CONST_ANI_BOLT)
	end
end

-- Register PVP-NPC defaults
function onCreatureAppear(self)
	local npc = Npc()
	if npc == self then
		local npc = Npc(self)
		local npcId = npc:getId()
		if not pvpNpcs[npcId] then
			pvpNpcs[npcId] = {}
			pvpNpcs[npcId].spawnPosition = npc:getPosition()
			pvpNpcs[npcId].npcTarget = 0
			pvpNpcs[npcId].melee = true
			pvpNpcs[npcId].ranged = true
			pvpNpcs[npcId].focus = 0
			pvpNpcs[npcId].direction = DIRECTION_WEST
			pvpNpcs[npcId].timeout = 0
			local outfit = Creature(npc:getId()):getOutfit()
			local lookTypes = {268,269}
			local hairTypes = {2,58,12,97,38,37,29,22,27,115,96,132,21,39}
			outfit.lookType = lookTypes[math.random(1,#lookTypes)]
			outfit.lookHead = hairTypes[math.random(1,#hairTypes)]
			Creature(npc:getId()):setOutfit(outfit)
		end
	end
	npcHandler:onCreatureAppear(self)
end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()
	-- Defaults
    local npc = Npc()
	local npcId = npc:getId()
	local npcPosition = npc:getPosition()
	local targetId = 0

	-- Populate npcTarget if it exists
	if pvpNpcs[npcId] then
		targetId = pvpNpcs[npcId].npcTarget
	end

	-- Check target
    local target = Creature(targetId)
    if not target then -- Not target
		if pvpNpcs[npcId].npcTarget ~= 0 then -- Target just died or logged out
			pvpNpcs[npcId].npcTarget = 0
			doNpcSetCreatureFocus(0)
			searchTarget(npcId)
		elseif npc:getPosition() == pvpNpcs[npcId].spawnPosition then
			if npc:getDirection() ~= pvpNpcs[npcId].direction then
				npc:setDirection(pvpNpcs[npcId].direction)
			end
			searchTarget(npcId)
		else
			local offsetX = npcPosition.x - pvpNpcs[npcId].spawnPosition.x
			local offsetY = npcPosition.y - pvpNpcs[npcId].spawnPosition.y
			if math.abs(offsetX) <= 1 and math.abs(offsetY) <= 1 then
				Creature(npcId):teleportTo(pvpNpcs[npcId].spawnPosition, true)
			else
				if pvpNpcs[npcId].timeout < 10 then
					selfMoveTo(pvpNpcs[npcId].spawnPosition.x, pvpNpcs[npcId].spawnPosition.y, pvpNpcs[npcId].spawnPosition.z)
					pvpNpcs[npcId].timeout = pvpNpcs[npcId].timeout + 1
				else
					Creature(npcId):teleportTo(pvpNpcs[npcId].spawnPosition)
					pvpNpcs[npcId].spawnPosition:sendMagicEffect(CONST_ME_TELEPORT)
					pvpNpcs[npcId].timeout = 0
				end
			end
		end
    else
		-- Reset timeout
		pvpNpcs[npcId].timeout = 0

		-- Check target is still in range
		local targetPosition = target:getPosition()
		local targetTile = Tile(targetPosition)
		if targetTile:hasFlag(TILESTATE_PROTECTIONZONE) or targetTile:hasFlag(TILESTATE_HOUSE) then -- if player in PZ
			pvpNpcs[npcId].npcTarget = 0
			doNpcSetCreatureFocus(0)
			searchTarget(npcId)
			npcHandler:onThink()
			return
		end
		local offsetX = npcPosition.x - targetPosition.x
		local offsetY = npcPosition.y - targetPosition.y
		local radius = config.attackRadius
		if math.abs(offsetX) <= radius.x and math.abs(offsetY) <= radius.y and npcPosition.z == targetPosition.z then -- If target still onscreen
			if targetPosition:getDistance(pvpNpcs[npcId].spawnPosition) <= radius.walkDistance then -- If NPC walked too far from spawnPosition
				doNpcSetCreatureFocus(targetId)

				-- Targeted voices
                if pvpNpcs[npcId].focus ~= targetId then
					pvpNpcs[npcId].focus = targetId
					if target:isPlayer() then
						local playerVoice = {
							{"STOP RIGHT THERE! CRIMINAL SCUM", TALKTYPE_YELL},
							{"Today you shall die... " .. target:getName() .. ".", TALKTYPE_SAY},
							{"I WILL NOT TOLERATE VIOLENCE HERE!", TALKTYPE_YELL},
							{"Time to die, fool!", TALKTYPE_SAY},
							{"It's time to meet my blade - thug!", TALKTYPE_SAY}
						}
						local line = math.random(#playerVoice)
						npc:say(playerVoice[line][1], playerVoice[line][2])
					elseif target:isMonster() then
						local monsterVoice = {
							{"There is a monster inside the town walls!", TALKTYPE_SAY},
							{"Now how did you get in here?!", TALKTYPE_SAY},
							{"RUN CITIZENS! A " .. target:getName():upper() .. " HAS BREACHED THE CITY!", TALKTYPE_YELL},
							{"Quick! slay the " .. target:getName():lower() .. "!", TALKTYPE_SAY},
							{"I will end you!", TALKTYPE_SAY},
							{"CHARGE!", TALKTYPE_YELL},
							{"COME KILL THIS " .. target:getName():upper() .. "!", TALKTYPE_YELL}
						}
						local line = math.random(#monsterVoice)
						npc:say(monsterVoice[line][1], monsterVoice[line][2])
					end
				end

				-- Battle voices
				if pvpNpcs[npcId].melee then -- reuse code that makes 2000ms ticks
					if math.random(1,10) <= 1 then
						local battleVoice = {
							{"I'll make this quick!", TALKTYPE_MONSTER_SAY},
							{"GUARDS! TO ME!", TALKTYPE_MONSTER_YELL},
							{"You belong in the ground!", TALKTYPE_MONSTER_SAY},
							{"Fool!", TALKTYPE_MONSTER_SAY},
							{"No mercy!", TALKTYPE_MONSTER_SAY},
							{"You're going to regret that!", TALKTYPE_MONSTER_SAY}
						}
						local line = math.random(#battleVoice)
						npc:say(battleVoice[line][1], battleVoice[line][2])
					end
				end

				-- Follow Target
				if npcPosition:getDistance(targetPosition) > 1 then
					selfMoveTo(targetPosition.x, targetPosition.y, targetPosition.z)
				end

				-- Ranged Attack
				if npcPosition:getDistance(targetPosition) <= radius.targetDistance then
					if pvpNpcs[npcId].ranged == true then
						if math.random(1,10) > 6 then -- 33% chance to shoot a bolt
							-- Ranged Hit
							addEvent(rangedAttack, math.random(1000,1500), npcId, targetId) -- delayed for better visuals
						end
						pvpNpcs[npcId].ranged = false -- exhaust for one tick
					else
						pvpNpcs[npcId].ranged = true -- toggle exhaust off now
					end
				end

				-- Melee Attack
				if npcPosition:getDistance(targetPosition) <= 1 then
					if pvpNpcs[npcId].melee == true then
						if math.random(1,10) > 2 then -- 80% chance to hit
							-- Melee Hit
							doTargetCombatHealth(npcId, targetId, COMBAT_PHYSICALDAMAGE, -math.floor(10 / 100 * target:getMaxHealth()), -math.floor(25 / 100 * target:getMaxHealth()), CONST_ME_NONE)
						else -- missed
							targetPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
						end
						pvpNpcs[npcId].melee = false -- exhaust for one tick
					else
						pvpNpcs[npcId].melee = true -- toggle exhaust off now
					end
				end
			else
				selfMoveTo(pvpNpcs[npcId].spawnPosition.x, pvpNpcs[npcId].spawnPosition.y, pvpNpcs[npcId].spawnPosition.z)
				pvpNpcs[npcId].npcTarget = 0
				doNpcSetCreatureFocus(0)
			end
		else
			pvpNpcs[npcId].npcTarget = 0
			doNpcSetCreatureFocus(0)
			searchTarget(npcId)
		end
	end
	npcHandler:onThink()
end

function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
npcHandler:addModule(FocusModule:new())
