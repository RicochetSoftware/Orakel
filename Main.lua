local root = script.Parent
local Module = {}
local run = game:GetService("RunService")



Module.Configuration = {
	Version = "version 1.8.1.0";
	SoloTestMode = game:FindService("NetworkServer") == nil and game:FindService("NetworkClient") == nil;
	PrintHeader = "Orakel |  ";
	WarnHeader = "Orakel Warning |  ";
	ErrorHeader = "Orakel Error |  ";
	Logo = {
		Full = "http://www.roblox.com/asset/?id=220270074";
		Symbol = "http://www.roblox.com/asset/?id=220270067";
		Text = "http://www.roblox.com/asset/?id=220270070";
	};
	Entities = root.Entities;
}



Module.GameInfo = {
	Name = "ORAKEL";
	Icon = "http://www.roblox.com/asset/?id=220270070";
	IntroSong = "http://www.roblox.com/asset/?id=157520543";
	MainMenu = true; --Run main menu OR just straight up load a level?
	StartLevel = "c1m1";
	--MapsDir = game.ServerStorage.Maps;
	ScriptsDir = game.ReplicatedStorage.Scripts;
	CutsceneDir = game.ReplicatedStorage.Cutscenes;
	AnimsDir = game.ReplicatedStorage.Animations;
	EventsDir = game.ReplicatedStorage.Events;
	CustomPlayer = false;
	CameraOffset = CFrame.new(0, 2, 0); --NOTE: ONLY ACTIVE WHEN CUSTOMPLAYER IS ENABLED
	--3rd. Person: CFrame.new(1, 2, 10);
	CorpseFadeTime = 10;
}



--Essentially this list defines what brushes are drawn invisible when compiled
Module.EntitiesToHide = {
	--string Entity, bool setInvis
	["point_camera"] = true;
	["info_player_start"] = true;
	["func_button"] = true;
	["func_water"] = true;
	["func_trigger"] = true;
	["trigger_hurt"] = true;
	["nav_clip"] = true;
	["func_precipitation"] = true;
}


Module.GetChildrenRecursive = function(obj)
  local children = obj:GetChildren()
  local list = {}
  for child = 1, #children do
    list[#list + 1] = children[child]
    local subChildren = Module.GetChildrenRecursive(children[child])
    for sc = 1, #subChildren do
      list[#list + 1] = subChildren[sc]
    end
  end
  return list
end


local function initEntity(ent, sc)
  local entCode = require(sc)
  
  local kvals = entCode.KeyValues
  local inputs = entCode.Inputs
  local update = entCode.Update

  if update ~= nil then
    spawn(function()
      update(ent)
    end)
  end
  print("initializing "..tostring(ent).." ...")
  
  if inputs ~= nil then
    for input, func in pairs(inputs) do
      local newInp = Module.InitInput(ent, input)
      newInp.Event:connect(func)
    end
  else
    warn(Module.Configuration.ErrorHeader.."Entity '"..tostring(ent).."' has no inputs defined!!")
  end
  game.ReplicatedStorage.Events.MapChange.Event:connect(entCode.Kill)
end


Module.InitEntities = function(map)
  local ents = map.Entities:GetChildren()
  local eScripts = game.ReplicatedStorage.Orakel.Entities:GetChildren()
  for _, ent in pairs(ents) do
    for _, es in pairs(eScripts) do
      if es.Name == ent.Name then
        initEntity(ent, es)
        --else
        --warn(Module.Configuration.WarnHeader.."Tried to initialize invalid entity '"..ent.Name.."' !")
      end
    end
  end
end



Module.InitInput = function(ent, name)
  local be = Instance.new("BindableEvent")
  be.Name = name
  be.Parent = ent
  return be
end


Module.FireInput = function(ent, inp, ...)
  local ex = ent:FindFirstChild(inp, true)
  if ex then
    ex:Fire(ent, ...)
  else
    warn(Module.Configuration.WarnHeader.."Tried to fire input '"..tostring(inp).."' which is not a part of '"..tostring(ent).."' !")
  end
end


Module.GetKeyValue = function(ent, val)
  local ex = ent:FindFirstChild(val, true)
  if ex then
    return ex.Value
  end
  return nil
end


Module.SetKeyValue = function(ent, val, newVal)
  local ex = ent:FindFirstChild(val, true)
  if ex then
    ex.Value = newVal
  end
end



Module.TweenModel = function(model, c0, c1, t0, callBack)
	print(Module.Configuration.PrintHeader.."Tweening "..tostring(model).."...")
	local CFrameInterp = Module.LoadModule("CFrameInterp")
	local children = Module.GetChildrenRecursive(model)
	local now = tick()
	local angle, interpFunc = CFrameInterp(c0, c1)
	local steps = t0 * 60
	local lastPos = model.PrimaryPart.Position
	local lastTick = tick()

	for f = 0, steps, 1 / steps do
		if f >= 1 then
			break
		end
		local cf = interpFunc(f)
		model:SetPrimaryPartCFrame(cf)
		for i = 1, #children do
			if children[i]:IsA("BasePart") then
				local v = (model.PrimaryPart.Position - lastPos) / (lastTick - tick())
				children[i].Velocity = Vector3.new(-v.x, -v.y, -v.z)
			end
		end
		
		lastPos = model.PrimaryPart.Position
		lastTick = tick()
		Module.WaitRender()
	end
	
	for _, p in pairs(children) do
		if p:IsA("BasePart") then
			p.Velocity = Vector3.new(0, 0, 0)
		end
	end
	
	model:SetPrimaryPartCFrame(c1)
	print(Module.Configuration.PrintHeader..tick() - now.." time taken to tween "..tostring(model)..", Set Duration was "..t0)
	
	if callBack ~= nil then
		if type(callBack) == "function" then
			callBack()
		end
	end
end



Module.PrintVersion = function()
	warn("Orakel "..Module.Configuration.Version.." up and running!")
end



Module.PrintStatus = function(origin)
	warn(Module.Configuration.PrintHeader..origin.." initialized")
end



Module.WaitRender = function()
	run.RenderStepped:wait()
end


Module.FindSound = function(name)
	local assetlib = Module.LoadModule("AssetLib")
	for _, stype in pairs(assetlib.Sounds) do
		for sname, snd in pairs(stype) do
			if sname == name then
				return snd
			end
		end
	end
	return nil
end


local function findScript(rootDir, sc)
  local strLib = Module.LoadModule("StringLib")
  local folder, file
  local filename = sc
  if string.find(sc, "_") then
    filename = strLib.Split(sc, "_")
  end
  if type(filename) == "table" then
    folder = rootDir:FindFirstChild(filename[1])
    file = folder:FindFirstChild(filename[2])
  else
    file = rootDir:FindFirstChild(filename)
  end
  return file
end


Module.PlayCutscene = function(sc, arg)
	local dir = Module.GameInfo.CutsceneDir
	local file = findScript(dir, sc)
	if file then
		warn(Module.Configuration.PrintHeader.."Running scene '"..sc.."'")
		spawn(function()
			local stat,err = pcall(function()
				local sc = require(file)
				sc.Main(arg)
				Module.GameInfo.EventsDir.MapChange.Event:connect(sc.Kill)
			end)
			if not stat then
				warn(Module.Configuration.ErrorHeader..err)
			end
		end)
	else
		warn(Module.Configuration.WarnHeader.."Tried to run cutscene '"..sc.."' which does not exist!")
	end
end


Module.RunScript = function(sc, arg)
	local dir = Module.GameInfo.ScriptsDir
	local file = findScript(dir, sc)
	if file then
		warn(Module.Configuration.PrintHeader.."Running script '"..sc.."'")
		spawn(function()
			local stat,err = pcall(function()
				local sc = require(file)
				sc.Main(arg)
				Module.GameInfo.EventsDir.MapChange.Event:connect(sc.Kill)
			end)
			if not stat then
				warn(Module.Configuration.ErrorHeader..err)
			end
		end)
	else
		warn(Module.Configuration.WarnHeader.."Tried to run script '"..sc.."' which does not exist!")
	end
end


Module.RunScene = function(sc, arg, arg2)
  local dir = Module.GameInfo.ScriptsDir
  local file = findScript(dir, sc)
	if file then
		warn(Module.Configuration.PrintHeader.."Running scene '"..sc.."'")
		spawn(function()
			local stat,err = pcall(function()
				local sc = require(file)
				sc.Main(arg, arg2)
				Module.GameInfo.EventsDir.MapChange.Event:connect(sc.Kill)
			end)
			if not stat then
				warn(Module.Configuration.ErrorHeader..err)
			end
		end)
	else
		warn(Module.Configuration.WarnHeader.."Tried to run choreo_scene '"..sc.."' which does not exist!")
	end
end


Module.GetMap = function()
	local map
	if game.Players.LocalPlayer == nil then
		map = workspace.Game.CurrentMap.Value
	else
    map = game.Players.LocalPlayer.CurrentMap.Value
	end
	return map
end


Module.RecursiveFindEntity = function(dir, entityName)
	local c = dir:GetChildren()
	for i = 1, #c do
		local entName = c[i]:FindFirstChild("EntityName")
		if entName then
			if entName.Value == entityName then
				return c[i]
			end
		else
			Module.RecursiveFindEntity(c[i], entityName)
		end
	end
	return nil
end




Module.FindEntity = function(entityName)
	if entityName == "" then 
		return nil 
	end
	local map = Module.GetMap()
	local ent
	if map ~= nil then
		ent = Module.RecursiveFindEntity(map.Entities, entityName)
	end
	return ent
end


Module.FindNpc = function(entityName)
	if entityName == "" then 
		return nil 
	end
	local map = Module.GetMap()
	local ent
	if map ~= nil then
		ent = Module.RecursiveFindEntity(workspace.npcCache, entityName)
	end
	return ent
end


Module.LoadModule = function(module)
	local root = script.Parent
	local found = root:FindFirstChild(module, true)
	if found then
		return require(found)
	else
		error(Module.Configuration.ErrorHeader.."Module '"..tostring(module).."' wasn't found!")
	end
end






return Module