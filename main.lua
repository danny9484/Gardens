PLUGIN = nil

function Initialize(Plugin)
	Plugin:SetName("Gardens")
	Plugin:SetVersion(1)

	-- Hooks
  --cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_AVAILABLE, MyOnChunkAvailable);
  cPluginManager:AddHook(cPluginManager.HOOK_UPDATING_SIGN, MyOnUpdatingSign);
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, MyOnPlayerBreakingBlock);
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_PLACING_BLOCK, MyOnPlayerPlacingBlock);
	--cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, MyOnWorldStarted);
	--cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, MyOnPlayerJoined);

	PLUGIN = Plugin -- NOTE: only needed if you want OnDisable() to use GetName() or something like that

	-- Command Bindings

	-- Database stuff
	g_Storage = cSQLiteStorage:new()
	create_database()

	-- Global variables
	fences = {}
	marker = {}
	signs = {}
	signs_maybe = {}

	Initialize_signs()
	Initialize_marker()
	Initialize_fences()

	LOG("Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
	return true
end

function Initialize_marker()
		local callback = function(World)
			local world_name = World:GetName()
			g_Storage:ExecuteCommand("initialize_marker",
				{
					World_name = world_name
				},
				function(a_Values)
					local X = a_Values["X"]
					local Y = a_Values["Y"]
					local Z = a_Values["Z"]
					local World_name = a_Values["World"]
					set_marker(X, Y, Z, World_name)
				end
			)
		end
		cRoot:Get():ForEachWorld(callback)
end

function Initialize_fences()
		local callback = function(World)
			local world_name = World:GetName()
			g_Storage:ExecuteCommand("initialize_fences",
				{
					World_name = world_name
				},
				function(a_Values)
					local X = a_Values["X"]
					local Y = a_Values["Y"]
					local Z = a_Values["Z"]
					local World_name = a_Values["World"]
					local Player_name = a_Values["Player_name"]
					set_fences(X, Z, Player_name, World_name)
				end
			)
		end
		cRoot:Get():ForEachWorld(callback)
end

function Initialize_signs()
		local callback = function(World)
			local world_name = World:GetName()
			g_Storage:ExecuteCommand("initialize_signs",
				{
					World_name = world_name
				},
				function(a_Values)
					local X = a_Values["X"]
					local Y = a_Values["Y"]
					local Z = a_Values["Z"]
					local World_name = a_Values["World"]
					local Player_name = a_Values["Player_name"]
					set_signs(X, Y, Z, Player_name, World_name)
				end
			)
		end
		cRoot:Get():ForEachWorld(callback)
end

function save_marker(X, Y, Z, World)
	-- register new sign in database
	g_Storage:ExecuteCommand("save_marker",
		{
			X = X,
			Y = Y,
			Z = Z,
			World = World:GetName(),
		}
	)
	return true
end

function save_fence(X, Z, Player_name, World)
	-- register new sign in database
	g_Storage:ExecuteCommand("save_fence",
		{
			X = X,
			Z = Z,
			World = World:GetName(),
			Player_name = Player_name
		}
	)
	return true
end

function save_sign(X, Y, Z, World, Player_name)
	-- register new sign in database
	g_Storage:ExecuteCommand("save_sign",
		{
			X = X,
			Y = Y,
			Z = Z,
			World = World:GetName(),
			Player_name = Player_name
		}
	)
	return true
end

function remove_sign(X, Y, Z, World)
	-- remove sign in database
	g_Storage:ExecuteCommand("remove_sign",
		{
			X = X,
			Y = Y,
			Z = Z,
			World = World:GetName()
		}
	)
	return true
end

function remove_fence(X, Z, World)
	-- remove sign in database
	g_Storage:ExecuteCommand("remove_fence",
		{
			X = X,
			Z = Z,
			World = World:GetName()
		}
	)
	return true
end

function remove_marker(X, Y, Z, World)
	-- remove sign in database
	g_Storage:ExecuteCommand("remove_marker",
		{
			X = X,
			Y = Y,
			Z = Z,
			World = World:GetName()
		}
	)
	return true
end

function OnDisable()
	LOG(PLUGIN:GetName() .. " is shutting down...")
end

function create_database()
	-- Create DB if not exists
	cSQLiteStorage:new()
  return true
end

function MyOnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockType, BlockMeta)
	if fences[BlockX] == nil or fences[BlockX][BlockZ][Player:GetWorld()] == nil then	-- belongs the block to nobody?
		return false
	end
	if fences[BlockX][BlockZ][Player:GetWorld()][Player:GetName()] == true then -- belongs the block to the player breaking it?
		return false
	end
	Player:SendMessage("you can't place in this garden")
	return true	-- you can't place anything
end

function MyOnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	if signs ~= nil and signs[BlockX] ~= nil and signs[BlockX][BlockY] ~= nil and signs[BlockX][BlockY][BlockZ] ~= nil and signs[BlockX][BlockY][BlockZ][Player:GetWorld():GetName()] ~= nil and signs[BlockX][BlockY][BlockZ][Player:GetWorld():GetName()][Player:GetName()] == true then
		local World = Player:GetWorld()
		remove_sign(BlockX, BlockY, BlockZ, World)
		local X, Y, Z = check_fence_gate(World, BlockX, BlockY, BlockZ)
		local X_fence, Y_fence, Z_fence = X, Y, Z
		X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, "", false, true, Player_name, friend1, friend2)
		while X ~= X_fence or Y ~= Y_fence or Z ~= Z_fence do
			X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, D_fence, false, true, Player_name, friend1, friend2)
		end
		Player:SendMessage("you removed your Garden")
		return false
	end
	if marker ~= nil and marker[BlockX] ~= nil and marker[BlockX][BlockY] ~= nil and marker[BlockX][BlockY][BlockZ] ~= nil and marker[BlockX][BlockY][BlockZ][Player:GetWorld():GetName()] ~= nil then
		Player:SendMessage("destroy the Garden Sign first to remove your Garden")
		return true
	end
	if fences[BlockX] == nil or fences[BlockX][BlockZ][Player:GetWorld()] == nil then	-- belongs the block to nobody?
		return false
	end
	if fences[BlockX][BlockZ][Player:GetWorld()][Player:GetName()] == true then -- belongs the block to the player breaking it?
		return false
	end
	Player:SendMessage("you can't destroy this garden")
	return true	-- you can't break it
end

function MyOnChunkAvailable(World, ChunkX, ChunkZ)
  local RelX = 0
  local RelY = 0
  local RelZ = 0
  local height = 256
  while RelX < 16 do
    while RelY < height do
      while RelZ < 16 do
        if signs_maybe[RelX + ChunkX] ~= nil and signs_maybe[RelX + ChunkX][RelY] ~= nil and signs_maybe[RelX + ChunkX][RelY][RelZ + ChunkZ] == true then
          sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
        end
        RelZ = RelZ + 1
      end
      if signs_maybe[RelX + ChunkX] ~= nil and signs_maybe[RelX + ChunkX][RelY] ~= nil and signs_maybe[RelX + ChunkX][RelY][RelZ + ChunkZ] == true then
        sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
      end
      RelY = RelY + 1
    end
    if signs_maybe[RelX + ChunkX] ~= nil and signs_maybe[RelX + ChunkX][RelY] ~= nil and signs_maybe[RelX + ChunkX][RelY][RelZ + ChunkZ] == true then
    sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
    end
    RelX = RelX + 1
  end
end

function process_garden(World, X, Y, Z, register, Player_name, friend1, friend2)
  if check_fence_gate(World, X, Y, Z) == false then
    return false
  end
	LOG("gate is working")
  if check_fence(World, X, Y, Z, register, Player_name, friend1, friend2) == false then
		LOG("error")
    return false
  end
	if register == false then
		LOG("registering now")
		process_garden(World, X, Y, Z, true, Player_name, friend1, friend2)
	end
	return true
end

function register_marker(X, Y, Z, World)
	marker[X][Y][Z][World:GetName()] = true
end

function register_fence(X, Z, Player_name, World)
	fences[X][Z][World:GetName()][Player_name] = true
	fences[X + 1][Z][World:GetName()][Player_name] = true
	fences[X + 1][Z + 1][World:GetName()][Player_name] = true
	fences[X + 1][Z - 1][World:GetName()][Player_name] = true
	fences[X - 1][Z][World:GetName()][Player_name] = true
	fences[X - 1][Z + 1][World:GetName()][Player_name] = true
	fences[X + 1][Z - 1][World:GetName()][Player_name] = true
	fences[X][Z + 1][World:GetName()][Player_name] = true
	fences[X][Z - 1][World:GetName()][Player_name] = true
	return true
end

function check_variables(X, Y, Z, World)
	if marker[X] == nil then
		marker[X] = {}
	end
	if marker[X][Y] == nil then
		marker[X][Y] = {}
	end
	if marker[X][Y][Z] == nil then
		marker[X][Y][Z] = {}
	end
	if marker[X][Y][Z][World:GetName()] == nil then
		marker[X][Y][Z][World:GetName()] = {}
	end
	if fences[X] == nil then
		fences[X] = {}
	end
	if fences[X][Z] == nil then
		fences[X][Z] = {}
	end
	if fences[X][Z][World:GetName()] == nil then
		fences[X][Z][World:GetName()] = {}
	end
	if fences[X - 1] == nil then
		fences[X - 1] = {}
	end
	if fences[X + 1] == nil then
		fences[X + 1] = {}
	end
	if fences[X - 1][Z] == nil then
		fences[X - 1][Z] = {}
	end
	if fences[X + 1][Z] == nil then
		fences[X + 1][Z] = {}
	end
	if fences[X][Z - 1] == nil then
		fences[X][Z - 1] = {}
	end
	if fences[X][Z + 1] == nil then
		fences[X][Z + 1] = {}
	end
	if fences[X + 1][Z + 1] == nil then
		fences[X + 1][Z + 1] = {}
	end
	if fences[X - 1][Z + 1] == nil then
		fences[X - 1][Z + 1] = {}
	end
	if fences[X + 1][Z - 1] == nil then
		fences[X + 1][Z - 1] = {}
	end
	if fences[X - 1][Z - 1] == nil then
		fences[X - 1][Z - 1] = {}
	end
	if fences[X - 1][Z][World:GetName()] == nil then
		fences[X - 1][Z][World:GetName()] = {}
	end
	if fences[X + 1][Z][World:GetName()] == nil then
		fences[X + 1][Z][World:GetName()] = {}
	end
	if fences[X][Z - 1][World:GetName()] == nil then
		fences[X][Z - 1][World:GetName()] = {}
	end
	if fences[X][Z + 1][World:GetName()] == nil then
		fences[X][Z + 1][World:GetName()] = {}
	end
	if fences[X + 1][Z + 1][World:GetName()] == nil then
		fences[X + 1][Z + 1][World:GetName()] = {}
	end
	if fences[X - 1][Z + 1][World:GetName()] == nil then
		fences[X - 1][Z + 1][World:GetName()] = {}
	end
	if fences[X + 1][Z - 1][World:GetName()] == nil then
		fences[X + 1][Z - 1][World:GetName()] = {}
	end
	if fences[X - 1][Z - 1][World:GetName()] == nil then
		fences[X - 1][Z - 1][World:GetName()] = {}
	end
end

function deregister_fence(X, Z, World)
	fences[X][Z][World:GetName()] = nil
	fences[X + 1][Z][World:GetName()] = nil
	fences[X + 1][Z + 1][World:GetName()] = nil
	fences[X + 1][Z - 1][World:GetName()] = nil
	fences[X - 1][Z][World:GetName()] = nil
	fences[X - 1][Z + 1][World:GetName()] = nil
	fences[X + 1][Z - 1][World:GetName()] = nil
	fences[X][Z + 1][World:GetName()] = nil
	fences[X][Z - 1][World:GetName()] = nil
end

function deregister_marker(X, Y, Z, World)
	marker[X][Y][Z][World:GetName()] = nil
end



function fence_function(World, X, Y, Z, D, register, deregister, Player_name, friend1, friend2)
	if deregister then
			deregister_fence(X, Z, World)
			remove_fence(X, Z, World)
			deregister_marker(X, Y, Z, World)
			remove_marker(X, Y, Z, World)
	end
	if register then
		check_variables(X, Y, Z, World)
			register_fence(X, Z, Player_name, World)
			save_fence(X, Z, Player_name, World)
			register_marker(X, Y, Z, World)
			save_marker(X, Y, Z, World)
			if friend1 ~= nil then
				register_fence(X, Z, friend1, World)
				save_fence(X, Z, friend1, World)
			end
			if friend2 ~= nil then
				register_fence(X, Z, friend2, World)
				save_fence(X, Z, friend2, World)
			end
	end
	if (World:GetBlock(X + 1, Y, Z) == 85 or World:GetBlock(X + 1, Y, Z) == 107) and D ~= "x-" then
		return X + 1, Y, Z, "x+"
	else if (World:GetBlock(X, Y, Z + 1) == 85 or World:GetBlock(X, Y, Z + 1) == 107) and D ~= "z-" then
			return X, Y, Z + 1, "z+"
		else if (World:GetBlock(X - 1, Y, Z) == 85 or World:GetBlock(X - 1, Y, Z) == 107) and D ~= "x+" then
				return X - 1, Y, Z, "x-"
			else if (World:GetBlock(X, Y, Z - 1) == 85 or World:GetBlock(X, Y, Z - 1) == 107) and D ~= "z+" then
					return X, Y, Z - 1, "z-"
				end
			end
		end
	end
	return false
end

function check_fence(World, X, Y, Z, register, Player_name, friend1, friend2)
  X, Y, Z = check_fence_gate(World, X, Y, Z)
  local X_fence, Y_fence, Z_fence = X, Y, Z
	X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, "", register, false, Player_name, friend1, friend2)
  while X ~= X_fence or Y ~= Y_fence or Z ~= Z_fence do
		X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, D_fence, register, false, Player_name, friend1, friend2)
		if X_fence == false then
			return false
		end
  end
	LOG("finished")
	return true
end

function check_fence_gate(World, X, Y, Z, register, Player_name)
  if World:GetBlock(X + 1, Y, Z) == 107 then
    return X + 1, Y, Z
  end
  if World:GetBlock(X - 1, Y, Z) == 107 then
    return X - 1, Y, Z
  end
  if World:GetBlock(X, Y, Z + 1) == 107 then
    return X, Y, Z + 1
  end
  if World:GetBlock(X, Y, Z - 1) == 107 then
    return X, Y, Z + 1
  end
  return false
end

function set_fences(X, Z, Line2, World_name)
	if fences[X] == nil then
		fences[X] = {}
	end
	if fences[X][Z] == nil then
		fences[X][Z] = {}
	end
	if fences[X][Z][World_name] == nil then
		fences[X][Z][World_name] = {}
	end
	fences[X][Z][World_name][Line2] = true
end

function set_marker(X, Y, Z, World_name)
	if marker[X] == nil then
		marker[X] = {}
	end
	if marker[X][Y] == nil then
		marker[X][Y] = {}
	end
	if marker[X][Y][Z] == nil then
		marker[X][Y][Z] = {}
	end
	marker[X][Y][Z][World_name] = true
end

function set_signs(X, Y, Z, Line2, World_name)
	if signs[X] == nil then
		signs[X] = {}
	end
	if signs[X][Y] == nil then
		signs[X][Y] = {}
	end
	if signs[X][Y][Z] == nil then
		signs[X][Y][Z] = {}
	end
	if signs[X][Y][Z][World_name] == nil then
		signs[X][Y][Z][World_name] = {}
	end
	signs[X][Y][Z][World_name][Line2] = true
end

function sign_found(World, X, Y, Z)
  local sign_valid, Line1, Line2, Line3, Line4 = World:GetSignLines(X , Y, Z)
	LOG(X .. " " .. Y .. " " .. Z)
	if sign_valid then
		LOG("test123")
	else
		LOG("nope")
	end
  if Line1 == "[garden]" then
    if Line2 ~= "" then
      LOG("found a Garden by " .. Line2)
      if process_garden(World, X, Y, Z, false, Line2) then
				set_signs(X, Y, Z, Line2)
        return true
      end
    end
    LOG("found a broken Garden")
  end
end

function MyOnUpdatingSign(World, BlockX, BlockY, BlockZ, Line1, Line2, Line3, Line4, Player)
    if Line1 == "[garden]" then
      if process_garden(World, BlockX, BlockY, BlockZ, false, Player:GetName(), Line3, Line4) then
        Player:SendMessage("you created a Garden")
				save_sign(BlockX, BlockY, BlockZ, World, Player:GetName())
				set_signs(BlockX, BlockY, BlockZ, Player:GetName(), World:GetName())
        return false, Line1, Player:GetName(), Line3, Line4;
      end
      Player:SendMessage("your Garden is broken")
    end
end
