
local stringFind = string.find
local stringLower = string.lower
local function onChildAdded(child)
    if not child:IsA("BasePart") then return end
    if not stringFind(stringLower(child.Name), "saint", 1, true) then return end
    if child:GetAttribute("DespawnTimerId") then return end
    child:Destroy()
end
local function scanExisting()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("BasePart") and stringFind(stringLower(child.Name), "saint", 1, true) then
            if not child:GetAttribute("DespawnTimerId") then
                child:Destroy()
            end
        end
    end
end
scanExisting()
workspace.ChildAdded:Connect(onChildAdded)

task.spawn(function()
    local pl=game:GetService("Players")
    if not pl.LocalPlayer then pl:GetPropertyChangedSignal("LocalPlayer"):Wait() end
    local lp=pl.LocalPlayer
    local rem=game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    while true do
        pcall(function()
            local btn = lp.PlayerGui.MainMenu.ButtonContainer.PlayButton
            if btn.ContentText == "CREATE CHARACTER" then
                rem.CreateCharacterEvent:FireServer(1, "Outlaw", "Red Corner")
            elseif btn.Text == "PLAY" then
                firesignal(btn.MouseButton1Click)
            end
        end)
        task.wait(0.3)
    end
end)
task.spawn(function()
    local lp=game:GetService("Players").LocalPlayer or game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait() and game:GetService("Players").LocalPlayer
    local pGui=lp:WaitForChild("PlayerGui",10)
    local kill={"Main Menu","BlackScreenGui","Logo_Loader"}
    while true do
        task.wait(0.5)
        for _,n in ipairs(kill) do
            local g=pGui:FindFirstChild(n)
            if g then pcall(function() g:Destroy() end) end
        end
    end
end)

local cloneref=cloneref or function(x) return x end
local RS   =cloneref(game:GetService("RunService"))
local PS   =cloneref(game:GetService("Players"))
local UIS  =cloneref(game:GetService("UserInputService"))
local TS   =cloneref(game:GetService("TweenService"))
local VIM  =cloneref(game:GetService("VirtualUser"))
local LT   =cloneref(game:GetService("Lighting"))
local HS   =cloneref(game:GetService("HttpService"))
local TP   =cloneref(game:GetService("TeleportService"))
local CAS  =cloneref(game:GetService("ContextActionService"))
local CS   =cloneref(game:GetService("CollectionService"))
local Cam  =workspace.CurrentCamera
local LP   =PS.LocalPlayer
local sprinting=false
local GUN_MAX_CLIP=30
local GUN_FIRE_RATE=0.1
local SAFE_CF=CFrame.new(-6923.66748046875, 45.199729919433594, -1535.4359130859375)
local function getSafeCF()
    local lp2 = game:GetService("Players").LocalPlayer
    local safePos = SAFE_CF.Position
    -- keep going higher until no player is within 60 studs
    local attempts = 0
    local function anyoneNear()
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= lp2 and plr.Character then
                local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp2 and (hrp2.Position - safePos).Magnitude < 60 then return true end
            end
        end
        return false
    end
    while anyoneNear() and attempts < 20 do
        safePos = Vector3.new(safePos.X, safePos.Y + 80, safePos.Z)
        attempts += 1
    end
    safePos = Vector3.new(safePos.X, math.max(safePos.Y, 50), safePos.Z)
    return CFrame.new(safePos)
end
local SAINT_PARTS={"SaintsHeart","SaintsLeftArm","SaintsLeftLeg","SaintsRibcage","SaintsRightArm","SaintsRightLeg"}
local S = {}



local _grabbing = false

workspace.DescendantAdded:Connect(function(obj)
    if obj.Name ~= "SaintsUnknown" then return end
    if _grabbing then return end
    local lp2 = game:GetService("Players").LocalPlayer
    if lp2:GetAttribute("EquippedStand") ~= "" then return end
    pcall(function()
        local hs2 = game:GetService("HttpService")
        local ok,r = pcall(function() return hs2:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
        local tp = game:GetService("TeleportService")
        if ok and r then
            for _,s in ipairs(r.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    tp:TeleportToPlaceInstance(game.PlaceId, s.id, lp2); return
                end
            end
        end
        tp:Teleport(game.PlaceId, lp2)
    end)
end)

function isRealCorpsePart(obj)
    if not obj:GetAttribute("DespawnTimerId") then 
        notify("Debug: Missing DespawnTimerId on "..obj.Name, 1)
        return false 
    end
    local pp = obj:FindFirstChild("PickupPrompt") or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not pp then 
        notify("Debug: No ProximityPrompt on "..obj.Name, 1)
        return false 
    end
    if obj:IsA("BasePart") and obj.Anchored then
        notify("Debug: Ignoring Anchored Part (Honeypot): "..obj.Name, 1)
        return false
    end
    return true
end

local _antiStealConn = nil

-- antisteal: Heartbeat locks HRP to safe orbit, vaults every 0.5s for invincibility
local function startAntiSteal()
    if _antiStealConn then _antiStealConn:Disconnect(); _antiStealConn=nil end
    local lp2 = game:GetService("Players").LocalPlayer
    local gotStand = lp2:GetAttribute("EquippedStand")
    if not gotStand or gotStand == "" then return end
    local asChar = lp2.Character
    local t = 0
    local vt = 0
    -- vault to safe first
    local h0 = asChar and asChar:FindFirstChild("HumanoidRootPart")
    if h0 then
        pcall(function() ActionRemote:FireServer("Vault") end)
        task.wait(0.05)
        h0.CFrame = SAFE_CF
    end
    _antiStealConn = RS.Heartbeat:Connect(function(dt)
        if lp2:GetAttribute("EquippedStand") ~= gotStand or lp2.Character ~= asChar then
            _antiStealConn:Disconnect(); _antiStealConn = nil; return
        end
        t += dt * 1.5; vt += dt
        local h2 = lp2.Character and lp2.Character:FindFirstChild("HumanoidRootPart")
        if h2 then
            h2.CFrame = CFrame.new(
                SAFE_CF.Position.X + math.cos(t)*100,
                SAFE_CF.Position.Y,
                SAFE_CF.Position.Z + math.sin(t)*100
            )
            h2.AssemblyLinearVelocity = Vector3.zero
            h2.AssemblyAngularVelocity = Vector3.zero
        end
        if vt >= 0.5 then
            vt = 0
            pcall(function() ActionRemote:FireServer("Vault") end)
        end
    end)
end

-- lerp toward corpse while keeping vault active, then fire prompt
function collectPartAndSafe(obj)
    notify("Debug: Entering collectPartAndSafe for "..obj.Name, 1)
    if not obj or not obj.Parent then return end
    if obj.Name == "SaintsUnknown" then return end
    if not isRealCorpsePart(obj) then return end
    if _grabbing then 
        notify("Debug: Already grabbing, skipping", 1)
        return 
    end
    
    notify("Debug: Delaying for "..tostring(S.saintsGrabDelay or 0).."s", 1)
    local delayTime = tonumber(S.saintsGrabDelay) or 0
    if delayTime > 0 then task.wait(delayTime) end
    if not obj or not obj.Parent then return end

    local lp2 = game:GetService("Players").LocalPlayer
    local hrp = lp2.Character and lp2.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    _grabbing = true
    
    -- STOP CONFLICTING MOVEMENT
    if _antiStealConn then _antiStealConn:Disconnect(); _antiStealConn = nil; notify("Debug: Paused Anti-Steal for collection", 1) end
    if Tog.BWFly and Tog.BWFly.Value then Tog.BWFly:SetValue(false); notify("Debug: Paused Fly for collection", 1) end

    local speed = tonumber(S.saintsTweenSpeed) or 25
    local targetCF = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
    
    notify("Debug: Starting tween to "..obj.Name.." (Speed: "..speed..")", 1)
    charTweenTo(targetCF, speed)
    notify("Debug: Reached "..obj.Name, 1)

    task.wait(0.1)

    -- at corpse now — find nearest prompt and fire it
    hrp = lp2.Character and lp2.Character:FindFirstChild("HumanoidRootPart")
    local freshPart = workspace:FindFirstChild(obj.Name, true) or obj
    local pp = freshPart:FindFirstChild("PickupPrompt")
        or freshPart:FindFirstChildWhichIsA("ProximityPrompt", true)
    if pp and hrp then
        pcall(function() firetouchinterest(hrp, freshPart, 0) end)
        if holdproximityprompt then
            pcall(holdproximityprompt, pp, 3.2)
        else
            pcall(fireproximityprompt, pp)
            task.wait(3.2)
        end
        pcall(function() firetouchinterest(hrp, freshPart, 1) end)
    end

    -- wait up to 15s for stand to change
    for i = 1, 30 do
        task.wait(0.5)
        if lp2:GetAttribute("EquippedStand") ~= prev then break end
    end
    _grabbing = false

    -- if we got the stand, go to safe + antisteal
    local gotStand = lp2:GetAttribute("EquippedStand")
    if gotStand and gotStand ~= "" and gotStand ~= prev then
        startAntiSteal()
    end
end

local standM1Conn2=nil -- placeholder to avoid duplicate variable
local miniGameThread=nil
local rokaFarmThread = nil
local saintsThread=nil
local corpsePromptConn=nil
local autoHopThread=nil
local autoHopPartConn=nil
local storageAction=nil
local getStorage=nil
local saintsEspThread=nil
local saintsEspDrawings={}
local wipePending=false
local wipeTimer=nil
local purchaseList={"Select"}
local purchaseCDs={"Select"}
local autoBuyItemsConn=nil
local autoDepositConn=nil
local specificDepositConn=nil
local depositItems={}
local chestPromptConn=nil
local horseConn=nil
local horseGodConn=nil
local horseAtkConn=nil
local horseStamConn=nil
local cachedHorse=nil
local horseRerollConn=nil
local horseGodConns={}
local horseStamConns={}
local fishThread=nil
local _fishTweenCancel=false

local npcList={"Select"}
local fishPlatform=nil
local fishChestConn=nil
local autoBaitConn=nil
local autoSellConn=nil

local _cachedPing=0.15
local _pingHistory={}
task.spawn(function()
    while true do
        pcall(function()
            local stats=game:GetService("Stats")
            local item=stats.Network.ServerStatsItem["Data Ping"]
            local raw=math.max(item:GetValue()/1000,0.01)
            table.insert(_pingHistory,raw)
            if #_pingHistory>6 then table.remove(_pingHistory,1) end
            local sum=0
            for _,v in ipairs(_pingHistory) do sum=sum+v end
            _cachedPing=sum/#_pingHistory
        end)
        task.wait(0.5)
    end
end)

LP=cloneref(LP)

-- Anti-AFK By Markii
local _lp2=game:GetService("Players").LocalPlayer; if _lp2 then _lp2.Idled:Connect(function()
    local vu=game:GetService("VirtualUser")
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end) end
if not LP.Character then
    local ok=false
    task.spawn(function() LP.CharacterAdded:Wait(); ok=true end)
    local t=tick()
    while not LP.Character and not ok and tick()-t<10 do task.wait(0.1) end
end

local repo="https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
local libSrc,themeSrc,saveSrc
local done=0
local function dl(url,cb)
    task.spawn(function()
        local ok,result=pcall(function() return game:HttpGet(url) end)
        if ok then cb(result) end
        done=done+1
    end)
end
dl(repo.."Library.lua",             function(s) libSrc=s end)
dl(repo.."addons/ThemeManager.lua", function(s) themeSrc=s end)
dl(repo.."addons/SaveManager.lua",  function(s) saveSrc=s end)
local t0=tick()
while done<3 and tick()-t0<15 do task.wait(0.05) end
local Library     =loadstring(libSrc)()
local ThemeManager=loadstring(themeSrc)()
local SaveManager =loadstring(saveSrc)()
Library.ShowCustomCursor=false
Library.ShowToggleFrameInKeybinds=true
Library.NotifySide="Left"
local Window=Library:CreateWindow({
    Title="Bridger Western | NB Hub",
    Center=true, AutoShow=true,
    Size=UDim2.fromOffset(660,700),
    ShowCustomCursor=false,
    UnlockMouseWhileOpen=true,
    MenuFadeTime=0.2,
})
Opt=Library.Options
Tog=Library.Toggles
function notify(msg,dur) Library:Notify(msg,dur or 3) end

local Tabs={
    Combat   =Window:AddTab("Main"),
    Farm     =Window:AddTab("Farm"),
    Player   =Window:AddTab("Player"),
    Visuals  =Window:AddTab("Visuals"),
    UI       =Window:AddTab("Settings"),
}
local GB={
    -- Main tab
    CombatL =Tabs.Combat:AddLeftGroupbox("Combat"),
    CombatR =Tabs.Combat:AddRightGroupbox("Stand"),
    MainSaints =Tabs.Combat:AddLeftGroupbox("Saints"),
    MainStatus =Tabs.Combat:AddRightGroupbox("Status"),

    -- Farm tab
    FarmL   =Tabs.Farm:AddLeftGroupbox("Tree Farm"),
    -- Player tab
    PlayerL =Tabs.Player:AddLeftGroupbox("Movement"),
    PlayerR =Tabs.Player:AddRightGroupbox("Character"),
    AimL    =Tabs.Player:AddLeftGroupbox("Aimbot"),
    AimR    =Tabs.Player:AddRightGroupbox("Aimbot Settings"),
    MiscL   =Tabs.Player:AddLeftGroupbox("Server"),
    MiscR   =Tabs.Player:AddRightGroupbox("Utility"),
    MiscCom =Tabs.Player:AddLeftGroupbox("Combat Misc"),
    -- Visuals tab
    VisL    =Tabs.Visuals:AddLeftGroupbox("Camera"),
    VisR    =Tabs.Visuals:AddRightGroupbox("Rendering"),
    ESPSet  =Tabs.Visuals:AddLeftGroupbox("ESP Settings"),
    PlrESP  =Tabs.Visuals:AddRightGroupbox("Player ESP"),
}

local S={
    speed=100, infJumpH=50, flySpeed=100,
    aimbotMode="Hold", aimbotFOV=45, aimbotSens=1,
    aimbotX=0, aimbotY=0,
    teamCheck=false, visibleOnly=false, targetPlayers=false,
    brightness=2, nearbyTable={},
    hitboxSize=5, hitboxTrans=0.9,
}

local function getChar()  return LP.Character end
local function getHRP()   local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local ActionRemote=game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ActionRemote")

local function tpTo(pos,hrpOverride)
    local hrp=hrpOverride or getHRP(); if not hrp then return end
    pcall(function() ActionRemote:FireServer("Vault") end)
    task.wait(0.1)
    hrp.CFrame=CFrame.new(pos)
end

local function vaultTo(cf,hrpOverride)
    local hrp=hrpOverride or getHRP(); if not hrp then return end
    pcall(function() ActionRemote:FireServer("Vault") end)
    task.wait(0.1)
    hrp.CFrame=cf
end

local function charTweenTo(cf,speed)
    local hrp=getHRP(); if not hrp then return end
    local startCF=hrp.CFrame; local dist=(startCF.Position-cf.Position).Magnitude
    if dist<0.5 then hrp.CFrame=cf; return end
    local dur=dist/(speed or 15); local elapsed=0
    while elapsed<dur do
        local dt=RS.Heartbeat:Wait()
        elapsed=elapsed+dt; local t=math.min(elapsed/dur,1)
        hrp.CFrame=startCF:Lerp(cf,t)
        hrp.AssemblyLinearVelocity=Vector3.zero
        pcall(function() ActionRemote:FireServer("Vault") end)
    end
    hrp.CFrame=cf
end

do
-- =====================
-- PLAYER TAB
-- =====================
GB.PlayerL:AddLabel("Teleport")
GB.PlayerL:AddInput("Coordinates",{Default="",Numeric=false,Finished=false,Text="Coordinates",Placeholder="X, Y, Z"})
GB.PlayerL:AddButton({Text="Tween To",Func=function()
    local s=Opt.Coordinates.Value
    local x,y,z=s:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x then
        local target = CFrame.new(tonumber(x),tonumber(y),tonumber(z))
        local speed = S.flySpeed or 100
        local oldNoclip = Tog.Noclip and Tog.Noclip.Value
        if Tog.Noclip then Tog.Noclip:SetValue(true) end
        charTweenTo(target, speed)
        if Tog.Noclip then Tog.Noclip:SetValue(oldNoclip) end
    else notify("Use format: X, Y, Z") end
end})
GB.PlayerL:AddButton({Text="Copy Position",Func=function()
    local hrp=getHRP()
    if hrp then setclipboard(tostring(hrp.Position)); notify("Copied!") end
end})
GB.PlayerL:AddLabel("TP to Player")
GB.PlayerL:AddDropdown("TPPlayerSelect",{SpecialType="Player",Text="Select Player"})
GB.PlayerL:AddButton({Text="Teleport",Func=function()
    local val=Opt.TPPlayerSelect and Opt.TPPlayerSelect.Value
    local plr=type(val)=="table" and next(val) or val
    if not plr or type(plr)~="string" then notify("Select a player first",2); return end
    local target=PS:FindFirstChild(plr)
    if not target then notify("Player not found",2); return end
    local tChar=target.Character
    local tHRP=tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then notify("Player has no character",2); return end
    local myHRP=getHRP(); if not myHRP then return end
    tpTo(tHRP.Position,myHRP)
    notify("Teleported to "..plr,2)
end})
GB.PlayerL:AddLabel("Movement")
GB.PlayerL:AddToggle("Speedhack",{Text="Speed",Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("Speedhack",Enum.RenderPriority.Input.Value,function(dt)
                local hrp=getHRP(); local hum=getHum()
                if hrp and hum and hum.Health>0 and hum.MoveDirection.Magnitude>0 then
                    pcall(function() ActionRemote:FireServer("Vault") end)
                    hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt
                end
            end)
        else RS:UnbindFromRenderStep("Speedhack") end
    end,
}):AddKeyPicker("SpeedhackKeybind",{Default="L",SyncToggleState=true,Mode="Toggle",Text="Speed Keybind"})
GB.PlayerL:AddSlider("SpeedhackSpeed",{Text="Speed",Default=100,Min=0,Max=200,Rounding=0,Compact=true,Callback=function(p) S.speed=p end})
local ijConn=nil
GB.PlayerL:AddToggle("InfiniteJump",{Text="Inf Jump",Default=false,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then
            ijConn=UIS.JumpRequest:Connect(function()
                local hrp=getHRP()
                if hrp then hrp.Velocity=Vector3.new(hrp.Velocity.X,S.infJumpH,hrp.Velocity.Z) end
            end)
        end
    end,
}):AddKeyPicker("InfiniteJumpKeybind",{Default="K",SyncToggleState=true,Mode="Toggle",Text="Inf Jump Keybind"})
GB.PlayerL:AddSlider("InfiniteJumpHeight",{Text="Jump Height",Default=50,Min=0,Max=1000,Rounding=0,Compact=true,Callback=function(p) S.infJumpH=p end})
local noclipConn=nil
GB.PlayerL:AddToggle("Noclip",{Text="Noclip",Default=false,
    Callback=function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        if p then
            noclipConn=RS.RenderStepped:Connect(function()
                local c=getChar(); if not c then return end
                for _,part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end)
        end
    end,
}):AddKeyPicker("NoclipKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Noclip Keybind"})
local flyLoop=nil
GB.PlayerL:AddToggle("Fly",{Text="Tween",Default=false,
    Callback=function(p)
        if flyLoop then flyLoop:Disconnect(); flyLoop=nil end
        if p then
            flyLoop = RS.Heartbeat:Connect(function(dt)
                local c=getChar()
                local hrp=c and c:FindFirstChild("HumanoidRootPart")
                local cam = workspace.CurrentCamera
                if hrp then
                    local moveDir=Vector3.new(0,0,0)
                    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0,1,0) end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                    
                    if moveDir.Magnitude > 0 then
                        local speed = tonumber(S.flySpeed) or 50
                        local targetPos = hrp.Position + (moveDir.Unit * speed * dt)
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.CFrame = CFrame.new(targetPos, targetPos + cam.CFrame.LookVector)
                        pcall(function() ActionRemote:FireServer("Vault") end)
                    else
                        hrp.Velocity = Vector3.new(0,0,0)
                    end
                    
                    for _, v in ipairs(c:GetDescendants()) do 
                        if v:IsA("BasePart") then v.CanCollide = false end 
                    end
                end
            end)
        end
    end,
}):AddKeyPicker("FlyKeybind",{Default="'",SyncToggleState=true,Mode="Toggle",Text="Tween Keybind"})
GB.PlayerL:AddSlider("FlySpeed",{Text="Tween Speed",Default=50,Min=1,Max=100,Rounding=0,Compact=true,Callback=function(p) S.flySpeed=p end})

GB.PlayerR:AddLabel("Stats")
local statsLabel=GB.PlayerR:AddLabel("KOs: - | Streak: - | Hi: - | Age: -")
task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",10); if not ls then return end
    local tick_=0
    RS.Heartbeat:Connect(function(dt)
        tick_=tick_+dt; if tick_<1 then return end; tick_=0
        local ko=ls:FindFirstChild("KOs"); local st=ls:FindFirstChild("STREAK")
        local hi=ls:FindFirstChild("HI STREAK"); local age=ls:FindFirstChild("Age")
        statsLabel:SetText(string.format("KOs: %s | Streak: %s | Hi: %s | Age: %s",
            ko and tostring(ko.Value) or "-",
            st and tostring(st.Value) or "-",
            hi and tostring(hi.Value) or "-",
            age and tostring(age.Value) or "-"))
    end)
end)
local function getNearestPlayer()
    local hrp=getHRP(); if not hrp then return nil end
    local best,bestDist=nil,math.huge
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr.UserId~=LP.UserId and plr.Character then
            local tHRP=plr.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local d=(tHRP.Position-hrp.Position).Magnitude
                if d<bestDist then bestDist=d; best=plr end
            end
        end
    end
    return best
end
local desyncConn=nil
local desyncTarget=nil
GB.PlayerR:AddToggle("BWDesync",{Text="Desync",Default=false,
    Callback=function(p)
        if desyncConn then task.cancel(desyncConn); desyncConn=nil end
        if not p then
            pcall(function() local hrp=getHRP(); if hrp then sethiddenproperty(hrp,"PhysicsRepRootPart",nil) end end)
            return
        end
        desyncConn=task.spawn(function()
            local c=LP.Character
            local hum=c and c:FindFirstChildOfClass("Humanoid")
            local hrp=hum and hum.RootPart
            if not hrp then return end
            while RS.Heartbeat:Wait() do
                if LP.Character~=c then break end
                local target=nil
                local sel=Opt.BWDesyncTarget and Opt.BWDesyncTarget.Value
                local selName=type(sel)=="table" and next(sel) or sel
                if selName and selName~="Nearest" then
                    local plr=PS:FindFirstChild(selName)
                    local pc=plr and plr.Character
                    target=pc and pc:FindFirstChild("HumanoidRootPart")
                else
                    local nearest=getNearestPlayer()
                    local nc=nearest and nearest.Character
                    target=nc and nc:FindFirstChild("HumanoidRootPart")
                end
                pcall(function() sethiddenproperty(hrp,"PhysicsRepRootPart",target) end)
            end
        end)
    end,
})
GB.PlayerR:AddDropdown("BWDesyncTarget",{Text="Desync Target",Values={"Nearest"},Default=1,Multi=false})
GB.PlayerR:AddButton({Text="Refresh Desync Players",Func=function()
    local list={"Nearest"}
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr.UserId~=LP.UserId then table.insert(list,plr.Name) end
    end
    Opt.BWDesyncTarget:SetValues(list)
end})
-- Fling
local _flingTargetName=""
local _flingActive=false

local function _getFlingChar()
    local plr=PS:FindFirstChild(_flingTargetName)
    return plr and plr.Character
end

local function _tpPlayerToPos(victim,pos)
    if _flingActive then return end
    _flingActive=true
    task.spawn(function()
        pcall(function()
            local c=LP.Character; if not c then _flingActive=false; return end
            local pp=c.PrimaryPart; if not pp then _flingActive=false; return end
            if not victim or not victim.PrimaryPart then _flingActive=false; return end

            game:GetService("ReplicatedStorage").Remotes:WaitForChild("UseTool"):FireServer(
                "Silver Dagger","Throw",
                Vector3.new(-2474.008056640625,43.26507568359375,-2527.55615234375)
            )
            task.wait(0.4)
            for i=1,15 do
                ActionRemote:FireServer("Vault")
                pp.CFrame=victim.PrimaryPart.CFrame-victim.PrimaryPart.CFrame.LookVector*0.7
                pp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                task.wait(0.017)
            end
            task.wait(0.2)
            local i=0
            while i<25 do
                ActionRemote:FireServer("Vault")
                task.wait(0.1)
                pp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                pp.CFrame=CFrame.new(pos)
                i=i+1
            end
        end)
        _flingActive=false
    end)
end

GB.PlayerR:AddLabel("Fling")
GB.PlayerR:AddDropdown("BWFlingTarget",{Text="Target Player",Values={"Select"},Default=1,Multi=false,
    Callback=function(v)
        local sel=type(v)=="table" and next(v) or v
        _flingTargetName=(sel and sel~="Select") and sel or ""
    end})
GB.PlayerR:AddButton({Text="Refresh Players",Func=function()
    local list={"Select"}
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr.UserId~=LP.UserId then table.insert(list,plr.Name) end
    end
    Opt.BWFlingTarget:SetValues(list)
end})
GB.PlayerR:AddButton({Text="Fling",Func=function()
    local tc=_getFlingChar(); if not tc then notify("Select a target",2); return end
    local smoke=workspace:FindFirstChild("DimensionMap") and workspace.DimensionMap:FindFirstChild("Smoke")
    if not smoke then notify("DimensionMap.Smoke not found",3); return end
    _tpPlayerToPos(tc,smoke.Position+Vector3.new(0,50,0))
end})
GB.PlayerR:AddButton({Text="Void",Func=function()
    local tc=_getFlingChar(); if not tc then notify("Select a target",2); return end
    local smoke=workspace:FindFirstChild("DimensionMap") and workspace.DimensionMap:FindFirstChild("Smoke")
    if not smoke then notify("DimensionMap.Smoke not found",3); return end
    _tpPlayerToPos(tc,smoke.Position+Vector3.new(0,120,0))
end})

GB.PlayerR:AddButton({Text="Kill Yourself",Func=function()
    local hum=getHum(); if hum then hum.Health=0 end
end})

end
do
-- =====================
-- AIMBOT
-- =====================
local _aimbotKeyHeld=false
local _aimbotKeyName="MB2"
local fovCircle=nil
local aimbotConn=nil
local function getFOVScale() return Cam.ViewportSize.Y/2/math.tan(math.rad(Cam.FieldOfView/2)) end
local function getAimbotTargets()
    local targets={}
    local ents=workspace:FindFirstChild("Entities")
    if S.targetPlayers then
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr.UserId~=LP.UserId and plr.Character then table.insert(targets,plr.Character) end
        end
    elseif ents then
        for _,m in ipairs(ents:GetChildren()) do
            if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then table.insert(targets,m) end
        end
    end
    return targets
end
local function getAimPart(char)
    local v=Opt.AimPart and Opt.AimPart.Value or "Head"
    if type(v)=="table" then v=next(v) or "Head" end
    if v=="Random" then local p={"Head","HumanoidRootPart","UpperTorso","Torso"}; v=p[math.random(1,#p)] end
    return char:FindFirstChild(v) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end
local function getInputName(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1" end
    if inp.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2" end
    if inp.UserInputType==Enum.UserInputType.MouseButton3 then return "MB3" end
    if inp.KeyCode~=Enum.KeyCode.Unknown then return inp.KeyCode.Name end
    return ""
end
UIS.InputBegan:Connect(function(inp,gpe) if not gpe and getInputName(inp)==_aimbotKeyName then _aimbotKeyHeld=true end end)
UIS.InputEnded:Connect(function(inp) if getInputName(inp)==_aimbotKeyName then _aimbotKeyHeld=false end end)
GB.AimL:AddLabel("Configuration")
GB.AimL:AddDropdown("AimPart",{Text="Aim Part",Default="Head",Values={"Head","Torso","Random"}})
GB.AimL:AddDropdown("AimbotMode",{Text="Mode",Default="Hold",Values={"Hold","Always"},Callback=function(v) S.aimbotMode=type(v)=="table" and next(v) or v end})
GB.AimL:AddLabel("Hold Key"):AddKeyPicker("AimbotKeybind",{Default="MB2",SyncToggleState=false,Mode="Hold",Text="Aimbot Hold Key",
    Callback=function(v)
        local name=type(v)=="string" and v or tostring(v)
        if name=="MouseButton1" then name="MB1" elseif name=="MouseButton2" then name="MB2" elseif name=="MouseButton3" then name="MB3" end
        _aimbotKeyName=name; _aimbotKeyHeld=false
    end,
})
GB.AimL:AddToggle("Aimbot",{Text="Aimbot",Default=false,
    Callback=function(p)
        if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
        if not p then return end
        aimbotConn=RS.RenderStepped:Connect(function()
            local mode=S.aimbotMode or "Hold"
            if mode=="Hold" and not _aimbotKeyHeld then return end
            local c=getChar(); if not c then return end
            local vpSize=Cam.ViewportSize
            local cx=vpSize.X/2+S.aimbotX; local cy=vpSize.Y/2+S.aimbotY
            local fovPx=math.tan(math.rad(S.aimbotFOV/2))*getFOVScale()
            local best,bestDist=nil,fovPx
            for _,char in ipairs(getAimbotTargets()) do
                local part=getAimPart(char)
                if part then
                    local hum=char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health>0 then
                        local sp,onScreen=Cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5
                            if d<bestDist then bestDist=d; best=part end
                        end
                    end
                end
            end
            if best then
                local toTarget=(best.Position-Cam.CFrame.Position).Unit
                local t=math.clamp(S.aimbotSens*0.15,0.01,1)
                local lv=Cam.CFrame.LookVector:Lerp(toTarget,t)
                Cam.CFrame=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+lv)
            end
        end)
    end,
})
GB.AimR:AddLabel("Targeting")
GB.AimR:AddToggle("TargetPlayers",{Text="Target Players",Callback=function(p) S.targetPlayers=p end})
GB.AimR:AddToggle("VisibleOnly",{Text="Visible Only",Callback=function(p) S.visibleOnly=p end})
GB.AimR:AddSlider("AimbotSens",{Text="Smoothness",Default=1,Min=0.1,Max=5,Rounding=2,Compact=true,Callback=function(p) S.aimbotSens=p end})
GB.AimR:AddSlider("AimbotXOffset",{Text="X Offset",Default=0,Min=-300,Max=300,Rounding=0,Compact=true,Callback=function(p) S.aimbotX=p end})
GB.AimR:AddSlider("AimbotYOffset",{Text="Y Offset",Default=0,Min=-300,Max=300,Rounding=0,Compact=true,Callback=function(p) S.aimbotY=p end})
GB.AimR:AddLabel("FOV Circle")
GB.AimR:AddToggle("ShowFOV",{Text="Show FOV",
    Callback=function(p)
        if p then
            if not fovCircle then fovCircle=Drawing.new("Circle"); fovCircle.Thickness=1; fovCircle.NumSides=100; fovCircle.Filled=false; fovCircle.Color=Color3.fromRGB(255,255,255) end
            fovCircle.Radius=math.tan(math.rad(S.aimbotFOV/2))*getFOVScale()
            fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
            fovCircle.Visible=true
        elseif fovCircle then fovCircle.Visible=false end
    end,
})
GB.AimR:AddSlider("AimbotFOV",{Text="FOV (degrees)",Default=45,Min=1,Max=180,Rounding=0,Compact=true,
    Callback=function(p)
        S.aimbotFOV=p
        if fovCircle and fovCircle.Visible then fovCircle.Radius=math.tan(math.rad(p/2))*getFOVScale() end
    end,
})

end
do
-- =====================
-- VISUALS
-- =====================

local specState={active=false,target=nil,conns={}}
local function stopSpectate()
    specState.active=false
    for _,c in ipairs(specState.conns) do pcall(function() c:Disconnect() end) end
    specState.conns={}
    local c=getChar()
    if c then Cam.CameraSubject=c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom end
end
GB.VisL:AddLabel("Spectate")
GB.VisL:AddDropdown("SpectateDropdown",{SpecialType="Player",Text="Spectate Player",Callback=function(p) specState.target=p end})
GB.VisL:AddButton({Text="Spectate / Stop",Func=function()
    if specState.active then stopSpectate(); notify("Stopped spectating"); return end
    local val=specState.target
    local t=typeof(val)=="Instance" and val or PS:FindFirstChild(tostring(val))
    if not t then notify("Select a player first"); return end
    local char=t.Character; if not char then notify("Player has no character"); return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then notify("No humanoid"); return end
    specState.active=true; Cam.CameraType=Enum.CameraType.Custom; Cam.CameraSubject=hum
    notify("Spectating "..t.Name)
    table.insert(specState.conns,t.CharacterAdded:Connect(function(c)
        if not specState.active then return end
        task.wait(0.5); local h=c:FindFirstChildOfClass("Humanoid"); if h then Cam.CameraSubject=h end
    end))
end})
local noFogConn=nil
GB.VisR:AddLabel("Fog")
GB.VisR:AddLabel("these features on madium ban dont use them")
GB.VisR:AddToggle("NoFog",{Text="No Fog",
    Callback=function(p)
        if noFogConn then noFogConn:Disconnect(); noFogConn=nil end
        if p then
            LT.FogStart=1e8; LT.FogEnd=1e9
            noFogConn=LT:GetPropertyChangedSignal("FogEnd"):Connect(function()
                if LT.FogEnd<1e8 then LT.FogStart=1e8; LT.FogEnd=1e9 end
            end)
        else LT.FogStart=0; LT.FogEnd=100000 end
    end,
})
local fbLoop=nil
local function applyFullbright()
    LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000
    LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128)
end
GB.VisR:AddLabel("Lighting")
GB.VisR:AddToggle("FullBright",{Text="Fullbright",
    Callback=function(p)
        if fbLoop then fbLoop:Disconnect(); fbLoop=nil end
        if p then
            applyFullbright()
            fbLoop=LT:GetPropertyChangedSignal("Brightness"):Connect(function()
                if Tog.FullBright and Tog.FullBright.Value then applyFullbright() end
            end)
        else LT.Brightness=1; LT.ClockTime=14; LT.GlobalShadows=true end
    end,
}):AddKeyPicker("FullBrightKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="FullBright Keybind"})
GB.VisR:AddSlider("Brightness",{Text="Brightness",Default=2,Min=0,Max=10,Rounding=1,Compact=true,
    Callback=function(p) S.brightness=p; if Tog.FullBright and Tog.FullBright.Value then applyFullbright() end end})
GB.VisR:AddToggle("NoShadows",{Text="No Shadows",Default=false,Callback=function(p) LT.GlobalShadows=not p end})
GB.VisR:AddToggle("RemoveAtmosphere",{Text="Remove Atmosphere",Default=false,
    Callback=function(p)
        for _,v in ipairs(LT:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
                v.Enabled=not p
            end
        end
        if p then
            LT.ChildAdded:Connect(function(v)
                if not (Tog.RemoveAtmosphere and Tog.RemoveAtmosphere.Value) then return end
                if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
                    v.Enabled=false
                end
            end)
        end
    end,
})
GB.VisR:AddSlider("TimeOfDay",{Text="Time of Day",Default=14,Min=0,Max=24,Rounding=1,Compact=true,Callback=function(p) LT.ClockTime=p end})
GB.VisR:AddSlider("MaxZoom",{Text="Max Camera Zoom",Default=400,Min=0,Max=2000,Rounding=0,Compact=true,Callback=function(p) LP.CameraMaxZoomDistance=p end})

-- Anti Lag
local AntiLagL=Tabs.Visuals:AddLeftGroupbox("Anti Lag")
local AntiLagR=Tabs.Visuals:AddRightGroupbox("Anti Lag")

-- Disable 3D rendering
local _3dDisabled=false
local _blackScreen=nil
AntiLagL:AddToggle("BWDisable3D",{Text="Disable 3D Rendering",Default=false,
    Callback=function(p)
        _3dDisabled=p
        if p then
            if not _blackScreen then
                local sg=Instance.new("ScreenGui")
                sg.Name="BWBlackScreen"; sg.ResetOnSpawn=false; sg.DisplayOrder=999
                sg.Parent=gethui and gethui() or LP:WaitForChild("PlayerGui",5)
                local f=Instance.new("Frame",sg)
                f.Size=UDim2.fromScale(1,1); f.BackgroundColor3=Color3.new(0,0,0); f.BorderSizePixel=0
                _blackScreen=sg
            end
            pcall(function()
                local rs=settings().Rendering
                if rs then rs.QualityLevel=Enum.QualityLevel.Level01 end
            end)
        else
            if _blackScreen then _blackScreen:Destroy(); _blackScreen=nil end
        end
    end,
})

-- Mute all sounds
local _mutedSounds={}
AntiLagL:AddToggle("BWMuteSounds",{Text="Mute All Sounds",Default=false,
    Callback=function(p)
        pcall(function()
            local SoundService=game:GetService("SoundService")
            SoundService.RespectFilteringEnabled=true
            if p then
                SoundService:SetListener(Enum.ListenerType.ObjectPosition,workspace)
                -- mute all sounds in workspace
                for _,s in ipairs(workspace:GetDescendants()) do
                    if s:IsA("Sound") then
                        _mutedSounds[s]=s.Volume
                        s.Volume=0
                    end
                end
                workspace.DescendantAdded:Connect(function(s)
                    if _3dDisabled and s:IsA("Sound") then s.Volume=0 end
                end)
            else
                for s,vol in pairs(_mutedSounds) do
                    pcall(function() if s and s.Parent then s.Volume=vol end end)
                end
                _mutedSounds={}
            end
        end)
    end,
})

-- Remove all particles/effects
local _removedFX={}
AntiLagL:AddToggle("BWRemoveFX",{Text="Remove Particles & Effects",Default=false,
    Callback=function(p)
        if p then
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Trail") or v:IsA("SelectionBox") then
                    local parent=v.Parent
                    if parent then
                        _removedFX[v]={parent=parent,name=v.Name}
                        pcall(function() v.Parent=nil end)
                    end
                end
            end
            workspace.DescendantAdded:Connect(function(v)
                if not (Tog.BWRemoveFX and Tog.BWRemoveFX.Value) then return end
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Trail") then
                    pcall(function() v.Parent=nil end)
                end
            end)
        else
            for v,data in pairs(_removedFX) do
                pcall(function() if data.parent and data.parent.Parent then v.Parent=data.parent end end)
            end
            _removedFX={}
        end
    end,
})

-- Remove all decals/textures
AntiLagL:AddToggle("BWRemoveTextures",{Text="Remove Decals & Textures",Default=false,
    Callback=function(p)
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") or v:IsA("SpecialMesh") then
                pcall(function() v.Transparency=p and 1 or 0 end)
            end
        end
    end,
})

-- Reduce render distance / LOD
AntiLagL:AddToggle("BWLowLOD",{Text="Low Graphics (Level 1)",Default=false,
    Callback=function(p)
        pcall(function()
            local rs=settings().Rendering
            if rs then rs.QualityLevel=p and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end
        end)
    end,
})

-- Hide all other players' characters
local _hiddenPlrs={}
AntiLagR:AddToggle("BWHideOtherPlayers",{Text="Hide Other Players",Default=false,
    Callback=function(p)
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr.UserId~=LP.UserId and plr.Character then
                for _,part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        pcall(function()
                            if p then
                                _hiddenPlrs[part]=part.Transparency
                                part.Transparency=1
                            elseif _hiddenPlrs[part] then
                                part.Transparency=_hiddenPlrs[part]
                                _hiddenPlrs[part]=nil
                            end
                        end)
                    end
                end
            end
        end
    end,
})

-- Hide all entities (mobs) visually
local _hiddenEnts={}
AntiLagR:AddToggle("BWHideEntities",{Text="Hide Entities (Mobs)",Default=false,
    Callback=function(p)
        local ents=workspace:FindFirstChild("Entities"); if not ents then return end
        for _,model in ipairs(ents:GetChildren()) do
            if model:IsA("Model") then
                for _,part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        pcall(function()
                            if p then _hiddenEnts[part]=part.Transparency; part.Transparency=1
                            elseif _hiddenEnts[part] then part.Transparency=_hiddenEnts[part]; _hiddenEnts[part]=nil end
                        end)
                    end
                end
            end
        end
    end,
})

-- Freeze all non-player models
AntiLagR:AddToggle("BWFreezeWorld",{Text="Freeze World Objects",Default=false,
    Callback=function(p)
        pcall(function()
            workspace.StreamingEnabled=false
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
                    if not PS:GetPlayerFromCharacter(v.Parent) then
                        pcall(function() v.Anchored=p end)
                    end
                end
            end
        end)
    end,
})

-- Lock FPS
local _fpsCap=60
AntiLagR:AddSlider("BWFPSCap",{Text="FPS Cap",Default=60,Min=10,Max=240,Rounding=0,Compact=true,
    Callback=function(v)
        _fpsCap=v
        pcall(function() settings().Rendering.FrameRateManager=Enum.FramerateManagerMode.On end)
    end,
})

-- One click ultra low settings button
AntiLagR:AddButton({Text="Ultra Low Settings (1 Click)",Func=function()
    pcall(function()
        local rs=settings().Rendering
        if rs then rs.QualityLevel=Enum.QualityLevel.Level01 end
    end)
    LT.GlobalShadows=false
    LT.FogStart=1e8; LT.FogEnd=1e9
    LT.Brightness=1
    for _,v in ipairs(LT:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
            pcall(function() v.Enabled=false end)
        end
    end
    if Tog.BWRemoveFX then Tog.BWRemoveFX:SetValue(true) end
    if Tog.BWMuteSounds then Tog.BWMuteSounds:SetValue(true) end
    notify("Ultra low settings applied",3)
end})

end
do
-- =====================
-- ESP (full rewrite)
-- =====================
local ESPObjects={}  -- [model] = {hl, nameTxt, healthTxt, boxTL, boxBR}
local ESPEnabled={plr=false,mob=false,npc=false,chest=false}
local ESPColors={plr=Color3.fromRGB(0,162,255),mob=Color3.fromRGB(255,80,80),npc=Color3.fromRGB(255,215,0),chest=Color3.fromRGB(100,220,255)}

local function makeESPEntry(model,color)
    if ESPObjects[model] then return end
    local hl=Instance.new("Highlight")
    hl.FillColor=color; hl.OutlineColor=color
    hl.FillTransparency=0.7; hl.OutlineTransparency=0
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled=true; hl.Adornee=model; hl.Parent=game:GetService("CoreGui")
    local nameTxt=Drawing.new("Text")
    nameTxt.Center=true; nameTxt.Outline=true; nameTxt.Color=color; nameTxt.Size=13; nameTxt.Visible=false
    local hpTxt=Drawing.new("Text")
    hpTxt.Center=true; hpTxt.Outline=true; hpTxt.Color=Color3.fromRGB(255,255,255); hpTxt.Size=12; hpTxt.Visible=false
    ESPObjects[model]={hl=hl,nameTxt=nameTxt,hpTxt=hpTxt,color=color}
    model.AncestryChanged:Connect(function(_,p) if not p then
        pcall(function() hl:Destroy(); nameTxt:Remove(); hpTxt:Remove() end)
        ESPObjects[model]=nil
    end end)
end

local function removeESPEntry(model)
    local e=ESPObjects[model]; if not e then return end
    pcall(function() e.hl:Destroy(); e.nameTxt:Remove(); e.hpTxt:Remove() end)
    ESPObjects[model]=nil
end

local function clearESPType(etype)
    for model,e in pairs(ESPObjects) do
        if e.espType==etype then removeESPEntry(model) end
    end
end

local function espTick()
    local myHRP=getHRP()
    -- add players
    if ESPEnabled.plr then
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr.UserId~=LP.UserId and plr.Character then
                local e=ESPObjects[plr.Character]
                if not e then makeESPEntry(plr.Character,ESPColors.plr); if ESPObjects[plr.Character] then ESPObjects[plr.Character].espType="plr" end end
            end
        end
    end
    -- add mobs from Entities
    if ESPEnabled.mob then
        local ents=workspace:FindFirstChild("Entities")
        if ents then
            for _,m in ipairs(ents:GetChildren()) do
                if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) and not ESPObjects[m] then
                    makeESPEntry(m,ESPColors.mob); if ESPObjects[m] then ESPObjects[m].espType="mob" end
                end
            end
        end
    end
    -- add NPCs
    if ESPEnabled.npc then
        local npcF=workspace:FindFirstChild("NPC") or workspace:FindFirstChild("NPCs")
        if npcF then
            for _,m in ipairs(npcF:GetChildren()) do
                if m:IsA("Model") and not ESPObjects[m] then
                    makeESPEntry(m,ESPColors.npc); if ESPObjects[m] then ESPObjects[m].espType="npc" end
                end
            end
        end
    end
    -- add chests
    if ESPEnabled.chest then
        local chestsF=workspace:FindFirstChild("Chests")
        if chestsF then
            for _,c in ipairs(chestsF:GetChildren()) do
                if not ESPObjects[c] then
                    makeESPEntry(c,ESPColors.chest); if ESPObjects[c] then ESPObjects[c].espType="chest" end
                end
            end
        end
    end
    -- update drawings
    for model,e in pairs(ESPObjects) do
        if not (model and model.Parent) then
            removeESPEntry(model)
        else
            local pivot=pcall(function() return model:GetPivot() end) and model:GetPivot() or CFrame.new()
            local pos=(model:FindFirstChild("HumanoidRootPart") and model.HumanoidRootPart.Position)
                or (model.PrimaryPart and model.PrimaryPart.Position)
                or pivot.Position
            local sp,onScreen=Cam:WorldToViewportPoint(pos+Vector3.new(0,2,0))
            local hum=model:FindFirstChildOfClass("Humanoid")
            if onScreen then
                local dist=myHRP and (pos-myHRP.Position).Magnitude or 0
                local name=model.Name
                if hum then
                    name=name..string.format(" [%.0f/%.0f]",hum.Health,hum.MaxHealth)
                end
                name=name..string.format(" %.0fm",dist)
                e.nameTxt.Text=name
                e.nameTxt.Position=Vector2.new(sp.X,sp.Y-20)
                e.nameTxt.Visible=true
                e.hpTxt.Visible=false
                e.hl.Enabled=true
            else
                e.nameTxt.Visible=false
                e.hpTxt.Visible=false
                e.hl.Enabled=false
            end
        end
    end
end
RS.Heartbeat:Connect(function() pcall(espTick) end)

GB.ESPSet:AddLabel("ESP Toggles")
GB.ESPSet:AddToggle("BWMobESP",{Text="Mob ESP",Default=false,
    Callback=function(p) ESPEnabled.mob=p; if not p then for m,e in pairs(ESPObjects) do if e.espType=="mob" then removeESPEntry(m) end end end end})
GB.ESPSet:AddToggle("BWChestESPToggle",{Text="Chest ESP",Default=false,
    Callback=function(p) ESPEnabled.chest=p; if not p then for m,e in pairs(ESPObjects) do if e.espType=="chest" then removeESPEntry(m) end end end end})
GB.PlrESP:AddLabel("ESP")
GB.PlrESP:AddToggle("PlrESPEnabled",{Text="Player ESP",Default=false,
    Callback=function(p) ESPEnabled.plr=p; if not p then for m,e in pairs(ESPObjects) do if e.espType=="plr" then removeESPEntry(m) end end end end})

end
do
-- =====================
-- MISC
-- =====================
GB.MiscL:AddLabel("Server")
local _visitedServers={}; _visitedServers[game.JobId]=true
local function serverHop(minP)
    minP=tonumber(minP) or 0
    local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local function findServer()
        local cursor=nil; local pages=0
        while pages<20 do
            pages=pages+1
            local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet(url..(cursor and "&cursor="..cursor or ""))) end)
            if not ok or not res then break end
            for _,s in ipairs(res.data or {}) do
                if s.playing>=minP and s.playing<s.maxPlayers and not _visitedServers[s.id] then return s end
            end
            cursor=res.nextPageCursor; if not cursor then break end
        end
        return nil
    end
    for attempt=1,3 do
        local found=findServer()
        if found then
            _visitedServers[found.id]=true
            task.wait(0.05)
            pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,found.id,LP) end)
            return true
        end
        _visitedServers={}; _visitedServers[game.JobId]=true
        notify("No servers found (attempt "..attempt.."), resetting...",2)
        task.wait(2)
    end
    notify("Server hop failed",4); return false
end
GB.MiscL:AddButton({Text="Rejoin",Func=function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end})
GB.MiscL:AddInput("JobID",{Default="",Numeric=false,Finished=false,Text="JobID",Placeholder="Paste job id..."})
GB.MiscL:AddButton({Text="Join Server",Func=function() TP:TeleportToPlaceInstance(game.PlaceId,Opt.JobID.Value,LP) end})
GB.MiscL:AddButton({Text="Copy JobId",Func=function() setclipboard(game.JobId); notify("Copied: "..game.JobId) end})
GB.MiscL:AddButton({Text="Server Hop",Func=function() serverHop(10) end})
GB.MiscL:AddToggle("BWHop17Plus",{Text="Hop 17+ Player Servers",Default=false,
    Callback=function(p)
        if p then serverHop(17) end
    end,
})
-- auto execute: write this script to autoexec so it runs on every game load
pcall(function()
    if not isfolder("autoexec") then makefolder("autoexec") end
    local src=nil
    -- try every common executor method to get this script's source
    if getscriptcontent then
        pcall(function() src=getscriptcontent(script) end)
        if not src or src=="" then pcall(function() src=getscriptcontent() end) end
    end
    if (not src or src=="") and decompile then
        pcall(function() src=decompile(script) end)
    end
    if (not src or src=="") and getrawmemory then
        pcall(function() src=getrawmemory(script) end)
    end
    -- if we got source, write it
    if src and src~="" then
        writefile("autoexec/bw_hub.lua",src)
    end
end)
GB.MiscR:AddLabel("Notifications")
local nearbyConn=nil
GB.MiscR:AddToggle("NearbyNotifier",{Text="Nearby Notifier",
    Callback=function(p)
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn=nil end
        S.nearbyTable={}; if not p then return end
        nearbyConn=RS.Heartbeat:Connect(function()
            local myHRP=getHRP(); if not myHRP then return end
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr.UserId~=LP.UserId then
                    local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then S.nearbyTable[plr]=nil
                    else
                        local dist=(myHRP.Position-hrp.Position).Magnitude
                        local near=dist<=(Opt.NearbyDist and Opt.NearbyDist.Value or 50)
                        if near and not S.nearbyTable[plr] then S.nearbyTable[plr]=true; notify(plr.Name.." nearby ["..math.floor(dist).."m]",6)
                        elseif not near and S.nearbyTable[plr] then S.nearbyTable[plr]=nil; notify(plr.Name.." left range",4) end
                    end
                end
            end
        end)
    end,
})
GB.MiscR:AddSlider("NearbyDist",{Text="Nearby Distance",Default=50,Min=5,Max=500,Rounding=0,Compact=true})
GB.MiscR:AddLabel("Display")
local statGui=nil
GB.MiscR:AddToggle("ShowStats",{Text="FPS & Ping",
    Callback=function(p)
        if not p then if statGui then statGui:Destroy(); statGui=nil end; return end
        statGui=Instance.new("ScreenGui"); statGui.Name="NBStats"; statGui.ResetOnSpawn=false; statGui.DisplayOrder=999
        statGui.Parent=gethui and gethui() or LP:WaitForChild("PlayerGui",10)
        local lbl=Instance.new("TextLabel")
        lbl.Size=UDim2.new(0,130,0,40); lbl.Position=UDim2.new(1,-140,0,10)
        lbl.BackgroundColor3=Color3.fromRGB(15,15,15); lbl.BackgroundTransparency=0.3
        lbl.TextColor3=Color3.new(1,1,1); lbl.Font=Enum.Font.Code; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.BorderSizePixel=0; lbl.Parent=statGui
        Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,4)
        local pad=Instance.new("UIPadding",lbl); pad.PaddingLeft=UDim.new(0,6)
        local last=tick(); local tick_=0
        RS.Heartbeat:Connect(function(dt)
            if not statGui then return end
            tick_=tick_+dt; if tick_<0.5 then return end; tick_=0
            local now=tick(); local fps=math.floor(1/math.max(now-last,0.001)); last=now
            lbl.Text=string.format("FPS: %d\nPing: %dms",fps,math.floor(_cachedPing*1000))
        end)
    end,
})
local hitboxConn=nil
GB.MiscCom:AddLabel("Hitbox")
GB.MiscCom:AddToggle("HitboxExpander",{Text="Hitbox Expander",
    Callback=function(p)
        if hitboxConn then hitboxConn:Disconnect(); hitboxConn=nil end
        if p then
            hitboxConn=RS.Heartbeat:Connect(function()
                pcall(function()
                    for _,plr in ipairs(PS:GetPlayers()) do
                        if plr.UserId~=LP.UserId and plr.Character then
                            local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.Size=Vector3.new(1,1,1)*(Opt.HitboxSize and Opt.HitboxSize.Value or 5)
                                hrp.Transparency=Opt.HitboxTrans and Opt.HitboxTrans.Value or 0.9
                                hrp.CanCollide=false; hrp.LocalTransparencyModifier=0
                            end
                        end
                    end
                end)
            end)
        else
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr.UserId~=LP.UserId and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Size=Vector3.new(2,2,1); hrp.Transparency=1; hrp.CanCollide=false end
                end
            end
        end
    end,
})
GB.MiscCom:AddSlider("HitboxSize",{Text="Hitbox Size",Default=5,Min=0,Max=20,Rounding=0,Compact=true})
GB.MiscCom:AddSlider("HitboxTrans",{Text="Transparency",Default=0.9,Min=0,Max=1,Rounding=1,Compact=true})

end
do
-- =====================
-- COMBAT TAB
-- =====================
local function findRemote(name)
    local cache={}
    if cache[name] and cache[name].Parent then return cache[name] end
    local rem=game:GetService("ReplicatedStorage").Remotes:FindFirstChild(name)
    if rem then cache[name]=rem; return rem end
    for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v.Name==name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent")) then cache[name]=v; return v end
    end
    return nil
end
GB.CombatL:AddLabel("some features wont work on madium executor")
GB.CombatL:AddLabel("Passives")
local noRecoilConns={}
local noRecoilHook=nil
GB.CombatL:AddToggle("BWNoRecoil",{Text="No Recoil",Default=false,
    Callback=function(p)
        for _,c in pairs(noRecoilConns) do pcall(function() c:Enable() end) end
        table.clear(noRecoilConns)
        if noRecoilHook then pcall(function() noRecoilHook() end); noRecoilHook=nil end
        if not p then return end
        local remotes=game:GetService("ReplicatedStorage").Remotes
        local shakeNames={ScreenShakeRemote=true,PlayerHitShakeRemote=true}
        for name in pairs(shakeNames) do
            local rem=remotes:FindFirstChild(name)
            if rem then
                for _,conn in pairs(getconnections(rem.OnClientEvent)) do conn:Disable(); table.insert(noRecoilConns,conn) end
            end
        end
        local mt=getrawmetatable(game); local oldNC=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if (method=="FireClient" or method=="FireAllClients") and shakeNames[self.Name] then return end
            return oldNC(self,...)
        end)
        setreadonly(mt,true)
        noRecoilHook=function()
            local m=getrawmetatable(game); setreadonly(m,false); m.__namecall=oldNC; setreadonly(m,true)
        end
    end,
})
local _noStunConns={}
GB.CombatL:AddToggle("BWNoIsBusy",{Text="No Stun",Default=false,
    Callback=function(p)
        for _,c in ipairs(_noStunConns) do pcall(function() c:Disconnect() end) end
        _noStunConns={}; if not p then return end
        local conn=RS.Heartbeat:Connect(function()
            pcall(function()
                local c=getChar(); if not c then return end
                if c:GetAttribute("IsBusy") then c:SetAttribute("IsBusy",false) end
                if c:GetAttribute("IsStunned") then c:SetAttribute("IsStunned",false) end
            end)
        end)
        table.insert(_noStunConns,conn)
    end,
})
local noRagConn=nil
local _ragdollConns={}
GB.CombatL:AddToggle("BWNoRagdoll",{Text="No Ragdoll",Default=false,
    Callback=function(p)
        if noRagConn then noRagConn:Disconnect(); noRagConn=nil end
        for _,c in ipairs(_ragdollConns) do pcall(function() c:Disconnect() end) end
        _ragdollConns={}
        if not p then return end
        local function fixChar(c)
            if not c then return end
            -- clear ragdoll attributes
            pcall(function() c:SetAttribute("IsRagdolled",false) end)
            -- re-enable all Motor6Ds that ragdoll disables
            for _,v in ipairs(c:GetDescendants()) do
                if v:IsA("Motor6D") then
                    pcall(function() v.Enabled=true end)
                end
                -- destroy any BallSocketConstraints or NoCollisionConstraints ragdoll adds
                if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
                    if v:GetAttribute("Ragdoll") then pcall(function() v:Destroy() end) end
                end
            end
            local hum=c:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState()==Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        noRagConn=RS.Heartbeat:Connect(function()
            pcall(function()
                local c=getChar(); if not c then return end
                if c:GetAttribute("IsRagdolled") then
                    fixChar(c)
                end
            end)
        end)
        -- also hook character added to fix on respawn
        table.insert(_ragdollConns, LP.CharacterAdded:Connect(function(c)
            task.wait(0.5); fixChar(c)
        end))
    end,
})
GB.CombatL:AddLabel("Gun")
;(function()
local saGun=game:GetService("ReplicatedStorage").Remotes.GunAction
local saEnts=workspace:WaitForChild("Entities",30) or workspace:FindFirstChild("Entities")
local saFOV=50
local saMaxDist=270
local saMinSpeed=1
local saPing=0.15
local saPingSamples={}
local saVelCache={}
task.spawn(function()
    while true do
        pcall(function()
            local raw=math.max(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000,0.01)
            table.insert(saPingSamples,raw)
            if #saPingSamples>6 then table.remove(saPingSamples,1) end
            local n=0; for _,v in ipairs(saPingSamples) do n=n+v end
            saPing=n/#saPingSamples
        end)
        task.wait(0.5)
    end
end)
local function saPredict(head,origin)
    local pos=head.Position
    local hrp=head.Parent and head.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then return pos end
    local d=(hrp.Position-origin).Magnitude; if d<=10 then return pos end
    local vel=hrp.AssemblyLinearVelocity
    local flat=Vector3.new(vel.X,0,vel.Z)
    local id=hrp:GetDebugId()
    if not saVelCache[id] then saVelCache[id]={} end
    local h=saVelCache[id]; table.insert(h,flat); if #h>3 then table.remove(h,1) end
    local sv=Vector3.new(0,0,0); for _,v in ipairs(h) do sv=sv+v end; sv=sv/#h
    local spd=sv.Magnitude
    if spd<=saMinSpeed then return pos end
    local tt=(hrp.Position-origin); if tt.Magnitude<0.001 then return pos end
    tt=tt.Unit
    local ftt=Vector3.new(tt.X,0,tt.Z); if ftt.Magnitude>0.001 then ftt=ftt.Unit end
    local lat=sv-ftt*sv:Dot(ftt)
    local lat2=(saPing/2)+0.05
    local dm=math.clamp(d/60,0.6,1.4)
    local ss=math.clamp(1-((spd-16)/40),0.3,1.0)
    local rl=flat-ftt*flat:Dot(ftt)
    local sf=1.0
    if rl.Magnitude>0.5 and lat.Magnitude>0.5 then
        sf=math.clamp((rl.Unit:Dot(lat.Unit)+1)/2,0.2,1.0)
    end
    pos=pos+lat*lat2*dm*ss*sf
    if math.abs(vel.Y)>5 then
        local hd=math.abs(hrp.Position.Y-origin.Y)
        pos=pos+Vector3.new(0,vel.Y*lat2*0.4*math.clamp(hd/20,0.2,1.0),0)
    end
    return pos
end
local function saGetTarget(origin,look)
    local e=saEnts or workspace:FindFirstChild("Entities"); if not e then return nil end
    local c=LP.Character
    local best,ba=nil,saFOV/2
    for _,m in ipairs(e:GetChildren()) do
        if m:IsA("Model") and m~=c then
            local head=m:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                local hum=m:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local d=(head.Position-origin).Magnitude
                    if d<=saMaxDist then
                        local a=math.deg(math.acos(math.clamp(look:Dot((head.Position-origin).Unit),-1,1)))
                        if a<ba then ba=a; best=head end
                    end
                end
            end
        end
    end
    if not best then return nil end
    return saPredict(best,origin)
end
local function saHandler(_,state,_)
    if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    local c=LP.Character; if not c then return Enum.ContextActionResult.Pass end
    local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return Enum.ContextActionResult.Pass end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local a=t:FindFirstChild("AmmoInClip")
            if a and a.Value>0 then
                local p=saGetTarget(hrp.Position,hrp.CFrame.LookVector)
                if p then
                    pcall(function() saGun:FireServer("Fire",p,false) end)
                    return Enum.ContextActionResult.Sink
                end
                return Enum.ContextActionResult.Pass
            end
        end
    end
    return Enum.ContextActionResult.Pass
end
GB.CombatL:AddLabel("Works best when enemy is close to you")
GB.CombatL:AddToggle("BWSilentAim",{Text="Silent Aim",Default=false,
    Callback=function(p)
        CAS:UnbindAction("BWSAAction")
        if p then CAS:BindActionAtPriority("BWSAAction",saHandler,false,3000,Enum.UserInputType.MouseButton1) end
    end,
}):AddKeyPicker("BWSilentAimKey",{Default="",SyncToggleState=true,Mode="Toggle",Text="Silent Aim Keybind"})
end)()

local _usingAmmoPack=false
local autoUseAmmoConn=nil
GB.CombatL:AddToggle("BWAutoUseAmmo",{Text="Auto Use Ammo Pack",Default=false,
    Callback=function(p)
        if autoUseAmmoConn then autoUseAmmoConn:Disconnect(); autoUseAmmoConn=nil end
        if not p then return end
        local _reloadFired=false
        local tick_=0
        autoUseAmmoConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<1 then return end; tick_=0
            if _usingAmmoPack then return end
            local function getStoredAmmo()
                local c=getChar(); if not c then return nil end
                for _,child in ipairs(c:GetChildren()) do
                    if child:IsA("Tool") then
                        local a=child:FindFirstChild("StoredAmmo") or child:FindFirstChild("AmmoStored")
                        if a then return a end
                    end
                end
                return nil
            end
            local storedVal=getStoredAmmo()
            local stored=storedVal and storedVal.Value or 99
            if stored>=30 then return end
            local ammoPack=LP.Backpack:FindFirstChild("AmmoPack"); if not ammoPack then return end
            task.spawn(function()
                _usingAmmoPack=true
                local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid")
                if not hum then _usingAmmoPack=false; return end
                local prevGun=nil
                for _,child in ipairs(c:GetChildren()) do
                    if child:IsA("Tool") and child:FindFirstChild("AmmoInClip") then prevGun=child; break end
                end
                hum:EquipTool(ammoPack); task.wait(0.1)
                local useRemote=ammoPack:FindFirstChild("UseAmmoPack")
                if useRemote then pcall(function() useRemote:FireServer() end) end
                task.wait(0.15)
                local gunToEquip=prevGun and prevGun.Parent==LP.Backpack and prevGun
                if not gunToEquip then
                    for _,tool in ipairs(LP.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("AmmoInClip") then gunToEquip=tool; break end
                    end
                end
                if gunToEquip then hum:EquipTool(gunToEquip); task.wait(0.2) end
                _reloadFired=false; _usingAmmoPack=false
            end)
        end)
    end,
})
local standEvent=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("StandEvent")
local aimedAttackReq=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("AimedAttackRequest")
task.spawn(function()
    local rem=game:GetService("ReplicatedStorage").Remotes
    if not standEvent then standEvent=rem:WaitForChild("StandEvent",30) end
    if not aimedAttackReq then aimedAttackReq=rem:WaitForChild("AimedAttackRequest",30) end
end)
local autoSummonConn=nil
GB.MainStatus:AddToggle("BWAutoSummon",{Text="Auto Summon Stand",Default=false,
    Callback=function(p)
        if autoSummonConn then autoSummonConn:Disconnect(); autoSummonConn=nil end
        if not p then return end
        local tick_=0
        autoSummonConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<2 then return end; tick_=0
            pcall(function()
                local stand=LP:GetAttribute("EquippedStand")
                if stand and stand~="" then standEvent:FireServer("Summon",stand) end
            end)
        end)
    end,
})
local standM1Conn=nil
GB.MainStatus:AddToggle("BWStandM1",{Text="Auto Stand M1",Default=false,
    Callback=function(p)
        if standM1Conn then standM1Conn:Disconnect(); standM1Conn=nil end
        if not p then return end
        local tick_=0
        standM1Conn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<0.05 then return end; tick_=0
            pcall(function()
                local c=getChar(); if not c then return end
                local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                local stand=LP:GetAttribute("EquippedStand"); if not stand or stand=="" then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local targetPos=hrp.Position+hrp.CFrame.LookVector*20
                local ents=workspace:FindFirstChild("Entities")
                if ents then
                    local best,bestDist=nil,150
                    for _,model in ipairs(ents:GetChildren()) do
                        if model:IsA("Model") and model~=c then
                            local th=model:FindFirstChild("HumanoidRootPart"); local hm=model:FindFirstChildOfClass("Humanoid")
                            if th and hm and hm.Health>0 then
                                local d=(th.Position-hrp.Position).Magnitude
                                if d<bestDist then bestDist=d; best=th end
                            end
                        end
                    end
                    if best then targetPos=best.Position end
                end
                aimedAttackReq:FireServer("ClickAttack",targetPos)
            end)
        end)
    end,
})
local spamAbilityConn=nil
local spamAbilityKeys={}
local _sfStandConfigs=nil
local ABILITY_KEYS={"E","R","G","T","V"}
GB.MainStatus:AddDropdown("BWStandAbilityKey",{Text="Spam Ability Keys",Values=ABILITY_KEYS,Default={},Multi=true,
    Callback=function(v) spamAbilityKeys=type(v)=="table" and v or {} end})
GB.MainStatus:AddToggle("BWSpamAbility",{Text="Spam Abilities",Default=false,
    Callback=function(p)
        if spamAbilityConn then spamAbilityConn:Disconnect(); spamAbilityConn=nil end
        if not p then
            pcall(function()
                local stand=LP:GetAttribute("EquippedStand")
                if stand and stand~="" then standEvent:FireServer("CancelBarrage",stand) end
            end)
            return
        end
        local tick_=0
        spamAbilityConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<0.1 then return end; tick_=0
            pcall(function()
                local c=getChar(); if not c then return end
                local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                local stand=LP:GetAttribute("EquippedStand"); if not stand or stand=="" then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not _sfStandConfigs then
                    _sfStandConfigs=pcall(function() return require(game:GetService("ReplicatedStorage"):FindFirstChild("StandConfigs")) end) and require(game:GetService("ReplicatedStorage"):FindFirstChild("StandConfigs"))
                end
                if not _sfStandConfigs then return end
                local cfg=_sfStandConfigs[stand]; if not cfg then return end
                local abilityMap=cfg.AbilityMap; if not abilityMap then return end
                local targetPos=hrp.Position+hrp.CFrame.LookVector*20
                local ents=workspace:FindFirstChild("Entities")
                if ents then
                    local best,bestDist=nil,150
                    for _,model in ipairs(ents:GetChildren()) do
                        if model:IsA("Model") and model~=c then
                            local th=model:FindFirstChild("HumanoidRootPart"); local hm=model:FindFirstChildOfClass("Humanoid")
                            if th and hm and hm.Health>0 then
                                local d=(th.Position-hrp.Position).Magnitude
                                if d<bestDist then bestDist=d; best=th end
                            end
                        end
                    end
                    if best then targetPos=best.Position end
                end
                for key in pairs(spamAbilityKeys) do
                    local abilityName=abilityMap[key]
                    if abilityName then
                        if type(abilityName)=="table" then abilityName=abilityName.Press or abilityName end
                        if abilityName then standEvent:FireServer("Ability",stand,abilityName,targetPos) end
                    end
                end
            end)
        end)
    end,
})
GB.MainStatus:AddLabel("Fists")
local autoEquipFistsConn=nil
GB.MainStatus:AddToggle("BWAutoEquipFists",{Text="Auto Raise Fists",Default=false,
    Callback=function(p)
        if autoEquipFistsConn then autoEquipFistsConn:Disconnect(); autoEquipFistsConn=nil end
        if not p then return end
        local tick_=0
        autoEquipFistsConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<0.5 then return end; tick_=0
            pcall(function()
                local c=getChar(); if not c then return end
                if not c:GetAttribute("FistsRaised") then
                    local rem=findRemote("ToggleFists")
                    if rem then rem:FireServer() end
                end
            end)
        end)
    end,
})
local autoM1Conn=nil
GB.MainStatus:AddToggle("BWAutoM1",{Text="Auto M1 Fist",Default=false,
    Callback=function(p)
        if autoM1Conn then autoM1Conn:Disconnect(); autoM1Conn=nil end
        if not p then return end
        local tick_=0
        autoM1Conn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<0.15 then return end; tick_=0
            pcall(function()
                local rem=findRemote("FistAttack")
                if rem then rem:FireServer() end
            end)
        end)
    end,
})
-- Projectile Redirect
local _projConn=nil
local _projPlayerName="Nearest"
GB.PlayerR:AddLabel("Projectile Redirect")
GB.PlayerR:AddDropdown("BWProjTarget",{Text="Redirect To",Values={"Nearest"},Default=1,Multi=false,
    Callback=function(v)
        local sel=type(v)=="table" and next(v) or v
        _projPlayerName=sel or "Nearest"
    end})
GB.PlayerR:AddButton({Text="Refresh Players",Func=function()
    local list={"Nearest"}
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr.UserId~=LP.UserId then table.insert(list,plr.Name) end
    end
    Opt.BWProjTarget:SetValues(list)
end})
GB.PlayerR:AddToggle("BWProjRedirect",{Text="Redirect Projectiles",Default=false,
    Callback=function(p)
        if _projConn then _projConn:Disconnect(); _projConn=nil end
        if not p then return end
        local function getTarget()
            if _projPlayerName~="Nearest" then
                local plr=PS:FindFirstChild(_projPlayerName)
                local c=plr and plr.Character
                local hrp=c and c:FindFirstChild("HumanoidRootPart")
                if hrp then return hrp end
            end
            local nearest=getNearestPlayer()
            local c=nearest and nearest.Character
            return c and c:FindFirstChild("HumanoidRootPart")
        end
        local function hookContainer(container)
            _projConn=container.ChildAdded:Connect(function(proj)
                task.defer(function()
                    pcall(function()
                        local owned=false
                        pcall(function() owned=isnetworkowner(proj) end)
                        if not owned then
                            pcall(function() proj:SetNetworkOwner(LP) end)
                            task.wait()
                            pcall(function() owned=isnetworkowner(proj) end)
                        end
                        if not owned then return end
                        local target=getTarget()
                        if target and target.Parent then
                            proj.CFrame=target.CFrame
                            proj.AssemblyLinearVelocity=Vector3.new(0,0,0)
                        end
                    end)
                end)
            end)
        end
        local container=workspace:FindFirstChild("ProjectileContainer")
        if container then
            hookContainer(container)
        else
            task.spawn(function()
                container=workspace:WaitForChild("ProjectileContainer",30)
                if not container then notify("ProjectileContainer not found",3); Tog.BWProjRedirect:SetValue(false); return end
                if Tog.BWProjRedirect and Tog.BWProjRedirect.Value then hookContainer(container) end
            end)
        end
    end,
})

GB.CombatR:AddLabel("Lock On")
local lockOnConn=nil
local lockOnTarget=nil
local lockOnPart="Head"
local function getLockOnTarget()
    local myHRP=getHRP(); if not myHRP then return nil end
    local ents=workspace:FindFirstChild("Entities"); if not ents then return nil end
    local best,bestDist=nil,math.huge
    for _,v in ipairs(ents:GetChildren()) do
        if v:IsA("Model") and v.Name~=LP.Name then
            local hum=v:FindFirstChildOfClass("Humanoid"); local hrp=v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>0 then
                local d=(hrp.Position-myHRP.Position).Magnitude
                if d<bestDist then bestDist=d; best=v end
            end
        end
    end
    return best
end
GB.CombatR:AddToggle("BWLockOn",{Text="Lock On",Default=false,
    Callback=function(p)
        if lockOnConn then lockOnConn:Disconnect(); lockOnConn=nil end
        lockOnTarget=nil; if not p then return end
        lockOnTarget=getLockOnTarget()
        local rescanTick=0
        lockOnConn=RS.RenderStepped:Connect(function(dt)
            rescanTick=rescanTick+dt
            local aimPart=lockOnTarget and (lockOnPart=="Head" and lockOnTarget:FindFirstChild("Head") or lockOnTarget:FindFirstChild("HumanoidRootPart"))
            local hum=lockOnTarget and lockOnTarget:FindFirstChildOfClass("Humanoid")
            if not aimPart or not hum or hum.Health<=0 or not lockOnTarget.Parent then
                if rescanTick>=0.5 then rescanTick=0; lockOnTarget=getLockOnTarget(); aimPart=lockOnTarget and lockOnTarget:FindFirstChild(lockOnPart=="Head" and "Head" or "HumanoidRootPart") end
            end
            if not aimPart then return end
            Cam.CFrame=CFrame.new(Cam.CFrame.Position,aimPart.Position)
        end)
    end,
}):AddKeyPicker("BWLockOnKey",{Default="E",SyncToggleState=true,Mode="Toggle",Text="Lock On Keybind"})
GB.CombatR:AddDropdown("BWLockOnPart",{Text="Aim Part",Values={"Head","Torso"},Default=1,Multi=false,
    Callback=function(v)
        local sel=type(v)=="table" and next(v) or v
        lockOnPart=(sel=="Torso") and "HumanoidRootPart" or "Head"
    end,
})
local lockOnList={"Nearest Entity","Nearest Player"}
for _,plr in ipairs(PS:GetPlayers()) do if plr.UserId~=LP.UserId then table.insert(lockOnList,plr.Name) end end
GB.CombatR:AddDropdown("BWLockOnTarget",{Text="Lock On Target",Values=lockOnList,Default=1,Multi=false,
    Callback=function(v)
        local sel=type(v)=="table" and next(v) or v
        if sel=="Nearest Player" then
            getLockOnTarget=function()
                local myHRP=getHRP(); if not myHRP then return nil end
                local best,bestDist=nil,math.huge
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr.UserId~=LP.UserId and plr.Character then
                        local hum=plr.Character:FindFirstChildOfClass("Humanoid"); local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health>0 then
                            local d=(hrp.Position-myHRP.Position).Magnitude
                            if d<bestDist then bestDist=d; best=plr.Character end
                        end
                    end
                end
                return best
            end
        elseif sel=="Nearest Entity" then
            getLockOnTarget=function()
                local myHRP=getHRP(); if not myHRP then return nil end
                local ents=workspace:FindFirstChild("Entities"); if not ents then return nil end
                local best,bestDist=nil,math.huge
                for _,v in ipairs(ents:GetChildren()) do
                    if v:IsA("Model") and v.Name~=LP.Name then
                        local hum=v:FindFirstChildOfClass("Humanoid"); local hrp=v:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health>0 then
                            local d=(hrp.Position-myHRP.Position).Magnitude
                            if d<bestDist then bestDist=d; best=v end
                        end
                    end
                end
                return best
            end
        else
            getLockOnTarget=function()
                local plr=PS:FindFirstChild(sel); return plr and plr.Character or nil
            end
        end
    end,
})
GB.CombatL:AddLabel("Freeze Mobs")
local _frozenParts={}
local _freezeConn=nil
local function freezeRoot(v)
    if not v:IsA("BasePart") then return end
    if v.Name~="HumanoidRootPart" then return end
    local chr=getChar(); if chr and v:IsDescendantOf(chr) then return end
    local ents=workspace:FindFirstChild("Entities"); if not ents or not v:IsDescendantOf(ents) then return end
    if not v.Parent:FindFirstChildWhichIsA("Humanoid") then return end
    if v:FindFirstChild("xFreezeConn") then return end
    local frozenPos = v.Position
    local frozenCF  = v.CFrame
    local tag = Instance.new("StringValue"); tag.Name="xFreezeConn"; tag.Parent=v
    local conn = RS.Heartbeat:Connect(function()
        if not v or not v.Parent then conn:Disconnect(); return end
        if not tag.Parent then conn:Disconnect(); return end
        v.Velocity             = Vector3.zero
        v.AssemblyLinearVelocity = Vector3.zero
        v.AssemblyAngularVelocity = Vector3.zero
        v.CFrame               = frozenCF
    end)
    table.insert(_frozenParts, {part=v, conn=conn, tag=tag})
end
GB.CombatL:AddToggle("BWFreezeMobs",{Text="Freeze Mobs",Default=false,
    Callback=function(p)
        for _,d in ipairs(_frozenParts) do
            pcall(function() if d.conn then d.conn:Disconnect() end; if d.tag and d.tag.Parent then d.tag:Destroy() end end)
        end
        _frozenParts={}; if _freezeConn then _freezeConn:Disconnect(); _freezeConn=nil end
        if not p then return end
        local ents=workspace:FindFirstChild("Entities")
        if ents then for _,model in ipairs(ents:GetChildren()) do local hrp=model:FindFirstChild("HumanoidRootPart"); if hrp then freezeRoot(hrp) end end end
        _freezeConn=workspace.DescendantAdded:Connect(function(v)
            if v.Name=="HumanoidRootPart" then local ents2=workspace:FindFirstChild("Entities"); if ents2 and v:IsDescendantOf(ents2) then freezeRoot(v) end end
        end)
    end,
})
GB.CombatL:AddLabel("Insta Kill Mobs")
local iKillConn=nil
GB.CombatL:AddToggle("BWInstaKill",{Text="Insta Kill Mobs",Default=false,
    Callback=function(p)
        if iKillConn then iKillConn:Disconnect(); iKillConn=nil end
        if not p then return end
        local tick_=0
        iKillConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<0.05 then return end; tick_=0
            pcall(function()
                sethiddenproperty(LP,"SimulationRadius",math.huge)
                local ents=workspace:FindFirstChild("Entities"); if not ents then return end
                for _,v in ipairs(ents:GetChildren()) do
                    if v:IsA("Model") and v~=getChar() then
                        local hum=v:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health>0 then hum.Health=0 end
                    end
                end
            end)
        end)
    end,
}):AddKeyPicker("BWInstaKillKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Insta Kill Mobs Keybind"})

end
do
local rokaFarmLoop
local rokaFarmThread = nil
local autoSellWoodConn = nil

GB.FarmL:AddDropdown("BWTreeType",{Text="Tree Type",Values={"Forest Trees","Swamp Trees","Both"},Default="Forest Trees",Multi=false})
GB.FarmL:AddToggle("BWRokaFarm",{Text="Tree Farm",Default=false,
    Callback=function(p)
        if rokaFarmThread then task.cancel(rokaFarmThread); rokaFarmThread=nil end
        if not p then return end
        rokaFarmThread = task.spawn(rokaFarmLoop)
    end})
GB.FarmL:AddSlider("BWTreeFarmSpeed",{Text="Tree Tween Speed",Default=25,Min=5,Max=150,Rounding=0,Compact=true,Callback=function(p) S.treeFarmSpeed=p end})
GB.FarmL:AddButton({Text="Buy Lumber Axe", Func=function()
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.DialogueRemote:FireServer("Action","Buy_LumberAxe",workspace.NPC.ChuckB)
    end)
    notify("Bought Lumber Axe", 2)
end})
GB.FarmL:AddButton({Text="Sell All Wood", Func=function()
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.DialogueRemote:FireServer("Action","SellAll_Wood",workspace.NPC.ChuckB)
    end)
    notify("Sold wood", 2)
end})
GB.FarmL:AddToggle("BWAutoSellWood",{Text="Auto Sell Wood",Default=false,
    Callback=function(p)
        if autoSellWoodConn then task.cancel(autoSellWoodConn); autoSellWoodConn=nil end
        if not p then return end
        autoSellWoodConn = task.spawn(function()
            local dial=game:GetService("ReplicatedStorage").Remotes.DialogueRemote
            local chuckB=workspace.NPC and workspace.NPC:FindFirstChild("ChuckB")
            while Tog.BWAutoSellWood and Tog.BWAutoSellWood.Value do
                if not chuckB then chuckB=workspace.NPC and workspace.NPC:FindFirstChild("ChuckB") end
                if chuckB then
                    pcall(function() dial:FireServer("Action","SellAll_Wood",chuckB) end)
                end
                task.wait(0.8)
            end
        end)
    end})


--
--
-- =====================
-- ROKA FARM
-- =====================

local function waitForRespawn()
    local t0 = tick()
    while LP.Character and tick()-t0 < 5 do task.wait(0.2) end
    while true do
        local c2 = LP.Character
        if c2 then
            local hum2 = c2:FindFirstChildOfClass("Humanoid")
            local hrp2 = c2:FindFirstChild("HumanoidRootPart")
            if hum2 and hrp2 and hum2.Health > 0 then
                task.wait(1.5)
                c2 = LP.Character
                local hum3 = c2 and c2:FindFirstChildOfClass("Humanoid")
                                if hum3 and hum3.Health > 0 then return end
            end
        end
        task.wait(0.3)
    end
end

rokaFarmLoop = function()
    notify("Tree Farm started", 2)
    local useTool = game:GetService("ReplicatedStorage").Remotes.UseTool
    while Tog.BWRokaFarm and Tog.BWRokaFarm.Value do
        local c = LP.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not hum or hum.Health <= 0 then
            notify("Waiting for respawn...", 2)
            waitForRespawn()
            if not (Tog.BWRokaFarm and Tog.BWRokaFarm.Value) then break end
        end
        c = LP.Character; if not c then task.wait(0.5); continue end
        hum = c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then task.wait(0.5); continue end
        local myHRP = getHRP(); if not myHRP then task.wait(0.5); continue end
        local axe = LP.Backpack:FindFirstChild("LumberAxe") or c:FindFirstChild("LumberAxe")
        if not axe then notify("No axe found!", 3); task.wait(2); continue end
        if axe.Parent ~= c then hum:EquipTool(axe); task.wait(0.2) end
        
        local treeTypeSel = Opt.BWTreeType and (type(Opt.BWTreeType.Value)=="table" and next(Opt.BWTreeType.Value) or Opt.BWTreeType.Value) or "Forest Trees"
        local snapshot = {}
        if treeTypeSel == "Forest Trees" or treeTypeSel == "Both" then
            for _, t in ipairs(workspace.Map.ForestTrees:GetChildren()) do table.insert(snapshot, t) end
        end
        if treeTypeSel == "Swamp Trees" or treeTypeSel == "Both" then
            for _, t in ipairs(workspace.Map.SwampTrees:GetChildren()) do table.insert(snapshot, t) end
        end
        
        -- Sort by distance
        table.sort(snapshot, function(a, b)
            local aPos = a:GetPivot().Position
            local bPos = b:GetPivot().Position
            return (myHRP.Position - aPos).Magnitude < (myHRP.Position - bPos).Magnitude
        end)
        
        local chopped = 0
        for _, tree in ipairs(snapshot) do
            if not (Tog.BWRokaFarm and Tog.BWRokaFarm.Value) then break end
            if (tree:GetAttribute("TreeHealth") or 1) <= 0 then continue end
            c = LP.Character; if not c then break end
            hum = c:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then break end
            myHRP = getHRP(); if not myHRP then break end
            axe = LP.Backpack:FindFirstChild("LumberAxe") or c:FindFirstChild("LumberAxe")
            if not axe then break end
            if axe.Parent ~= c then hum:EquipTool(axe); task.wait(0.2) end
            local tpos = tree:GetPivot().Position
            notify("Chopping "..tree.Name, 2)
            charTweenTo(CFrame.new(tpos - Vector3.new(0,4,0)), tonumber(S.treeFarmSpeed) or 25)
            local wt = tick()
            while tree:GetAttribute("TreeHealth") == nil and tick()-wt < 3 do
                pcall(function() useTool:FireServer("LumberAxe","Swing",nil) end)
                task.wait(0.15)
            end
            local lastHP = tree:GetAttribute("TreeHealth") or 0
            local stuckSwings = 0
            while (tree:GetAttribute("TreeHealth") or 0) > 0 and Tog.BWRokaFarm and Tog.BWRokaFarm.Value do
                c = LP.Character
                hum = c and c:FindFirstChildOfClass("Humanoid")
                if not c or not hum or hum.Health <= 0 then break end
                local curHP = tree:GetAttribute("TreeHealth") or 0
                if curHP == lastHP then
                    stuckSwings += 1
                    if stuckSwings >= 15 then
                        notify("Tree HP not dropping, skipping", 2)
                        break
                    end
                else
                    stuckSwings = 0
                    lastHP = curHP
                end
                pcall(function() useTool:FireServer("LumberAxe","Swing",nil) end)
                task.wait(0.15)
            end
            c = LP.Character
            hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not hum or hum.Health <= 0 then
                notify("Died, waiting for respawn...", 2)
                waitForRespawn()
                if not (Tog.BWRokaFarm and Tog.BWRokaFarm.Value) then return end
                break
            end
            chopped += 1
            notify("Tree done ("..chopped.." chopped)", 2)
        end
        task.wait(0.3)
    end
    notify("Tree Farm stopped", 2)
end

-- ── Unified Roka Loop ────────────────────────────────────────────────────────
-- Plant seed → wait for fruits to exist → vault to plant → fire all ClickDetectors
-- runs in sync with tree farm: plant while trees chop, collect when ready
local ROKA_PLANT_CF = CFrame.new(-6880.32763671875, 45.59973907470703, -3319.293701171875)
local rokaFarmConn = nil
local rokaPlantConn = nil
local rokaStorage = nil
local function stor()
    if not rokaStorage or not rokaStorage.Parent then
        rokaStorage = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("StorageAction")
    end
    return rokaStorage
end
local useTool_ = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UseTool")

local function rokaDeposit()
    pcall(function() stor():InvokeServer("Deposit","Rokakaka") end)
    task.wait(0.5)
end
local function rokaWithdrawSeed()
    pcall(function() stor():InvokeServer("Withdraw","Rokakaka Seed") end)
    task.wait(1.5)
end
local function rokaHasSeed()
    local c=LP.Character
    return LP.Backpack:FindFirstChild("Rokakaka Seed") or (c and c:FindFirstChild("Rokakaka Seed"))
end
local function rokaHasRoka()
    local c=LP.Character
    return LP.Backpack:FindFirstChild("Rokakaka") or (c and c:FindFirstChild("Rokakaka"))
end
local function rokaPlant()
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local seed=rokaHasSeed(); if not seed then return end
    local myHRP=getHRP(); if not myHRP then return end
    if seed.Parent~=c then hum:EquipTool(seed); task.wait(0.2) end
    vaultTo(ROKA_PLANT_CF,myHRP); task.wait(0.3)
    if not useTool_ then useTool_=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UseTool") end
    pcall(function() useTool_:FireServer("Rokakaka Seed","Plant",nil) end)
    notify("Planted!",2); task.wait(2)
end
local function rokaClaim()
    local lp2=workspace:FindFirstChild("LocaPlant")
    local plant=lp2 and lp2:FindFirstChild("Plant"); if not plant then return end
    local fruits=plant:FindFirstChild("Fruits"); if not fruits or #fruits:GetChildren()==0 then return end
    local hrp=getHRP(); if not hrp then return end
    local plantPos=plant:IsA("BasePart") and plant.Position or plant:GetPivot().Position
    pcall(function() ActionRemote:FireServer("Vault") end); task.wait(0.05)
    hrp.CFrame=CFrame.new(plantPos+Vector3.new(0,3,0)); task.wait(0.5)
    for _,fruit in ipairs(fruits:GetChildren()) do
        local cd=fruit:FindFirstChildOfClass("ClickDetector")
        if cd then pcall(fireclickdetector,cd); task.wait(0.1) end
    end
    notify("Claimed!",2); task.wait(0.5)
    rokaDeposit()
end

GB.FarmL:AddToggle("BWAutoFarmRoka",{Text="Auto Roka Farm",Default=false,
    Callback=function(p)
        if rokaFarmConn then task.cancel(rokaFarmConn); rokaFarmConn=nil end
        if not p then return end
        rokaFarmConn=task.spawn(function()
            while Tog.BWAutoFarmRoka and Tog.BWAutoFarmRoka.Value do
                -- deposit any roka we have
                if rokaHasRoka() then rokaDeposit() end
                -- if no plant growing, plant one
                if not workspace:FindFirstChild("LocaPlant") then
                    if not rokaHasSeed() then rokaWithdrawSeed() end
                    if not rokaHasSeed() then task.wait(3); continue end
                    rokaPlant()
                end
                -- wait for fruit then claim
                while Tog.BWAutoFarmRoka and Tog.BWAutoFarmRoka.Value do
                    local lp2=workspace:FindFirstChild("LocaPlant"); if not lp2 then break end
                    local fruits=lp2:FindFirstChild("Plant") and lp2.Plant:FindFirstChild("Fruits")
                    if fruits and #fruits:GetChildren()>0 then
                        rokaClaim()
                        -- wait for LocaPlant to clear before next cycle
                        local t0=tick()
                        while tick()-t0<20 do
                            if not workspace:FindFirstChild("LocaPlant") then break end
                            task.wait(1)
                        end
                        break
                    end
                    task.wait(5)
                end
                task.wait(1)
            end
        end)
    end})

GB.FarmL:AddToggle("BWAutoPlantSeed",{Text="Auto Plant Seeds",Default=false,
    Callback=function(p)
        if rokaPlantConn then task.cancel(rokaPlantConn); rokaPlantConn=nil end
        if not p then return end
        rokaPlantConn=task.spawn(function()
            while Tog.BWAutoPlantSeed and Tog.BWAutoPlantSeed.Value do
                if rokaHasSeed() then rokaPlant()
                else task.wait(1) end
            end
        end)
    end})

local rokaTradeConn = nil
GB.FarmL:AddLabel("Roka Trade")
GB.FarmL:AddDropdown("BWRokaTradeTarget",{Text="Request Trade Target",Values={"Select"},Default=1,Multi=false})
GB.FarmL:AddButton({Text="Refresh Players",Func=function()
    local list={"Select"}
    for _,p in ipairs(PS:GetPlayers()) do if p~=LP then table.insert(list,p.Name) end end
    Opt.BWRokaTradeTarget:SetValues(list)
end})
local autoRokaRequestConn = nil
GB.FarmL:AddToggle("BWAutoRequestRoka",{Text="Auto Request Roka Trade",Default=false,
    Callback=function(p)
        if autoRokaRequestConn then task.cancel(autoRokaRequestConn); autoRokaRequestConn=nil end
        if not p then return end
        autoRokaRequestConn = task.spawn(function()
            while Tog.BWAutoRequestRoka and Tog.BWAutoRequestRoka.Value do
                local val=Opt.BWRokaTradeTarget and Opt.BWRokaTradeTarget.Value
                local sel=type(val)=="table" and next(val) or val
                if sel and sel~="Select" then
                    local target=PS:FindFirstChild(sel)
                    local tc=target and target.Character
                    local thrp=tc and tc:FindFirstChild("HumanoidRootPart")
                    if thrp then
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.UseTool:FireServer("Rokakaka","RequestTrade",thrp.Position)
                        end)
                    end
                end
                task.wait(2)
            end
        end)
    end})
GB.FarmL:AddToggle("BWAutoRokaTrade",{Text="Auto Accept Roka Trade",Default=false,
    Callback=function(p)
        if rokaTradeConn then rokaTradeConn:Disconnect(); rokaTradeConn=nil end
        if not p then return end
        local tradeRem = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RokaTradeEvent")
        if not tradeRem then notify("RokaTradeEvent not found",3); Tog.BWAutoRokaTrade:SetValue(false); return end
        rokaTradeConn = LP.PlayerGui.DescendantAdded:Connect(function(obj)
            if not (Tog.BWAutoRokaTrade and Tog.BWAutoRokaTrade.Value) then return end
            if obj:IsA("TextButton") and obj.Name == "Yes" then
                task.wait(0.1)
                pcall(function() tradeRem:FireServer("RespondConfirm") end)
                notify("Auto accepted Roka trade!", 3)
            end
        end)
    end})
GB.FarmL:AddToggle("BWAutoDeclineRoka",{Text="Auto Decline Roka Trade",Default=false,
    Callback=function(p)
        if not p then
            if rokaTradeConn then rokaTradeConn:Disconnect(); rokaTradeConn=nil end
            return
        end
        local tradeRem = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RokaTradeEvent")
        if not tradeRem then return end
        rokaTradeConn = LP.PlayerGui.DescendantAdded:Connect(function(obj)
            if not (Tog.BWAutoDeclineRoka and Tog.BWAutoDeclineRoka.Value) then return end
            if obj:IsA("TextButton") and obj.Name == "No" then
                task.wait(0.1)
                pcall(function() tradeRem:FireServer("RespondNo") end)
            end
        end)
    end})

local autoStoreSeedConn = nil
GB.FarmL:AddToggle("BWAutoStoreRokaSeed",{Text="Auto Store Roka Seeds",Default=false,
    Callback=function(p)
        if autoStoreSeedConn then autoStoreSeedConn:Disconnect(); autoStoreSeedConn=nil end
        if not p then return end
        local function check(obj)
            if obj.Name == "Rokakaka Seed" then
                task.wait(0.2)
                pcall(function() 
                    game:GetService("ReplicatedStorage").Remotes.StorageAction:InvokeServer("Deposit", "Rokakaka Seed")
                end)
                notify("Auto stored Rokakaka Seed!", 2)
            end
        end
        autoStoreSeedConn = LP.Backpack.ChildAdded:Connect(check)
        for _,v in ipairs(LP.Backpack:GetChildren()) do check(v) end
        if LP.Character then
            for _,v in ipairs(LP.Character:GetChildren()) do check(v) end
        end
    end})

end
do
-- =====================
-- NPC TAB
-- =====================
local function refreshNPCs()
    npcList={"Select"}
    local f=workspace:FindFirstChild("NPC") or workspace:FindFirstChild("NPCs"); if not f then return end
    local seen={}
    for _,v in ipairs(f:GetChildren()) do
        if v:IsA("Model") and not seen[v.Name] then seen[v.Name]=true; table.insert(npcList,v.Name) end
    end
    table.sort(npcList,function(a,b) return a<b end)
    if Opt.BWNPCSelect then Opt.BWNPCSelect:SetValues(npcList) end
end
GB.CombatL:AddLabel("NPC Teleport")
GB.CombatL:AddButton({Text="Refresh NPCs",Func=function() refreshNPCs() end})
GB.CombatL:AddDropdown("BWNPCSelect",{Text="NPC",Values=npcList,Default=1,Multi=false})
GB.CombatL:AddButton({Text="Teleport to NPC",Func=function()
    local val=Opt.BWNPCSelect and Opt.BWNPCSelect.Value
    local sel=type(val)=="table" and next(val) or val
    if not sel or sel=="Select" then return end
    local f=workspace:FindFirstChild("NPC") or workspace:FindFirstChild("NPCs"); if not f then return end
    local npc=f:FindFirstChild(sel); if not npc then return end
    local hrp=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
    local myHRP=getHRP(); if not myHRP then return end
    tpTo(hrp.Position,myHRP)
end})



GB.MainSaints:AddToggle("BWAutoHop",{Text="Auto Hop Saint Parts",Default=false,
    Callback=function(p)
        if autoHopThread then task.cancel(autoHopThread); autoHopThread=nil end
        if autoHopPartConn then autoHopPartConn:Disconnect(); autoHopPartConn=nil end
        if not p then return end
        local hopCooldown=false
        local function grabPart(part)
            if hopCooldown then return end
            hopCooldown=true
            collectPartAndSafe(part)
            notify("Grabbed "..part.Name,3)
            local prevStand=LP:GetAttribute("EquippedStand")
            local elapsed=0
            while Tog.BWAutoHop and Tog.BWAutoHop.Value and elapsed<20 do
                task.wait(0.5); elapsed=elapsed+0.5
                if LP:GetAttribute("EquippedStand")~=prevStand then break end
            end
            hopCooldown=false
        end
        autoHopPartConn=workspace.DescendantAdded:Connect(function(obj)
            if not (Tog.BWAutoHop and Tog.BWAutoHop.Value) then return end
            if not obj:IsA("BasePart") then return end
            for _,name in ipairs(SAINT_PARTS) do
                if obj.Name==name then task.spawn(grabPart,obj); break end
            end
        end)
        autoHopThread=task.spawn(function()
            local TP2 = game:GetService("TeleportService")
            local HS2 = game:GetService("HttpService")
            local function hopNow()
                notify("Hopping...", 2)
                local ok, res = pcall(function()
                    return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
                end)
                if not ok or not res then notify("Hop failed", 3); return end
                local data = HS2:JSONDecode(res)
                for _, s in ipairs(data.data or {}) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then
                        pcall(function() TP2:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
                        return
                    end
                end
                notify("No servers found", 3)
            end
            local function findPart()
                for _,name in ipairs(SAINT_PARTS) do
                    local part = workspace:FindFirstChild(name, true)
                    if part and part:IsA("BasePart") then return part end
                end
                return nil
            end
            while Tog.BWAutoHop and Tog.BWAutoHop.Value do
                local waitTime = Opt.BWAutoHopDelay and Opt.BWAutoHopDelay.Value or 15
                local part = findPart()
                if part then
                    task.spawn(grabPart, part)
                    while hopCooldown and Tog.BWAutoHop and Tog.BWAutoHop.Value do task.wait(0.5) end
                else
                    notify("No parts - hopping in "..waitTime.."s", 3)
                    local elapsed = 0
                    local grabbed = false
                    while elapsed < waitTime and Tog.BWAutoHop and Tog.BWAutoHop.Value do
                        task.wait(1); elapsed += 1
                        local p = findPart()
                        if p then
                            task.spawn(grabPart, p)
                            grabbed = true
                            break
                        end
                    end
                    if not grabbed and Tog.BWAutoHop and Tog.BWAutoHop.Value then
                        hopNow()
                        task.wait(15)
                    else
                        while hopCooldown and Tog.BWAutoHop and Tog.BWAutoHop.Value do task.wait(0.5) end
                    end
                end
            end
        end)
    end,
})
GB.MainSaints:AddSlider("BWAutoHopDelay",{Text="Hop Delay (s)",Default=15,Min=5,Max=300,Rounding=0,Compact=true})

GB.CombatL:AddLabel("Storage")
task.spawn(function()
    local rem = game:GetService("ReplicatedStorage").Remotes
    storageAction = rem:WaitForChild("StorageAction",10)
end)
GB.CombatL:AddButton({Text="Insta Wipe",Func=function()
    pcall(function() game:GetService("ReplicatedStorage").Remotes.ManualWipeEvent:FireServer() end)
    notify("Wiped!",2)
end})
GB.CombatL:AddButton({Text="Deposit All",Func=function()
    task.spawn(function()
        if not storageAction then storageAction=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("StorageAction") end
        if not storageAction then notify("StorageAction not found",3); return end
        local function dep(container)
            for _,item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    pcall(function() storageAction:InvokeServer("Deposit",item.Name) end)
                    task.wait(0.1)
                end
            end
        end
        dep(LP.Backpack)
        if LP.Character then dep(LP.Character) end
        notify("Deposited all",2)
    end)
end})
local autoDepositConn2 = nil
task.defer(refreshNPCs)

-- Saints Parts ESP
GB.MainSaints:AddToggle("BWSaintsESP",{Text="Saints Parts ESP",Default=false,
    Callback=function(p)
        if saintsEspThread then task.cancel(saintsEspThread); saintsEspThread=nil end
        for _,d in pairs(saintsEspDrawings) do pcall(function() d:Remove() end) end
        saintsEspDrawings={}
        if not p then return end
        saintsEspThread=task.spawn(function()
            while Tog.BWSaintsESP and Tog.BWSaintsESP.Value do
                local myHRP=getHRP()
                for _,partName in ipairs(SAINT_PARTS) do
                    local part=workspace:FindFirstChild(partName)
                    if part and myHRP then
                        local sp,onScreen=Cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            if not saintsEspDrawings[partName] then saintsEspDrawings[partName]=Drawing.new("Text") end
                            local d=saintsEspDrawings[partName]
                            local dist=(part.Position-myHRP.Position).Magnitude
                            d.Text=partName.." ["..math.floor(dist).."m]"
                            d.Position=Vector2.new(sp.X,sp.Y); d.Size=14
                            d.Color=Color3.fromRGB(255,215,0); d.Outline=true; d.Center=true; d.Visible=true
                        elseif saintsEspDrawings[partName] then saintsEspDrawings[partName].Visible=false end
                    elseif saintsEspDrawings[partName] then
                        pcall(function() saintsEspDrawings[partName]:Remove() end)
                        saintsEspDrawings[partName]=nil
                    end
                end
                task.wait(0.05)
            end
            for _,d in pairs(saintsEspDrawings) do pcall(function() d:Remove() end) end
            saintsEspDrawings={}
        end)
    end,
})

-- Sniper Spawns
-- Wipe

-- Purchase Pads
GB.CombatR:AddLabel("Purchasables")
task.spawn(function()
    local pads=workspace:FindFirstChild("PurchasePads"); if not pads then return end
    local seen={}
    for _,pad in ipairs(pads:GetChildren()) do
        if pad:IsA("BasePart") or pad:IsA("Model") then
            local toolName=pad:GetAttribute("ToolName") or pad:GetAttribute("Toolname") or pad.Name
            local price=pad:GetAttribute("Price") or "?"
            local cd=pad:FindFirstChildOfClass("ClickDetector") or pad:FindFirstChild("ClickDetector",true)
            local key=toolName..tostring(price)
            if cd and not seen[key] then
                seen[key]=true
                table.insert(purchaseList,toolName.." ("..tostring(price).." moola)")
                table.insert(purchaseCDs,cd)
            end
        end
    end
    if Opt.BWPurchaseSelect then Opt.BWPurchaseSelect:SetValues(purchaseList) end
end)
GB.CombatR:AddDropdown("BWPurchaseSelect",{Text="Item",Values=purchaseList,Default=1,Multi=false})
GB.CombatR:AddButton({Text="Buy",Func=function()
    local val=Opt.BWPurchaseSelect and Opt.BWPurchaseSelect.Value
    local sel=type(val)=="table" and next(val) or val
    if not sel or sel=="Select" then notify("Select an item first",2); return end
    for i,name in ipairs(purchaseList) do
        if name==sel then
            local cd=purchaseCDs[i]
            if cd then pcall(function() fireclickdetector(cd) end); notify("Bought: "..sel,2) end
            return
        end
    end
end})
-- Auto Buy
GB.CombatR:AddDropdown("BWAutoBuySelect",{Text="Auto Buy Items",Values=purchaseList,Default={},Multi=true,Callback=function() end})
GB.CombatR:AddSlider("BWAutoBuyDelay",{Text="Buy Interval (s)",Default=3,Min=0.5,Max=30,Rounding=1,Compact=true})
GB.CombatR:AddToggle("BWAutoBuyItems",{Text="Auto Buy Items",Default=false,
    Callback=function(p)
        if autoBuyItemsConn then autoBuyItemsConn:Disconnect(); autoBuyItemsConn=nil end
        if not p then return end
        local tick_=0
        autoBuyItemsConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt
            local delay=Opt.BWAutoBuyDelay and Opt.BWAutoBuyDelay.Value or 3
            if tick_<delay then return end; tick_=0
            pcall(function()
                local selected=Opt.BWAutoBuySelect and Opt.BWAutoBuySelect.Value
                if not selected or not next(selected) then return end
                for sel in pairs(selected) do
                    for i,name in ipairs(purchaseList) do
                        if name==sel then
                            local cd=purchaseCDs[i]
                            if cd then pcall(function() fireclickdetector(cd) end) end
                            break
                        end
                    end
                end
            end)
        end)
    end,
})

-- =====================
-- =====================
-- FISHING TAB
-- =====================
local fishTab=Tabs.Farm
local fishR=fishTab:AddRightGroupbox("Shop")

-- Chest ESP + Proximity Prompt toggle
-- Two fishing spots — rotates after each cast cycle
local FISH_SPOTS = {
    {pos=Vector3.new(-4850.638671875, 45.263832092285156, -2057.288330078125), dir=Vector3.new(0,0,-1)},
    {pos=Vector3.new(-6146.09814453125, 1.0518869161605835, -2543.03466796875),  dir=Vector3.new(-1,0,0)},
}
local _fishSpotIdx = 1
local FISH_CUSTOM_SPOTS = {}
local _customSpotIdx = 0

-- persist custom spots to file
local function saveFishSpots()
    local t = {}
    for _,cf in ipairs(FISH_CUSTOM_SPOTS) do
        local p=cf.Position; local lv=cf.LookVector
        table.insert(t, string.format("%.4f,%.4f,%.4f,%.4f,%.4f", p.X,p.Y,p.Z,lv.X,lv.Z))
    end
    pcall(function() writefile("bw_fishspots.txt", table.concat(t,"\n")) end)
end
local function loadFishSpots()
    pcall(function()
        local data = readfile("bw_fishspots.txt")
        if not data or data=="" then return end
        for line in data:gmatch("[^\n]+") do
            local x,y,z,lx,lz = line:match("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)")
            if x then
                local pos=Vector3.new(tonumber(x),tonumber(y),tonumber(z))
                local look=Vector3.new(tonumber(lx),0,tonumber(lz))
                if look.Magnitude < 0.001 then look=Vector3.new(-1,0,0) end
                table.insert(FISH_CUSTOM_SPOTS, CFrame.new(pos, pos+look))
            end
        end
    end)
end
loadFishSpots()
local function _nextFishSpot()
    if #FISH_CUSTOM_SPOTS > 0 then
        _customSpotIdx = (_customSpotIdx % #FISH_CUSTOM_SPOTS) + 1
        notify("Moving to Saved Spot #".._customSpotIdx, 2)
    else
        _fishSpotIdx = (_fishSpotIdx % #FISH_SPOTS) + 1
        notify("Moving to Default Spot #".._fishSpotIdx, 2)
    end
end
local function _setClosestSpot()
    local hrp=getHRP(); if not hrp then return end
    if #FISH_CUSTOM_SPOTS > 0 then
        local closest=1; local minDist=math.huge
        for i,cf in ipairs(FISH_CUSTOM_SPOTS) do
            local d=(hrp.Position-cf.p).Magnitude
            if d<minDist then minDist=d; closest=i end
        end
        _customSpotIdx=closest; notify("Starting at nearest Saved Spot #"..closest,2)
    else
        local closest=1; local minDist=math.huge
        for i,s in ipairs(FISH_SPOTS) do
            local d=(hrp.Position-s.pos).Magnitude
            if d<minDist then minDist=d; closest=i end
        end
        _fishSpotIdx=closest; notify("Starting at nearest Default Spot #"..closest,2)
    end
end
local function _fishCF()
    if #FISH_CUSTOM_SPOTS > 0 then
        if _customSpotIdx < 1 or _customSpotIdx > #FISH_CUSTOM_SPOTS then _customSpotIdx = 1 end
        return FISH_CUSTOM_SPOTS[_customSpotIdx]
    end
    local s = FISH_SPOTS[_fishSpotIdx]
    return CFrame.new(s.pos, s.pos + s.dir)
end
local FISH_STAND_POS=FISH_SPOTS[1].pos
local FISH_DIR=FISH_SPOTS[1].dir
local FISH_CAST_ANIM="rbxassetid://99374973462906"
-- SLOWED DOWN from 40 to 14
local FISH_TWEEN_SPEED=14

local fishRem=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UseTool")
local bwDialogue=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DialogueRemote")

local function fishTweenTo(cf,hrp)
    if not hrp then return end
    _fishTweenCancel=false
    local startCF=hrp.CFrame
    local dist=(startCF.Position-cf.Position).Magnitude
    if dist<0.5 then hrp.CFrame=cf; return end
    local dur=dist/FISH_TWEEN_SPEED
    local elapsed=0
    while elapsed<dur and not _fishTweenCancel do
        local dt=RS.RenderStepped:Wait()
        if not hrp or not hrp.Parent then break end
        elapsed=elapsed+dt
        local t=math.min(elapsed/dur,1)
        hrp.CFrame=startCF:Lerp(cf,t)
        hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity=Vector3.new(0,0,0)
    end
    if not _fishTweenCancel and hrp and hrp.Parent then hrp.CFrame=cf end
end

local function fishAnimPlaying()
    local c=getChar(); if not c then return false end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return false end
    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
        if t.Animation and t.Animation.AnimationId==FISH_CAST_ANIM then return true end
    end
    return false
end

local function findBobber(hrp)
    local closest,closestDist=nil,60
    for _,v in ipairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("AlignPosition") then
            local d=(v.Position-hrp.Position).Magnitude
            if d<closestDist then closestDist=d; closest=v end
        end
    end
    return closest
end

local function doFishLoop()

    local function useBait(hum,c)
        -- find bait in backpack
        local bait=LP.Backpack:FindFirstChild("Bait") or LP.Backpack:FindFirstChild("FishingBait")
        if not bait then return end
        -- unequip current tool first
        hum:UnequipTools()
        task.wait(0.2)
        -- equip bait
        hum:EquipTool(bait)
        task.wait(0.3)
        -- fire use on the bait tool
        local useRem=bait:FindFirstChild("UseRemote") or bait:FindFirstChild("Use") or bait:FindFirstChild("Activate")
        if useRem and useRem:IsA("RemoteEvent") then
            pcall(function() useRem:FireServer() end)
        elseif useRem and useRem:IsA("RemoteFunction") then
            pcall(function() useRem:InvokeServer() end)
        else
            -- fallback: fire tool activated
            pcall(function()
                local activated=bait:FindFirstChild("Activated")
                if activated then activated:Fire() end
            end)
        end
        task.wait(0.3)
        -- unequip bait
        hum:UnequipTools()
        task.wait(0.2)
    end

    local function equipRod(hum,c)
        if c:FindFirstChild("FishingRod") then return true end
        local rod=LP.Backpack:FindFirstChild("FishingRod")
        if not rod then return false end
        hum:EquipTool(rod)
        task.wait(0.5)
        return true
    end

    local function cast(hrp)
        if not fishRem then fishRem=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("UseTool") end
        if not fishRem then return false end
        local cf=_fishCF()
        local lv=cf.LookVector
        local dir=Vector3.new(lv.X,0,lv.Z)
        if dir.Magnitude<0.01 then dir=Vector3.new(-1,0,0) end
        local castPos=cf.Position+dir.Unit*25+Vector3.new(0,-3,0)
        fishRem:FireServer("FishingRod","Primary",castPos)
        task.wait(1.5)
        return true
    end

    local function waitForBite(hrp)
        local bobber=nil
        local t0=tick()
        while tick()-t0<5 do bobber=findBobber(hrp); if bobber then break end; task.wait(0.1) end
        if not bobber then return nil end
        pcall(function() local rc=bobber:FindFirstChild("RopeConstraint"); if rc then rc:Destroy() end end)
        local beam=bobber:FindFirstChild("Beam")
        if beam then
            local timeout=tick()+40
            while tick()<timeout do
                if not bobber.Parent then return nil end
                if not (Tog.BWAutoFish and Tog.BWAutoFish.Value) then return nil end
                if beam.CurveSize0==0 then break end
                task.wait(0.05)
            end
        else task.wait(8) end
        return bobber
    end

    local function reel(bobber)
        if not bobber or not bobber.Parent then return end
        fishRem:FireServer("FishingRod","Primary",bobber.Position)
        task.wait(1)
    end

    -- SETUP: TP, use bait, equip rod
    local c=getChar(); if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end

    local targetCF=_fishCF()
    local oldNoclip=Tog.Noclip and Tog.Noclip.Value
    if Tog.Noclip then Tog.Noclip:SetValue(true) end
    charTweenTo(targetCF,25)
    if Tog.Noclip then Tog.Noclip:SetValue(oldNoclip) end
    task.wait(0.3)

    useBait(hum,c)
    if not equipRod(hum,c) then notify("No Fishing Rod in backpack!",4); return end

    -- MAIN LOOP
    while Tog.BWAutoFish and Tog.BWAutoFish.Value do
        local ok=pcall(function()
            c=getChar(); if not c then task.wait(2); return end
            hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(2); return end
            hum=c:FindFirstChildOfClass("Humanoid"); if not hum then task.wait(2); return end

            -- if dead, wait for respawn then re-setup
            if hum.Health<=0 then
                task.wait(1)
                local respawnWait=0
                while respawnWait<10 do
                    task.wait(0.5); respawnWait=respawnWait+0.5
                    local newC=getChar()
                    local newHum=newC and newC:FindFirstChildOfClass("Humanoid")
                    if newHum and newHum.Health>0 then break end
                end
                c=getChar(); if not c then return end
                hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                
                local targetCF=_fishCF()
                local oldNoclip=Tog.Noclip and Tog.Noclip.Value
                if Tog.Noclip then Tog.Noclip:SetValue(true) end
                charTweenTo(targetCF,25)
                if Tog.Noclip then Tog.Noclip:SetValue(oldNoclip) end
                task.wait(0.5)
                useBait(hum,c)
                if not equipRod(hum,c) then notify("Lost fishing rod on death!",5) end
                return
            end

            -- ensure we are at the spot
            local currentSpot=_fishCF()
            if (hrp.Position-currentSpot.p).Magnitude>10 then
                local oldNoclip=Tog.Noclip and Tog.Noclip.Value
                if Tog.Noclip then Tog.Noclip:SetValue(true) end
                charTweenTo(currentSpot,25)
                if Tog.Noclip then Tog.Noclip:SetValue(oldNoclip) end
                task.wait(0.5)
            end

            -- re-equip rod if it got unequipped
            if not c:FindFirstChild("FishingRod") then
                if not equipRod(hum,c) then
                    -- rod may be gone (dropped on death), notify and wait
                    notify("No Fishing Rod - did you die?",4)
                    task.wait(3); return
                end
            end

            -- cast
            if not cast(hrp) then task.wait(1); return end

            -- wait for bite
            local bobber=waitForBite(hrp)
            if not bobber then task.wait(1); return end

            -- reel
            reel(bobber)

            -- wait for minigame UI to fully disappear before touching the rod
            local pGui = LP:FindFirstChild("PlayerGui")
            if pGui then
                local t0 = tick()
                repeat task.wait(0.1) until tick()-t0 > 10 or (function()
                    local ms = pGui:FindFirstChild("MashingSystem")
                    local container = ms and ms:FindFirstChild("Container")
                    return not container or not container.Visible
                end)()
                -- extra wait after minigame closes so animation completes
                task.wait(1.5)
            end
            useBait(hum,c)
            equipRod(hum,c)
        end)
        if not ok then task.wait(3) end
    end
end

fishR:AddLabel("Shop")
fishR:AddButton({Text="Buy Fishing Rod (150 moola)",Func=function()
    if not bwDialogue then bwDialogue=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DialogueRemote") end
    pcall(function() bwDialogue:FireServer("Action","Buy_FishingRod",workspace.NPC.Daniel) end)
end})
fishR:AddToggle("BWFishPlatform",{Text="Create Platform",Default=false,
    Callback=function(p)
        if fishPlatform then fishPlatform:Destroy(); fishPlatform=nil end
        if not p then return end
        local hrp=getHRP(); if not hrp then return end
        local part=Instance.new("Part"); part.Size=Vector3.new(8,0.5,8)
        part.CFrame=CFrame.new(hrp.Position-Vector3.new(0,3,0))
        part.Anchored=true; part.CanCollide=true; part.Material=Enum.Material.SmoothPlastic
        part.Name="FishPlatform"; part.Parent=workspace; fishPlatform=part; notify("Platform created!",2)
    end,
})
fishR:AddToggle("BWFishFreeze",{Text="Freeze Position",Default=false,
    Callback=function(p)
        if p then
            local hrp=getHRP(); if not hrp then return end
            flyFrame=hrp.CFrame
            RS:BindToRenderStep("FishFreeze",Enum.RenderPriority.Input.Value+1,function()
                local h=getHRP(); if not h then return end
                h.CFrame=flyFrame; h.AssemblyLinearVelocity=Vector3.new(0,0,0); h.AssemblyAngularVelocity=Vector3.new(0,0,0)
            end)
        else RS:UnbindFromRenderStep("FishFreeze") end
    end,
})
fishR:AddButton({Text="Create New Fishing Spot",Func=function()
    local hrp=getHRP(); if not hrp then notify("No character",2); return end
    table.insert(FISH_CUSTOM_SPOTS, hrp.CFrame)
    saveFishSpots()
    notify("Spot "..#FISH_CUSTOM_SPOTS.." saved! Total: "..#FISH_CUSTOM_SPOTS,3)
end})
fishR:AddButton({Text="Tween to Fishing Spot",Func=function()
    local hrp=getHRP(); if not hrp then return end
    local target=_fishCF()
    local oldNoclip=Tog.Noclip and Tog.Noclip.Value
    if Tog.Noclip then Tog.Noclip:SetValue(true) end
    charTweenTo(target,25)
    if Tog.Noclip then Tog.Noclip:SetValue(oldNoclip) end
end})
fishR:AddButton({Text="Clear Saved Spots",Func=function()
    FISH_CUSTOM_SPOTS={}; _customSpotIdx=0; pcall(function() writefile("bw_fishspots.txt","") end); notify("Cleared - using default spots",2)
end})
fishR:AddLabel("Turn off Auto Buy Bait when using Auto Fishing")
fishR:AddToggle("BWAutoFish",{Text="Auto Fishing",Default=false,
    Callback=function(p)
        if fishThread then task.cancel(fishThread); fishThread=nil end
        RS:UnbindFromRenderStep("FishFreeze")
        if not p then return end
        _setClosestSpot()
        fishThread=task.spawn(doFishLoop)
        -- spook: rotate spot and restart loop so it vaults to new position
        task.spawn(function()
            local pGui=LP:WaitForChild("PlayerGui",10)
            local notifier=pGui and pGui:WaitForChild("NotifierGui",10)
            if not notifier then return end
            notifier.DescendantAdded:Connect(function(obj)
                if not (Tog.BWAutoFish and Tog.BWAutoFish.Value) then return end
                if obj.Name~="Notification" then return end
                task.wait(0.1)
                local ok,msg=pcall(function() return obj.Text end)
                if not ok or not msg then ok,msg=pcall(function() return obj:FindFirstChildWhichIsA("TextLabel").Text end) end
                if ok and msg and (msg:lower():find("spooked") or msg:lower():find("new spot")) then
                    _nextFishSpot()
                    if fishThread then task.cancel(fishThread); fishThread=nil end
                    fishThread=task.spawn(doFishLoop)
                end
            end)
        end)
    end,
})
fishR:AddLabel("Minigame")
fishR:AddToggle("BWAutoMinigame",{Text="Auto Minigame",Default=false,
    Callback=function(p)
        if miniGameThread then task.cancel(miniGameThread); miniGameThread=nil end
        if not p then return end
        local VIM2=game:GetService("VirtualInputManager")
        miniGameThread=task.spawn(function()
            while Tog.BWAutoMinigame and Tog.BWAutoMinigame.Value do
                pcall(function()
                    local playerGui=LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui",10)
                    local mashingSystem=playerGui:FindFirstChild("MashingSystem"); if not mashingSystem then return end
                    local container=mashingSystem:FindFirstChild("Container"); if not container or not container.Visible then return end
                    local circle=container:FindFirstChild("Circle"); if not circle then return end
                    local keyLabel=circle:FindFirstChild("KeyLabel"); if not keyLabel then return end
                    if circle.BackgroundTransparency~=1 and keyLabel.TextTransparency~=1 then
                        local txt=tostring(keyLabel.Text):gsub("%s+","")
                        local key=Enum.KeyCode[txt]
                        if key then
                            VIM2:SendKeyEvent(true,key,false,game)
                            task.wait(0.1)
                            VIM2:SendKeyEvent(false,key,false,game)
                        end
                    end
                end)
                task.wait(0.01)
            end
        end)
    end,
})
fishR:AddLabel("Chests")
fishR:AddToggle("BWChestTP",{Text="Chest Tween",Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.BWChestTP and Tog.BWChestTP.Value do
                local hrp=getHRP(); if not hrp then task.wait(0.5); continue end
                local startPos=hrp.CFrame
                local chestsF=workspace:FindFirstChild("Chests")
                if chestsF then
                    for _,child in ipairs(chestsF:GetChildren()) do
                        if not (Tog.BWChestTP and Tog.BWChestTP.Value) then break end
                        local prompt,part=nil,nil
                        if child:IsA("BasePart") then
                            prompt=child:FindFirstChild("ProximityPrompt"); part=child
                        elseif child:IsA("Model") then
                            local cb=child:FindFirstChild("ChestBox")
                            if cb then prompt=cb:FindFirstChild("ProximityPrompt"); part=cb
                            else prompt=child:FindFirstChildWhichIsA("ProximityPrompt",true); part=child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart") end
                        end
                        if prompt and prompt.Enabled and part then
                            local dist=(hrp.Position-part.Position).Magnitude
                            if dist<=20 then
                                notify("Collecting nearby chest...",2)
                                charTweenTo(CFrame.new(part.Position+Vector3.new(0,2,0)),25)
                                task.wait(0.2)
                                pcall(fireproximityprompt,prompt)
                                task.wait(0.5)
                                charTweenTo(_fishCF(),25)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end})
local chestHopConn=nil
fishR:AddToggle("BWChestHop",{Text="Auto Hop When Chests Gone",Default=false,
    Callback=function(p)
        if chestHopConn then chestHopConn:Disconnect(); chestHopConn=nil end
        if not p then return end
        chestHopConn=RS.Heartbeat:Connect(function()
            local chestsF=workspace:FindFirstChild("Chests")
            if not chestsF or #chestsF:GetChildren()==0 then
                if Tog.BWChestHop and Tog.BWChestHop.Value then
                    chestHopConn:Disconnect(); chestHopConn=nil
                    task.wait(1)
                    serverHop(10)
                end
            end
        end)
    end})
fishR:AddToggle("BWFishChestPrompt",{Text="Auto Collect Fishing Chest",Default=false,
    Callback=function(p)
        if fishChestConn then fishChestConn:Disconnect(); fishChestConn=nil end
        if not p then return end
        local lastFire=0
        fishChestConn=RS.Heartbeat:Connect(function()
            local now=tick(); if now-lastFire<2 then return end
            local hrp=getHRP(); if not hrp then return end
            local chestsF=workspace:FindFirstChild("Chests"); if not chestsF then return end
            for _,child in ipairs(chestsF:GetChildren()) do
                local prompt,part=nil,nil
                if child:IsA("BasePart") then
                    prompt=child:FindFirstChild("ProximityPrompt"); part=child
                elseif child:IsA("Model") then
                    local cb=child:FindFirstChild("ChestBox")
                    if cb then prompt=cb:FindFirstChild("ProximityPrompt"); part=cb
                    else prompt=child:FindFirstChildWhichIsA("ProximityPrompt",true); part=child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart") end
                end
                if prompt and prompt.Enabled and part then
                    lastFire=now
                    -- just fire the prompt directly - fishing chest spawns right next to you
                    pcall(fireproximityprompt, prompt)
                end
            end
        end)
    end,
})

fishR:AddLabel("Bait")
fishR:AddToggle("BWAutoBait",{Text="Auto Buy Bait",Default=false,
    Callback=function(p)
        if autoBaitConn then autoBaitConn:Disconnect(); autoBaitConn=nil end
        if not p then return end
        local tick_=0
        autoBaitConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<5 then return end; tick_=0
            pcall(function()
                local dial=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DialogueRemote")
                if not dial then return end
                local npcF=workspace:FindFirstChild("NPC")
                local daniel=npcF and npcF:FindFirstChild("Daniel")
                if not daniel then return end
                dial:FireServer("Action","Buy_Bait",daniel)
            end)
        end)
    end,
})
fishR:AddLabel("Sell Fish")
fishR:AddButton({Text="Sell All Fish",Func=function()
    local sellRemote=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DialogueRemote")
    if not sellRemote then notify("DialogueRemote not found",3); return end
    local daniel=workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Daniel")
    if not daniel then notify("Daniel NPC not found",3); return end
    local ignoredTools={FishingRod=true,AmmoPack=true,Stand=true}
    for _,tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and not ignoredTools[tool.Name] and not tool:FindFirstChild("AmmoInClip") then
            pcall(function() sellRemote:FireServer("Action","SellAll_"..tool.Name,daniel) end)
            task.wait(0.05)
        end
    end
    local c=getChar()
    if c then
        for _,tool in ipairs(c:GetChildren()) do
            if tool:IsA("Tool") and not ignoredTools[tool.Name] and not tool:FindFirstChild("AmmoInClip") then
                pcall(function() sellRemote:FireServer("Action","SellAll_"..tool.Name,daniel) end)
                task.wait(0.05)
            end
        end
    end
end})
fishR:AddToggle("BWAutoSellFish",{Text="Auto Sell Fish",Default=false,
    Callback=function(p)
        if autoSellConn then autoSellConn:Disconnect(); autoSellConn=nil end
        if not p then return end
        local sellRemote=game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DialogueRemote")
        local tick_=0
        autoSellConn=RS.Heartbeat:Connect(function(dt)
            tick_=tick_+dt; if tick_<10 then return end; tick_=0
            pcall(function()
                if not sellRemote then return end
                local daniel=workspace.NPC and workspace.NPC:FindFirstChild("Daniel"); if not daniel then return end
                local ignoredTools={FishingRod=true,AmmoPack=true,Stand=true}
                for _,tool in ipairs(LP.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and not ignoredTools[tool.Name] and not tool:FindFirstChild("AmmoInClip") then
                        sellRemote:FireServer("Action","SellAll_"..tool.Name,daniel)
                        task.wait(0.05)
                    end
                end
            end)
        end)
    end,
})

end
do
-- =====================
-- STAND FARM TAB
-- =====================
(function()
-- Stand section
GB.MainStatus:AddLabel("Stand")
local currentStandLabel=GB.MainStatus:AddLabel("Equipped: None")
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local s=LP:GetAttribute("EquippedStand")
            currentStandLabel:SetText("Equipped: "..(s and s~="" and s or "None"))
        end)
    end
end)




end)()

end

local UILeft=Tabs.UI:AddLeftGroupbox("Menu")
local UIRight=Tabs.UI:AddRightGroupbox("Appearance")
local menuKeybind=UILeft:AddLabel("Toggle Menu"):AddKeyPicker("MenuKeybind",{
    Default="RightShift",NoUI=false,Text="Toggle Menu",
    Callback=function() Library:Toggle() end,
})
Library.ToggleKeybind=menuKeybind
UILeft:AddToggle("ShowKeybinds",{Text="Keybinds Panel",Default=true,
    Callback=function(p) if Library.KeybindFrame then Library.KeybindFrame.Visible=p end end})
UILeft:AddButton({Text="Unload Script",Func=function() Library:Unload() end})

Library.OnUnload(function()
    CAS:UnbindAction("BWSAAction")
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    for _,e in pairs(ESPObjects) do pcall(function() e.hl:Destroy(); e.nameTxt:Remove(); e.hpTxt:Remove() end) end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("NBHub")
ThemeManager:ApplyTheme("BBot")
SaveManager:SetFolder("NBHub/configs")
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)
SaveManager:LoadAutoloadConfig()
ThemeManager:ApplyTheme("BBot")
notify("NB Hub Loaded!",5)
