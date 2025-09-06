--!strict

local Types = require(script.Parent.Parent.Misc.Types)

local Bitpacker = {} :: Types.Bitpacker

-- =======================
-- // PRIVATE API
-- =======================

function bufferSize(guild: Types.GuildData): number
	local size = 0
	size += 1 + #guild.GuildName
	size += 1 + #guild.GuildTag
	size += 1 + #guild.Description
	size += 4 -- // GuildLeader (u32)
	size += 1 -- // GuildType (u8)
	size += 4 -- // CreatedAt (u32)
	size += 2 -- // Members count (u16)
	size += #guild.Members * 4 -- // Member IDs (u32 each)
	size += 2 -- // JoinRequests count (u16)
	size += #guild.JoinRequests * 4 -- // Request IDs (u32 each)

	return size
end

-- =======================
-- // PUBLIC API
-- =======================

-- packGuildData(): Packs the guild table for data compression
-- @param guild: The guild table
-- @return string: The buffer in string format
function Bitpacker.packGuildData(guild: Types.GuildData): string
	local size = bufferSize(guild)
	local buf = buffer.create(size)
	local offset = 0

	local function writeString(str: string)
		assert(#str <= 255, "String too long")
		buffer.writeu8(buf, offset, #str)
		offset += 1
		buffer.writestring(buf, offset, str)
		offset += #str
	end

	writeString(guild.GuildName)
	writeString(guild.GuildTag)
	writeString(guild.Description)

	buffer.writeu32(buf, offset, guild.GuildLeader)
	offset += 4

	buffer.writeu8(buf, offset, guild.GuildType == "Public" and 0 or 1)
	offset += 1

	buffer.writeu32(buf, offset, guild.CreatedAt)
	offset += 4

	buffer.writeu16(buf, offset, #guild.Members)
	offset += 2

	for _, userId in guild.Members do
		buffer.writeu32(buf, offset, userId)
		offset += 4
	end

	buffer.writeu16(buf, offset, #guild.JoinRequests)
	offset += 2

	for _, userId in guild.JoinRequests do
		buffer.writeu32(buf, offset, userId)
		offset += 4
	end
	
	return buffer.tostring(buf)
end

-- unpackGuildData(): Unpacks the buffer string and turns it back to normal
-- @param data: The packed buffer string
-- @return guild: The guild table
function Bitpacker.unpackGuildData(data: string): Types.GuildData
	local buf = buffer.fromstring(data)
	local offset = 0

	local function readString(): string
		local len = buffer.readu8(buf, offset)
		offset += 1
		local str = buffer.readstring(buf, offset, len)
		offset += len
		return str
	end

	local name = readString()
	local tag = readString()
	local desc = readString()

	local leader = buffer.readu32(buf, offset)
	offset += 4

	local typeByte = buffer.readu8(buf, offset)
	offset += 1

	local createdAt = buffer.readu32(buf, offset)
	offset += 4

	local memberCount = buffer.readu16(buf, offset)
	offset += 2

	local members = {}
	for _ = 1, memberCount do
		table.insert(members, buffer.readu32(buf, offset))
		offset += 4
	end

	local requestCount = buffer.readu16(buf, offset)
	offset += 2

	local joinRequests = {}
	for _ = 1, requestCount do
		table.insert(joinRequests, buffer.readu32(buf, offset))
		offset += 4
	end

	return {
		GuildName = name,
		GuildTag = tag,
		Description = desc,
		GuildLeader = leader,
		GuildType = typeByte == 0 and "Public" or "InviteOnly",
		CreatedAt = createdAt,
		Members = members,
		JoinRequests = joinRequests
	} :: Types.GuildData
end

return Bitpacker