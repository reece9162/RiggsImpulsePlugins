/// Helper library for reading/writing files to the data folder.
// @module impulse.FileData

impulse.FileData = impulse.FileData or {}
impulse.FileData.Stored = impulse.FileData.Stored or {}

// Create a folder to store data in.
file.CreateDir("impulse")

/// Populates a file in the `data/impulse` folder with some serialized data.
// @realm shared
// @string key Name of the file to save
// @param value Some sort of data to save
// @bool[opt=false] bGlobal Whether or not to write directly to the `data/impulse` folder, or the `data/impulse/schema` folder,
// where `schema` is the name of the current schema.
// @bool[opt=false] bIgnoreMap Whether or not to ignore the map and save in the schema folder, rather than
// `data/impulse/schema/map`, where `map` is the name of the current map.
function impulse.FileData.Set(key, value, bGlobal, bIgnoreMap)
	// Get the base path to write to.
	local path = "impulse/" .. (bGlobal and "" or SCHEMA_NAME .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")

	// Create the schema folder if the data is not global.
	if (!bGlobal) then
		file.CreateDir("impulse/" .. SCHEMA_NAME .. "/")
	end

	// If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)
	// Write the data using JSON encoding.
	file.Write(path .. key .. ".txt", util.TableToJSON({value}))

	// Cache the data value here.
	impulse.FileData.Stored[key] = value

	return path
end

/// Retrieves the contents of a saved file in the `data/impulse` folder.
// @realm shared
// @string key Name of the file to load
// @param default Value to return if the file could not be loaded successfully
// @bool[opt=false] bGlobal Whether or not the data is in the `data/impulse` folder, or the `data/impulse/schema` folder,
// where `schema` is the name of the current schema.
// @bool[opt=false] bIgnoreMap Whether or not to ignore the map and load from the schema folder, rather than
// `data/impulse/schema/map`, where `map` is the name of the current map.
// @bool[opt=false] bRefresh Whether or not to skip the cache and forcefully load from disk.
// @return Value associated with the key, or the default that was given if it doesn't exists
function impulse.FileData.Get(key, default, bGlobal, bIgnoreMap, bRefresh)
	// If it exists in the cache, return the cached value so it is faster.
	if (!bRefresh) then
		local stored = impulse.FileData.Stored[key]

		if (stored != nil) then
			return stored
		end
	end

	// Get the path to read from.
	local path = "impulse/" .. (bGlobal and "" or SCHEMA_NAME .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	// Read the data from a local file.
	local contents = file.Read(path .. key .. ".txt", "DATA")

	if (contents and contents != "") then
		local status, decoded = pcall(util.JSONToTable, contents)

		if (status and decoded) then
			local value = decoded[1]

			if (value != nil) then
				return value
			end
		end

		// Backwards compatibility.
		// This may be removed in the future.
		status, decoded = pcall(pon.decode, contents)

		if (status and decoded) then
			local value = decoded[1]

			if (value != nil) then
				return value
			end
		end
	end

	return default
end

/// Deletes the contents of a saved file in the `data/impulse` folder.
// @realm shared
// @string key Name of the file to delete
// @bool[opt=false] bGlobal Whether or not the data is in the `data/impulse` folder, or the `data/impulse/schema` folder,
// where `schema` is the name of the current schema.
// @bool[opt=false] bIgnoreMap Whether or not to ignore the map and delete from the schema folder, rather than
// `data/impulse/schema/map`, where `map` is the name of the current map.
// @treturn bool Whether or not the deletion has succeeded
function impulse.FileData.Delete(key, bGlobal, bIgnoreMap)
	// Get the path to read from.
	local path = "impulse/" .. (bGlobal and "" or SCHEMA_NAME .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	// Read the data from a local file.
	local contents = file.Read(path .. key .. ".txt", "DATA")

	if (contents and contents != "") then
		file.Delete(path .. key .. ".txt")
		impulse.FileData.Stored[key] = nil
		return true
	end

	return false
end

if ( SERVER ) then
	timer.Create("impulseSaveData", 600, 0, function()
		hook.Run("SaveData")
	end)
end
