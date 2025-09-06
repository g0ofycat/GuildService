--!strict

local Settings = {
	MAX_PLAYERS_PER_GUILD = 50, -- // The maximum players allowed in 1 guild
	NAME_CHARACTER_LIMIT = 50, -- // The Character limit for the name when creating or modifying guilds
	TAG_CHARACTER_LIMIT = 5, -- // The Character limit for the tag when creating or modifying guilds
	DESCRIPTION_CHARACTER_LIMIT = 255, -- // The Character limit for the description when creating or modifying guilds
}

table.freeze(Settings)

return Settings