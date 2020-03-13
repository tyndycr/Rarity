function onStartup()
	
	-- Test Environment
	for i = 30000, 1,-1 do
		local itemType = ItemType(i)
		if itemType:getWeaponType() ~= 0 then
			if itemType:getWeaponType() == WEAPON_SWORD then
				local pos = Position(48, 62, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			elseif itemType:getWeaponType() == WEAPON_CLUB then
				local pos = Position(50, 62, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			elseif itemType:getWeaponType() == WEAPON_AXE then
				local pos = Position(52, 62, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			elseif itemType:getWeaponType() == WEAPON_WAND then
				local pos = Position(47, 63, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			elseif itemType:getWeaponType() == WEAPON_DISTANCE then
				local pos = Position(54, 62, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			elseif itemType:getWeaponType() == WEAPON_SHIELD then
				local pos = Position(55, 63, 8)
				local cabinet = Tile(pos):getItemById(20297)
				cabinet:addItem(i, 1)
			end
		else
			local slotType = itemType:getSlotPosition()
			if bit.band(slotType, SLOTP_HEAD) ~= 0 then
				local pos = Position(47, 65, 8)
				local chest = Tile(pos):getItemById(1748)
				chest:addItem(i, 1)
			elseif bit.band(slotType, SLOTP_ARMOR) ~= 0 then
				local pos = Position(47, 66, 8)
				local chest = Tile(pos):getItemById(1748)
				chest:addItem(i, 1)
			elseif bit.band(slotType, SLOTP_LEGS) ~= 0 then
				local pos = Position(47, 67, 8)
				local chest = Tile(pos):getItemById(1748)
				chest:addItem(i, 1)
			elseif bit.band(slotType, SLOTP_FEET) ~= 0 then
				local pos = Position(47, 68, 8)
				local chest = Tile(pos):getItemById(1748)
				chest:addItem(i, 1)
			elseif bit.band(slotType, SLOTP_NECKLACE) ~= 0 then
				local pos = Position(48, 70, 8)
				local crate = Tile(pos):getItemById(1739)
				crate:addItem(i, 1)
			elseif bit.band(slotType, SLOTP_RING) ~= 0 then
				local pos = Position(54, 70, 8)
				local crate = Tile(pos):getItemById(1739)
				crate:addItem(i, 1)
			end
			if itemType:isCorpse() then
				local pos = Position(82, 90, 8)
				Game.createItem(i, 1, pos)
			end
			if i == 2148 or i == 2152 or i == 2160 then
				local pos = Position(88, 67, 8)
				local bag = Tile(pos):getItemById(21518)
				bag:addItem(i, 100)
			end
			if itemType:isRune() then
				local pos = Position(47, 87, 8)
				local bag = Tile(pos):getItemById(5801)
				bag:addItem(i, 100)
			end
		end
	end
	
	-- Mana Potions
	local manaBackpack = Tile(Position(49, 90, 8)):getItemById(2365)
	local greatBackpack = manaBackpack:addItem(2001)
	for i = 1,20 do
		greatBackpack:addItem(7590, 100)
	end
	manaBackpack:addItem(7590, 100)
	local strongBackpack = manaBackpack:addItem(2001)
	for i = 1,20 do
		strongBackpack:addItem(7589, 100)
	end
	manaBackpack:addItem(7589, 100)
	local normalBackpack = manaBackpack:addItem(2001)
	for i = 1,20 do
		normalBackpack:addItem(7620, 100)
	end
	manaBackpack:addItem(7620, 100)
	
	-- Health Potions
	local healthBackpack = Tile(Position(53, 90, 8)):getItemById(2365)
	ultimateBackpack = healthBackpack:addItem(2000)
	for i = 1,20 do
		ultimateBackpack:addItem(8473, 100)
	end
	healthBackpack:addItem(8473, 100)
	greatBackpack = healthBackpack:addItem(2000)
	for i = 1,20 do
		greatBackpack:addItem(7591, 100)
	end
	healthBackpack:addItem(7591, 100)
	strongBackpack = healthBackpack:addItem(2000)
	for i = 1,20 do
		strongBackpack:addItem(7588, 100)
	end
	healthBackpack:addItem(7588, 100)
	normalBackpack = healthBackpack:addItem(2000)
	for i = 1,20 do
		normalBackpack:addItem(7618, 100)
	end
	healthBackpack:addItem(7618, 100)
	smallBackpack = healthBackpack:addItem(2000)
	for i = 1,20 do
		smallBackpack:addItem(8704, 100)
	end
	healthBackpack:addItem(8704, 100)
	
	-- END test environment scripts
	
	db.query("TRUNCATE TABLE `players_online`")
	db.asyncQuery("DELETE FROM `guild_wars` WHERE `status` = 0")
	db.asyncQuery("DELETE FROM `players` WHERE `deletion` != 0 AND `deletion` < " .. os.time())
	db.asyncQuery("DELETE FROM `ip_bans` WHERE `expires_at` != 0 AND `expires_at` <= " .. os.time())
	db.asyncQuery("DELETE FROM `market_history` WHERE `inserted` <= " .. (os.time() - configManager.getNumber(configKeys.MARKET_OFFER_DURATION)))

	-- Move expired bans to ban history
	local resultId = db.storeQuery("SELECT * FROM `account_bans` WHERE `expires_at` != 0 AND `expires_at` <= " .. os.time())
	if resultId ~= false then
		repeat
			local accountId = result.getNumber(resultId, "account_id")
			db.asyncQuery("INSERT INTO `account_ban_history` (`account_id`, `reason`, `banned_at`, `expired_at`, `banned_by`) VALUES (" .. accountId .. ", " .. db.escapeString(result.getString(resultId, "reason")) .. ", " .. result.getNumber(resultId, "banned_at") .. ", " .. result.getNumber(resultId, "expires_at") .. ", " .. result.getNumber(resultId, "banned_by") .. ")")
			db.asyncQuery("DELETE FROM `account_bans` WHERE `account_id` = " .. accountId)
		until not result.next(resultId)
		result.free(resultId)
	end

	-- Check house auctions
	local resultId = db.storeQuery("SELECT `id`, `highest_bidder`, `last_bid`, (SELECT `balance` FROM `players` WHERE `players`.`id` = `highest_bidder`) AS `balance` FROM `houses` WHERE `owner` = 0 AND `bid_end` != 0 AND `bid_end` < " .. os.time())
	if resultId ~= false then
		repeat
			local house = House(result.getNumber(resultId, "id"))
			if house then
				local highestBidder = result.getNumber(resultId, "highest_bidder")
				local balance = result.getNumber(resultId, "balance")
				local lastBid = result.getNumber(resultId, "last_bid")
				if balance >= lastBid then
					db.query("UPDATE `players` SET `balance` = " .. (balance - lastBid) .. " WHERE `id` = " .. highestBidder)
					house:setOwnerGuid(highestBidder)
				end
				db.asyncQuery("UPDATE `houses` SET `last_bid` = 0, `bid_end` = 0, `highest_bidder` = 0, `bid` = 0 WHERE `id` = " .. house:getId())
			end
		until not result.next(resultId)
		result.free(resultId)
	end

	-- store towns in database
	db.query("TRUNCATE TABLE `towns`")
	for i, town in ipairs(Game.getTowns()) do
		local position = town:getTemplePosition()
		db.query("INSERT INTO `towns` (`id`, `name`, `posx`, `posy`, `posz`) VALUES (" .. town:getId() .. ", " .. db.escapeString(town:getName()) .. ", " .. position.x .. ", " .. position.y .. ", " .. position.z .. ")")
	end
end
