# GuildService

**GuildService** is a Roblox module designed to manage **clans or guilds** within your game.  
It provides a complete system for creating, modifying, and managing guilds, including handling **data serialization** and **compression** for efficient storage and retrieval.

Guilds can be either **Public**, allowing anyone to join freely, or **InviteOnly**, requiring approval from the guild leader.

The module has a clean API, making it easy to integrate while also providing features like:

- *Membership management*
- *Join requests*
- *Guild ownership transfer*
- *Utility functions* for querying guild information

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

GuildService.ModifyGuild(player, guildId, "New Knights", "NK", "Updated description", "InviteOnly")
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

5. **Checking Player Membership**

```lua
local GuildService = require(path.to.GuildService)

local guild = GuildService.GetOrLoadGuild(guildId)

local isMember = GuildService.CheckPlayerInGuild(guild, player)

print(player.Name, "is member?", isMember)
```

6. **Getting Player’s Guild**

```lua
local GuildService = require(path.to.GuildService)

local playerGuildId, guildData = GuildService.GetPlayerGuild(player)

if playerGuildId then
    print("Player is in guild:", playerGuildId)
end
```

7. **Kicking or Leaving a Guild**

```lua
local GuildService = require(path.to.GuildService)

GuildService.KickPlayer(guildId, guildLeader, memberToKick)

GuildService.LeaveGuild(player)
```

8. **Joining a Guild (AcceptJoinRequest and RejectJoinRequest is for 'InviteOnly' Guilds)**

```lua
local GuildService = require(path.to.GuildService)

GuildService.RequestJoin(player, guildId)

GuildService.AcceptJoinRequest(guildLeader, player, guildId)

GuildService.RejectJoinRequest(guildLeader, player, guildId)

GuildService.CancelJoinRequest(player, guildId)
```

9. **Getting Guild Info and Members**

```lua
local GuildService = require(path.to.GuildService)

local guildInfo = GuildService.GetGuildInfo(guildId)

local members = GuildService.GetGuildMembers(guildId)

print("Guild Info:", guildInfo)

print("Members:", members)
```

10. **Utility Functions**

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
```