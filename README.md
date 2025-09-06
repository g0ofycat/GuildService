# GuildService

GuildService is a module used for creating **'clans / guilds'** inside of Roblox Games. It handles data compression and also serialization of data. The API is quite simple to use and Guilds can also be *'Public'* or *'InviteOnly'*.

# How to use

1. **Creating Guilds**

```lua
local GuildService = require(path.to.GuildService)

local guildId = GuildService.CreateGuild(path.to.player, "Knights", "KN", "A fun guild", "Public") -- // :CreateGuild() returns a guildId created by :GenerateGUID(). This guildId is used for most core operations and can easily be retrived through DataStores

if guildId then
    print("Guild created with ID:", guildId)
end
```

2. **Modifying a Guild**

```lua
local GuildService = require(path.to.GuildService)

GuildService.ModifyGuild(guildId, player, "New Knights", "NK", "Updated description", "InviteOnly")
```

3. **Deleting a Guild**

```lua
local GuildService = require(path.to.GuildService)

local success = GuildService.DeleteGuild(player, guildId)

print("Guild deleted?", success)
```

4. **Transferring Guild Ownership**

```lua
local GuildService = require(path.to.GuildService)

GuildService.TransferOwnership(currentLeader, newLeader, guildId)
```

5. **Transferring Guild Ownership**

```lua
local GuildService = require(path.to.GuildService)

GuildService.LoadGuild(guildId)

local data = GuildService.SerializeGuild(guildId)

GuildService.SaveGuild(guildId)
```

6. **Transferring Guild Ownership**

```lua
local GuildService = require(path.to.GuildService)

local guild = GuildService.GetOrLoadGuild(guildId)

local isMember = GuildService.CheckPlayerInGuild(guild, player)

print(player.Name, "is member?", isMember)
```

7. **Getting Player’s Guild**

```lua
local GuildService = require(path.to.GuildService)

local playerGuildId, guildData = GuildService.GetPlayerGuild(player)

if playerGuildId then
    print("Player is in guild:", playerGuildId)
end
```

8. **Kicking or Leaving a Guild**

```lua
local GuildService = require(path.to.GuildService)

GuildService.KickPlayer(guildId, guildLeader, memberToKick)

GuildService.LeaveGuild(player)
```

9. **Joining a Guild (AcceptJoinRequest and RejectJoinRequest is for 'InviteOnly' Guilds)**

```lua
local GuildService = require(path.to.GuildService)

GuildService.RequestJoin(player, guildId)

GuildService.AcceptJoinRequest(guildLeader, player, guildId)

GuildService.RejectJoinRequest(guildLeader, player, guildId)

GuildService.CancelJoinRequest(player, guildId)
```

10. **Getting Guild Info and Members**

```lua
local GuildService = require(path.to.GuildService)

local guildInfo = GuildService.GetGuildInfo(guildId)

local members = GuildService.GetGuildMembers(guildId)

print("Guild Info:", guildInfo)

print("Members:", members)
```

11. **Utility Functions**

```lua
local GuildService = require(path.to.GuildService)

local memberCount = GuildService.GetGuildMemberCount(guildId)

local isFull = GuildService.IsGuildFull(guildId)

print("Member count:", memberCount, "Guild full?", isFull)
```

# API Reference

```lua
export type GuildService = {
	
	-- // Main operations
	
	CreateGuild: (player: Player, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly") -> string?,
	DeleteGuild: (player: Player, guildId: string) -> boolean,
	ModifyGuild: (guildId: string, player: Player, guildName: string, guildTag: string, description: string, guildType: "Public" | "InviteOnly") -> string?,
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
```