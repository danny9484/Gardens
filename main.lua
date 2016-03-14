PLUGIN = nil

function Initialize(Plugin)
	Plugin:SetName("Gardens")
	Plugin:SetVersion(1)

	-- Hooks
  cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_AVAILABLE, MyOnChunkAvailable);
  cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BROKEN_BLOCK, MyOnPlayerBrokenBlock);
  cPluginManager:AddHook(cPluginManager.HOOK_UPDATING_SIGN, MyOnUpdatingSign);
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, MyOnPlayerBreakingBlock);


	PLUGIN = Plugin -- NOTE: only needed if you want OnDisable() to use GetName() or something like that

	-- Command Bindings

	-- Global variables
	fences = {}

	LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
	return true
end

function OnDisable()
	LOG(PLUGIN:GetName() .. " is shutting down...")
end

function MyOnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	if fences[BlockX] == nil and fences[BlockX][BlockZ] == nil then	-- belongs the block to nobody?
		return false
	end
	if fences[BlockX][BlockZ][Player:GetName()] == true then -- belongs the block to the player breaking it?
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
        if World:GetBlock(RelX + ChunkX, RelY, RelZ + ChunkZ) == 63 then
          sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
        end
        RelZ = RelZ + 1
      end
      if World:GetBlock(RelX + ChunkX, RelY, RelZ + ChunkZ) == 63 then
        sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
      end
      RelY = RelY + 1
    end
    if World:GetBlock(RelX + ChunkX, RelY, RelZ + ChunkZ) == 63 then
    sign_found(World, RelX + ChunkX, RelY, RelZ + ChunkZ)
    end
    RelX = RelX + 1
  end
end

function process_garden(World, X, Y, Z, register, Player_name)
  if check_fence_gate(World, X, Y, Z) == false then
    return false
  end
	LOG("gate is working")
  if check_fence(World, X, Y, Z, register, Player_name) == false then
		LOG("error")
    return false
  end
	if register == false then
		LOG("registering now")
		process_garden(World, X, Y, Z, true, Player_name)
	end
	return true
end

function fence_function(World, X, Y, Z, D, register, Player_name)
	LOG(Player_name)
	if register then
		LOG("1")
		if fences[X] == nil then
			LOG("2")
			fences[X] = {}
		end
		if fences[X][Z] == nil then
			LOG("3")
			fences[X][Z] = {}
		end
		if fences[X][Z][Player_name] == nil then
			LOG("4")
			LOG(Player_name)
			fences[X][Z][Player_name] = true
			LOG(X .. " " .. Z .. " " .. Player_name)
		end
	end
	if (World:GetBlock(X + 1, Y, Z) == 85 or World:GetBlock(X + 1, Y, Z) == 107) and D ~= "x-" then
		LOG("left")
		return X + 1, Y, Z, "x+"
	else if (World:GetBlock(X, Y, Z + 1) == 85 or World:GetBlock(X, Y, Z + 1) == 107) and D ~= "z-" then
		LOG("up")
			return X, Y, Z + 1, "z+"
		else if (World:GetBlock(X - 1, Y, Z) == 85 or World:GetBlock(X - 1, Y, Z) == 107) and D ~= "x+" then
			LOG("right")
				return X - 1, Y, Z, "x-"
			else if (World:GetBlock(X, Y, Z - 1) == 85 or World:GetBlock(X, Y, Z - 1) == 107) and D ~= "z+" then
				LOG("down")
					return X, Y, Z - 1, "z-"
				end
			end
		end
	end
	return false
end

function check_fence(World, X, Y, Z, register, Player_name)
  X, Y, Z = check_fence_gate(World, X, Y, Z)
  local X_fence, Y_fence, Z_fence = X, Y, Z
	X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, "", register, Player_name)
	LOG(X_fence .. " " .. Y_fence .. " " .. Z_fence .. " " .. D_fence)
	LOG(X .. " " .. Y .. " " .. Z)
  while X ~= X_fence or Y ~= Y_fence or Z ~= Z_fence do
		X_fence, Y_fence, Z_fence, D_fence = fence_function(World, X_fence, Y_fence, Z_fence, D_fence, register, Player_name)
		if X_fence == false then
			return false
		end
		LOG("fence_registered")
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

function sign_found(World, X, Y, Z)
  local sign_valid, Line1, Line2, Line3, Line4 = World:GetSignLines(X , Y, Z)
  if Line1 == "[garden]" then
    if Line2 ~= "" then
      LOG("found a garden by " .. Line2)
      if process_garden(World, X, Y, Z, false, Line2) then
        return true
      end
    end
    LOG("found a broken garden")
  end
end

function MyOnUpdatingSign(World, BlockX, BlockY, BlockZ, Line1, Line2, Line3, Line4, Player)
    if Line1 == "[garden]" then
      if process_garden(World, BlockX, BlockY, BlockZ, false, Player:GetName()) then
        Player:SendMessage("you have created a garden")
        return false, Line1, Player:GetName(), Line3, Line4;
      end
      Player:SendMessage("your garden is broken")
    end
end

function MyOnPlayerBrokenBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
  LOG(BlockType)
end
