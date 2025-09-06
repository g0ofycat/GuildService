--!strict

-- =======================
-- // IMPORTS & MAIN
-- =======================

local Types = require(script.Parent.Parent.Misc.Types)

local Base64 = {} :: Types.Base64

-- =======================
-- // VARIABLES
-- =======================

Base64.Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- =======================
-- // PUBLIC API
-- =======================

-- Encode(): Encodes a string to Base64 for serilization
-- @param input: The string to convert
-- @return string: The encoded string
function Base64.Encode(input: string): string
	local output = {}
	local bytes = { string.byte(input, 1, #input) }

	for i = 1, #bytes, 3 do
		local a = bytes[i]
		local b = bytes[i + 1] or 0
		local c = bytes[i + 2] or 0

		local n = bit32.lshift(a, 16) + bit32.lshift(b, 8) + c

		local c1 = bit32.band(bit32.rshift(n, 18), 0x3F) + 1
		local c2 = bit32.band(bit32.rshift(n, 12), 0x3F) + 1
		local c3 = bit32.band(bit32.rshift(n, 6), 0x3F) + 1
		local c4 = bit32.band(n, 0x3F) + 1

		table.insert(output, string.sub(Base64.Characters, c1, c1))
		table.insert(output, string.sub(Base64.Characters, c2, c2))
		table.insert(output, i + 1 > #bytes and "=" or string.sub(Base64.Characters, c3, c3))
		table.insert(output, i + 2 > #bytes and "=" or string.sub(Base64.Characters, c4, c4))
	end

	return table.concat(output)
end

-- Decode(): Decodes a Base64 string
-- @param input: The string to convert
-- @return string: The decoded string
function Base64.Decode(input: string): string
	local output = {}
	local bytes = {}
	local map = {}

	for i = 1, #Base64.Characters do
		map[string.sub(Base64.Characters, i, i)] = i - 1
	end

	input = input:gsub("[^%w+/=]", "")

	for i = 1, #input, 4 do
		local a = map[string.sub(input, i, i)] or 0
		local b = map[string.sub(input, i + 1, i + 1)] or 0
		local c = map[string.sub(input, i + 2, i + 2)] or 0
		local d = map[string.sub(input, i + 3, i + 3)] or 0

		local n = bit32.lshift(a, 18) + bit32.lshift(b, 12) + bit32.lshift(c, 6) + d

		local byte1 = bit32.rshift(n, 16) % 256
		local byte2 = bit32.rshift(n, 8) % 256
		local byte3 = n % 256

		table.insert(bytes, string.char(byte1))
		
		if input:sub(i + 2, i + 2) ~= "=" then
			table.insert(bytes, string.char(byte2))
		end
		if input:sub(i + 3, i + 3) ~= "=" then
			table.insert(bytes, string.char(byte3))
		end
	end

	return table.concat(bytes)
end

return Base64