--!strict

-- =========================
-- // SERVICES & IMPORTS
-- =========================

local GuildService = {}

-- // SERVICES

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- // IMPORTS

local Bitpacker = require(script.Parent.DataCompression.Bitpacker)
local Base64 = require(script.Parent.DataCompression.Base64)
local Settings = require(script.Parent.Misc.Settings)
local Types = require(script.Parent.Misc.Types)

-- =========================
-- // DATA & DATASTORES
-- =========================

GuildService.Guilds = {} :: Types.Guilds -- // Persistent data that is used to cache all guild data. GuildService.Guilds[guildId] = Types.GuildData

local GuildStores = DataStoreService:GetDataStore("GuildStores") -- // Holds all of the guildData that are encoded in a Base64 Buffer String
local AllGuildIds = DataStoreService:GetDataStore("AllGuildIds") -- // Holds the Guild ID's generated using :GenerateGUID() which is the key to guildData

-- =========================
-- // MAIN GUILD FUNCTIONS
-- =========================

-- CreateGuild(): Creates a new guild
-- @param player: The player that wants to create it
-- @param guildName: The name of the guild (Less than 50 Characters)
-- @param guildTag: A shortened version of the guild name (Less than 5 Characters)
-- @param description: A short description of the guild (Less than 255 Characters)
-- @param guildType: "Public" | "InviteOnly"
-- @return string?: The guild ID
function GuildService.CreateGuild(player: Player, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly"): string?
	assert(player and player.UserId, "Invalid player")
	assert(#guildName > 0 and #guildName <= 50, "Guild name must be 1-50 characters")
	assert(#guildTag > 0 and #guildTag <= 5, "Guild tag must be 1-5 characters")
	assert(#description <= 255, "Description must be 0-255 characters")

	local existingGuildId, existingGuild = GuildService.GetPlayerGuild(player)

	if existingGuildId and existingGuild then
		if existingGuild.GuildLeader == player.UserId then
			warn("Player already owns a guild")
			return nil
		else
			warn("Player is already a member of a guild")
			return nil
		end
	end

	local guildId = HttpService:GenerateGUID(false)

	GuildService.Guilds[guildId] = {
		GuildName = guildName,
		GuildTag = guildTag,
		Description = description,
		GuildLeader = player.UserId,
		GuildType = guildType,
		CreatedAt = os.time(),
		Members = {player.UserId},
		JoinRequests = {}
	}

	local serializedData = GuildService.SerializeGuild(guildId)

	if serializedData then
		local success, err = pcall(function()
			GuildStores:SetAsync(`Guild_{guildId}`, serializedData)
		end)
		if not success then
			warn("Failed to save guild to DataStore:", err)
			GuildService.Guilds[guildId] = nil
			return nil
		end
	else
		warn("Failed to serialize guild data")
		GuildService.Guilds[guildId] = nil
		return nil
	end

	local success, err = pcall(function()
		AllGuildIds:UpdateAsync("AllGuildIds", function(current)
			current = current or {}

			for _, id in ipairs(current) do
				if id == guildId then
					return current
				end
			end

			table.insert(current, guildId)
			
			return current
		end)
	end)

	if not success then
		warn("Failed to update AllGuildIds:", err)
		GuildService.Guilds[guildId] = nil
		GuildStores:RemoveAsync(`Guild_{guildId}`)
		return nil
	end

	print("Successfully created guild!")

	return guildId
end

-- ModifyGuild(): Modifies a created guild
-- @param player: The player that wants to modify it
-- @param guildId: The guild ID
-- @param guildName: The name of the guild (Less than 50 Characters)
-- @param guildTag: A shortened version of the guild name (Less than 5 Characters)
-- @param description: A short description of the guild (Less than 255 Characters)
-- @param guildType: "Public" | "InviteOnly"
-- @return string?: The guild ID
function GuildService.ModifyGuild(player: Player, guildId: string, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly"): string?
	assert(player and player.UserId, "Invalid player")
	assert(#guildName > 0 and #guildName <= 50, "Guild name must be 1-50 characters")
	assert(#guildTag > 0 and #guildTag <= 5, "Guild tag must be 1-5 characters")
	assert(#description <= 255, "Description must be 0-255 characters")

	local existingGuild = GuildService.GetOrLoadGuild(guildId)

	if not existingGuild then
		warn("Guild does not exist")
		return nil
	end

	if existingGuild.GuildLeader ~= player.UserId then
		warn("You don't own this guild!")
		return nil
	end

	existingGuild.GuildName = guildName
	existingGuild.GuildTag = guildTag
	existingGuild.Description = description
	existingGuild.GuildType = guildType

	local serializedData = GuildService.SerializeGuild(guildId)
	if not serializedData then
		warn("Failed to serialize guild data")
		return nil
	end

	local success, err = pcall(function()
		GuildStores:UpdateAsync(`Guild_{guildId}`, function(oldValue)
			return serializedData
		end)
	end)

	if not success then
		warn("Failed to save guild to DataStore:", err)
		return nil
	end

	return guildId
end

-- DeleteGuild(): Delete guild from memory and DataStore
-- @param player: The player that wants to delete it
-- @param guildId: The guild ID
-- @return boolean: False if didn't work, true if did
function GuildService.DeleteGuild(player: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return false
	end
	
	if guild.GuildLeader ~= player.UserId then
		warn("You are not the guild owner!")
		return false
	end
	
	GuildService.Guilds[guildId] = nil

	local removeSuccess, removeErr = pcall(function()
		GuildStores:RemoveAsync(`Guild_{guildId}`)
	end)
	
	if not removeSuccess then
		warn("Failed to delete guild from DataStore:", removeErr)
		GuildService.Guilds[guildId] = guild
		return false
	end

	local updateSuccess, updateErr = pcall(function()
		AllGuildIds:UpdateAsync("AllGuildIds", function(current)
			current = current or {}
			
			for i = #current, 1, -1 do
				if current[i] == guildId then
					table.remove(current, i)
					break
				end
			end
			
			return current
		end)
	end)
	
	if not updateSuccess then
		warn("Failed to update AllGuildIds after deletion:", updateErr)
	end

	return true
end

-- TransferOwnership(): Transfers leadership to another person
-- @param currentLeader: The player that wants to transfer their ownership
-- @param newLeader: The player to transfer their ownership to
-- @param guildId: The guild ID
-- @return boolean: False if didn't work, true if did
function GuildService.TransferOwnership(currentLeader: Player, newLeader: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return false
	end
	
	if guild.GuildLeader ~= currentLeader.UserId then
		warn("You are not the guild owner!")
		return false
	end
	
	guild.GuildLeader = newLeader.UserId
	
	print("Successfully transferred ownership!")
	
	return GuildService.SaveGuild(guildId)
end

-- =========================
-- // MISC GUILD FUNCTIONS
-- =========================

-- KickPlayer(): Kicks a player from the guild if you're the owner
-- @param guildId: The guild ID
-- @param player: The player that wants to kick
-- @param playerToKick: The player to kick
-- @return boolean: False if the operation failed
function GuildService.KickPlayer(guildId: string, player: Player, playerToKick: Player): boolean
	local existingGuild = GuildService.GetOrLoadGuild(guildId)

	if not existingGuild then
		warn("Guild does not exist")
		return false
	end

	if existingGuild.GuildLeader ~= player.UserId then
		warn("You aren't the guild owner!")
		return false
	end

	if player.UserId == playerToKick.UserId then
		warn("You can't kick yourself!")
		return false
	end

	local index = table.find(existingGuild.Members, playerToKick.UserId)

	if not index then
		warn("Player is not in the guild")
		return false
	end

	table.remove(existingGuild.Members, index)

	return GuildService.SaveGuild(guildId)
end

-- CheckPlayerInGuild(): Checks if a player is in a guild
-- @param guild: Types.GuildData
-- @param player: The player
function GuildService.CheckPlayerInGuild(guild: Types.GuildData, player: Player): boolean
	if guild.GuildLeader == player.UserId then
		return true
	end

	for _, memberId in guild.Members do
		if memberId == player.UserId then
			return true
		end
	end

	return false
end

-- GetPlayerGuild(): Function to get guild by player
-- @param player: The player
-- @return (string?, Types.GuildData?): GuildID, GuildData
function GuildService.GetPlayerGuild(player: Player): (string?, Types.GuildData?)
	for guildId, guild in GuildService.Guilds do
		if GuildService.CheckPlayerInGuild(guild, player) then
			return guildId, guild
		end
	end

	local success, idList = pcall(function()
		return AllGuildIds:GetAsync("AllGuildIds")
	end)

	if success and type(idList) == "table" then
		for _, guildId in idList do
			if not GuildService.Guilds[guildId] then
				local guild = GuildService.GetOrLoadGuild(guildId)
				if guild and GuildService.CheckPlayerInGuild(guild, player) then
					return guildId, guild
				end
			end
		end
	end

	return nil, nil
end

-- =========================
-- // DATA FUNCTIONS
-- =========================

-- LoadGuild(): Load guild from DataStore
-- @param guildId: The guild ID
-- @return boolean: False if didn't work
function GuildService.LoadGuild(guildId: string): boolean
	local success, data = pcall(function()
		return GuildStores:GetAsync(`Guild_{guildId}`)
	end)

	if not success then
		warn("Failed to load guild from DataStore:", data)
		return false
	end

	if data then
		return GuildService.DeserializeGuild(guildId, data)
	end

	return false
end

-- SaveGuild(): Save guild to DataStore
-- @param guildId: The guild ID
-- @return boolean: False if didn't work, true if did
function GuildService.SaveGuild(guildId: string): boolean
	local serializedData = GuildService.SerializeGuild(guildId)
	if not serializedData then
		warn("Failed to serialize guild data")
		return false
	end

	local success, err = pcall(function()
		GuildStores:SetAsync(`Guild_{guildId}`, serializedData)
	end)

	if not success then
		warn("Failed to save guild to DataStore:", err)
		return false
	end

	return true
end

-- GetOrLoadGuild(): Helper function to get or load a guild
-- @param guildId: The guild ID
-- @return Types.GuildData
function GuildService.GetOrLoadGuild(guildId: string): Types.GuildData?
	local guild = GuildService.Guilds[guildId]

	if not guild then
		if GuildService.LoadGuild(guildId) then
			return GuildService.Guilds[guildId]
		end
		return nil
	end

	return guild
end

-- LoadAllGuilds(): Loads all guilds from the DataStore
-- @return boolean: If it has succeeded or not
function GuildService.LoadAllGuilds(): boolean
	local success, idList = pcall(function()
		return AllGuildIds:GetAsync("AllGuildIds")
	end)

	if not success then
		warn("Failed to fetch list of guild IDs:", idList)
		return false
	end

	if not idList or type(idList) ~= "table" then
		warn("No guild IDs found or invalid data type")
		return true
	end

	if #idList == 0 then
		print("No guilds to load")
		return true
	end

	local failedCount = 0
	for _, guildId in idList do
		local guildSuccess = GuildService.LoadGuild(guildId)
		if not guildSuccess then
			warn(`Failed to load guild: {guildId}`)
			failedCount += 1
		end
	end

	if failedCount > 0 then
		warn(`Failed to load {failedCount} out of {#idList} guilds`)
	end

	return failedCount == 0
end

-- =========================
-- // GUILD JOINING & LEAVING
-- =========================

-- AcceptJoinRequest(): Adds the player to an InviteOnly guild
-- @param player: The player that owns the guild
-- @param playerToAdd: The player that wants to be invited
-- @param guildId: The guild ID
-- @return boolean: False if didn't work
function GuildService.AcceptJoinRequest(player: Player, playerToAdd: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId) :: Types.GuildData

	if not guild then
		warn("Guild not found")
		return false
	end

	if guild.GuildLeader ~= player.UserId then
		warn("You are not the guild owner!")
		return false
	end

	if guild.GuildType == "Public" then
		warn("You don't have to request! This is a Public Guild!")
		return false
	end

	local index = table.find(guild.JoinRequests, playerToAdd.UserId)
	
	if not index then
		warn("Player didn't request to be in this guild!")
		return false
	end

	local currentGuildId, _ = GuildService.GetPlayerGuild(playerToAdd)
	
	if currentGuildId then
		warn("Player is already in a guild")
		return false
	end

	if GuildService.IsGuildFull(guildId) then
		warn("Maximum amount of players in this guild!")
		return false
	end
	
	table.insert(guild.Members, playerToAdd.UserId)
	table.remove(guild.JoinRequests, index)
	
	print("Accepted player into guild!")
	
	return GuildService.SaveGuild(guildId)
end

-- RequestJoin(): Request to join someone elses guild
-- @param player: The player
-- @param guildId: The guild ID
-- @return boolean: False if didn't work
function GuildService.RequestJoin(player: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId)
	
	if not guild then
		warn("Guild not found")
		return false
	end

	local currentGuildId = GuildService.GetPlayerGuild(player)
	
	if currentGuildId then
		warn("Player is already in a guild")
		return false
	end

	if guild.GuildType == "InviteOnly" then
		for _, userId in guild.JoinRequests do
			if userId == player.UserId then
				warn("Join request already exists")
				return false
			end
		end
		
		table.insert(guild.JoinRequests, player.UserId)
		
		print("Added player's request to join the InviteOnly guild!")
		
		return GuildService.SaveGuild(guildId)
	else
		if GuildService.IsGuildFull(guildId) then
			warn("Maximum amount of players in this guild!")
			return false
		end

		table.insert(guild.Members, player.UserId)
		return GuildService.SaveGuild(guildId)
	end
end

-- LeaveGuild(): Remove player from guild
-- @param player: The player
-- @return boolean: False if didn't work
function GuildService.LeaveGuild(player: Player): boolean
	local guildId, guild = GuildService.GetPlayerGuild(player)
	
	if not guildId or not guild then
		warn("Player is not in a guild")
		return false
	end

	if guild.GuildLeader == player.UserId then
		warn("Guild leader cannot leave. Transfer leadership or delete guild.")
		return false
	end

	local index = table.find(guild.Members, player.UserId)
	
	if index then
		table.remove(guild.Members, index)
	end
	
	local joinId = table.find(guild.JoinRequests, player.UserId)

	if joinId then
		table.remove(guild.JoinRequests, joinId)
	end
	
	return GuildService.SaveGuild(guildId)
end

-- =========================
-- // GUILD HELPERS
-- =========================

-- GetGuildInfo(): Returns a table of guild data
-- @param guildId: The guild ID
-- @return Types.GuildData?
function GuildService.GetGuildInfo(guildId: string): Types.GuildData?
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return nil
	end
	
	return guild
end

-- GetGuildMembers(): Gets an array of guild members
-- @param guildId: The guild ID
-- @return {number}: An array of UserIds that are members
function GuildService.GetGuildMembers(guildId: string): { number }?
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return nil
	end
	
	return guild.Members
end

-- =========================
-- // JOIN REQUEST HELPERS
-- =========================

-- RejectJoinRequest(): Rejects a join request from a guild
-- @param player: The owner of the guild
-- @param playerToReject: The player to kick
-- @param guildId: The guild ID
-- @return boolean: False if didn't work
function GuildService.RejectJoinRequest(player: Player, playerToReject: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return false
	end
	
	if guild.GuildLeader ~= player.UserId then
		warn("You are not the guild owner!")
		return false
	end
	
	local index = table.find(guild, playerToReject.UserId)

	if index then
		table.remove(guild.JoinRequests, index)
	else
		warn("Player didn't request to join!")
		return false
	end
	
	return GuildService.SaveGuild(guildId)
end

-- GetJoinRequests(): Gets an array of UserIds that want to join the guild
-- @param guildId: The guild ID
-- @return {number}: An array of UserIds that want to join
function GuildService.GetJoinRequests(guildId: string): { number }?
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return nil
	end
	
	return guild.JoinRequests
end

-- CancelJoinRequest(): Cancels the join request you've sent to a guild
-- @param player: The player
-- @param guildId: The guild ID
-- @return boolean: False if didn't work
function GuildService.CancelJoinRequest(player: Player, guildId: string): boolean
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return false
	end
	
	local index = table.find(guild, player.UserId)
	
	if index then
		table.remove(guild.JoinRequests, index)
	end
	
	print("Cancelled join request!")
	
	return GuildService.SaveGuild(guildId)
end

-- =========================
-- // DATA COMPRESSION
-- =========================

-- SerializeGuild(): Serialize guild data for storage/transmission
-- @param guildId: The guild ID
-- @return string?: Base64 buffer string
function GuildService.SerializeGuild(guildId: string): string?
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		return nil
	end

	local rawData = Bitpacker.packGuildData(guild)
	
	return Base64.Encode(rawData)
end

-- DeserializeGuild(): Decode from Base64 and deserialize buffer and load guild data into the Guilds table
-- @param guildId: The guild ID
-- @param data: The buffer string
-- @return boolean: True if successful
function GuildService.DeserializeGuild(guildId: string, base64Data: string): boolean
	local success, result = pcall(function()
		local rawData = Base64.Decode(base64Data)
		return Bitpacker.unpackGuildData(rawData)
	end)

	if success and result then
		GuildService.Guilds[guildId] = result
		return true
	else
		warn("Failed to deserialize guild " .. guildId .. ": " .. tostring(result))
		return false
	end
end

-- =========================
-- // UTILITY
-- =========================

-- GetGuildMemberCount(): Gets the amount a players in a guild
-- @param guildId: The guild ID
-- @return number?: The amount of players in that guild
function GuildService.GetGuildMemberCount(guildId: string): number?
	local guild = GuildService.GetOrLoadGuild(guildId)
	
	if not guild then
		warn("Guild not found")
		return nil
	end
	
	return #guild.Members
end

-- IsGuildFull(): Checks if the guild is full
-- @param guildId: The guild ID
-- @return boolean?: True if the guild is true
function GuildService.IsGuildFull(guildId: string): boolean?
	local guild = GuildService.GetOrLoadGuild(guildId)

	if not guild then
		warn("Guild not found")
		return nil
	end

	return #guild.Members >= Settings.MAX_PLAYERS_PER_GUILD
end

return GuildService