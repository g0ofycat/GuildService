--!strict

-- // .GuildService

export type GuildService = {
	
	-- // Main operations
	
	CreateGuild: (player: Player, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly") -> string?,
	DeleteGuild: (player: Player, guildId: string) -> boolean,
	ModifyGuild: (player: Player, guildId: string, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly") -> string?,
	TransferOwnership: (currentLeader: Player, newLeader: Player, guildId: string) -> boolean,
	
	-- // Guild data operations
	
	GetOrLoadGuild: (guildId: string) -> GuildData?,
	LoadGuild: (guildId: string) -> boolean,
	SaveGuild: (guildId: string) -> boolean,
	SerializeGuild: (guildId: string) -> any?,
	DeserializeGuild: (guildId: string, data: any) -> boolean,
	LoadAllGuilds: () -> boolean,
	
	-- // Player guild operations
	
	CheckPlayerInGuild: (guild: GuildData, player: Player) -> boolean,
	GetPlayerGuild: (player: Player) -> (string?, GuildData?),
	KickPlayer: (guildId: string, player: Player, playerToKick: Player) -> boolean,
	LeaveGuild: (player: Player) -> boolean,
	
	-- // Join system
	
	RequestJoin: (player: Player, guildId: string) -> boolean,
	AcceptJoinRequest: (player: Player, playerToAdd: Player, guildId: string) -> boolean,
	
	-- // Join Request Helpers
	
	RejectJoinRequest: (player: Player, playerToReject: Player, guildId: string) -> boolean,
	GetJoinRequests: (guildId: string) -> { number }?,
	CancelJoinRequest: (player: Player, guildId: string) -> boolean,
	
	-- // Guild Helpers
	
	GetGuildInfo: (guildId: string) -> GuildData?,
	GetGuildMembers: (guildId: string) -> { number }?,
	
	-- // Utility

	GetGuildMemberCount: (guildId: string) -> number?,
	IsGuildFull: (guildId: string) -> boolean?,
	
	-- // Other
	
	Guilds: Guilds
}

export type GuildData = {
	GuildName: string,
	GuildTag: string,
	Description: string,
	GuildLeader: number,
	GuildType: "Public" | "InviteOnly",
	CreatedAt: number,
	Members: { number },
	JoinRequests: { number }
}

export type Guilds = {
	[string]: GuildData -- // [string]: GenerateGUID()
}

-- // .Bitpacker

export type Bitpacker = {
	packGuildData: (guild: GuildData) -> string,
	unpackGuildData: (data: string) -> GuildData
}

-- // .Base64

export type Base64 = {
	Encode: (input: string) -> string,
	Decode: (input: string) -> string,

	Characters: string
}

return nil