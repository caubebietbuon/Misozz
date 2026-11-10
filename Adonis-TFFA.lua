-- ADONIS HUB v3 | GENERATED: edit src/, then run python tools/build.py
-- Single executable. All modules are embedded; no HTTP/file loading needed.
return (function()
    assert(type(loadstring) == "function", "Adonis Hub requires loadstring")
    local sources = {
        ["boost_fps"] = [=[
-- Local visual reductions. Unknown pet ownership is always left visible.
return function(ctx)
local session
local nextRetry=0
local process,ensureDrain,onFailure
local seedPlot,seedPlots,watchRoot
local ownerKeys={OwnerUserId=true,OwnerId=true,Owner=true,PlayerUserId=true}
local invisibleParticles=NumberSequence.new(1)
local function sameValue(a,b)
    if a==b then return true end
    if typeof(a)~="NumberSequence" or typeof(b)~="NumberSequence" then return false end
    local ak,bk=a.Keypoints,b.Keypoints
    if #ak~=#bk then return false end
    for i,key in ipairs(ak) do
        local other=bk[i]
        if key.Time~=other.Time or key.Value~=other.Value or key.Envelope~=other.Envelope then return false end
    end
    return true
end
local function inWorld(obj)
    local p=obj
    while p do if p==workspace then return true end; p=p.Parent end
    return false
end
local function ownership(obj)
    local pet,owner,conflict,localScope=false,nil,false,false
    local plot,plotPet
    local ancestors={}
    local p=obj
    while p and p~=workspace do
        ancestors[#ancestors+1]=p
        if p.Name=="Animals" and p.Parent and p.Parent.Parent
            and p.Parent.Parent.Parent==workspace and p.Parent.Parent.Name=="Plots" then
            plot,plotPet=p.Parent,true
        end
        if p==ctx.player.Character or (p.Parent==workspace and p.Name=="LocalPlotProps") then localScope=true end
        p=p.Parent
    end
    if plot and ctx.plotOwner then
        local record=session.plotOwners[plot]
        if not record then record={ctx.plotOwner(plot,session.roster)}; session.plotOwners[plot]=record end
        local id=record[1]
        if id==ctx.player.UserId then return false end
        if plotPet and id and session.players[id] and not localScope then return true end
        -- Unknown/conflicting plot ownership may not be overridden by a pet tag.
        return false
    end
    -- Asset metadata is not plot ownership. Consult it only outside Plots.
    for _,ancestor in ipairs(ancestors) do
        if ancestor:IsA("Model") and (ancestor:GetAttribute("AnimalId")~=nil or ancestor:GetAttribute("AnimalName")~=nil) then pet=true end
        for key in pairs(ownerKeys) do
            local value=ancestor:GetAttribute(key)
            if value~=nil then
                local id=tonumber(value)
                if not id and type(value)=="string" then id=session.names[value] end
                if not id or (owner and owner~=id) then conflict=true else owner=id end
            end
        end
    end
    -- A conflicting/local ancestry can never authorize hiding our own animal.
    return pet and not localScope and not conflict and owner~=nil
        and session.players[owner] and owner~=ctx.player.UserId
end
local function restore(obj,properties)
    for property,record in pairs(properties) do
        if record.connection then record.connection:Disconnect() end
        pcall(function() if sameValue(obj[property],record.forced) then obj[property]=record.original end end)
    end
end
local function disconnectAll(list)
    for _,connection in pairs(list) do connection:Disconnect() end
end
local function release()
    local s=session; session=nil
    if not s then return end
    if s.drain then s.drain:Disconnect(); s.drain=nil end
    for _,connection in ipairs(s.connections) do connection:Disconnect() end
    for _,connection in pairs(s.models) do connection:Disconnect() end
    for _,map in ipairs({s.scopes,s.plotChildren,s.rootNames,s.rootSlots,s.playerWatches}) do
        for _,connections in pairs(map) do disconnectAll(connections) end
    end
    for obj,properties in pairs(s.records) do restore(obj,properties) end
end
local function enqueue(s,obj,urgent)
    if obj and session==s then
        local queue=urgent and s.priority or s.normal
        local existing=s.queued[obj]
        if existing==queue or existing==s.priority then return end
        queue.tail=queue.tail+1; queue.items[queue.tail]=obj; s.queued[obj]=queue
        if urgent then
            s.petStartedAt=s.petStartedAt or os.clock()
            if ensureDrain then ensureDrain(s) end
        end
    end
end
local function queue() return {items={},head=1,tail=0} end
local function pop(s)
    local q=s.priority.head<=s.priority.tail and s.priority or s.normal
    if q.head>q.tail then return nil,false end
    local obj=q.items[q.head]; q.items[q.head]=nil; q.head=q.head+1
    if q.head>q.tail then q.items={}; q.head=1; q.tail=0 end
    if s.queued[obj]~=q then return nil,true end -- promoted, ignore old normal entry
    s.queued[obj]=nil
    return obj,true,q==s.priority
end
local function watchContainer(s,obj)
    if not obj or s.scopes[obj] then return end
    local function refresh()
        enqueue(s,obj,true)
        if s.shallow[obj] then seedPlot(s,obj) end
    end
    local function changed(child) enqueue(s,child,true) end
    s.scopes[obj]={obj.DescendantAdded:Connect(changed),obj.DescendantRemoving:Connect(changed),
        obj:GetPropertyChangedSignal("Parent"):Connect(refresh),obj:GetPropertyChangedSignal("Name"):Connect(refresh)}
end
local function watchPlotChildren(s,plot)
    if s.plotChildren[plot] then return end
    local list={}; s.plotChildren[plot]=list
    local childNames={}
    local function added(child)
        if not childNames[child] then
            childNames[child]=child:GetPropertyChangedSignal("Name"):Connect(function()
                enqueue(s,child,true); seedPlot(s,plot)
            end)
        end
        enqueue(s,child,true); seedPlot(s,plot)
    end
    list[1]=plot.ChildAdded:Connect(added)
    list[2]=plot.ChildRemoved:Connect(function(child)
        if childNames[child] then childNames[child]:Disconnect(); childNames[child]=nil end
        enqueue(s,child,true); seedPlot(s,plot)
    end)
    list[3]={Disconnect=function() disconnectAll(childNames) end}
    for _,child in ipairs(plot:GetChildren()) do added(child) end
end
seedPlot=function(s,plot)
    if not plot then return end
    s.plotOwners[plot]=nil
    s.shallow[plot]=true
    watchContainer(s,plot)
    watchPlotChildren(s,plot)
    local animals=plot:FindFirstChild("Animals")
    watchContainer(s,animals)
    enqueue(s,plot,true)
    enqueue(s,plot:FindFirstChild("OwnerTag"),true)
    enqueue(s,animals,true)
end
seedPlots=function(s,plots)
    if not plots then return end
    s.seededRoots[plots]=true
    s.shallow[plots]=true
    watchRoot(s,plots)
    if not s.rootSlots[plots] then
        s.rootSlots[plots]={plots.ChildAdded:Connect(function(plot) seedPlot(s,plot) end),
            plots.ChildRemoved:Connect(function(plot) enqueue(s,plot,true) end)}
    end
    for _,plot in ipairs(plots:GetChildren()) do seedPlot(s,plot) end
end
watchRoot=function(s,obj)
    if s.rootNames[obj] or not (obj:IsA("Model") or obj:IsA("Folder")) then return end
    local function changed()
        if obj.Parent==workspace and obj.Name=="Plots" then seedPlots(s,obj)
        elseif s.seededRoots[obj] then
            s.seededRoots[obj],s.shallow[obj]=nil,nil
            for _,plot in ipairs(obj:GetChildren()) do seedPlot(s,plot) end
            enqueue(s,obj,true)
        end
    end
    s.rootNames[obj]={obj:GetPropertyChangedSignal("Name"):Connect(changed),obj:GetPropertyChangedSignal("Parent"):Connect(changed)}
end
local function plotAncestor(obj)
    local p=obj
    while p and p.Parent do
        if p.Parent.Name=="Plots" and p.Parent.Parent==workspace then return p end
        p=p.Parent
    end
end
local function targets(obj)
    local hidden=inWorld(obj) and ownership(obj)
    local result={}
    if obj==ctx.services.Lighting then result.GlobalShadows=false end
    if obj:IsA("BasePart") then result.CastShadow=false end
    if obj:IsA("Light") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then result.Shadows=false end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
        or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect")
        or obj:IsA("DepthOfFieldEffect") then result.Enabled=false end
    if obj:IsA("Explosion") then result.Visible=false end
    -- Enabled alone does not hide explicit Emit() bursts or particles already
    -- alive. Mask their drawing without clearing/destroying the emitter.
    if obj:IsA("ParticleEmitter") then result.Transparency=invisibleParticles; result.Rate=0 end
    if obj:IsA("Smoke") then result.Opacity=0 end
    if hidden then
        if obj:IsA("BasePart") then result.LocalTransparencyModifier=1 end
        if obj:IsA("Decal") or obj:IsA("Texture") then result.Transparency=1 end
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then result.Enabled=false end
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then result.Enabled=false end
    end
    return result
end
local function apply(s,obj,desired)
    local properties=s.records[obj] or {}
    for property,record in pairs(properties) do
        if desired[property]==nil then restore(obj,{[property]=record}); properties[property]=nil end
    end
    for property,value in pairs(desired) do
        if not properties[property] then
            local ok,original=pcall(function() return obj[property] end)
            if ok then
                local record={original=original,forced=value,writing=false}
                properties[property]=record
                record.connection=obj:GetPropertyChangedSignal(property):Connect(function()
                    if session~=s or record.writing then return end
                    local current=obj[property]
                    if sameValue(current,record.forced) then return end
                    record.original=current; record.writing=true
                    obj[property]=record.forced; record.writing=false
                end)
                record.writing=true; obj[property]=value; record.writing=false
            end
        end
    end
    s.records[obj]=next(properties) and properties or nil
end
local function begin()
    local s={normal=queue(),priority=queue(),queued={},shallow={},seededRoots={},records={},models={},connections={},
        plotOwners={},scopes={},plotChildren={},rootNames={},rootSlots={},playerWatches={},identities={},departing={}}
    session=s
    -- Do not make pet visuals wait behind tens of thousands of biome parts.
    seedPlots(s,workspace:FindFirstChild("Plots"))
    for _,obj in ipairs(workspace:GetChildren()) do watchRoot(s,obj) end
    apply(s,ctx.services.Lighting,{GlobalShadows=false})
    enqueue(s,workspace); enqueue(s,ctx.services.Lighting)
    local function added(obj)
        if obj.Parent==workspace then watchRoot(s,obj) end
        local plot=plotAncestor(obj)
        if plot then
            enqueue(s,obj,true)
            if obj==plot or obj.Name=="OwnerTag" or obj.Name=="Animals" then seedPlot(s,plot) end
        elseif obj.Name=="Plots" and obj.Parent==workspace then seedPlots(s,obj)
        else enqueue(s,obj) end
    end
    table.insert(s.connections,workspace.DescendantAdded:Connect(added))
    table.insert(s.connections,workspace.DescendantRemoving:Connect(added))
    table.insert(s.connections,ctx.services.Lighting.DescendantAdded:Connect(added))
    table.insert(s.connections,ctx.services.Lighting.DescendantRemoving:Connect(added))
    local function rosterChanged()
        for plot in pairs(s.plotChildren) do seedPlot(s,plot) end
        for model in pairs(s.identities) do enqueue(s,model,true) end
    end
    local function watchPlayer(player)
        if s.playerWatches[player] or type(player.GetPropertyChangedSignal)~="function" then return end
        s.playerWatches[player]={player:GetPropertyChangedSignal("Name"):Connect(rosterChanged),
            player:GetPropertyChangedSignal("DisplayName"):Connect(rosterChanged)}
    end
    local players=ctx.services.Players
    if players.PlayerAdded then
        s.connections[#s.connections+1]=players.PlayerAdded:Connect(function(player)
            s.departing[player.UserId]=nil; watchPlayer(player); rosterChanged()
        end)
    end
    if players.PlayerRemoving then
        s.connections[#s.connections+1]=players.PlayerRemoving:Connect(function(player)
            s.departing[player.UserId]=true
            if s.playerWatches[player] then disconnectAll(s.playerWatches[player]); s.playerWatches[player]=nil end
            rosterChanged()
        end)
    end
    for _,player in ipairs(players:GetPlayers()) do watchPlayer(player) end
end
process=function(s,priorityOnly,seconds,limit)
    local deadline=os.clock()+seconds
    s.plotOwners={}
    s.players,s.names,s.roster={},{},{}
    for _,player in ipairs(ctx.services.Players:GetPlayers()) do
        if not s.departing[player.UserId] then
            s.players[player.UserId]=true; s.names[player.Name]=player.UserId
            s.roster[#s.roster+1]=player
        end
    end
    if not priorityOnly and workspace.CurrentCamera~=s.camera then s.camera=workspace.CurrentCamera; enqueue(s,s.camera) end
    -- Spend a bounded slice on urgent pet work; map decorations get only the
    -- remainder. Never turn a large initial world into one blocking traversal.
    local normalWork=0
    for i=1,limit do
        if os.clock()>=deadline then break end
        if priorityOnly and s.priority.head>s.priority.tail then break end
        if s.priority.head>s.priority.tail then
            if normalWork>=32 then break end
            normalWork=normalWork+1
        end
        local obj,more,urgent=pop(s)
        if not more then break end
        if obj then
            if urgent then s.petJobs=(s.petJobs or 0)+1 end
            local present=inWorld(obj) or obj==ctx.services.Lighting or obj.Parent==ctx.services.Lighting
                or obj==s.camera or obj.Parent==s.camera
            if present then
                if obj:IsA("Model") then
                    s.identities[obj]=(obj:GetAttribute("AnimalId")~=nil or obj:GetAttribute("AnimalName")~=nil) and not plotAncestor(obj) or nil
                end
                if obj.Name=="OwnerTag" and obj.Parent and obj.Parent.Parent
                    and obj.Parent.Parent.Name=="Plots" and not s.models[obj]
                    and ctx.watchPlotTag then
                    s.models[obj]=ctx.watchPlotTag(obj,function() seedPlot(s,obj.Parent) end)
                    seedPlot(s,obj.Parent)
                end
                if (obj:IsA("Model") or obj:IsA("Folder") or s.shallow[obj]) and not s.models[obj] then
                    s.models[obj]=obj.AttributeChanged:Connect(function(key)
                        if ownerKeys[key] or key=="AnimalId" or key=="AnimalName" then
                            if s.shallow[obj] then seedPlot(s,obj) else enqueue(s,obj,urgent) end
                        end
                    end)
                end
                apply(s,obj,targets(obj))
            else
                if s.records[obj] then restore(obj,s.records[obj]); s.records[obj]=nil end
                if s.models[obj] then s.models[obj]:Disconnect(); s.models[obj]=nil end
                for _,map in ipairs({s.scopes,s.plotChildren,s.rootNames,s.rootSlots}) do
                    if map[obj] then disconnectAll(map[obj]); map[obj]=nil end
                end
                s.identities[obj]=nil
            end
            if not s.shallow[obj] or not present then
                for _,child in ipairs(obj:GetChildren()) do
                    if child.Name=="Plots" and child.Parent==workspace then
                        if not s.seededRoots[child] then seedPlots(s,child) end
                    else enqueue(s,child,urgent) end
                end
            end
        end
    end
end
local function finishDrain(s)
    if session~=s or s.priority.head<=s.priority.tail then return end
    if s.drain then s.drain:Disconnect(); s.drain=nil end
    if s.petStartedAt then s.petFinishedAt=os.clock() end
end
-- Temporary event connection drains ONLY queued pet work. No normal-world
-- scans, input, rendering bindings, logging or disk I/O in this callback.
ensureDrain=function(s)
    if s.drain or session~=s then return end
    local run=ctx.services.RunService
    if not run then return end
    s.drain=run.Heartbeat:Connect(function()
        if session~=s then return end
        if not ctx.state.alive or not ctx.cfg.BoostFPS then release(); return end
        local ok,err=pcall(process,s,true,0.0015,256)
        if not ok then onFailure(err); return end
        finishDrain(s)
    end)
end
onFailure=function(err)
    release(); nextRetry=os.clock()+30
    ctx.log("BOOST_FPS_ERROR",tostring(err).."; restored graphics, retry after 30s")
end
local function update()
    if not ctx.state.alive or not ctx.cfg.BoostFPS then release(); return end
    if os.clock()<nextRetry then return end
    if not session then begin() end
    local s=session
    process(s,false,0.004,256)
    finishDrain(s)
    if s.petFinishedAt and s.priority.head>s.priority.tail then
        -- Report outside Heartbeat, once per completed burst rather than frame.
        ctx.log("BOOST_PETS_READY",string.format("jobs=%d elapsed=%.3fs",s.petJobs or 0,s.petFinishedAt-s.petStartedAt))
        s.petStartedAt,s.petFinishedAt,s.petJobs=nil,nil,0
    end
end
function ctx.updateBoostFPS()
    local ok,err=pcall(update)
    if not ok then onFailure(err) end
end
function ctx.boostDiagnostics()
    local s=session
    local hidden=0
    if s then
        for _,properties in pairs(s.records) do if properties.LocalTransparencyModifier then hidden=hidden+1 end end
    end
    return {"enabled="..tostring(ctx.cfg.BoostFPS).." active="..tostring(s~=nil)
        .." queued="..tostring(s and (s.normal.tail-s.normal.head+1+s.priority.tail-s.priority.head+1) or 0)
        .." petPriority="..tostring(s and s.priority.tail-s.priority.head+1 or 0)
        .." fastDrain="..tostring(s and s.drain~=nil or false)
        .." hiddenPetParts="..hidden
        .."; Plots.Animals uses explicit OwnerTag/Name; unknown/conflicting owners stay visible"}
end
table.insert(ctx.disposers,release)
end
]=],
        ["branding"] = [=[
-- Generated logo payload. Edit assets/adonis-logo.png, then python tools/build-branding.py.
-- Local executor asset support is optional; no HTTP request or remote asset ID.
return function(ctx)
local register=type(getcustomasset)=="function" and getcustomasset
    or (type(getsynasset)=="function" and getsynasset)
ctx.brandLogo=""
if not register or type(writefile)~="function" then return end
local path="AdonisHub-logo-ae94de1951f4.png"
local ok,uri=pcall(function()
    local exists=false
    if type(isfile)=="function" then local checked,value=pcall(isfile,path); exists=checked and value==true end
    if not exists then
        -- Decode once at initialization, before any automated cinema is active.
        local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup={}; for i=1,#alphabet do lookup[alphabet:sub(i,i)]=i-1 end
        local payload="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"
        local bytes={}
        for i=1,#payload,4 do
            local a,b,c,d=payload:sub(i,i),payload:sub(i+1,i+1),payload:sub(i+2,i+2),payload:sub(i+3,i+3)
            local n=lookup[a]*262144+lookup[b]*4096+(lookup[c] or 0)*64+(lookup[d] or 0)
            bytes[#bytes+1]=string.char(math.floor(n/65536)%256)
            if c~="=" then bytes[#bytes+1]=string.char(math.floor(n/256)%256) end
            if d~="=" then bytes[#bytes+1]=string.char(n%256) end
        end
        writefile(path,table.concat(bytes))
    end
    return register(path)
end)
if ok and type(uri)=="string" and uri~="" then ctx.brandLogo=uri
elseif ctx.log then ctx.log("LOGO_UNAVAILABLE",tostring(uri)) end
end
]=],
        ["cinema"] = [=[
-- Adonis Hub / cinema
return function(ctx)
local pg = ctx.pg
local connections = ctx.connections
local function cinemaPrompt(...) return ctx.cinemaPrompt(...) end
local function clickAt(...) return ctx.clickAt(...) end
local function finishThrowCinema(...) return ctx.finishThrowCinema(...) end
local function log(...) return ctx.log(...) end
local function onScreen(...) return ctx.onScreen(...) end
local function promptKind(...) return ctx.promptKind(...) end
local function say(...) return ctx.say(...) end
local function ui(...) return ctx.ui(...) end
local function visible(...) return ctx.visible(...) end
local function textAlpha(obj)
    return ctx.cinemaTextTransparency and ctx.cinemaTextTransparency(obj) or obj.TextTransparency
end

-- Index matching text once; update it from events instead of rescanning PlayerGui.
local promptCandidates, textConnections = {}, {}
function ctx.promptKind(text)
    text = text:gsub("<[^>]*>", ""):lower():gsub("%s+", " ")
    text = text:match("^%s*(.-)%s*$"):gsub("[!%.]+$", "")
    if text == "tap to continue" then return "continue" end
    if text == "tap to skip" then return "skip" end
end
local function indexText(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) or textConnections[obj] then return end
    promptCandidates[obj] = promptKind(obj.Text)
    textConnections[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
        promptCandidates[obj] = promptKind(obj.Text)
    end)
end
for _, obj in ipairs(pg:GetDescendants()) do indexText(obj) end
ctx.state.cinemaContinueSerial = 0
function ctx.cinemaPrompt()
    -- The probe shows this label is destroyed/recreated between Skip and Continue.
    -- Resolve the known path directly too, without depending solely on event order.
    local direct = ui("ThrowSequence.Text")
    if direct and (direct:IsA("TextLabel") or direct:IsA("TextButton")) then
        local kind = promptKind(direct.Text)
        if kind and onScreen(direct) and textAlpha(direct) < 0.98 then return direct, kind end
    end
    local skip
    for obj, kind in pairs(promptCandidates) do
        if obj.Parent and onScreen(obj) and textAlpha(obj) < 0.98 then
            if kind == "continue" then return obj, kind end
            skip = obj
        end
    end
    if skip then return skip, "skip" end
end
table.insert(connections, pg.DescendantAdded:Connect(indexText))
table.insert(connections, pg.DescendantRemoving:Connect(function(obj)
    promptCandidates[obj] = nil
    if textConnections[obj] then textConnections[obj]:Disconnect(); textConnections[obj] = nil end
end))
-- Latch actual cinema entry for this throw. HUD may still be present briefly
-- after the +20 tap; elapsed time alone must never finish a fresh throw.
local function observeCinema(prompt)
    local hud = ui("HUD.RightSideButtons.AnimalsButton")
    local hudVisible = visible(hud)
    local meterVisible = visible(ui("ThrowSequence.Meter.Bar"))
    if ctx.state.cinemaPending and not ctx.state.cinemaObserved
        and (prompt or (hud and not hudVisible and not meterVisible)) then
        ctx.state.cinemaObserved = true
        log("CINEMA_ENTERED", prompt and "Visible cinema prompt" or "HUD and meter left gameplay")
    end
    return hudVisible, meterVisible
end
-- One independent watcher owns cinema taps, even while another cycle step waits.
-- Respect START/STOP, but do not require Throw or any particular cycle stage.
task.spawn(function()
    local lastObj, lastKind, lastTap, lastError, attempts = nil, nil, 0, -math.huge, 0
    local lastReceiptError=-math.huge
    while ctx.state.alive do
        -- Passive pet receipts also work with START stopped and manual throws.
        -- Observe before the automation can tap Skip/Continue on this iteration.
        if ctx.observePetReceipt then
            local ok,err=pcall(ctx.observePetReceipt)
            if not ok and os.clock()-lastReceiptError>=5 then
                log("PET_OBSERVER_ERROR",err); lastReceiptError=os.clock()
            end
        end
        if ctx.state.running then
            local ok, err = pcall(function()
                if ctx.tapTrainingBonus then ctx.tapTrainingBonus() end
                local obj, kind = cinemaPrompt()
                if obj and not ctx.state.cinemaPending then
                    ctx.state.cinemaContinueSerial = 0
                    ctx.state.cinemaInterrupted = false
                    ctx.state.cinemaObserved = false
                    ctx.state.cinemaPending = true
                end
                local hudVisible = observeCinema(obj)
                -- Only an already active cinema may receive taps without text.
                -- The game accepts screen taps during the inter-prompt transition,
                -- including when ThrowSequence.Text is temporarily destroyed.
                local transition = not obj and ctx.state.cinemaPending
                    and (ctx.state.cinemaObserved or ctx.state.cinemaContinueSerial>0)
                    and not hudVisible
                if transition then kind = "transition" end
                local ready = os.clock()-lastTap >= 0.75
                    or (obj and (obj ~= lastObj or kind ~= lastKind))
                if (obj or transition) and ready then
                    ctx.state.cinemaPending = true
                    if obj ~= lastObj or kind ~= lastKind then attempts = 0 end
                    attempts = attempts+1
                    local method = attempts >= 3 and attempts % 2 == 1 and "VirtualUser" or "VirtualInputManager"
                    local camera = workspace.CurrentCamera
                    if not camera then return end
                    -- The prompt at the bottom can extend beyond the viewport.
                    -- Tap a clear in-bounds point; the game's cinema listens to screen input.
                    local x,y=ctx.clearTapPoint()
                    if not x then return end
                    -- Set the retry deadline even if the selected input API fails.
                    lastObj, lastKind, lastTap = obj, kind, os.clock()
                    local clicked, clickError = pcall(ctx.cinemaTap, x, y, method)
                    if not clicked then error(clickError, 0) end
                    if kind == "continue" then
                        ctx.state.cinemaContinueSerial = ctx.state.cinemaContinueSerial+1
                    end
                    log("CINEMA_TAP", kind .. " source=" .. (obj and obj:GetFullName() or "active cinema")
                        .. " attempt=" .. attempts .. " method=" .. method)
                elseif not obj and not transition then
                    lastObj, lastKind = nil, nil
                end
            end)
            if not ok and os.clock()-lastError > 5 then
                log("CINEMA_TAP_ERROR", err); lastError = os.clock()
            end
        end
        if ctx.updateThrowPresentation then ctx.updateThrowPresentation() end
        if ctx.updateBoostFPS then ctx.updateBoostFPS() end
        if ctx.flushConfig then ctx.flushConfig() end
        task.wait(0.15)
    end
end)
function ctx.finishThrowCinema()
    ctx.state.cinemaPending = true
    if ctx.updateThrowPresentation then ctx.updateThrowPresentation() end
    say("Cinema: auto tap transitions / Skip / Continue...")
    local returnedAt
    while ctx.state.alive and ctx.state.running do
        local prompt = cinemaPrompt()
        local hudVisible, meterVisible = observeCinema(prompt)
        -- STOP can leave a pending cinema that the player finishes manually.
        -- There will be no automatic Continue serial for that manual action.
        local interrupted = ctx.state.cinemaInterrupted
        -- A Continue label/input can be missed even though the game has already
        -- returned. Observed cinema -> stable gameplay is also completion;
        -- waiting only for our own click serial otherwise holds the view forever.
        local hudRecovery = ctx.state.cinemaContinueSerial == 0 and not interrupted
        if not prompt and (ctx.state.cinemaContinueSerial > 0 or interrupted or ctx.state.cinemaObserved)
            and hudVisible and not meterVisible then
            returnedAt = returnedAt or os.clock()
            if os.clock()-returnedAt >= (hudRecovery and 1.2 or 0.8) then
                ctx.state.completedThrows = ctx.state.completedThrows+1
                ctx.state.cinemaPending = false
                ctx.state.cinemaInterrupted = false
                ctx.state.cinemaObserved = false
                ctx.state.cinemaContinueSerial = 0
                if ctx.finishThrowPresentation then
                    local ok,err = pcall(ctx.finishThrowPresentation)
                    if not ok then log("PRESENTATION_ERROR",err) end
                end
                if interrupted then log("CINEMA_RECOVERED", "Stable HUD after STOP/manual cinema completion") end
                if hudRecovery then log("CINEMA_RECOVERED", "Observed cinema ended; stable HUD without a Continue input") end
                say("Throw completed.")
                return
            end
        else
            returnedAt = nil
        end
        task.wait(0.15)
    end
    error("Stopped", 0)
end

ctx.promptTextConnections = textConnections
table.insert(ctx.disposers, function()
    for _, connection in pairs(textConnections) do connection:Disconnect() end
end)

end
]=],
        ["cinema_view"] = [=[
-- Keep rendering the live game world instead of the cinematic camera.
return function(ctx)
local RunService = ctx.services.RunService
local prepared, session, failed, normalFov
local binding = "AdonisHubThrowView"
-- Visually transparent, but distinct from 1 so the game's final fade-to-1
-- still fires a property event and can be restored accurately afterwards.
local hiddenAlpha = 0.999999
local function active()
    return ctx.state.alive and ctx.state.running and ctx.featureEnabled("Throw") and ctx.cfg.HideCinema and ctx.state.cinemaPending
end
local function root()
    local char = ctx.player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
function ctx.captureThrowView(atMeter)
    failed = false
    local camera,part = workspace.CurrentCamera,root()
    prepared = nil
    if not camera or not part then return end
    local cf,focus,fov = camera.CFrame,camera.Focus,camera.FieldOfView
    if not atMeter then normalFov = camera.CameraType ~= Enum.CameraType.Scriptable and fov or 70 end
    if (camera.CameraType == Enum.CameraType.Scriptable and not atMeter) or not cf then
        -- START may be pressed with the meter/cinema already open. Use an
        -- ordinary view of the actual character rather than a cinematic pose.
        cf = CFrame.new(part.Position+Vector3.new(0,7,14),part.Position+Vector3.new(0,2,0))
        focus,fov = CFrame.new(part.Position),70
    end
    prepared = {cf=cf,focus=focus,fov=fov or 70,position=part.Position,part=part,fixed=atMeter==true}
end
local function restoreGui(s)
    for obj,properties in pairs(s.guis) do
        for property,record in pairs(properties) do
            record.connection:Disconnect()
            if obj.Parent then pcall(function() obj[property] = record.wanted end) end
        end
    end
    s.guis = {}
end
function ctx.releaseCinemaView(completed)
    local s = session
    if not s then return end
    session = nil
    ctx.state.cinemaViewActive = false
    RunService:UnbindFromRenderStep(binding)
    for _,connection in ipairs(s.connections) do connection:Disconnect() end
    restoreGui(s)
    for camera,saved in pairs(s.cameras) do
        pcall(function()
            if completed and camera == workspace.CurrentCamera then
                local char = ctx.player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                camera.CameraType = Enum.CameraType.Custom
                if humanoid then camera.CameraSubject = humanoid end
                camera.FieldOfView = s.normalFov or s.view.fov
                -- Leave the last live-world pose; the normal camera resumes.
            else
                camera.CameraType = saved.kind
                if saved.subject then camera.CameraSubject = saved.subject end
                camera.CFrame,camera.Focus,camera.FieldOfView = saved.cf,saved.focus,saved.fov
            end
        end)
    end
    ctx.log("CINEMA_VIEW_END",completed and "Normal player camera restored" or "Camera override released")
end
local function maskProperties(obj,targets)
    local s = session
    if not s or s.guis[obj] or s.guiCount>=192 then return end
    s.guiCount=s.guiCount+1; s.guis[obj]={}
    for property,forced in pairs(targets) do
        local record={wanted=obj[property],writing=false}
        s.guis[obj][property]=record
        record.connection=obj:GetPropertyChangedSignal(property):Connect(function()
            if record.writing or session~=s then return end
            local value=obj[property]
            if value==record.forced then return end
            record.wanted=value
            record.writing=true; obj[property]=forced; record.forced=obj[property]; record.writing=false
        end)
        record.writing=true; obj[property]=forced; record.forced=obj[property]; record.writing=false
    end
end
local function hide(obj)
    local s = session
    if not s or s.guis[obj] then return end
    -- Mask drawing, not visibility/state: the cinema watcher reads original
    -- prompt alpha through cinemaTextTransparency while processing hidden taps.
    local node,scope = obj,false
    while node and node ~= ctx.pg do
        local parent = node.Parent
        if (node.Name == "ThrowSequence" and parent == ctx.pg)
            or (node.Name == "ScreenFX" and parent == ctx.pg) then scope=true; break end
        node = parent
    end
    if not scope or s.guiCount >= 160 then return end
    local properties = {}
    if obj:IsA("GuiObject") then table.insert(properties,"BackgroundTransparency") end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        table.insert(properties,"TextTransparency"); table.insert(properties,"TextStrokeTransparency")
    end
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then table.insert(properties,"ImageTransparency") end
    if obj:IsA("UIStroke") then table.insert(properties,"Transparency") end
    if obj:IsA("CanvasGroup") then table.insert(properties,"GroupTransparency") end
    if #properties == 0 then return end
    local targets={}
    for _,property in ipairs(properties) do
        targets[property]=hiddenAlpha
    end
    maskProperties(obj,targets)
end
local function maskEffect(obj)
    local targets
    if obj:IsA("BlurEffect") then targets={Size=0.000001}
    elseif obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") then targets={Intensity=0.000001}
    elseif obj:IsA("DepthOfFieldEffect") then targets={NearIntensity=0.000001,FarIntensity=0.000001}
    elseif obj:IsA("ColorCorrectionEffect") then
        targets={Brightness=0.000001,Contrast=0.000001,Saturation=0.000001,
            TintColor=Color3.new(hiddenAlpha,hiddenAlpha,hiddenAlpha)}
    end
    if targets then maskProperties(obj,targets) end
end
local function watchEffects(host)
    local s=session
    if not s or not host or s.effectHosts[host] or type(host.GetChildren)~="function" then return end
    s.effectHosts[host]=true
    for i,obj in ipairs(host:GetChildren()) do
        maskEffect(obj)
        if i>=64 then break end
    end
    table.insert(s.connections,host.ChildAdded:Connect(maskEffect))
end
local function indexRoot(gui)
    if gui.Parent ~= ctx.pg then return end
    local scope
    if gui.Name == "ThrowSequence" then scope=gui
    elseif gui.Name == "ScreenFX" then scope=gui end
    if scope then
        hide(scope)
        local count = 0
        for _,obj in ipairs(scope:GetDescendants()) do
            hide(obj)
            count = count+1
            if count >= 160 then break end
        end
    end
end
local function draw(s)
    if session ~= s then return end
    if not active() or not s.view.part.Parent then ctx.releaseCinemaView(false); return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    if not s.cameras[camera] then
        s.cameras[camera] = {kind=camera.CameraType,subject=camera.CameraSubject,
            cf=camera.CFrame,focus=camera.Focus,fov=camera.FieldOfView}
    end
    -- Constant camera math only: no scans, logging, cloning or I/O per frame.
    local delta = s.view.fixed and Vector3.new() or s.view.part.Position-s.view.position
    if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end
    camera.CFrame = s.view.cf+delta
    if s.view.focus then camera.Focus = s.view.focus+delta end
    if camera.FieldOfView ~= s.view.fov then camera.FieldOfView = s.view.fov end
end
function ctx.cinemaTextTransparency(obj)
    local properties = session and session.guis[obj]
    local record = properties and properties.TextTransparency
    return record and record.wanted or obj.TextTransparency
end
function ctx.updateCinemaView()
    if not active() then ctx.releaseCinemaView(false); return end
    if session then watchEffects(workspace.CurrentCamera); return end
    if failed then return end
    if prepared and not prepared.part.Parent then prepared = nil end
    if not prepared then ctx.captureThrowView() end
    if not prepared then return end
    local s = {view=prepared,normalFov=normalFov,cameras={},guis={},guiCount=0,effectHosts={},connections={}}
    session = s
    local ok,err = pcall(function()
        watchEffects(ctx.services.Lighting)
        watchEffects(workspace.CurrentCamera)
        for _,name in ipairs({"ThrowSequence","ScreenFX"}) do
            local gui = ctx.pg:FindFirstChild(name)
            if gui then indexRoot(gui) end
        end
        table.insert(s.connections,ctx.pg.DescendantAdded:Connect(function(obj)
            hide(obj); indexRoot(obj)
        end))
        RunService:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+1,function()
            local rendered,reason = pcall(draw,s)
            if not rendered then
                failed = true
                ctx.releaseCinemaView(false)
                ctx.log("CINEMA_VIEW_ERROR",reason)
            end
        end)
        draw(s)
    end)
    if not ok then
        failed = true; ctx.releaseCinemaView(false); ctx.log("CINEMA_VIEW_ERROR",err)
        return
    end
    if session ~= s then return end
    ctx.state.cinemaViewActive = true
    ctx.log("CINEMA_VIEW_BEGIN",(s.view.fixed and "Fixed throw-line view" or "Fallback character view")
        .. " position=" .. tostring(s.view.cf.Position) .. " maskedObjects=" .. s.guiCount)
end
table.insert(ctx.disposers,function() ctx.releaseCinemaView(false) end)
end
]=],
        ["config"] = [=[
-- Adonis Hub / config
return function(ctx)
local Http = ctx.services.Http
local function save(...) return ctx.save(...) end

local cfg = {Train=false, X2=false, Throw=false, Equip=false, AllInOne=false, ThrowsPerTurn=1, Upgrade=false, Food=false,
    Sell=false, AutoSaveConfig=false, BoostFPS=false, PlotUpgrade=false,
    -- Legacy filter values round-trip for compatibility, but Auto Sell always sells all Backpack pets.
    SellMode="Filtered", SellIncomeMax="",
    SellNormal=true, SellGold=false, SellDiamond=false, SellEmerald=false, SellRuby=false, SellRainbow=false,
    -- HideCinema is the independent visual toggle; the old version marker is retained only for config compatibility.
    HideCinema=true, CinemaCoverDefaultVersion=1,
    -- KeepPercent is retained for saved-config compatibility; Food no longer uses it.
    TrainSeconds=60, KeepPercent=30, ThrowX=19, ThrowY=4.82, ThrowZ=-43}
local configFile = "AdonisHub-TFFA.json"
if type(readfile) == "function" then
    local ok, data = pcall(function() return Http:JSONDecode(readfile(configFile)) end)
    if ok and type(data) == "table" then
        for k, v in pairs(cfg) do
            if type(data[k]) == type(v) then cfg[k] = data[k] end
        end
        -- Older releases always saved menu changes; preserve that preference.
        if data.AutoSaveConfig==nil then cfg.AutoSaveConfig=true end
    end
end
cfg.TrainSeconds = math.clamp(cfg.TrainSeconds, 5, 3600)
cfg.ThrowsPerTurn = math.floor(math.clamp(cfg.ThrowsPerTurn,1,100))
cfg.KeepPercent = math.clamp(cfg.KeepPercent, 0, 100)
if cfg.SellMode~="All" and cfg.SellMode~="Filtered" then cfg.SellMode="Filtered" end
local pendingJson,nextRetryAt,writing=nil,0,false
local function inCinema()
    return ctx.state and (ctx.state.cinemaPending
        or (ctx.cinemaPrompt and ctx.cinemaPrompt())
        or (ctx.petReceiptCinemaActive and ctx.petReceiptCinemaActive()))
end
function ctx.flushConfig()
    if not pendingJson then return true end
    if inCinema() then return true,"queued until cinema ends" end
    if writing then return true,"queued behind current config write" end
    if os.clock()<nextRetryAt then return false,"waiting to retry config write" end
    local payload=pendingJson
    writing=true
    local ok,err=pcall(function()
        assert(type(writefile)=="function","Executor does not support writefile")
        writefile(configFile,payload)
    end)
    writing=false
    if ok then
        if pendingJson==payload then pendingJson=nil end
        if ctx.log then ctx.log("CONFIG_SAVED",configFile) end
    else
        nextRetryAt=os.clock()+30
        if ctx.log then ctx.log("CONFIG_SAVE_ERROR",tostring(err)) end
    end
    return ok,err
end
local function queueSave()
    local ok,json=pcall(function() return Http:JSONEncode(cfg) end)
    if not ok then return false,tostring(json) end
    pendingJson,nextRetryAt=json,0
    return ctx.flushConfig()
end
function ctx.save()
    if not cfg.AutoSaveConfig then return false,"Auto Save Config is OFF" end
    return queueSave()
end
function ctx.setAutoSaveConfig(enabled)
    cfg.AutoSaveConfig=enabled==true
    -- Persist this explicit switch even when turning automatic writes OFF.
    return queueSave()
end

ctx.cfg, ctx.configFile = cfg, configFile

end
]=],
        ["controller"] = [=[
-- Adonis Hub / independent switches and serialized feature orchestration.
return function(ctx)
local cfg=ctx.cfg
local actionKeys={"AllInOne","Train","X2","Throw","Equip","Sell","Upgrade","PlotUpgrade","Food"}
ctx.state.controlRevision=0
local function hasActions()
    for _,key in ipairs(actionKeys) do if cfg[key] then return true end end
    return false
end
local function refreshControls()
    for _,key in ipairs(actionKeys) do
        local b=ctx.view.controls[key]
        if b then ctx.refreshToggle(b,cfg[key]) end
    end
end
local function releaseTraining()
    if ctx.state.alive and ctx.state.hubTraining and not ctx.state.cinemaPending
        and not ctx.cinemaPrompt() and not ctx.visible(ctx.ui("ThrowSequence.Meter.Bar")) then
        pcall(ctx.stopTraining)
        ctx.state.hubTraining=false
    end
end
function ctx.runOptional(name,action)
    if not ctx.actionActive(name) then return false end
    local previous,previousRevision=ctx.state.actionFeature,ctx.state.actionRevision
    ctx.state.actionFeature,ctx.state.actionRevision=name,ctx.state.controlRevision
    ctx.log("STEP_BEGIN",name)
    local ok,err=xpcall(action,debug.traceback)
    local cancelled=not ctx.actionActive(name)
    ctx.state.actionFeature,ctx.state.actionRevision=previous,previousRevision
    if not ok and cancelled then ctx.log("STEP_CANCELLED",name)
    elseif not ok and ctx.state.running then
        ctx.log("STEP_ERROR",name..": "..tostring(err))
        ctx.say(name.." interrupted; retrying enabled features")
    elseif ok then ctx.log("STEP_END",name) end
    return ok
end
local purchaseNames={"Upgrade","PlotUpgrade","Food"}
local readyMethods={Upgrade="trainingUpgradeReady",PlotUpgrade="plotUpgradeReady",Food="foodReady"}
local purchaseActions={Upgrade="doUpgrade",PlotUpgrade="doPlotUpgrade",Food="doFood"}
local nextPurchaseCheck=0
local nextInterruptCheck,interruptReady=0,false
function ctx.requestPurchase(name)
    ctx.state.purchaseUrgent=true
    nextInterruptCheck=0
    if name=="Food" and ctx.state.allInOneTurn then ctx.state.allInOneTurn.foodBought=false end
end
function ctx.purchaseInterruptReady()
    if not ctx.state.purchaseUrgent or ctx.state.purchaseServicing or ctx.state.throwSessionActive
        or ctx.state.cinemaPending or ctx.cinemaPrompt() then return false end
    if os.clock()<nextInterruptCheck then return interruptReady end
    nextInterruptCheck=os.clock()+0.25; interruptReady=false
    for _,name in ipairs(purchaseNames) do
        if cfg[name] and ctx[readyMethods[name]] then
            local ok,ready=pcall(ctx[readyMethods[name]])
            if ok and ready then interruptReady=true; break end
        end
    end
    return interruptReady
end
function ctx.servicePurchases(force)
    if not ctx.state.alive or not ctx.state.running or ctx.state.purchaseServicing
        or ctx.state.throwSessionActive or ctx.state.cinemaPending or ctx.cinemaPrompt()
        or ctx.visible(ctx.ui("ThrowSequence.Meter.Bar")) then return false end
    local batch=cfg.AllInOne and ctx.state.allInOneTurn
    if batch and batch.phase=="throw" and batch.completed<batch.target then return false end
    if not force and not ctx.state.purchaseUrgent and os.clock()<nextPurchaseCheck then return false end
    ctx.state.purchaseUrgent=false
    nextPurchaseCheck=os.clock()+1
    ctx.state.purchaseServicing=true
    local serviced=false
    for _,name in ipairs(purchaseNames) do
        if not ctx.state.alive or not ctx.state.running or ctx.state.cinemaPending or ctx.cinemaPrompt() then break end
        local ready=ctx[readyMethods[name]]
        local turn=cfg.AllInOne and ctx.state.allInOneTurn
        if cfg[name] and ready and not (name=="Food" and turn and turn.foodBought) then
            local ok,affordable=pcall(ready)
            if ok and affordable then
                serviced=true
                local before=ctx.state.foodPurchaseSerial or 0
                ctx.runOptional(name,ctx[purchaseActions[name]])
                if name=="Food" and turn and (ctx.state.foodPurchaseSerial or 0)>before then turn.foodBought=true end
            end
        end
    end
    ctx.state.purchaseServicing=false
    return serviced
end
function ctx.halt(message)
    for _,key in ipairs(actionKeys) do cfg[key]=false end
    ctx.state.allInOneTurn=nil
    ctx.state.purchaseUrgent=false
    ctx.state.controlRevision=ctx.state.controlRevision+1
    ctx.state.running=false
    ctx.refreshMenuState()
    if ctx.state.cinemaPending then ctx.state.cinemaInterrupted=true end
    if ctx.cancelThrowApproach then ctx.cancelThrowApproach() end
    if ctx.stopThrowPresentation then ctx.stopThrowPresentation() end
    refreshControls(); ctx.save()
    ctx.log("STOP",message or "All automatic actions disabled")
    ctx.flushLog()
    if message then ctx.say(message) end
end
local function cycle()
    local revision=ctx.state.controlRevision
    local function current() return ctx.state.running and revision==ctx.state.controlRevision end
    if cfg.AllInOne and not ctx.state.allInOneTurn then
        ctx.state.allInOneTurn={phase="train",completed=0,target=cfg.ThrowsPerTurn,seconds=cfg.TrainSeconds}
    end
    local turn=cfg.AllInOne and ctx.state.allInOneTurn or nil
    local function countThrow()
        if turn and turn.beforeThrow and ctx.state.completedThrows>turn.beforeThrow then
            turn.completed=turn.completed+1; turn.beforeThrow=nil
        end
    end
    if ctx.state.cinemaPending or ctx.cinemaPrompt() then
        ctx.finishThrowCinema()
        countThrow()
        if current() then ctx.runOptional("Equip",ctx.doEquip) end
        return
    end
    ctx.runOptional("Equip",ctx.doEquip)
    if ctx.featureEnabled("Train") or ctx.state.purchaseUrgent then ctx.servicePurchases() end
    if not current() then return end
    if ctx.featureEnabled("Train") and (not turn or turn.phase=="train") then
        local other=cfg.AllInOne or cfg.Throw or cfg.Sell
        local ok=ctx.runOptional("Train",function() ctx.doTrain(turn and turn.seconds or (other and cfg.TrainSeconds or math.huge)) end)
        if not ok or not current() then releaseTraining(); return end
    end
    if turn and turn.phase=="train" then turn.phase="throw" end
    releaseTraining()
    if not current() then return end
    local turns=turn and math.max(0,turn.target-turn.completed) or 1
    ctx.state.throwSessionActive=ctx.featureEnabled("Throw")
    for i=1,turns do
        if not current() then return end
        if ctx.featureEnabled("Throw") then
            local before=ctx.state.completedThrows
            if turn then turn.beforeThrow=before end
            local ok=ctx.runOptional("Throw",ctx.doThrow)
            countThrow()
            if not ok or ctx.state.completedThrows<=before then ctx.state.throwSessionActive=false; return end
        end
        if current() then ctx.runOptional("Equip",ctx.doEquip) end
    end
    if not current() then return end
    ctx.state.throwSessionActive=false
    if ctx.state.purchaseUrgent then ctx.servicePurchases(true) end
    if not current() then return end
    ctx.runOptional("Sell",ctx.doSell)
    if not current() then return end
    ctx.state.throwSessionActive=false
    ctx.servicePurchases(true)
    if turn and current() then ctx.state.allInOneTurn=nil end
end
function ctx.syncAutomation()
    if not ctx.state.alive then return end
    ctx.state.running=hasActions()
    ctx.refreshMenuState()
    if not ctx.state.running then
        if ctx.state.cinemaPending then ctx.state.cinemaInterrupted=true end
        if ctx.cancelThrowApproach then ctx.cancelThrowApproach() end
        if ctx.stopThrowPresentation then ctx.stopThrowPresentation() end
        ctx.say("Ready. Turn On A Feature.")
        return
    end
    if ctx.state.busy then return end
    ctx.state.busy=true
    task.spawn(function()
        while ctx.state.alive and ctx.state.running do
            ctx.state.throwSessionActive=false
            local ok,err=xpcall(cycle,debug.traceback)
            ctx.state.throwSessionActive=false
            ctx.state.purchaseServicing=false
            ctx.state.actionFeature,ctx.state.actionRevision=nil,nil
            releaseTraining()
            if not ok and ctx.state.alive and ctx.state.running then
                ctx.log("ERROR",err); ctx.say("Retrying Enabled Features...")
            end
            local revision=ctx.state.controlRevision
            local deadline=os.clock()+(ok and 1 or 3)
            while ctx.state.alive and ctx.state.running and revision==ctx.state.controlRevision and not ctx.state.purchaseUrgent and os.clock()<deadline do
                task.wait(0.1)
            end
        end
        releaseTraining()
        ctx.state.busy=false
    end)
end
local description="Auto Trainning -> Tap X2 -> Throw Food"
local toggles={
    {"AllInOne","Auto All In One",description,'Main Farm',0,{height=78}},
    {"Train","Auto Train",nil,'Main Farm',156,{height=48}},
    {"X2","Auto Tap X2",nil,'Main Farm',212,{height=48}},
    {"Throw","Auto Throw Food ( Full Power )",nil,'Main Farm',268,{height=48}},
    {"Equip","Equip Best",nil,'Main Farm',324,{height=48}},
    {"HideCinema","Hide Cinema",nil,'Main Farm',380,{height=48}},
    {"Upgrade","Upgrade Training Bar",nil,'Upgrade',0,{height=64}},
    {"PlotUpgrade","Auto Upgrade Plot",nil,'Upgrade',76,{height=64}},
    {"Food","Buy Next Food",nil,'Upgrade',152,{height=64}},
    {"Sell","Auto Sell All Backpack",nil,'Auto Sell',0,{height=64}},
    {"BoostFPS","Boost FPS",nil,'Setting',0,{height=64}},
    {"AutoSaveConfig","Auto Save Config",nil,'Setting',76,{height=64}},
}
for _,item in ipairs(toggles) do
    local key=item[1]
    local b
    b=ctx.addToggle(item[2],item[3],ctx.view.pages[item[4]],item[5],function()
        cfg[key]=not cfg[key]
        if key=="AllInOne" then ctx.state.allInOneTurn=nil end
        if key=="AutoSaveConfig" then
            local ok,reason=ctx.setAutoSaveConfig(cfg.AutoSaveConfig)
            ctx.say(ok and ("Auto Save Config "..(cfg.AutoSaveConfig and "On" or "Off"))
                or ("Config Could Not Be Saved: "..tostring(reason)))
        else ctx.save() end
        ctx.refreshToggle(b,cfg[key])
        if key=="BoostFPS" then ctx.updateBoostFPS() end
        if key~="HideCinema" and key~="BoostFPS" and key~="AutoSaveConfig" then
            if key=="Upgrade" or key=="PlotUpgrade" or key=="Food" then
                if cfg[key] then ctx.requestPurchase(key) end
            elseif key~="X2" and key~="Equip" then ctx.state.controlRevision=ctx.state.controlRevision+1 end
            ctx.syncAutomation()
            if key=="Equip" and cfg.Equip and ctx.state.running then
                local ok,err=pcall(ctx.doEquip)
                if not ok then ctx.log("EQUIP_ERROR",err) end
            end
        end
        if (key=="Throw" or key=="AllInOne" or key=="HideCinema") and ctx.updateThrowPresentation then
            ctx.updateThrowPresentation()
        end
    end,item[6])
    ctx.view.controls[key]=b
    ctx.refreshToggle(b,cfg[key],true)
end
local function number(key,title,x,min,max)
    local box
    local function commit(value)
        if value and value==value and value~=math.huge and value~=-math.huge then
            cfg[key]=math.floor(math.clamp(value,min,max)); ctx.save()
        end
        box.Text=tostring(cfg[key])
    end
    box=ctx.addNumber(title,nil,ctx.view.pages['Main Farm'],88,cfg[key],{
        x=x,width=282,height=56})
    ctx.view.controls[key]=box
    table.insert(ctx.connections,box.FocusLost:Connect(function() commit(tonumber(box.Text)) end))
end
number("TrainSeconds","Training Time (Seconds)",4,5,3600)
number("ThrowsPerTurn","Throws Per Turn",298,1,100)
for name,height in pairs({['Main Farm']=444,Upgrade=228,['Auto Sell']=76,Setting=152}) do
    ctx.view.pages[name].CanvasSize=UDim2.fromOffset(0,height)
end
end
]=],
        ["diagnostics"] = [=[
-- Adonis Hub / diagnostics
return function(ctx)
local RunService = ctx.services.RunService
local UIS = ctx.services.UIS
local player = ctx.player
local connections = ctx.connections
local logFile = ctx.logFile
local function cinemaPrompt(...) return ctx.cinemaPrompt(...) end
local function flushLog(...) return ctx.flushLog(...) end
local function halt(...) return ctx.halt(...) end
local function log(...) return ctx.log(...) end
local function say(...) return ctx.say(...) end
local function snapshot(...) return ctx.snapshot(...) end
local function training(...) return ctx.training(...) end
local function ui(...) return ctx.ui(...) end
local function visible(...) return ctx.visible(...) end

local drag={active=false}
local launcherDrag={active=false,suppressClick=false}
ctx.view.dragState=drag
ctx.view.launcherDrag=launcherDrag
table.insert(connections, ctx.view.dragHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag.active,drag.input,drag.origin,drag.position=true,input,input.Position,ctx.view.panel.Position
    end
end))
table.insert(connections, ctx.view.reopen.InputBegan:Connect(function(input)
    if not ctx.view.menuOpen and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
        drag.active=false
        launcherDrag.active,launcherDrag.suppressClick=true,false
        launcherDrag.input,launcherDrag.origin,launcherDrag.position=input,input.Position,ctx.view.reopen.Position
    end
end))
table.insert(connections, UIS.InputChanged:Connect(function(input)
    if drag.active and ctx.view.menuOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input==drag.input) then
        local d = input.Position-drag.origin
        local p=drag.position
        ctx.view.panel.Position = UDim2.new(p.X.Scale,p.X.Offset+d.X,p.Y.Scale,p.Y.Offset+d.Y)
    end
    if launcherDrag.active and not ctx.view.menuOpen
        and (input==launcherDrag.input or (launcherDrag.input.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        local d=input.Position-launcherDrag.origin
        if d.Magnitude>=6 then launcherDrag.suppressClick=true end
        if launcherDrag.suppressClick then
            local p=launcherDrag.position
            local camera=workspace.CurrentCamera
            if camera then
                local size=camera.ViewportSize
                ctx.positionLauncher(p.X.Scale*size.X+p.X.Offset+d.X,p.Y.Scale*size.Y+p.Y.Offset+d.Y)
            end
        end
    end
end))
table.insert(connections, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input==drag.input then drag.active=false end
    if input==launcherDrag.input or (input.UserInputType==Enum.UserInputType.MouseButton1
        and launcherDrag.input and launcherDrag.input.UserInputType==Enum.UserInputType.MouseButton1) then launcherDrag.active=false end
end))
table.insert(ctx.disposers,function() drag.active=false; launcherDrag.active=false end)
table.insert(connections, UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F8 then
        local ok, err = pcall(snapshot, "F8 manual snapshot")
        if not ok then log("SNAPSHOT_ERROR", err) end
        say(flushLog() and ("Log saved: " .. logFile) or "Could not save log file")
        flushLog()
    end
    if input.KeyCode == Enum.KeyCode.End then halt("Emergency stop. Finish game action manually.") end
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then ctx.toggleMenu() end
end))
table.insert(connections, ctx.view.gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ctx.state.alive and not ctx.view.gui.Enabled then ctx.view.gui.Enabled = true end
end))
local lastExternalError, lastExternalAt = "", 0
table.insert(connections, game:GetService("LogService").MessageOut:Connect(function(message, kind)
    if kind == Enum.MessageType.MessageError then
        -- These can include unrelated game errors; keep a separate category.
        if message ~= lastExternalError or os.clock()-lastExternalAt >= 5 then
            log("ROBLOX_ERROR_EXTERNAL_OR_HUB", message)
            lastExternalError, lastExternalAt = message, os.clock()
        end
    end
end))
table.insert(connections, player.CharacterAdded:Connect(function()
    log("CHARACTER", "CharacterAdded / respawn")
end))
local frameElapsed, frameCount, frameMax, slowFrames = 0, 0, 0, 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    frameElapsed = frameElapsed+dt
    frameCount = frameCount+1
    frameMax = math.max(frameMax, dt)
    if dt > 0.05 then slowFrames = slowFrames+1 end
end))
task.spawn(function()
    local previous = ""
    while ctx.state.alive do
        local ok, err = pcall(function()
            if frameElapsed >= 15 then
                log("PERF", string.format("avgFPS=%.1f maxFrameMs=%.1f framesOver50ms=%d cinema=%s",
                    frameCount/frameElapsed, frameMax*1000, slowFrames, tostring(ctx.state.cinemaPending)))
                frameElapsed, frameCount, frameMax, slowFrames = 0, 0, 0, 0
            end
            local prompt, kind = cinemaPrompt()
            local marker = ui("ThrowSequence.Meter.Bar.Marker.Text")
            local state = "training=" .. tostring(training())
                .. " meter=" .. tostring(visible(ui("ThrowSequence.Meter.Bar")))
                .. " cinema=" .. tostring(kind)
                .. " animalsButton=" .. tostring(visible(ui("HUD.RightSideButtons.AnimalsButton")))
                .. " equipButton=" .. tostring(visible(ui("AnimalsPanelGui.AnimalsPanel.Body.Content.EquipBest")))
            if state ~= previous then
                log("STATE", state)
                if prompt then log("PROMPT", prompt:GetFullName() .. " text=" .. prompt.Text) end
                if marker then log("METER", "bonus=" .. marker.Text) end
                previous = state
            end
        end)
        if not ok then log("OBSERVER_ERROR", err) end
        task.wait(1)
    end
end)
log("READY", "Logging to executor workspace: " .. logFile)
flushLog()
say("Ready. Turn On A Feature.")

end
]=],
        ["equipment"] = [=[
-- Adonis Hub / equipment: one initial attempt, then once per completed throw.
return function(ctx)
local buttonPath = "AnimalsPanelGui.AnimalsPanel.Body.Content.EquipBest"
local handledThrow = -1 -- Generation zero is the initial Equip, before any throw.
local lastUnavailable
local stats = {dispatches=0,lastThrow=0,outcome="waiting_initial_equip"}
ctx.state.equipStats = stats

function ctx.equipmentDiagnostics()
    return {
        "mode=initial_then_once_per_completed_throw completedThrows=" .. ctx.state.completedThrows
            .. " handledThrough=" .. handledThrow,
        "dispatches=" .. stats.dispatches .. " lastThrow=" .. stats.lastThrow .. " outcome=" .. stats.outcome,
        "enabled=" .. tostring(ctx.cfg.Equip) .. " running=" .. tostring(ctx.state.running)
            .. " cinemaPending=" .. tostring(ctx.state.cinemaPending),
    }
end

function ctx.doEquip()
    if not ctx.actionActive("Equip")
        or ctx.state.cinemaPending or ctx.cinemaPrompt() then return end
    local throwId = ctx.state.completedThrows
    if throwId <= handledThrow then return end
    local button = ctx.ui(buttonPath)
    local signal, reason = ctx.buttonSignal(button)
    if not signal then
        stats.outcome = "input_unavailable"
        if reason ~= lastUnavailable then ctx.log("EQUIP_UNAVAILABLE",reason); lastUnavailable = reason end
        return
    end
    -- Claim before dispatch so repeated cycle calls cannot click this throw twice.
    handledThrow = throwId
    ctx.state.equippedThroughThrow = throwId
    stats.dispatches,stats.lastThrow = stats.dispatches+1,throwId
    local ok, err = pcall(ctx.clickHidden,button)
    stats.outcome = ok and "input_sent" or "input_error"
    ctx.log(ok and "EQUIP_SENT" or "EQUIP_ERROR",
        "throw=" .. throwId .. (throwId == 0 and " initial" or " after_throw")
            .. (ok and " hidden Equip Best input sent" or (" " .. tostring(err))))
end
end
]=],
        ["food"] = [=[
-- Adonis Hub / food
return function(ctx)
local cfg = ctx.cfg
local lastSkip
local lastSkipAt = -math.huge
local catalogAttempts, lastCatalogAt = 0,-math.huge
local attemptedCard,attemptedUntil
local function active()
    return ctx.actionActive("Food")
        and not ctx.state.cinemaPending and not ctx.cinemaPrompt()
end
function ctx.foodDiagnostics()
    local plan, reason = ctx.foodPlan()
    local lines = {plan and ("plan=" .. plan.card.Name .. " price=" .. plan.price
        .. " current=Food" .. plan.current .. " cash=" .. tostring(plan.cash) .. " budget=" .. plan.budget)
        or ("blocked=" .. tostring(reason))}
    for _, line in ipairs(ctx.dataSample(ctx.ui("FoodShop.Main.Panel.Body.CardsScroll"),10)) do
        table.insert(lines,line)
    end
    local money = ctx.ui("StatsGui.Container.MoneyDisplay.ValueLabel")
    if money then table.insert(lines,money:GetFullName() .. " text=" .. string.format("%q",money.Text)) end
    return lines
end
local function skip(reason, dataFailure)
    if reason ~= lastSkip or os.clock()-lastSkipAt >= 60 then
        ctx.log("FOOD_SKIP", reason); lastSkip,lastSkipAt = reason,os.clock()
        ctx.say("Food waiting: " .. reason)
    end
    if dataFailure then ctx.dataIssue("food",reason,ctx.foodDiagnostics) end
end
local function action(label)
    return label and ctx.plainText(label.Text):upper():match("^%s*(.-)%s*$")
end
local function canInitialize()
    return catalogAttempts < 3 and os.clock()-lastCatalogAt >= 60
end
function ctx.foodPlan()
    local cards = ctx.ui("FoodShop.Main.Panel.Body.CardsScroll")
    if not cards then return nil, "Food cards not initialized", true, true end
    local current
    for _, card in ipairs(cards:GetChildren()) do
        local index = tonumber(card.Name:match("^Food(%d+)$"))
        local label = ctx.find(card, "ActionButton.Label")
        if index and action(label) == "EQUIPPED" then
            if current then return nil, "Multiple equipped food cards; cannot determine current food", false, true end
            current = index
        end
    end
    if not current then return nil, "Current equipped food unknown; no purchase", true, true end
    -- One catalog step only. Do not jump to the most expensive affordable item,
    -- or past a missing card whose price/state has not been observed.
    local index = current+1
    local card = cards:FindFirstChild("Food" .. index)
    if not card then return nil,"Next food Food" .. index .. " is not in the loaded catalog" end
    local label = ctx.find(card,"ActionButton.Label")
    if not label then return nil,"Next food action unavailable: " .. card.Name,false,true end
    local owned = action(label) == "EQUIP"
    local price = owned and 0 or ctx.currencyAmount(label.Text)
    if not price then
        return nil,"Unreadable next food action: " .. label:GetFullName()
            .. " text=" .. string.format("%q",label.Text),false,true
    end
    local cash = ctx.money()
    -- Latest user policy: enough cash buys the next food, no reserve for a bar
    -- or percentage floor. Unknown cash still permits a free owned equip only.
    if not owned and not cash then return nil,"Cannot read money for food",false,true end
    if not owned and cash < price then
        return nil,"Next food " .. card.Name .. " needs=" .. price .. " cash=" .. cash
    end
    return {cards=cards,card=card,current=current,index=index,price=price,owned=owned,
        cash=cash,budget=cash or 0}
end
function ctx.foodReady()
    local plan=ctx.foodPlan()
    return plan and not (attemptedCard==plan.card and os.clock()<(attemptedUntil or 0)) or false
end
function ctx.doFood()
    if not active() then return end
    -- Inspect existing hidden cards first. No shop trip just to discover poverty.
    local plan, reason, needsCatalog, issue = ctx.foodPlan()
    if plan and attemptedCard==plan.card and os.clock()<(attemptedUntil or 0) then return end
    if not plan and (not needsCatalog or not canInitialize()) then skip(reason,issue); return end
    local pad = ctx.find(workspace, "LocalPlotProps.FoodShop.ActivationCircle")
    if not (pad and pad:IsA("BasePart")) then skip("Food shop location unavailable"); return end
    ctx.say("Checking the next food upgrade...")
    ctx.closeAnimals()
    if not active() then return end
    plan, reason, needsCatalog, issue = ctx.foodPlan()
    if not plan and (not needsCatalog or not canInitialize()) then skip(reason,issue); return end
    if not plan then
        catalogAttempts,lastCatalogAt = catalogAttempts+1,os.clock()
        ctx.log("FOOD_CATALOG", "Initialize current food/prices; bounded attempt=" .. catalogAttempts)
    end
    ctx.stopTraining()
    if not active() then return end
    ctx.move(pad.Position+Vector3.new(0, 2.4, 0))
    local cards = ctx.waitFor(function()
        local c = ctx.ui("FoodShop.Main.Panel.Body.CardsScroll")
        return ctx.visible(c) and c
    end, 8)
    ctx.pause(os.clock()+0.4)
    local ok, err = xpcall(function()
        if not active() then return end
        plan, reason, needsCatalog, issue = ctx.foodPlan()
        if not plan then skip(reason,issue); return end
        local x = cards.CanvasPosition.X+plan.card.AbsolutePosition.X-cards.AbsolutePosition.X
        cards.CanvasPosition = Vector2.new(math.max(0, x), cards.CanvasPosition.Y)
        ctx.pause(os.clock()+0.3)
        if not active() then return end
        -- Re-evaluate after scrolling; no stale balance/price may authorize a buy.
        local fresh
        fresh, reason, needsCatalog, issue = ctx.foodPlan()
        if not fresh then skip(reason,issue); return end
        if fresh.card ~= plan.card then skip("Food selection changed; retry next cycle"); return end
        lastSkip = nil
        ctx.log("FOOD_SELECTED", "current=Food" .. fresh.current .. " next=" .. fresh.card.Name
            .. " price=" .. fresh.price .. " cash=" .. tostring(fresh.cash))
        attemptedCard,attemptedUntil=fresh.card,os.clock()+30
        ctx.state.foodPurchaseSerial=(ctx.state.foodPurchaseSerial or 0)+1
        ctx.click(fresh.card:FindFirstChild("ActionButton"))
        ctx.pause(os.clock()+0.8)
        local label = ctx.find(fresh.card, "ActionButton.Label")
        if active() and action(label) == "EQUIP" then
            ctx.click(fresh.card:FindFirstChild("ActionButton"))
        end
        ctx.pause(os.clock()+0.5)
        ctx.log("FOOD_RESULT", fresh.card.Name .. " action=" .. (label and label.Text or "missing"))
    end, debug.traceback)
    if active() then
        local close = ctx.ui("FoodShop.Main.Panel.Header.CloseButton")
        if ctx.visible(close) then
            ctx.click(close)
            ctx.waitFor(function() return not ctx.visible(cards) end, 5)
        end
    end
    if not ok then error(err, 0) end
end
end
]=],
        ["input"] = [=[
-- Adonis Hub / input
return function(ctx)
local function click(...) return ctx.click(...) end
local function clickAt(...) return ctx.clickAt(...) end
local function log(...) return ctx.log(...) end
local function move(...) return ctx.move(...) end
local function rootPart(...) return ctx.rootPart(...) end
local function visible(...) return ctx.visible(...) end

function ctx.clickAt(x, y)
    log("MOUSE", string.format("click x=%.1f y=%.1f", x, y))
    local vim = game:GetService("VirtualInputManager")
    -- Match normal pointer input: move first, then issue a distinct down/up pair.
    pcall(function() vim:SendMouseMoveEvent(x, y, game) end)
    vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- Observe delivery only; this is a normal event subscription, not an input hook.
table.insert(ctx.connections, ctx.services.UIS.InputBegan:Connect(function(key, processed)
    local pending = ctx.state.lastCinemaInput
    if pending and not pending.observed and os.clock()-pending.started <= 0.4
        and key.UserInputType == Enum.UserInputType.MouseButton1 then
        pending.observed, pending.processed = true, processed
        log("CINEMA_INPUT_RECEIVED", "method=" .. pending.method .. " processed=" .. tostring(processed)
            .. " position=" .. tostring(key.Position))
    end
end))
function ctx.cinemaTap(x, y, method)
    local pending = {method=method, started=os.clock(), observed=false}
    ctx.state.lastCinemaInput = pending
    if method == "VirtualUser" then
        local user = game:GetService("VirtualUser")
        local camera = assert(workspace.CurrentCamera, "Camera unavailable")
        local point = Vector2.new(x,y)
        user:CaptureController()
        user:Button1Down(point, camera.CFrame)
        task.wait(0.05)
        user:Button1Up(point, camera.CFrame)
    else
        ctx.clickAt(x,y)
    end
    log("CINEMA_INPUT_SENT", "method=" .. method .. " observedSoFar=" .. tostring(pending.observed)
        .. " (a nearby manual click can also be observed)")
end
function ctx.clearTapPoint(preferredX,preferredY)
    local camera=workspace.CurrentCamera
    if not camera then return nil end
    local size=camera.ViewportSize
    local inset=game:GetService("GuiService"):GetGuiInset()
    local candidates={{preferredX or size.X*0.6,preferredY or size.Y*0.47}}
    for _,y in ipairs({0.48,0.68,0.3}) do
        for _,x in ipairs({0.88,0.12,0.75,0.25,0.5}) do candidates[#candidates+1]={size.X*x,size.Y*y} end
    end
    local function covers(obj,x,y)
        if not obj or not obj.Visible then return false end
        local p,s=obj.AbsolutePosition,obj.AbsoluteSize
        return x>=p.X-8 and x<=p.X+s.X+8 and y>=p.Y-8 and y<=p.Y+s.Y+8
    end
    for _,point in ipairs(candidates) do
        local x,y=math.floor(point[1]),math.floor(point[2])
        if x>=24 and y>=24 and x<size.X-24 and y<size.Y-24
            and not covers(ctx.view.panel,x-inset.X,y-inset.Y) and not covers(ctx.view.reopen,x-inset.X,y-inset.Y)
            and not covers(ctx.view.petReceipt,x-inset.X,y-inset.Y) then
            local safe=true
            for _,hit in ipairs(ctx.pg:GetGuiObjectsAtPosition(x-inset.X,y-inset.Y)) do
                if visible(hit) and (hit:IsA("GuiButton") or hit.Active) then
                    local host=hit:FindFirstAncestorOfClass("ScreenGui")
                    if not host or (host.Name~="ThrowSequence" and host.Name~="ScreenFX") then safe=false; break end
                end
            end
            if safe then return x,y end
        end
    end
end
-- Resolve the existing handler without showing the panel or guessing remote arguments.
function ctx.buttonSignal(obj)
    if not (obj and obj:IsA("GuiButton")) then return nil, "Equip Best button not initialized" end
    if type(getconnections) ~= "function" or type(firesignal) ~= "function" then
        return nil, "Background button input requires getconnections and firesignal"
    end
    for _, name in ipairs({"Activated", "MouseButton1Click"}) do
        local signal = obj[name]
        local ok, listeners = pcall(getconnections, signal)
        if ok then
            for _, listener in ipairs(listeners) do
                if listener.Enabled ~= false then return signal, name end
            end
        end
    end
    return nil, "Equip Best button has no available input handler"
end
function ctx.clickHidden(obj)
    local signal, name = ctx.buttonSignal(obj)
    assert(signal, name)
    log("CLICK_BACKGROUND", obj:GetFullName() .. " signal=" .. name)
    firesignal(signal)
end
function ctx.click(obj)
    log("CLICK", obj and obj:GetFullName() or "nil button")
    assert(obj and obj:IsA("GuiButton") and visible(obj), "Button unavailable or hidden")
    -- Prefer the signal that actually has listeners; do not dispatch both.
    if type(getconnections) == "function" and type(firesignal) == "function" then
        for _, name in ipairs({"Activated", "MouseButton1Click"}) do
            local signal = obj[name]
            local ok, listeners = pcall(getconnections, signal)
            if ok and #listeners > 0 then
                log("CLICK_METHOD", name .. " listeners=" .. #listeners)
                firesignal(signal)
                return
            end
        end
    end
    -- A single Activated dispatch avoids firing the same purchase twice.
    local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
    local inset = game:GetService("GuiService"):GetGuiInset()
    local screen = obj:FindFirstAncestorOfClass("ScreenGui")
    local offset = screen and screen.IgnoreGuiInset and Vector2.new() or inset
    local camera = workspace.CurrentCamera
    if not (pos.X >= 0 and pos.Y >= 0 and camera
        and pos.X + size.X <= camera.ViewportSize.X
        and pos.Y+size.Y+offset.Y <= camera.ViewportSize.Y) then
        assert(type(firesignal) == "function", "Button off screen; signal dispatch unavailable")
        firesignal(obj.Activated)
        return
    end
    clickAt(pos.X+size.X/2+offset.X, pos.Y+size.Y/2+offset.Y)
end
-- Shop actions use real pointer input: Activated listeners can be cosmetic only.
-- Never fall back to firing a second signal for a potentially destructive action.
function ctx.clickScreenButton(obj, allowed)
    assert(obj and obj:IsA("GuiButton") and visible(obj), "Screen button unavailable")
    local camera=assert(workspace.CurrentCamera,"Camera unavailable")
    local inset=game:GetService("GuiService"):GetGuiInset()
    local p,s=obj.AbsolutePosition,obj.AbsoluteSize
    -- AbsolutePosition and GetGuiObjectsAtPosition use inset-applied GUI
    -- coordinates; pointer input uses screen pixels. This also covers full-screen
    -- IgnoreGuiInset roots whose GUI-space origin can be negative.
    local left,top=math.max(-inset.X,p.X),math.max(-inset.Y,p.Y)
    local right,bottom=math.min(camera.ViewportSize.X-inset.X,p.X+s.X),math.min(camera.ViewportSize.Y-inset.Y,p.Y+s.Y)
    local ancestor=obj.Parent
    while ancestor and ancestor~=ctx.pg do
        if ancestor:IsA("GuiObject") and ancestor.ClipsDescendants then
            local a,b=ancestor.AbsolutePosition,ancestor.AbsoluteSize
            left,top=math.max(left,a.X),math.max(top,a.Y)
            right,bottom=math.min(right,a.X+b.X),math.min(bottom,a.Y+b.Y)
        end
        ancestor=ancestor.Parent
    end
    assert(right-left>=4 and bottom-top>=4,"Screen button is clipped/off screen")
    local gx,gy=math.floor((left+right)/2),math.floor((top+bottom)/2)
    local x,y=gx+inset.X,gy+inset.Y
    assert(x>=0 and y>=0 and x<camera.ViewportSize.X and y<camera.ViewportSize.Y,"Screen button outside viewport")
    local panel=ctx.view.panel
    local wasVisible=panel and panel.Visible
    local pp,ps=panel and panel.AbsolutePosition,panel and panel.AbsoluteSize
    local overlaps=wasVisible and gx>=pp.X and gx<=pp.X+ps.X and gy>=pp.Y and gy<=pp.Y+ps.Y
    if overlaps then panel.Visible=false end
    local ok,err=pcall(function()
        local hits=ctx.pg:GetGuiObjectsAtPosition(gx,gy)
        local target
        for _,hit in ipairs(hits) do
            if visible(hit) and (hit:IsA("GuiButton") or hit.Active) then target=hit; break end
        end
        assert(target==obj,"Screen button is covered by another game control")
        assert(not allowed or allowed(),"Screen action cancelled")
        log("CLICK_SCREEN",obj:GetFullName()..string.format(" x=%.1f y=%.1f",x,y))
        clickAt(x,y)
    end)
    if overlaps and ctx.state.alive then panel.Visible=wasVisible end
    if not ok then error(err,0) end
end
function ctx.move(pos, settleSeconds)
    log("TELEPORT", tostring(pos))
    ctx.checkAction()
    local root = rootPart()
    root.CFrame = CFrame.new(pos)
    root.AssemblyLinearVelocity = Vector3.new()
    if settleSeconds == nil then settleSeconds = 0.25 end
    if settleSeconds > 0 then task.wait(settleSeconds) end
end

end
]=],
        ["logging"] = [=[
-- Adonis Hub / logging
return function(ctx)
local Http = ctx.services.Http
local player = ctx.player
local pg = ctx.pg
local cfg = ctx.cfg
local function flushLog(...) return ctx.flushLog(...) end
local function log(...) return ctx.log(...) end
local function snapshot(...) return ctx.snapshot(...) end
local function visible(...) return ctx.visible(...) end

local logFile = "AdonisHub-debug-" .. os.date("!%Y%m%d-%H%M%S") .. "-" .. Http:GenerateGUID(false):sub(1,8) .. ".txt"
local logLines, logDirty, logCount = {}, false, 0
local logPending, logCreated = {}, false
local appendSafe, lastIntegrityAt = true,-math.huge
local flushing = false
local logStarted = os.clock()
function ctx.log(kind, message)
    logCount = logCount+1
    local line = string.format("#%d +%.3fs [%s] %s", logCount,
        os.clock()-logStarted, kind, tostring(message))
    table.insert(logLines, line)
    table.insert(logPending, {seq=logCount,text=line})
    if #logLines > 3000 then
        local recent = {}
        for i = #logLines-1999, #logLines do table.insert(recent, logLines[i]) end
        logLines = recent
    end
    if #logPending > 3000 then
        logPending = {{seq=logCount,text="[LOG] Older unsaved entries dropped to bound memory"},{seq=logCount,text=line}}
    end
    logDirty = true
end
function ctx.flushLog()
    if flushing then return false end
    if not logDirty then return true end
    if type(writefile) == "function" then
        flushing = true
        local ok
        local flushedThrough = logCount
        local header = "ADONIS HUB DEBUG v3 | UTC session | " .. logFile .. "\n"
        local function rewrite()
            flushedThrough = logCount
            return pcall(writefile,logFile,header .. table.concat(logLines,"\n") .. "\n")
        end
        -- Some executor/file-sync implementations can report append success
        -- while losing the existing prefix. Check on first append, then at most
        -- once a minute; otherwise preserve a bounded complete recent report.
        if logCreated and appendSafe and type(appendfile) == "function" and type(readfile) == "function" then
            local pending = {}
            for _, record in ipairs(logPending) do table.insert(pending,record.text) end
            local payload = table.concat(pending,"\n") .. "\n"
            ok = pcall(appendfile, logFile, payload)
            if ok and os.clock()-lastIntegrityAt >= 60 then
                lastIntegrityAt = os.clock()
                local readOK, stored = pcall(readfile,logFile)
                ok = readOK and type(stored)=="string" and stored:sub(1,#header)==header
                    and stored:sub(-#payload)==payload
            end
            if not ok then
                appendSafe = false
                log("LOG_IO","Append/read integrity unavailable; preserving recent log with bounded rewrites")
                ok = rewrite()
            end
        else
            ok = rewrite()
        end
        if ok then
            local remaining = {}
            for _, record in ipairs(logPending) do
                if record.seq > flushedThrough then table.insert(remaining,record) end
            end
            logPending,logDirty,logCreated = remaining,#remaining>0,true
        end
        flushing = false
        return ok
    end
    return false
end
log("SESSION", "PlaceId=" .. game.PlaceId .. " config=" .. Http:JSONEncode(cfg))
log("BUILD", "adonis-blue-launcher-highlight-20261110")
log("CAPABILITIES", "writefile=" .. type(writefile) .. " firesignal=" .. type(firesignal)
    .. " gethui=" .. type(gethui))
task.spawn(function()
    while ctx.state.alive do
        task.wait(10)
        if not ctx.state.cinemaPending then flushLog() end
    end
end)
function ctx.snapshot(reason)
    log("SNAPSHOT", reason .. " running=" .. tostring(ctx.state.running)
        .. " cinemaPending=" .. tostring(ctx.state.cinemaPending) .. " throws=" .. ctx.state.completedThrows
        .. " equipThrough=" .. ctx.state.equippedThroughThrow)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then log("CHARACTER", "position=" .. tostring(root.Position) .. " anchored=" .. tostring(root.Anchored)) end
    local count = 0
    for _, obj in ipairs(pg:GetDescendants()) do
        if visible(obj) and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageButton")) then
            local txt = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text or ""
            if txt ~= "" or obj:IsA("GuiButton") then
                log("GUI", obj:GetFullName() .. " text=" .. string.format("%q", txt)
                    .. " pos=" .. tostring(obj.AbsolutePosition) .. " size=" .. tostring(obj.AbsoluteSize))
                count = count+1
                if count >= 350 then log("GUI", "Snapshot capped at 350 entries"); break end
            end
        end
    end
    for _, container in ipairs({player:FindFirstChild("Backpack"), char}) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    local attrs = {}
                    for k,v in pairs(obj:GetAttributes()) do table.insert(attrs, k .. "=" .. tostring(v)) end
                    log("TOOL", obj:GetFullName() .. " " .. table.concat(attrs, ", "))
                end
            end
        end
    end
    -- Manual snapshots include hidden feature data that visible-GUI dumps omit.
    for _, name in ipairs({"equipmentDiagnostics","sellDiagnostics","upgradeDiagnostics","foodDiagnostics","throwEntryDiagnostics","boostDiagnostics","plotDiagnostics","plotUpgradeDiagnostics"}) do
        if ctx[name] then
            local ok, lines = pcall(ctx[name])
            if ok then
                for i=1,math.min(16,#lines) do log("FEATURE_DATA",name .. " " .. lines[i]) end
            else log("FEATURE_DATA",name .. " failed: " .. tostring(lines)) end
        end
    end
    flushLog()
end

ctx.logFile = logFile

end
]=],
        ["pet_observer"] = [=[
-- Passive receipt observation. Never sends input or owns the game's camera.
return function(ctx)
local session
local containers,attributes={},{}
local function markChanged()
    if session then session.dirty=true; session.changedAt=os.clock() end
end
local function clearAttributes()
    for _,list in pairs(attributes) do for _,connection in ipairs(list) do connection:Disconnect() end end
    attributes={}
end
local function added(tool)
    if not session or not tool:IsA("Tool") then return end
    markChanged()
    if attributes[tool] then return end
    local count=0; for _ in pairs(attributes) do count=count+1 end
    if count>=8 then return end -- bounded transient watchers, including late AnimalId initialization
    local list={}
    for _,name in ipairs({"AnimalId","AnimalName","Income","Mutation","Rarity","Weight","SizeMult"}) do
        table.insert(list,tool:GetAttributeChangedSignal(name):Connect(markChanged))
    end
    attributes[tool]=list
end
local function removed(tool)
    if tool:IsA("Tool") then markChanged() end
    local list=attributes[tool]
    if list then
        for _,connection in ipairs(list) do connection:Disconnect() end
        attributes[tool]=nil
    end
end
local function bind(key,host)
    local old=containers[key]
    if old and old.host==host then return end
    if old then for _,connection in ipairs(old.connections) do connection:Disconnect() end end
    containers[key]=nil
    if host then
        containers[key]={host=host,connections={host.ChildAdded:Connect(added),host.ChildRemoved:Connect(removed)}}
    end
end
local function start(reset,via)
    clearAttributes()
    ctx.capturePetReceiptBaseline(reset)
    session={startedAt=os.clock(),dirty=true,changedAt=os.clock(),via=via}
    ctx.log("PET_OBSERVER_BEGIN",via)
end
local function close(final)
    if final then ctx.resolvePetReceipt(true,true) else ctx.discardPetReceiptBaseline() end
    clearAttributes(); session=nil
end
bind("bag",ctx.player:FindFirstChild("Backpack"))
bind("character",ctx.player.Character)
table.insert(ctx.connections,ctx.player.ChildAdded:Connect(function(obj)
    if obj:IsA("Backpack") then bind("bag",obj); markChanged() end
end))
table.insert(ctx.connections,ctx.player.ChildRemoved:Connect(function(obj)
    if containers.bag and containers.bag.host==obj then bind("bag",nil); markChanged() end
end))
table.insert(ctx.connections,ctx.player.CharacterAdded:Connect(function(character)
    if session then close(false) end -- a respawn cannot inherit the previous throw's reward baseline
    bind("character",character); markChanged()
end))
-- Capture immediately before a manual screen tap as well as the normal meter
-- poll. This covers short-lived meters without hooking or replaying game input.
table.insert(ctx.connections,ctx.services.UIS.InputBegan:Connect(function(input)
    if not ctx.state.alive then return end
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    if ctx.state.cinemaPending or ctx.cinemaPrompt() or (session and session.cinema) then return end
    if ctx.visible(ctx.ui("ThrowSequence.Meter.Bar")) then
        if not session then start(true,"meter input") else ctx.capturePetReceiptBaseline(true) end
        -- The game's meter can remain Visible behind cinema. This passive phase
        -- marker prevents later Skip/Continue taps from overwriting the baseline.
        session.cinema=true
    end
end))
function ctx.observePetReceipt()
    if not ctx.state.alive then return end
    local now=os.clock()
    local meter=ctx.visible(ctx.ui("ThrowSequence.Meter.Bar"))
    local prompt=ctx.cinemaPrompt()
    local hud=ctx.visible(ctx.ui("HUD.RightSideButtons.AnimalsButton"))
    if meter and not prompt and not ctx.state.cinemaPending and not (session and session.cinema) then
        if not session then start(true,"meter") end
        session.sawMeter=true; session.hudAt=nil
        -- Inventory moves while aiming must not become the throw's reward.
        if session.dirty then ctx.capturePetReceiptBaseline(true); session.dirty=false end
        return
    end
    if not session and ctx.state.cinemaPending and ctx.hasPetReceiptBaseline() then
        start(false,"existing automatic throw")
    end
    if not session then return end
    if prompt or ctx.state.cinemaPending or not hud then session.cinema=true end
    if session.cinema and session.dirty and now-session.changedAt>=0.35 then
        session.dirty=false
        if ctx.resolvePetReceipt(false,true) then clearAttributes() end
    end
    -- Observe completion without clicking Continue or changing cinemaPending.
    -- A short grace period allows the reward Tool/attributes to replicate.
    if hud and not prompt then
        session.hudAt=session.hudAt or now
        if now-session.hudAt>=1 and (not session.dirty or now-session.changedAt>=0.35) then
            if session.cinema then close(true)
            else close(false) end -- cancelled aim, no reward claim
        end
    else session.hudAt=nil end
    if session and now-session.startedAt>180 then
        ctx.log("PET_OBSERVER_TIMEOUT","No receipt/completion within 180s; discard stale observation")
        -- Discard rather than attribute an unrelated later grant to this throw.
        close(false)
    end
end
function ctx.petReceiptCinemaActive() return session and session.cinema==true or false end
table.insert(ctx.disposers,function()
    clearAttributes()
    for _,record in pairs(containers) do for _,connection in ipairs(record.connections) do connection:Disconnect() end end
    containers={}; session=nil
end)
end
]=],
        ["plot_upgrade"] = [=[
-- User-confirmed clickable sign; read current price, never guess remotes.
return function(ctx)
local nextAttempt=0
local lastReason
local function active()
    return ctx.actionActive("PlotUpgrade")
        and not ctx.state.cinemaPending and not ctx.cinemaPrompt()
        and not ctx.visible(ctx.ui("ThrowSequence.Meter.Bar"))
end
local function texts(root)
    local result,queue,head={},{root},1
    while head<=#queue and head<=64 do
        local obj=queue[head]; head=head+1
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if obj.Text~="" and ctx.visible(obj) then result[#result+1]=obj.Text end
        end
        for _,child in ipairs(obj:GetChildren()) do queue[#queue+1]=child end
    end
    return result
end
function ctx.plotUpgradeQuote()
    local sign=ctx.ui("PlotUpgradeSign")
    local button=ctx.ui("PlotUpgradeSign.Root.Upgrade")
    if not sign or not button or not button:IsA("GuiButton") then return nil,"Upgrade button missing" end
    -- Runtime F8: MAX is a separate visible Root.Max.Text, while the old
    -- Upgrade.Label price remains present but hidden. Never read that stale cost.
    local max=ctx.ui("PlotUpgradeSign.Root.Max")
    if max and ctx.visible(max) then
        for _,text in ipairs(texts(max)) do
            if ctx.plainText(text):upper():match("^%s*(.-)%s*$")=="MAX" then return nil,"MAX" end
        end
    end
    local buttonTexts=texts(button)
    for _,text in ipairs(buttonTexts) do
        local plain=ctx.plainText(text):upper():match("^%s*(.-)%s*$")
        if plain=="MAX" or plain=="MAXED" or plain=="MAX LEVEL" then return nil,"MAX" end
    end
    local price
    local function prices(list)
        for _,text in ipairs(list) do
            local plain=ctx.plainText(text):lower()
            if plain:find("robux",1,true) or plain:find("r$",1,true) then return false,"Robux price is not supported" end
            if text:find("$",1,true) then
                local n=ctx.currencyAmount(text)
                if not n then return false,"Unknown plot price" end
                if price and price~=n then return false,"Ambiguous plot prices" end
                price=n
            end
        end
        return true
    end
    local ok,reason=prices(buttonTexts)
    if not ok then return nil,reason end
    if price==nil then
        ok,reason=prices(texts(ctx.ui("PlotUpgradeSign.Root")))
        if not ok then return nil,reason end
    end
    if price==nil then return nil,"Plot price not readable" end
    return {button=button,sign=sign,price=price,anchor=sign.Adornee}
end
local function skip(reason)
    if reason~=lastReason then ctx.log("PLOT_UPGRADE_SKIP",reason); lastReason=reason end
end
function ctx.plotUpgradeDiagnostics()
    local quote,reason=ctx.plotUpgradeQuote()
    local result={"quote="..tostring(quote and quote.price).." reason="..tostring(reason)}
    local root=ctx.ui("PlotUpgradeSign.Root")
    if root then for _,line in ipairs(ctx.dataSample(root,8)) do result[#result+1]=line end end
    return result
end
function ctx.plotUpgradeReady()
    if os.clock()<nextAttempt then return false end
    local quote=ctx.plotUpgradeQuote()
    local cash=quote and ctx.money()
    return quote and cash and cash>=quote.price or false
end
function ctx.doPlotUpgrade()
    if not active() then return end
    local quote,reason=ctx.plotUpgradeQuote()
    if not quote then skip(reason); return end
    local cash=ctx.money()
    if not cash or cash<quote.price then skip(cash and "Insufficient money" or "Money unreadable"); return end
    if os.clock()<nextAttempt then skip("Waiting for previous plot input"); return end
    ctx.closeAnimals(); ctx.stopTraining()
    if not active() then return end
    local prepared
    prepared,reason=ctx.plotUpgradeQuote()
    cash=ctx.money()
    if not prepared or prepared.button~=quote.button or prepared.price~=quote.price
        or not cash or cash<prepared.price then skip(reason or "Quote/money changed before approach"); return end
    -- Only approach when not already able to point at the known local sign.
    if not ctx.onScreen(quote.button) then
        local anchor=quote.anchor
        if not anchor or not anchor:IsA("BasePart") then skip("Local plot sign anchor unavailable"); return end
        local root=ctx.rootPart()
        local delta=root.Position-anchor.Position
        local length=math.sqrt(delta.X*delta.X+delta.Z*delta.Z)
        local x,z=0,5
        if length>0.1 then x,z=delta.X/length*5,delta.Z/length*5 end
        -- Keep the character's current floor height; no camera takeover.
        ctx.move(Vector3.new(anchor.Position.X+x,root.Position.Y,anchor.Position.Z+z))
    end
    if not active() then return end
    local current
    current,reason=ctx.plotUpgradeQuote()
    cash=ctx.money()
    if not current or current.button~=quote.button or current.price~=quote.price
        or not cash or cash<current.price then skip(reason or "Quote/money changed"); return end
    if not ctx.onScreen(current.button) then skip("Plot button is off screen"); return end
    nextAttempt=os.clock()+30
    ctx.say("Upgrading plot...")
    ctx.clickScreenButton(current.button,function()
        if not active() then return false end
        local fresh=ctx.plotUpgradeQuote()
        local money=ctx.money()
        return fresh and fresh.button==current.button and fresh.price==current.price
            and money and money>=fresh.price
    end)
    lastReason=nil
    ctx.log("PLOT_UPGRADE_INPUT","price="..current.price.." button="..current.button:GetFullName()
        .." (pointer input sent; server purchase not confirmed)")
end
end
]=],
        ["plots"] = [=[
-- Shared plot identity. Numeric plot names are slots, never player identity.
return function(ctx)
local ownerKeys={"OwnerUserId","OwnerId","Owner","PlayerUserId"}
local function playerId(value,players)
    if typeof(value)=="Instance" then
        if value:IsA("Player") then return value.UserId end
        return nil
    end
    local id=tonumber(value)
    local found
    local text=type(value)=="string" and ctx.plainText(value):match("^%s*(.-)%s*$") or nil
    if text then text=text:gsub("^@","") end
    for _,player in ipairs(players or ctx.services.Players:GetPlayers()) do
        if (id and id==player.UserId) or text==player.Name or (text and text==player.DisplayName) then
            if found and found~=player.UserId then return nil end
            found=player.UserId
        end
    end
    return found
end
local function tagGui(tag)
    if tag:IsA("BillboardGui") or tag:IsA("SurfaceGui") then return tag end
    -- Exact Copy Path supplied by user: Plots.<slot>.OwnerTag.OwnerTag.Name.
    local nested=tag:FindFirstChild("OwnerTag")
    if nested then return nested end
    if tag:IsA("ObjectValue") then
        local value=tag.Value
        if value and (value:IsA("BillboardGui") or value:IsA("SurfaceGui")) then return value end
    end
end
local function nameLabel(tag)
    local gui=tagGui(tag)
    local label=gui and gui:FindFirstChild("Name")
    return label and (label:IsA("TextLabel") or label:IsA("TextButton")) and label or nil
end
-- Watch the nested or referenced GUI label, including replacement/renaming.
function ctx.watchPlotTag(tag,changed)
    local connections,guiConnections={},{}
    local childConnections,tagChildConnections={},{}
    local labelConnection
    local function clearGui()
        for _,connection in ipairs(guiConnections) do connection:Disconnect() end
        guiConnections={}
        for _,connection in pairs(childConnections) do connection:Disconnect() end
        childConnections={}
        if labelConnection then labelConnection:Disconnect(); labelConnection=nil end
    end
    local function bindLabel()
        if labelConnection then labelConnection:Disconnect(); labelConnection=nil end
        local label=nameLabel(tag)
        if label then labelConnection=label:GetPropertyChangedSignal("Text"):Connect(changed) end
        changed()
    end
    local function bindGui()
        clearGui()
        local gui=tagGui(tag)
        if gui then
            local function added(child)
                if not childConnections[child] then
                    childConnections[child]=child:GetPropertyChangedSignal("Name"):Connect(bindLabel)
                end
                bindLabel()
            end
            guiConnections[#guiConnections+1]=gui.ChildAdded:Connect(added)
            guiConnections[#guiConnections+1]=gui.ChildRemoved:Connect(function(child)
                if childConnections[child] then childConnections[child]:Disconnect(); childConnections[child]=nil end
                bindLabel()
            end)
            for _,child in ipairs(gui:GetChildren()) do added(child) end
        end
        bindLabel()
    end
    if tag:IsA("ObjectValue") or tag:IsA("StringValue") or tag:IsA("IntValue") or tag:IsA("NumberValue") then
        connections[#connections+1]=tag:GetPropertyChangedSignal("Value"):Connect(bindGui)
    end
    if not (tag:IsA("BillboardGui") or tag:IsA("SurfaceGui")) then
        local function added(child)
            if not tagChildConnections[child] then
                tagChildConnections[child]=child:GetPropertyChangedSignal("Name"):Connect(bindGui)
            end
            bindGui()
        end
        connections[#connections+1]=tag.ChildAdded:Connect(added)
        connections[#connections+1]=tag.ChildRemoved:Connect(function(child)
            if tagChildConnections[child] then tagChildConnections[child]:Disconnect(); tagChildConnections[child]=nil end
            bindGui()
        end)
        for _,child in ipairs(tag:GetChildren()) do added(child) end
    end
    connections[#connections+1]=tag.AttributeChanged:Connect(changed)
    bindGui()
    return {Disconnect=function()
        clearGui(); for _,connection in ipairs(connections) do connection:Disconnect() end
        for _,connection in pairs(tagChildConnections) do connection:Disconnect() end
    end}
end
function ctx.plotOwner(plot,players)
    local plots=workspace:FindFirstChild("Plots")
    if not plot or not plots or plot.Parent~=plots then return nil,"not a plot" end
    local owner,unknown,conflict
    local function accept(value)
        if value==nil or value=="" then return end
        local id=playerId(value,players)
        if not id then unknown=true
        elseif owner and owner~=id then conflict=true
        else owner=id end
    end
    for _,key in ipairs(ownerKeys) do accept(plot:GetAttribute(key)) end
    local tag=plot:FindFirstChild("OwnerTag")
    if tag then
        local label=nameLabel(tag)
        if tagGui(tag) then
            if label then accept(label.Text) else unknown=true end
        elseif tag:IsA("ObjectValue") or tag:IsA("StringValue") or tag:IsA("IntValue") or tag:IsA("NumberValue") then accept(tag.Value) end
        for _,key in ipairs(ownerKeys) do accept(tag:GetAttribute(key)) end
    end
    if conflict or unknown then return nil,conflict and "conflicting owner" or "unresolved owner tag" end
    return owner,owner and "explicit plot owner" or "owner not initialized"
end
function ctx.plotDiagnostics()
    local result={}
    local plots=workspace:FindFirstChild("Plots")
    if not plots then return {"Workspace.Plots missing"} end
    for i,plot in ipairs(plots:GetChildren()) do
        if i>16 then break end
        local id,reason=ctx.plotOwner(plot)
        local tag=plot:FindFirstChild("OwnerTag")
        result[#result+1]=plot:GetFullName().." owner="..tostring(id).." reason="..reason
            .." OwnerTagClass="..(tag and tag.ClassName or "nil")
        local label=tag and nameLabel(tag)
        if label then result[#result+1]=label:GetFullName().." Text="..string.format("%q",label.Text) end
        if tag and (tag:IsA("ObjectValue") or tag:IsA("StringValue") or tag:IsA("IntValue") or tag:IsA("NumberValue")) then
            local value=tag.Value
            result[#result+1]=" OwnerTag.Value="..(typeof(value)=="Instance" and value:GetFullName() or tostring(value))
            if typeof(value)=="Instance" and (value:IsA("BillboardGui") or value:IsA("SurfaceGui")) then
                for _,line in ipairs(ctx.dataSample(value,3)) do result[#result+1]=line end
            end
        end
    end
    return result
end
end
]=],
        ["presentation"] = [=[
-- Pet receipt from actual new reward Tools; cinema_view owns the live camera.
return function(ctx)
local baseline, expiresAt, preview
local receiptReported=false
local TweenService=ctx.services.TweenService
local receiptSerial,tweens,tweenConnections=0,{},{}
local exiting=false
local receiptSeconds,exitSeconds=5,0.2
local gui = Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.IgnoreGuiInset = "AdonisPresentation",false,true
gui.DisplayOrder = 99999 -- Below the Hub, above normal game UI.
gui.Parent = ctx.view.gui.Parent
local function label(parent,text,x,y,w,h)
    local obj = Instance.new("TextLabel",parent)
    obj.Position,obj.Size = UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
    obj.BackgroundTransparency,obj.TextColor3,obj.TextSize = 1,Color3.fromRGB(230,235,245),14
    obj.Text,obj.TextWrapped,obj.Active = text,true,false
    obj.Font = Enum.Font.SourceSans
    return obj
end
local function round(obj,radius)
    Instance.new("UICorner",obj).CornerRadius=UDim.new(0,radius)
end
local restPosition=UDim2.new(1,-20,1,-24)
local toast = Instance.new("CanvasGroup",gui)
toast.Name,toast.Size = "PetReceipt",UDim2.fromOffset(420,196)
toast.AnchorPoint,toast.Position = Vector2.new(1,1),restPosition
toast.BackgroundTransparency,toast.Visible,toast.Active = 1,false,false
toast.GroupTransparency=1
local scale=Instance.new("UIScale",toast); scale.Scale=1
local shadow=Instance.new("Frame",toast)
shadow.Name,shadow.Position,shadow.Size="Shadow",UDim2.fromOffset(4,8),UDim2.fromOffset(412,184)
shadow.BackgroundColor3,shadow.BackgroundTransparency=Color3.fromRGB(0,0,0),0.72
shadow.BorderSizePixel,shadow.Active=0,false; round(shadow,14)
local body=Instance.new("Frame",toast)
body.Name,body.Position,body.Size="Surface",UDim2.fromOffset(4,0),UDim2.fromOffset(412,184)
body.BackgroundColor3,body.BackgroundTransparency=Color3.fromRGB(30,32,40),0.08
body.BorderSizePixel,body.Active=0,false; round(body,12)
local border=Instance.new("UIStroke",body)
border.Color,border.Transparency,border.Thickness=Color3.fromRGB(219,230,255),0.85,1
local surfaceGradient=Instance.new("UIGradient",body)
surfaceGradient.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(205,215,235))
surfaceGradient.Rotation=90
local caption=label(body,"ANIMAL RECEIVED",18,10,190,16)
caption.TextSize,caption.Font,caption.TextXAlignment=10,Enum.Font.SourceSansSemibold,Enum.TextXAlignment.Left
caption.TextColor3=Color3.fromRGB(155,163,182)
local brand=label(body,"ADONIS HUB",268,10,126,16)
brand.TextSize,brand.TextColor3,brand.TextXAlignment=10,Color3.fromRGB(116,126,147),Enum.TextXAlignment.Right
local tile=Instance.new("Frame",body)
tile.Name,tile.Position,tile.Size="PetVisual",UDim2.fromOffset(16,40),UDim2.fromOffset(92,116)
tile.BackgroundColor3,tile.BackgroundTransparency=Color3.fromRGB(230,238,255),0.95
tile.BorderSizePixel,tile.Active=0,false; round(tile,9)
local image = Instance.new("ImageLabel",tile)
image.Position,image.Size = UDim2.fromOffset(4,4),UDim2.fromOffset(84,108)
image.BackgroundTransparency,image.Visible = 1,false
image.ScaleType=Enum.ScaleType.Fit
local fallback = label(tile,"PET",4,4,84,108)
fallback.TextColor3=Color3.fromRGB(139,151,176)
local name = label(body,"",124,36,270,32)
name.Name,name.TextSize,name.Font="AnimalName",19,Enum.Font.SourceSansSemibold
name.TextWrapped,name.TextTruncate=false,Enum.TextTruncate.AtEnd
local mutationCaption=label(body,"Mutation",124,73,68,24)
mutationCaption.TextSize,mutationCaption.TextColor3,mutationCaption.TextXAlignment=14,Color3.fromRGB(156,166,187),Enum.TextXAlignment.Left
local mutation = label(body,"",196,73,198,24)
mutation.Name,mutation.TextSize,mutation.Font="Mutation",17,Enum.Font.SourceSansBold
local mutationGradient=Instance.new("UIGradient",mutation)
mutationGradient.Enabled=false
mutationGradient.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,119,138)),
    ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,219,108)),
    ColorSequenceKeypoint.new(0.4,Color3.fromRGB(104,239,161)),
    ColorSequenceKeypoint.new(0.6,Color3.fromRGB(98,208,255)),
    ColorSequenceKeypoint.new(0.8,Color3.fromRGB(186,147,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,119,194))})
local income = label(body,"",124,101,270,26)
income.Name,income.TextSize,income.Font="Income",16,Enum.Font.SourceSansSemibold
income.TextColor3=Color3.fromRGB(140,246,109)
local details = label(body,"",124,131,270,36)
details.Name,details.TextSize,details.TextColor3="Details",11,Color3.fromRGB(160,171,192)
for _,obj in ipairs({name,mutation,income,details}) do obj.TextXAlignment = Enum.TextXAlignment.Left end
local track=Instance.new("Frame",body)
track.Name,track.Position,track.Size="LifetimeTrack",UDim2.fromOffset(18,176),UDim2.fromOffset(376,2)
track.BackgroundColor3,track.BackgroundTransparency,track.BorderSizePixel=Color3.fromRGB(255,255,255),0.94,0
local progress=Instance.new("Frame",track)
progress.Name,progress.Size,progress.BorderSizePixel="Lifetime",UDim2.new(1,0,1,0),0
progress.Active=false
local colors={normal=Color3.fromRGB(221,229,245),gold=Color3.fromRGB(255,211,84),
    diamond=Color3.fromRGB(91,182,255),emerald=Color3.fromRGB(77,226,146),
    ruby=Color3.fromRGB(255,100,120),rainbow=Color3.fromRGB(190,156,255)}
ctx.view.petReceipt = toast
ctx.view.petReceiptVisual,ctx.view.petReceiptProgress=tile,progress
ctx.view.petReceiptMutation,ctx.view.petReceiptIncome=mutation,income
local enabledConnection=gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ctx.state.alive and toast.Visible and not gui.Enabled then gui.Enabled=true end
end)

local function tools()
    local out = {}
    for _,host in pairs({ctx.player:FindFirstChild("Backpack"),ctx.player.Character}) do
        if host then
            for _,obj in ipairs(host:GetChildren()) do
                if obj:IsA("Tool") then
                    local id = obj:GetAttribute("AnimalId")
                    if id ~= nil then out[tostring(id)] = obj end
                end
            end
        end
    end
    return out
end
local function clearPreview()
    if preview then preview:Destroy(); preview = nil end
    image.Visible,fallback.Visible = false,true
end
local function cancelAnimations()
    receiptSerial=receiptSerial+1
    -- Disconnect first: Cancel may synchronously emit Completed(Cancelled).
    for _,connection in ipairs(tweenConnections) do connection:Disconnect() end
    tweenConnections={}
    for _,animation in ipairs(tweens) do animation:Cancel(); animation:Destroy() end
    tweens={}
end
local function animate(object,seconds,style,direction,goals,completed,repeats)
    local animation=TweenService:Create(object,TweenInfo.new(seconds,style,direction,repeats or 0),goals)
    table.insert(tweens,animation)
    if completed then
        local serial=receiptSerial
        table.insert(tweenConnections,animation.Completed:Connect(function(playback)
            if playback==Enum.PlaybackState.Completed and serial==receiptSerial and ctx.state.alive then completed() end
        end))
    end
    animation:Play()
end
local function hideReceipt()
    cancelAnimations()
    toast.Visible,exiting,expiresAt=false,false,nil
    clearPreview()
end
local function dismissReceipt()
    if not toast.Visible or exiting then return end
    cancelAnimations(); exiting=true
    animate(scale,exitSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.In,{Scale=0.98})
    animate(toast,exitSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.In,
        {Position=UDim2.new(1,8,1,-24),GroupTransparency=1},hideReceipt)
end
local function revealReceipt(system)
    exiting=false
    toast.Position,toast.GroupTransparency,toast.Visible=UDim2.new(1,24,1,-24),1,true
    gui.Enabled=true
    scale.Scale=0.97
    progress.Size=UDim2.new(1,0,1,0)
    mutationGradient.Rotation=0
    mutationGradient.Enabled=system:lower()=="rainbow"
    if mutationGradient.Enabled then
        mutation.TextColor3=Color3.fromRGB(255,255,255)
        animate(mutationGradient,3.6,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,{Rotation=360},nil,-1)
    end
    animate(toast,0.32,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,{Position=restPosition,GroupTransparency=0})
    animate(scale,0.32,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,{Scale=1})
    -- Include the exit fade in the five-second display window.
    local holdSeconds=receiptSeconds-exitSeconds
    animate(progress,holdSeconds,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,{Size=UDim2.new(0,0,1,0)},dismissReceipt)
    expiresAt=os.clock()+holdSeconds
end
local function petImage(tool)
    clearPreview()
    -- TextureId is the Tool's actual inventory icon, when supplied by the game.
    if type(tool.TextureId) == "string" and tool.TextureId ~= "" then
        image.Image,image.Visible,fallback.Visible = tool.TextureId,true,false
        return "tool_icon"
    end
    -- A single bounded pet clone; never clone the map, other pets or game scripts.
    local descendants = tool:GetDescendants()
    if #descendants > 400 then return "model_too_large" end
    local clone
    local ok,err = pcall(function()
        preview = Instance.new("ViewportFrame",tile)
        preview.Position,preview.Size = image.Position,image.Size
        preview.BackgroundTransparency = 1
        local world = Instance.new("WorldModel",preview)
        local model = Instance.new("Model",world)
        clone = assert(tool:Clone(),"Pet Tool cannot be cloned")
        local parts = 0
        for _,obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Sound") or obj:IsA("ParticleEmitter")
                or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
            elseif obj:IsA("BasePart") then
                parts = parts+1
                obj.Anchored,obj.CanCollide = true,false
            end
        end
        if parts == 0 then clone:Destroy(); error("No pet geometry") end
        clone.Parent = model
        local cf,size = model:GetBoundingBox()
        local camera = Instance.new("Camera",preview)
        camera.FieldOfView = 35
        local distance = math.max(size.X,size.Y,size.Z,0.1)/math.tan(math.rad(17.5))
        camera.CFrame = CFrame.new(cf.Position+Vector3.new(distance*0.7,distance*0.4,distance),cf.Position)
        preview.CurrentCamera = camera
        fallback.Visible = false
    end)
    if not ok then
        if clone then clone:Destroy() end
        clearPreview(); return "unavailable: " .. tostring(err)
    end
    return "tool_model"
end
local function compact(n)
    if type(n) ~= "number" then return "?" end
    local units = {"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc",
        "Ud","Dd","Td","Qad","Qid","Sxd","Spd","Ocd","Nod","Vg"}
    local i = 1
    while n >= 1000 and i < #units do n,i = n/1000,i+1 end
    return string.format("%.3g",n) .. units[i]
end
function ctx.showPetReceipt(tool)
    local data = tool:GetAttributes()
    if data.AnimalId == nil then return end
    cancelAnimations()
    name.Text = tool.Name ~= "" and tool.Name or tostring(data.AnimalName or "Animal")
    local system = data.Mutation
    -- Existing runtime logs omit Mutation on unmutated Tools.
    if system == nil or system == "" then system = "Normal" end
    if tostring(system):lower() == "emeral" then system = "Emerald" end
    system=tostring(system)
    mutation.Text = system
    mutation.TextColor3=colors[system:lower()] or colors.normal
    progress.BackgroundColor3=colors[system:lower()] or colors.normal
    income.Text = "Income: $" .. compact(data.Income) .. "/s"
    details.Text = "Rarity: " .. tostring(data.Rarity or "?")
        .. "\nWeight: " .. tostring(data.Weight or "?")
        .. " | Size: x" .. tostring(data.SizeMult or "?")
    local visual = petImage(tool)
    revealReceipt(system)
    ctx.state.lastPetReceipt = {id=tostring(data.AnimalId),name=name.Text,mutation=tostring(system),
        income=data.Income,visual=visual}
    ctx.log("PET_RECEIPT","id=" .. tostring(data.AnimalId) .. " name=" .. name.Text
        .. " mutation=" .. tostring(system) .. " visual=" .. visual)
end
function ctx.capturePetReceiptBaseline(reset)
    if baseline and not reset then return end
    baseline = {}
    receiptReported=false
    for id in pairs(tools()) do baseline[id] = true end
end
function ctx.hasPetReceiptBaseline() return baseline~=nil end
function ctx.discardPetReceiptBaseline() baseline=nil; receiptReported=false end
function ctx.beginThrowPresentation() ctx.capturePetReceiptBaseline(false) end
function ctx.updateThrowPresentation()
    if ctx.updateCinemaView then ctx.updateCinemaView() end
    if toast.Visible then
        if not ctx.state.alive then hideReceipt()
        elseif expiresAt and os.clock()>=expiresAt then dismissReceipt() end
    end
end
function ctx.resolvePetReceipt(final,allowStopped)
    if not baseline or not ctx.state.alive or (not ctx.state.running and not allowStopped) then return false end
    if receiptReported then
        if final then baseline=nil; receiptReported=false end
        return true
    end
    local reward,count = nil,0
    for id,obj in pairs(tools()) do
        if not baseline[id] then reward,count = obj,count+1 end
    end
    -- An ambiguous inventory delta must not be attributed to a particular throw.
    local income=reward and reward:GetAttribute("Income")
    local ready=count==1 and type(income)=="number" and income==income and income>=0 and income<math.huge
    if ready then ctx.showPetReceipt(reward); receiptReported=true
    elseif final then ctx.log("PET_RECEIPT_UNAVAILABLE","newAnimalIds=" .. count .. "; no unique initialized reward Tool") end
    if final then baseline=nil; receiptReported=false end
    return ready
end
function ctx.finishThrowPresentation()
    if ctx.releaseCinemaView then ctx.releaseCinemaView(true) end
    ctx.resolvePetReceipt(true,false)
end
function ctx.stopThrowPresentation()
    if ctx.releaseCinemaView then ctx.releaseCinemaView(false) end
    hideReceipt()
    -- Keep the baseline across STOP: pending cinema can be resumed normally.
end
table.insert(ctx.disposers,function()
    enabledConnection:Disconnect()
    hideReceipt(); gui:Destroy()
end)
end
]=],
        ["selling"] = [=[
-- Use the game's Sell Animals shop; Auto Sell has no mutation/income filters.
return function(ctx)
local bodyPath="SellShop.SellPanel.Body"
local busy,lastSkip,lastSkipAt=false,nil,-math.huge
local nextAttemptAt,pending=0,nil
local allButton,allLabel,padCache=nil,nil,nil
local lastConfirmPressed
local stats={inputs=0,leftBackpack=0,outcome="idle"}
ctx.state.sellStats=stats
local function active()
    return ctx.actionActive("Sell")
        and not ctx.state.cinemaPending and not ctx.cinemaPrompt()
        and not ctx.visible(ctx.ui("ThrowSequence.Meter.Bar"))
end
local function skip(reason)
    stats.outcome=reason
    if lastSkip~=reason or os.clock()-lastSkipAt>=60 then
        lastSkip,lastSkipAt=reason,os.clock()
        ctx.log("SELL_SKIP",reason); ctx.say("Auto Sell: "..reason)
    end
end
local function text(obj)
    if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return "" end
    return ctx.plainText(obj.Text):upper():gsub("%s+"," "):match("^%s*(.-)%s*$")
end
local function isAll(label)
    local value=text(label)
    return value=="SELL ALL" or value:match("^SELL ALL%s*%(")~=nil
end
local function inScope(obj,root)
    while obj do if obj==root then return true end; obj=obj.Parent end
    return false
end
local function resolveAll()
    -- User-supplied Copy Path, resolved under LocalPlayer rather than an account name.
    local button=ctx.ui(bodyPath..".Content.Summary.SellAll")
    if not button or not button:IsA("GuiButton") then return end
    if button~=allButton or not inScope(allLabel,button) or not isAll(allLabel) then
        allButton,allLabel=button,nil
        local nodes={button}
        local descendants=button:GetDescendants()
        for i=1,math.min(30,#descendants) do table.insert(nodes,descendants[i]) end
        for _,label in ipairs(nodes) do if isAll(label) then allLabel=label; break end end
    end
    return button,allLabel and tonumber(text(allLabel):match("%(%s*(%d+)%s*%)"))
end
local function confirmButton()
    local control=ctx.ui(bodyPath..".Content.SellAllConfirm")
    if not ctx.visible(control) then lastConfirmPressed=nil; return end
    -- SellAllConfirm can itself be an ImageButton backdrop containing BOTH
    -- SELL and CANCEL. Its centre is not the affirmative action.
    local found,hasCancel
    local nodes={control}
    local descendants=control:GetDescendants()
    for i=1,math.min(96,#descendants) do table.insert(nodes,descendants[i]) end
    for _,node in ipairs(nodes) do
        local value=text(node)
        if ctx.visible(node) and (value=="CANCEL" or value=="NO") then hasCancel=true end
        if value=="SELL" or value=="CONFIRM" or value=="YES" or isAll(node) then
            local button=node
            while button and button~=control and not button:IsA("GuiButton") do button=button.Parent end
            if button and button:IsA("GuiButton") and ctx.visible(button) and ctx.visible(node) then
                if found and found~=button then return nil,control end
                found=button
            end
        end
    end
    -- A label falling back to a shared SELL/CANCEL backdrop cannot identify a
    -- safe click target. Only a distinct affirmative child (or standalone button).
    if found==control and hasCancel then found=nil end
    return found,control
end
local function inventory()
    local ids,count,duplicate={},0,false
    local bag=ctx.player:FindFirstChild("Backpack")
    if bag then
        for _,tool in ipairs(bag:GetChildren()) do
            if tool:IsA("Tool") then
                local id=tool:GetAttribute("AnimalId")
                if (type(id)=="string" and id~="") or type(id)=="number" then
                    id=tostring(id)
                    if ids[id] then duplicate=true else count=count+1 end
                    ids[id]=true
                end
            end
        end
    end
    return ids,count,duplicate
end
local function reconcile(ids)
    if not pending then return end
    local left,remaining=0,false
    for id in pairs(pending) do
        if ids[id] then remaining=true else left=left+1 end
    end
    if left>0 then
        stats.leftBackpack=stats.leftBackpack+left
        ctx.log("SELL_OBSERVED","leftBackpack="..left.." (not server sale confirmation)")
        -- Keep only unobserved IDs to avoid counting a late partial update twice.
        for id in pairs(pending) do if not ids[id] then pending[id]=nil end end
    end
    if not remaining then pending=nil end
end
local function shopPad()
    local found=ctx.find(workspace,"SellPlace.ActivationCircle")
    if not (found and found:IsA("BasePart")) then padCache=nil; return end
    if found~=padCache then ctx.log("SELL_SHOP_LOCATION",found:GetFullName().." position="..tostring(found.Position)) end
    padCache=found
    return found
end
function ctx.sellDiagnostics()
    local button,count=resolveAll()
    local confirm,modal=confirmButton()
    local _,bagCount=inventory()
    local lines={"enabled="..tostring(ctx.cfg.Sell).." mode=ShopSellAll bag="..bagCount.." displayed="..tostring(count),
        "button="..(button and button:GetFullName() or "missing").." pad="..(padCache and padCache:GetFullName() or "unknown"),
        "inputs="..stats.inputs.." leftBackpack="..stats.leftBackpack.." pending="..tostring(pending~=nil)
            .." retryIn="..math.max(0,nextAttemptAt-os.clock()).." outcome="..stats.outcome,
        "confirmation="..(confirm and confirm:GetFullName() or "no affirmative control")
            .." modal="..tostring(modal~=nil)}
    for _,path in ipairs({".Content.Summary",".Content.SellAllConfirm"}) do
        for _,line in ipairs(ctx.dataSample(ctx.ui(bodyPath..path),5)) do table.insert(lines,line) end
    end
    return lines
end
function ctx.doSell()
    if not active() or busy then return end
    busy=true
    local opened,completed=false,false
    local ok,err=xpcall(function()
        local ids,count,duplicate=inventory()
        reconcile(ids)
        if count==0 then nextAttemptAt=0; skip("Backpack has no pets"); return end
        if duplicate then skip("Duplicate Backpack AnimalId; waiting for inventory"); return end
        local visibleConfirm=confirmButton()
        -- Finishing an already open prompt is the second stage of the existing
        -- attempt, not another SELL ALL request. Do not wait out its cooldown.
        local resumeConfirm=visibleConfirm and visibleConfirm~=lastConfirmPressed
        if os.clock()<nextAttemptAt and not resumeConfirm then skip("Waiting before the next shop attempt"); return end
        -- Missing UI and unconfirmed responses retry after 30 seconds; no
        -- permanent single-pet pending lock and no rapid destructive replay.
        nextAttemptAt=os.clock()+30
        local panel=ctx.ui(bodyPath)
        if not ctx.visible(panel) then
            local pad=shopPad()
            if not pad then skip("Sell shop pad unavailable; open Sell Animals and press F8"); return end
            ctx.closeAnimals()
            if not active() then return end
            ctx.say("Going to Sell Animals...")
            ctx.move(pad.Position+Vector3.new(0,2.4,0))
            opened=true
            local deadline=os.clock()+8
            repeat
                if not active() then return end
                panel=ctx.ui(bodyPath)
                if ctx.visible(panel) then break end
                ctx.pause(os.clock()+0.1)
            until os.clock()>=deadline
            if not ctx.visible(panel) then skip("Sell Animals did not open; press F8 at the shop"); return end
        end
        ctx.pause(os.clock()+0.6)
        if not active() then return end
        local button,displayed=resolveAll()
        local confirm,modal=confirmButton()
        local alreadyConfirm=modal~=nil
        if modal then
            if not confirm then skip("Confirmation is visible but its SELL button is unavailable; press F8"); return end
            button=confirm
        end
        ids,count,duplicate=inventory()
        if not ctx.visible(button) or duplicate or count==0 then skip("SELL ALL button not ready; press F8 while shop is open"); return end
        if displayed and displayed~=count then skip("Shop/Backpack count mismatch; waiting for replication"); return end
        local function allowed()
            if not active() or not ctx.visible(ctx.ui(bodyPath)) then return false end
            local current,total,dup=inventory()
            if dup or total~=count then return false end
            for id in pairs(ids) do if not current[id] then return false end end
            return true
        end
        if not allowed() then return end
        pending=ids
        ctx.log("SELL_ALL_ATTEMPT",button:GetFullName().." backpack="..count.." displayed="..tostring(displayed))
        ctx.clickScreenButton(button,allowed)
        if alreadyConfirm then lastConfirmPressed=button; ctx.log("SELL_ALL_CONFIRM",button:GetFullName().." resumed") end
        stats.inputs=stats.inputs+1; lastSkip=nil
        ctx.log("SELL_ALL_INPUT","backpack="..count.." pointer input sent; awaiting inventory")
        local confirmed=alreadyConfirm
        local deadline=os.clock()+4
        repeat
            if not active() then return end
            local current,total=inventory()
            if total==0 then
                reconcile(current); completed=true; nextAttemptAt=0
                stats.outcome="backpack_empty_after_sell_all"
                ctx.say("Auto Sell: Backpack is empty.")
                break
            end
            local nextConfirm=confirmButton()
            -- A separate control must become visible after the first action;
            -- never dispatch the same SELL ALL button twice in one attempt.
            if not confirmed and nextConfirm and nextConfirm~=button then
                if not allowed() then return end
                ctx.log("SELL_ALL_CONFIRM",nextConfirm:GetFullName())
                ctx.clickScreenButton(nextConfirm,allowed)
                stats.inputs=stats.inputs+1; confirmed=true; lastConfirmPressed=nextConfirm
            end
            ctx.pause(os.clock()+0.15)
        until os.clock()>=deadline
        if not completed then
            local current=inventory(); reconcile(current)
            skip("SELL ALL input sent but Backpack is not empty; retry after cooldown")
        end
    end,debug.traceback)
    -- Keep an unconfirmed shop visible for inspection; do not dismiss unknown dialogs.
    if opened and completed and active() then
        local close=ctx.ui(bodyPath..".Header.CloseButton")
        if ctx.visible(close) then
            local closed,why=pcall(ctx.clickScreenButton,close,active)
            if not closed then ctx.log("SELL_CLOSE_ERROR",why) end
        end
    end
    busy=false
    if not ok then error(err,0) end
end
end
]=],
        ["throw"] = [=[
-- Adonis Hub / throw
return function(ctx)
local RunService = ctx.services.RunService
local cfg = ctx.cfg
local function cinemaPrompt(...) return ctx.cinemaPrompt(...) end
local function clickAt(...) return ctx.clickAt(...) end
local function doThrow(...) return ctx.doThrow(...) end
local function enterThrowArea(...) return ctx.enterThrowArea(...) end
local function find(...) return ctx.find(...) end
local function finishThrowCinema(...) return ctx.finishThrowCinema(...) end
local function move(...) return ctx.move(...) end
local function rootPart(...) return ctx.rootPart(...) end
local function say(...) return ctx.say(...) end
local function stopTraining(...) return ctx.stopTraining(...) end
local function ui(...) return ctx.ui(...) end
local function visible(...) return ctx.visible(...) end
local function waitFor(...) return ctx.waitFor(...) end

local walking
local function meterObject()
    local bar = ui("ThrowSequence.Meter.Bar")
    return visible(bar) and bar or nil
end
function ctx.cancelThrowApproach()
    local own = walking
    walking = nil
    -- Never send movement after the meter/cinema takes ownership.
    if own and own.root.Parent and not meterObject() and not cinemaPrompt() then
        pcall(function() own.humanoid:MoveTo(own.root.Position) end)
    end
end
function ctx.throwEntryDiagnostics()
    local s = ctx.state.throwEntryStats
    if not s then return {"No throw approach recorded"} end
    return {"phase=" .. s.phase .. " attempts=" .. s.attempts .. " commands=" .. s.commands
        .. " rebounds=" .. s.rebounds .. " meterDrops=" .. s.meterDrops .. " staged=" .. tostring(s.staged),
        "position=" .. tostring(s.position) .. " elapsed=" .. string.format("%.2f",(s.finished or os.clock())-s.started)}
end
function ctx.enterThrowArea(overallDeadline)
    if meterObject() then return "meter" end
    if cinemaPrompt() or ctx.state.cinemaPending then return "cinema" end
    local stats = {phase="prepare",attempts=0,commands=0,rebounds=0,meterDrops=0,
        staged=false,started=os.clock()}
    ctx.state.throwEntryStats = stats
    local deadline = math.min(overallDeadline or math.huge,os.clock()+40)
    local originalCharacter = ctx.player.Character
    local function guard()
        if not ctx.actionActive("Throw") then error("Throw stopped",0) end
        if ctx.player.Character ~= originalCharacter then error("Character changed during throw approach",0) end
        local root = rootPart()
        local humanoid = assert(root.Parent:FindFirstChildOfClass("Humanoid"),"Humanoid unavailable")
        stats.position = root.Position
        return root,humanoid
    end
    local function distance(a,b)
        local d = a-b
        return Vector2.new(d.X,d.Z).Magnitude
    end
    local function run()
        local root = guard()
        local line = find(workspace,"StarterArea.CrossLine")
        local lineZ = -40
        if line then
            local part = line:IsA("BasePart") and line or line:FindFirstChildWhichIsA("BasePart",true)
            if part then lineZ = part.Position.Z end
        end
        -- A saved point on the outer lip must still produce a real crossing.
        local target = Vector3.new(cfg.ThrowX,cfg.ThrowY,math.min(cfg.ThrowZ,lineZ-3))
        local approach = Vector3.new(target.X,target.Y,math.max(lineZ+7,target.Z+7))
        if distance(root.Position,approach)>20 or math.abs(root.Position.Y-approach.Y)>10 then
            say("Teleporting outside throw line...")
            move(approach,0)
            stats.staged = true
        end
        -- Reissue walking after corrections/cleared goals. Position alone is
        -- not acceptance: return only after a stable meter, never on arrival.
        local function walk(goal,outside,seconds)
            local untilAt = math.min(deadline,os.clock()+seconds)
            local lastCommand,lastDistance,arrivedAt,meterAt = -math.huge,nil,nil,nil
            local reboundLogged = false
            while os.clock()<untilAt do
                local part,humanoid = guard()
                if cinemaPrompt() or ctx.state.cinemaPending then walking=nil; return "cinema" end
                if meterObject() then
                    walking = nil
                    meterAt = meterAt or os.clock()
                    stats.phase = "confirm_meter"
                    if os.clock()-meterAt>=0.15 then return "meter" end
                else
                    if meterAt then
                        stats.meterDrops = stats.meterDrops+1
                        ctx.log("THROW_ENTRY_METER_LOST","Transient meter closed; recover in this approach")
                        meterAt,lastCommand,arrivedAt = nil,-math.huge,nil
                    end
                    local locked = part.Anchored or humanoid.PlatformStand or humanoid.Sit
                        or (type(humanoid.WalkSpeed)=="number" and humanoid.WalkSpeed<=0)
                    if locked then
                        stats.phase = "waiting_character"
                    else
                        stats.phase = outside and "walk_outside" or "walk_inside"
                        local d = distance(part.Position,goal)
                        if not outside and lastDistance and d>lastDistance+2 and not reboundLogged then
                            stats.rebounds = stats.rebounds+1; reboundLogged=true
                            ctx.log("THROW_ENTRY_REBOUND","attempt=" .. stats.attempts .. " position=" .. tostring(part.Position))
                            lastCommand = -math.huge
                        end
                        if d<=0.9 then
                            arrivedAt = arrivedAt or os.clock()
                            if outside and part.Position.Z>=lineZ+2 and os.clock()-arrivedAt>=0.15 then
                                walking=nil; return "outside"
                            end
                            if not outside and os.clock()-arrivedAt>=1.25 then return "retry" end
                        else arrivedAt=nil end
                        if os.clock()-lastCommand>=0.25 then
                            walking = {root=part,humanoid=humanoid}
                            humanoid:MoveTo(goal)
                            lastCommand = os.clock(); stats.commands=stats.commands+1
                        end
                        lastDistance = d
                    end
                end
                task.wait(0.05)
            end
            return "retry"
        end
        local needsOutside = not stats.staged and root.Position.Z<lineZ+1.5
        for attempt=1,5 do
            guard()
            if os.clock()>=deadline then break end
            stats.attempts = attempt
            if needsOutside or attempt>1 then
                ctx.log("THROW_ENTRY_RETRY","attempt=" .. attempt .. "; walk outside and cross again")
                local result = walk(approach,true,3.5)
                if result=="meter" or result=="cinema" then return result end
            end
            say(attempt==1 and "Walking to throw area..." or "Re-entering throw area (" .. attempt .. "/5)...")
            local result = walk(target,false,4.5)
            if result=="meter" or result=="cinema" then return result end
        end
        stats.phase = "timeout"
        ctx.log("THROW_ENTRY_TIMEOUT",table.concat(ctx.throwEntryDiagnostics()," | "))
        error("Throw area did not accept entry after bounded walking retries",0)
    end
    local ok,result = xpcall(run,debug.traceback)
    stats.finished = os.clock()
    if not ok then ctx.cancelThrowApproach(); error(result,0) end
    walking = nil
    stats.phase = result
    ctx.log("THROW_ENTRY_ACCEPTED",table.concat(ctx.throwEntryDiagnostics()," | "))
    return result
end
table.insert(ctx.disposers,ctx.cancelThrowApproach)
function ctx.doThrow()
    -- Allow START to finish an existing cinema after the old build timed out.
    if cinemaPrompt() then finishThrowCinema(); return end
    ctx.state.cinemaContinueSerial = 0
    ctx.state.cinemaInterrupted = false
    ctx.state.cinemaObserved = false
    stopTraining()
    if ctx.captureThrowView then ctx.captureThrowView() end
    local entryDeadline,tapped = os.clock()+45,false
    for timingAttempt=1,3 do
        local phase = enterThrowArea(entryDeadline)
        if phase=="cinema" then finishThrowCinema(); return end
        local bar = ui("ThrowSequence.Meter.Bar")
        say("Timing throw: waiting for +20...")
        local deadline = os.clock()+12
        while ctx.actionActive("Throw") and visible(bar) and os.clock()<deadline do
            local marker = bar:FindFirstChild("Marker")
            local value = marker and marker:FindFirstChild("Text")
            local bonus = value and tonumber(value.Text:match("%d+"))
            if bonus and bonus>=20 then
                if ctx.beginThrowPresentation then ctx.beginThrowPresentation() end
                -- The user wants to remain at the meter's throw-line view.
                if ctx.captureThrowView then ctx.captureThrowView(true) end
                local inset = game:GetService("GuiService"):GetGuiInset()
                local screen = bar:FindFirstAncestorOfClass("ScreenGui")
                local offset = screen and screen.IgnoreGuiInset and Vector2.new() or inset
                local x,y=bar.AbsolutePosition.X+bar.AbsoluteSize.X/2+offset.X,bar.AbsolutePosition.Y+bar.AbsoluteSize.Y/2+offset.Y
                if ctx.clearTapPoint then x,y=ctx.clearTapPoint(x,y) end
                assert(x,"No unobstructed screen point for Throw")
                clickAt(x,y)
                tapped = true
                break
            end
            RunService.RenderStepped:Wait()
        end
        if tapped then break end
        if not ctx.actionActive("Throw") then error("Throw stopped",0) end
        assert(not visible(bar),"No +20 detected; stop and finish throw manually")
        ctx.log("THROW_METER_RETRY","Meter closed before input; re-enter attempt=" .. timingAttempt)
        assert(os.clock()<entryDeadline,"Throw entry recovery timed out")
    end
    assert(tapped,"Throw meter kept closing before input; will retry next cycle")
    ctx.state.cinemaPending = true
    if not ctx.state.running then ctx.state.cinemaInterrupted = true end
    if ctx.updateThrowPresentation then ctx.updateThrowPresentation() end
    -- Meter objects can remain Visible underneath the cinematic overlay.
    -- Do not require them to disappear before handling Skip / Continue.
    finishThrowCinema()
end

end
]=],
        ["training"] = [=[
-- Adonis Hub / training
return function(ctx)
local cfg = ctx.cfg
local function click(...) return ctx.click(...) end
local function doTrain(...) return ctx.doTrain(...) end
local function find(...) return ctx.find(...) end
local function move(...) return ctx.move(...) end
local function pause(...) return ctx.pause(...) end
local function rootPart(...) return ctx.rootPart(...) end
local function say(...) return ctx.say(...) end
local function stopTraining(...) return ctx.stopTraining(...) end
local function training(...) return ctx.training(...) end
local function ui(...) return ctx.ui(...) end
local function visible(...) return ctx.visible(...) end
local function waitFor(...) return ctx.waitFor(...) end

function ctx.training() return visible(ui("TrainingSequence.Button")) end
function ctx.stopTraining()
    if training() then
        ctx.state.hubTraining=false
        click(ui("TrainingSequence.Button"))
        waitFor(function() return not training() end, 6)
        -- UI can disappear before the training animation releases the character.
        pause(os.clock()+0.8)
        waitFor(function() return not rootPart().Anchored end, 5)
    end
end
local lastTap=-math.huge
function ctx.tapTrainingBonus()
    if not ctx.actionActive("X2") or not training() then return end
    if ctx.state.cinemaPending or (ctx.cinemaPrompt and ctx.cinemaPrompt())
        or visible(ui("ThrowSequence.Meter.Bar")) then return end
    local bonus=ui("TrainingSequence.TapBonusLayer.TapBonus")
    if visible(bonus) and os.clock()-lastTap>0.6 then
        lastTap=os.clock()
        click(bonus)
    end
end
function ctx.doTrain(seconds)
    if not ctx.actionActive("Train") then return end
    say("Training...")
    local turn=ctx.cfg.AllInOne and ctx.state.allInOneTurn
    local deadline=turn and turn.trainDeadline
    if deadline and os.clock()>=deadline then return end
    local function enter(limit)
        if limit and os.clock()>=limit then return false end
        ctx.state.hubTraining=true
        if training() then return true end
        local spot = find(workspace, "LocalPlotProps.TrainingArea.TrainingSpot")
        assert(spot and spot:IsA("BasePart"), "Training spot not found")
        move(spot.Position + Vector3.new(0, 2.4, 0))
        waitFor(function() return training() or (limit and os.clock()>=limit) end, 8)
        if not training() then return false end
        say("Training...")
        return true
    end
    if not enter(deadline) then return end
    deadline=deadline or os.clock()+(seconds or cfg.TrainSeconds)
    if turn then turn.trainDeadline=deadline end
    while ctx.actionActive("Train") and os.clock() < deadline do
        if ctx.servicePurchases then ctx.servicePurchases() end
        if not ctx.actionActive("Train") or os.clock()>=deadline then break end
        if not training() and not enter(deadline) then break end
        assert(training(), "Training ended unexpectedly")
        ctx.tapTrainingBonus()
        task.wait(0.08)
    end
    if ctx.state.running then stopTraining() end
end

end
]=],
        ["ui"] = [=[
-- Native Adonis shell; actions and saved settings remain in controller.
return function(ctx)
local W,H,SIDE,LEFT,CW=840,600,208,232,584
-- Monochrome black surfaces; the user's original logo retains its own colors.
local C={base=Color3.fromRGB(0,0,0),side=Color3.fromRGB(5,5,5),card=Color3.fromRGB(17,17,17),
    line=Color3.fromRGB(55,55,55),text=Color3.fromRGB(245,245,245),muted=Color3.fromRGB(155,155,155),
    accent=Color3.fromRGB(245,245,245),selected=Color3.fromRGB(29,29,29),off=Color3.fromRGB(55,55,55),
    hover=Color3.fromRGB(26,26,26),on=Color3.fromRGB(18,18,18),hero=Color3.fromRGB(19,19,19)}
local animations={}
local cameraConnection
local function connect(signal,callback) table.insert(ctx.connections,signal:Connect(callback)) end
local function round(obj,r) Instance.new("UICorner",obj).CornerRadius=UDim.new(0,r) end
local function stroke(obj,alpha,color)
    local s=Instance.new("UIStroke",obj)
    s.Color,s.Transparency,s.Thickness,s.ApplyStrokeMode=color or C.line,alpha or 0.5,1,Enum.ApplyStrokeMode.Border
    return s
end
local function frame(parent,x,y,w,h,color)
    local o=Instance.new("Frame",parent)
    o.Position,o.Size=UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
    o.BorderSizePixel,o.BackgroundColor3=0,color or C.card
    return o
end
local function label(parent,text,x,y,w,h,size,color,bold)
    local o=Instance.new("TextLabel",parent)
    o.Position,o.Size=UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
    o.BackgroundTransparency,o.Text,o.TextSize,o.TextColor3=1,text,size or 16,color or C.text
    o.Font=bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans
    o.TextStrokeTransparency,o.RichText=1,false
    o.TextXAlignment,o.TextTruncate=Enum.TextXAlignment.Left,Enum.TextTruncate.AtEnd
    return o
end
local function animate(obj,goals,instant)
    local previous=animations[obj]
    if previous then previous:Cancel(); previous:Destroy(); animations[obj]=nil end
    if instant or not ctx.services.TweenService then
        for key,value in pairs(goals) do obj[key]=value end
    else
        local tween=ctx.services.TweenService:Create(obj,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goals)
        animations[obj]=tween; tween:Play()
    end
end
table.insert(ctx.disposers,function()
    if cameraConnection then cameraConnection:Disconnect() end
    for _,tween in pairs(animations) do tween:Cancel(); tween:Destroy() end
    animations={}
end)
local gui=Instance.new("ScreenGui")
ctx.view.gui=gui
-- Register the shell before later construction so partial failures also unload.
gui.Name,gui.ResetOnSpawn,gui.IgnoreGuiInset,gui.DisplayOrder="AdonisHub",false,true,100000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local hosts={}
if type(gethui)=="function" then
    local ok,host=pcall(gethui)
    if ok and typeof(host)=="Instance" then hosts[#hosts+1]=host end
end
hosts[#hosts+1]=game:GetService("CoreGui"); hosts[#hosts+1]=ctx.pg
for _,host in ipairs(hosts) do if pcall(function() gui.Parent=host end) and gui.Parent==host then break end end
local panel=Instance.new("Frame",gui)
ctx.view.panel=panel
panel.Name,panel.Size,panel.BackgroundColor3,panel.BorderSizePixel="Menu",UDim2.fromOffset(W,H),C.base,0
panel.BackgroundTransparency=0.25
panel.ClipsDescendants=true
round(panel,18); stroke(panel,0.3)
local scale=Instance.new("UIScale",panel); scale.Scale=1
local top=frame(panel,0,0,W,64,C.base); top.BackgroundTransparency=0.6; round(top,18)
frame(top,0,46,W,18,C.base).BackgroundTransparency=1
frame(panel,0,64,W,1,C.line).BackgroundTransparency=0.65
local side=frame(panel,0,65,SIDE,H-65,C.side); side.BackgroundTransparency=0.6; round(side,18)
frame(side,SIDE-18,0,18,H-65,C.side).BackgroundTransparency=1
frame(panel,SIDE,82,1,H-110,C.line).BackgroundTransparency=0.65
local logoAspect=192/151
local markWidth,markHeight=44*logoAspect,44
local mark=frame(panel,16,10,markWidth,markHeight,C.base); mark.BackgroundTransparency=1; mark.ClipsDescendants=true; round(mark,12)
local a=label(mark,"A",0,0,markWidth,markHeight,26,C.text,true); a.TextXAlignment=Enum.TextXAlignment.Center
local logo=Instance.new("ImageLabel",mark)
logo.Name,logo.Size,logo.BackgroundTransparency,logo.ScaleType="BrandLogo",UDim2.new(1,0,1,0),1,Enum.ScaleType.Fit
logo.Image=ctx.brandLogo or ""; logo.Visible=logo.Image~=""; a.Visible=not logo.Visible; round(logo,12)
local title=label(panel,"Adonis HUB",82,7,250,29,23,C.text,true)
local subtitle=label(panel,"Throw Food For Animals",83,35,166,20,13,C.muted)
subtitle.TextTruncate=Enum.TextTruncate.None
local version=frame(panel,231,35,46,20,C.card); version.BackgroundTransparency=0.4; round(version,10); stroke(version,0.15)
local versionText=label(version,"v1.1",0,0,46,20,11,C.text,true); versionText.TextXAlignment=Enum.TextXAlignment.Center
version.Name="VersionBadge"
local subtitleWidth
local function fitVersion()
    local bounds=subtitle.TextBounds
    local width=bounds and bounds.X and bounds.X>0 and math.ceil(bounds.X) or 166
    if subtitleWidth~=width then subtitleWidth=width; subtitle.Size=UDim2.fromOffset(width,20) end
    version.Position=UDim2.fromOffset(83+width+6,35)
end
connect(subtitle:GetPropertyChangedSignal("TextBounds"),fitVersion); fitVersion()
local profile=frame(panel,16,500,176,70,C.card); profile.BackgroundTransparency=0.45; round(profile,16); stroke(profile,0.65)
local user=ctx.player
local display=user.DisplayName or user.Name
local avatarTile=frame(profile,10,14,38,38,C.selected); round(avatarTile,21)
local initial=label(avatarTile,display:sub(1,1):upper(),0,0,38,38,18,C.text,true)
initial.TextXAlignment=Enum.TextXAlignment.Center
local avatar=Instance.new("ImageLabel",avatarTile)
avatar.Name,avatar.Size,avatar.BackgroundTransparency="Avatar",UDim2.fromOffset(38,38),1; round(avatar,21)
local id=tonumber(user.UserId)
avatar.Image=id and id>0 and ("rbxthumb://type=AvatarHeadShot&id="..id.."&w=150&h=150") or ""
label(profile,display,58,14,108,22,14,C.text,true)
label(profile,"@"..user.Name,58,37,108,19,12,C.muted)
label(panel,"WORKSPACE",28,142,180,20,10,C.muted,true)
local pageTitle=label(panel,"Main Farm",LEFT+22,75,CW-30,25,19,C.text,true)
label(panel,"+",LEFT,75,20,25,23,C.text,true)
local pages,navs,indicators,navVisuals={},{},{},{}
local statusDot=frame(panel,LEFT,580,5,5,C.muted); round(statusDot,3)
local status=label(panel,"Ready. Turn On A Feature.",LEFT+14,564,CW-115,32,13,C.muted)
status.TextWrapped=true; status.TextTruncate=Enum.TextTruncate.None
local activity=label(panel,"Standby",W-102,570,78,22,12,C.muted,true)
activity.TextXAlignment=Enum.TextXAlignment.Right
label(panel,"Right Shift · Menu",20,578,180,18,12,C.muted)
ctx.view.gui,ctx.view.panel,ctx.view.title,ctx.view.status=gui,panel,title,status
ctx.view.pages,ctx.view.controls,ctx.view.toggleVisuals=pages,{},{}
ctx.view.logo,ctx.view.subtitle,ctx.view.version,ctx.view.versionText=logo,subtitle,version,versionText
ctx.view.avatar,ctx.view.profile,ctx.view.menuOpen=avatar,profile,true
ctx.view.activity,ctx.view.statusDot=activity,statusDot
ctx.view.menuMetrics={width=W,height=H,contentWidth=CW,pageHeight=444}
function ctx.refreshMenuState()
    local active=ctx.state.running==true
    activity.Text=active and "Active" or "Standby"
    animate(activity,{TextColor3=active and C.accent or C.muted})
    animate(statusDot,{BackgroundColor3=active and C.accent or C.muted})
end
function ctx.button(text,x,y,width,callback,parent,composite)
    local b=Instance.new(composite and "ImageButton" or "TextButton",parent or panel)
    b.Name,b.Position,b.Size=text,UDim2.fromOffset(x,y),UDim2.fromOffset(width,34)
    b.BackgroundColor3,b.BorderSizePixel,b.AutoButtonColor=C.card,0,false
    b.BackgroundTransparency=0.42
    if composite then b.Image="" else
        b.Text,b.TextSize,b.Font,b.TextColor3=text,16,Enum.Font.BuilderSansMedium,C.text
        b.TextStrokeTransparency,b.TextXAlignment=1,Enum.TextXAlignment.Center
    end
    round(b,8)
    connect(b.Activated,function()
        ctx.log("CONTROL",text)
        local ok,err=xpcall(callback,debug.traceback)
        if not ok then ctx.log("CALLBACK_ERROR",err) end
    end)
    return b
end
function ctx.textLabel(text,y,height) return label(panel,text,LEFT,y,CW,height or 24,15,C.muted) end
function ctx.say(text)
    status.Text=text; ctx.refreshMenuState()
    ctx.log("STATUS",text); print("[Adonis Hub] "..text)
end
local function glyph(parent,index)
    local lines={}
    local function line(x,y,w,h,r)
        local o=frame(parent,x,y,w,h,C.muted)
        if r then o.Rotation=r end
        round(o,1); lines[#lines+1]=o
    end
    if index==1 then
        line(0,10,3,8); line(7,3,3,15); line(14,7,3,11)
    elseif index==2 then
        line(8,1,2,16); line(3,4,8,2,-45); line(8,4,8,2,45); line(1,18,16,2)
    elseif index==3 then
        line(1,4,16,2); line(1,4,2,13); line(15,4,2,13); line(1,16,16,2); line(6,1,6,2)
    else
        for i,x in ipairs({4,11,7}) do line(0,(i-1)*7+3,18,1); line(x,(i-1)*7,3,7) end
    end
    return lines
end
function ctx.selectMenuTab(name,instant)
    if not pages[name] then return end
    ctx.view.activeTab=name; pageTitle.Text=name
    for key,page in pairs(pages) do
        local selected=key==name
        local v=navVisuals[key]
        page.Visible=selected; indicators[key].Visible=selected
        animate(navs[key],{BackgroundTransparency=selected and 0.35 or 1},instant)
        animate(v.label,{TextColor3=selected and C.text or C.muted},instant)
        for _,line in ipairs(v.lines) do animate(line,{BackgroundColor3=selected and C.accent or C.muted},instant) end
    end
end
for index,name in ipairs({"Main Farm","Upgrade","Auto Sell","Setting"}) do
    local page=Instance.new("ScrollingFrame",panel)
    page.Name,page.Position,page.Size=name,UDim2.fromOffset(LEFT,106),UDim2.fromOffset(CW,444)
    page.BackgroundTransparency,page.BorderSizePixel,page.ScrollBarThickness=1,0,3
    page.ScrollBarImageColor3=C.line; page.ScrollingDirection=Enum.ScrollingDirection.Y
    page.CanvasSize=UDim2.fromOffset(0,0); page.ClipsDescendants=true; pages[name]=page
    local tab=ctx.button(name,16,105+(index-1)*56,176,function() ctx.selectMenuTab(name) end,side,true)
    tab.Size,tab.BackgroundColor3=UDim2.fromOffset(176,46),C.selected; round(tab,18)
    local caption=label(tab,name,46,0,120,46,16,C.text,true)
    local icon=frame(tab,16,15,20,20); icon.BackgroundTransparency=1
    local lines=glyph(icon,index)
    local marker=frame(tab,0,16,3,18,C.accent); round(marker,2)
    navs[name],indicators[name]=tab,marker
    navVisuals[name]={label=caption,lines=lines,index=index}
    connect(tab.MouseEnter,function()
        if ctx.view.activeTab~=name then animate(tab,{BackgroundTransparency=0.6}) end
    end)
    connect(tab.MouseLeave,function()
        if ctx.view.activeTab~=name then animate(tab,{BackgroundTransparency=1}) end
    end)
end
local searchFrame=frame(panel,16,88,176,44,C.card); searchFrame.BackgroundTransparency=0.45; round(searchFrame,12); stroke(searchFrame,0.55)
local lens=frame(searchFrame,14,13,15,15,C.card); lens.BackgroundTransparency=1; round(lens,8); stroke(lens,0.05,C.muted)
local stem=frame(searchFrame,27,26,7,2,C.muted); stem.Rotation=45
local search=Instance.new("TextBox",searchFrame)
search.Name,search.Position,search.Size="FeatureSearch",UDim2.fromOffset(42,0),UDim2.fromOffset(124,44)
search.BackgroundTransparency,search.BorderSizePixel,search.Text,search.PlaceholderText=1,0,"","Search Features"
search.TextSize,search.Font,search.TextColor3,search.PlaceholderColor3=14,Enum.Font.BuilderSans,C.text,C.muted
search.TextXAlignment,search.TextStrokeTransparency,search.ClearTextOnFocus=Enum.TextXAlignment.Left,1,false
ctx.view.search=search
connect(search.FocusLost,function(enter)
    if not enter then return end
    local q=search.Text:lower():match("^%s*(.-)%s*$"); if q=="" then return end
    for _,name in ipairs({"Main Farm","Upgrade","Auto Sell","Setting"}) do
        if name:lower():find(q,1,true) then ctx.selectMenuTab(name); return end
    end
    for button,v in pairs(ctx.view.toggleVisuals) do
        if v.label.Text:lower():find(q,1,true) then ctx.selectMenuTab(button.Parent.Name); return end
    end
end)
ctx.view.navigation=navs
local launcherWidth,launcherHeight=52*logoAspect,52
local reopen=ctx.button("Open Adonis HUB",18,18,launcherWidth,function()
    if not ctx.view.launcherDrag or not ctx.view.launcherDrag.suppressClick then ctx.setMenuVisible(true) end
end,gui,true)
reopen.Name,reopen.Visible="OpenMenu",false; reopen.Size=UDim2.fromOffset(launcherWidth,launcherHeight)
reopen.BackgroundTransparency,reopen.ClipsDescendants=1,true; round(reopen,12)
local launcherBorder=stroke(reopen,0.12,Color3.fromRGB(255,255,255))
launcherBorder.Thickness=2
local launcherHighlight=Instance.new("UIGradient",launcherBorder)
launcherHighlight.Name,launcherHighlight.Rotation="BlueHighlight",0
launcherHighlight.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(12,38,78)),
    ColorSequenceKeypoint.new(0.55,Color3.fromRGB(20,72,150)),
    ColorSequenceKeypoint.new(0.8,Color3.fromRGB(32,144,255)),
    ColorSequenceKeypoint.new(0.94,Color3.fromRGB(116,226,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(50,169,255))})
launcherHighlight.Enabled=false
local highlightTween
local function stopHighlight()
    if highlightTween then highlightTween:Cancel(); highlightTween:Destroy(); highlightTween=nil end
    launcherHighlight.Enabled=false
end
local function updateHighlight()
    if not ctx.state.alive or not reopen.Visible then stopHighlight(); return end
    if highlightTween then return end
    launcherHighlight.Enabled=true
    launcherHighlight.Rotation=0
    if ctx.services.TweenService then
        highlightTween=ctx.services.TweenService:Create(launcherHighlight,
            TweenInfo.new(2.4,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360})
        highlightTween:Play()
    end
end
table.insert(ctx.disposers,stopHighlight)
local launcherInitial=label(reopen,"A",0,0,launcherWidth,launcherHeight,26,C.text,true); launcherInitial.TextXAlignment=Enum.TextXAlignment.Center
local launcherLogo=Instance.new("ImageLabel",reopen)
launcherLogo.Name,launcherLogo.Size,launcherLogo.BackgroundTransparency,launcherLogo.ScaleType="BrandLogo",UDim2.new(1,0,1,0),1,Enum.ScaleType.Fit
launcherLogo.Image=ctx.brandLogo or ""; launcherLogo.Visible=launcherLogo.Image~=""; launcherInitial.Visible=not launcherLogo.Visible
round(launcherLogo,12)
ctx.view.reopen,ctx.view.reopenLogo=reopen,launcherLogo
ctx.view.launcherHighlight,ctx.view.launcherBorder=launcherHighlight,launcherBorder
connect(reopen.MouseEnter,function() animate(launcherBorder,{Transparency=0.02}) end)
connect(reopen.MouseLeave,function() animate(launcherBorder,{Transparency=0.12}) end)
function ctx.positionLauncher(x,y)
    local camera=workspace.CurrentCamera
    if not camera then return end
    local size=camera.ViewportSize
    reopen.Position=UDim2.fromOffset(math.floor(math.clamp(x,4,math.max(4,size.X-launcherWidth-4))),
        math.floor(math.clamp(y,4,math.max(4,size.Y-launcherHeight-4))))
end
function ctx.setMenuVisible(open)
    if not ctx.state.alive then return end
    if not open and ctx.view.dragState then ctx.view.dragState.active=false end
    if ctx.view.launcherDrag then ctx.view.launcherDrag.active=false end
    ctx.view.menuOpen=open==true; panel.Visible=ctx.view.menuOpen; reopen.Visible=not ctx.view.menuOpen
    updateHighlight()
end
function ctx.toggleMenu() ctx.setMenuVisible(not ctx.view.menuOpen) end
local close=ctx.button("×",W-56,16,30,function() ctx.setMenuVisible(false) end)
close.Name,close.TextSize="CloseMenu",21
local minimize=ctx.button("–",W-96,16,30,function() ctx.setMenuVisible(false) end)
minimize.Name,minimize.TextSize="MinimizeMenu",17
for _,b in ipairs({close,minimize}) do
    b.Size,b.ZIndex=UDim2.fromOffset(30,30),22
    connect(b.MouseEnter,function() animate(b,{BackgroundColor3=C.hover,TextColor3=C.accent}) end)
    connect(b.MouseLeave,function() animate(b,{BackgroundColor3=C.card,TextColor3=C.text}) end)
end
local header=Instance.new("TextButton",panel)
header.Name,header.Text,header.Size="DragHeader","",UDim2.fromOffset(W,64)
header.BackgroundTransparency,header.BorderSizePixel,header.AutoButtonColor,header.ZIndex,header.Active=1,0,false,20,true
ctx.view.dragHeader,ctx.view.close,ctx.view.minimize=header,close,minimize
local function paintToggle(b,instant)
    local v=ctx.view.toggleVisuals[b]
    animate(b,{BackgroundColor3=v.on and C.on or (v.hovered and C.hover or (v.hero and C.hero or C.card))},instant)
    animate(v.border,{Color=v.on and C.accent or C.line,Transparency=v.on and 0.45 or (v.hovered and 0.2 or 0.65)},instant)
end
function ctx.addToggle(text,description,parent,y,callback,layout)
    local o=layout or {}; local width,height=o.width or CW-8,o.height or 62
    local b=ctx.button(text,o.x or 4,y+2,width,callback,parent,true)
    b.Size=UDim2.fromOffset(width,height); b.BackgroundColor3=description and C.hero or C.card; b.BackgroundTransparency=0.42; round(b,18)
    local border=stroke(b,0.6)
    local hero=description~=nil
    local caption=label(b,text,18,hero and 10 or 0,width-100,hero and 30 or height,hero and 18 or 16,C.text,true)
    if hero then
        local desc=label(b,description,18,44,width-36,height-48,13,C.muted)
        desc.TextWrapped,desc.TextTruncate=true,Enum.TextTruncate.None
    end
    local track=frame(b,width-66,hero and 14 or math.floor((height-25)/2),46,25,C.off); round(track,12)
    local thumb=frame(track,4,4,17,17,C.text); round(thumb,9)
    ctx.view.toggleVisuals[b]={track=track,thumb=thumb,label=caption,border=border,hero=hero,on=false,hovered=false}
    connect(b.MouseEnter,function() ctx.view.toggleVisuals[b].hovered=true; paintToggle(b) end)
    connect(b.MouseLeave,function() ctx.view.toggleVisuals[b].hovered=false; paintToggle(b) end)
    return b
end
function ctx.refreshToggle(button,on,instant)
    local v=ctx.view.toggleVisuals[button]; v.on=on==true
    animate(v.track,{BackgroundColor3=on and C.accent or C.off},instant)
    animate(v.thumb,{Position=UDim2.fromOffset(on and 25 or 4,4),BackgroundColor3=on and C.base or C.text},instant)
    paintToggle(button,instant)
end
function ctx.addSection(text,parent,y)
    local section=frame(parent,0,y,CW,24,C.base); section.BackgroundTransparency=1; section.Name="Section"
    local line=frame(section,0,12,CW,1,C.line); line.BackgroundTransparency=0.5
    local w=math.min(CW-24,#text*8+28)
    local pill=frame(section,(CW-w)/2,0,w,24,C.base); pill.BackgroundTransparency=0.55; round(pill,10)
    local caption=label(pill,text,0,0,w,24,12,C.muted); caption.TextXAlignment=Enum.TextXAlignment.Center
    return section
end
function ctx.addInfo(titleText,text,parent,y,height)
    local card=frame(parent,0,y,CW,height or 82,C.card); card.BackgroundTransparency=0.42; round(card,10)
    return card,label(card,titleText,16,8,CW-32,24,17,C.text,true),label(card,text,16,34,CW-32,(height or 82)-40,13,C.muted)
end
function ctx.addNumber(text,description,parent,y,value,layout)
    local o=layout or {}; local width,height=o.width or CW,o.height or 76
    local card=frame(parent,o.x or 0,y,width,height,C.card); card.BackgroundTransparency=0.42; round(card,18)
    local border=stroke(card,0.6)
    label(card,text,16,5,width-32,20,12,C.muted)
    local box=Instance.new("TextBox",card)
    box.Position,box.Size=UDim2.fromOffset(16,height-31),UDim2.fromOffset(width-32,26)
    box.BackgroundTransparency,box.TextColor3,box.BorderSizePixel=1,C.text,0
    box.Text,box.TextSize,box.Font=tostring(value),22,Enum.Font.BuilderSansMedium
    box.TextXAlignment,box.TextStrokeTransparency,box.ClearTextOnFocus=Enum.TextXAlignment.Left,1,false
    connect(box.Focused,function() animate(border,{Color=C.accent,Transparency=0.25}) end)
    connect(box.FocusLost,function() animate(border,{Color=C.line,Transparency=0.6}) end)
    ctx.view.numberVisuals=ctx.view.numberVisuals or {}
    ctx.view.numberVisuals[box]={border=border}
    return box
end
local lastX,lastY
local function fit()
    local camera=workspace.CurrentCamera; if not camera then return end
    local size=camera.ViewportSize; if size.X==lastX and size.Y==lastY then return end
    lastX,lastY=size.X,size.Y
    scale.Scale=math.clamp(math.min(1,(size.X-48)/W,(size.Y-48)/H),0.3,1)
    panel.Position=UDim2.fromOffset(math.floor(math.max(16,(size.X-W*scale.Scale)/2)+0.5),math.floor(math.max(16,(size.Y-H*scale.Scale)/2)+0.5))
    local p=reopen.Position
    ctx.positionLauncher(p.X.Scale*size.X+p.X.Offset,p.Y.Scale*size.Y+p.Y.Offset)
end
local function watchCamera()
    if cameraConnection then cameraConnection:Disconnect(); cameraConnection=nil end
    local camera=workspace.CurrentCamera
    if camera and type(camera.GetPropertyChangedSignal)=="function" then cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
    fit()
end
if type(workspace.GetPropertyChangedSignal)=="function" then connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera) end
watchCamera(); ctx.view.menuScale=scale
ctx.selectMenuTab("Main Farm",true)
end
]=],
        ["upgrade"] = [=[
-- Adonis Hub / upgrade
return function(ctx)
local lastSkip
local lastSkipAt = -math.huge
local attemptedPart,attemptedPrice,attemptedUntil
local function skip(reason)
    if reason ~= lastSkip or os.clock()-lastSkipAt >= 60 then
        ctx.log("UPGRADE_SKIP", reason); lastSkip,lastSkipAt = reason,os.clock()
    end
end
local function active()
    return ctx.actionActive("Upgrade")
        and not ctx.state.cinemaPending and not ctx.cinemaPrompt()
end
-- Currency text is observed on the local training sign. Attribute names/cost
-- formulas are not established, so do not invent a server-side price source.
function ctx.upgradeDiagnostics()
    local lines = {}
    local area = ctx.find(workspace,"LocalPlotProps.TrainingArea")
    for _, line in ipairs(ctx.dataSample(area,6)) do table.insert(lines,line) end
    for _, gui in ipairs(ctx.attachedGuis(area)) do
        for _, line in ipairs(ctx.dataSample(gui,6)) do
            table.insert(lines,line)
            if #lines >= 12 then break end
        end
        if #lines >= 12 then break end
    end
    for _, line in ipairs(ctx.worldGuiSample(4)) do table.insert(lines,line) end
    return lines
end
function ctx.trainingUpgradeQuote()
    local area = ctx.find(workspace, "LocalPlotProps.TrainingArea")
    local spot = area and area:FindFirstChild("TrainingSpot")
    local part = spot and spot:FindFirstChild("UpgradeButton")
    local prompt = part and part:FindFirstChildOfClass("ProximityPrompt")
    if not (part and part:IsA("BasePart") and prompt and prompt.Enabled) then
        return nil, "Training upgrade prompt unavailable or disabled"
    end
    local function priceIn(scopes)
        local price, source, ambiguous
        for _, scope in ipairs(scopes) do
            for _, obj in ipairs(scope:GetDescendants()) do
                -- Hidden price data is useful; the button still requires its prompt.
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local value = ctx.currencyAmount(obj.Text)
                    if value and value >= 0 and value < math.huge then
                        if price and value ~= price then ambiguous = true end
                        price, source = value, obj:GetFullName()
                    end
                end
            end
        end
        return price,source,ambiguous
    end
    for _, scope in ipairs({part, spot, area}) do
        local price, source, ambiguous = priceIn({scope})
        if ambiguous then return nil, "Multiple different training prices; cannot select a reliable upgrade cost" end
        if price then return {part=part, prompt=prompt, price=price, source=source} end
    end
    -- A PlayerGui BillboardGui/SurfaceGui may Adorn the training area. Never
    -- select another player's sign or an unrelated price based on its name.
    local price, source, ambiguous = priceIn(ctx.attachedGuis(area))
    if ambiguous then return nil,"Multiple attached training prices; cannot choose a cost" end
    if price then return {part=part,prompt=prompt,price=price,source=source} end
    for _, key in ipairs({"ActionText","ObjectText"}) do
        local value = ctx.currencyAmount(prompt[key] or "")
        if value then return {part=part,prompt=prompt,price=value,source=prompt:GetFullName() .. "." .. key} end
    end
    return nil, "No readable dollar price on the local training sign"
end
local function affordable()
    local quote, reason = ctx.trainingUpgradeQuote()
    if not quote then return nil, reason, "quote" end
    local cash = ctx.money()
    if not cash then return nil, "Cannot read money; no teleport", "money" end
    if cash < quote.price then
        return nil, "Not enough money: cash=" .. cash .. " price=" .. quote.price, "funds"
    end
    return quote
end
function ctx.trainingUpgradeReady()
    local quote=affordable()
    return quote and not (quote.part==attemptedPart and quote.price==attemptedPrice
        and os.clock()<(attemptedUntil or 0)) or false
end
function ctx.doUpgrade()
    if not active() then return end
    local quote, reason, issue = affordable()
    if not quote then
        skip(reason)
        if issue ~= "funds" then ctx.dataIssue("upgrade",reason,ctx.upgradeDiagnostics) end
        return
    end
    if not ctx.trainingUpgradeReady() then return end
    ctx.say("Training upgrade affordable; approaching...")
    ctx.closeAnimals()
    ctx.stopTraining()
    if not active() then return end
    -- Preparatory UI actions can yield: check the latest balance before moving.
    quote, reason = affordable()
    if not quote then skip(reason); return end
    ctx.log("UPGRADE_AFFORDABLE", "price=" .. quote.price .. " source=" .. quote.source)
    ctx.move(quote.part.Position+Vector3.new(0, 2.4, 3))
    if not active() then return end
    local current
    current, reason = affordable()
    if not current or current.part ~= quote.part then skip(reason or "Upgrade location changed"); return end
    lastSkip = nil
    -- Tap E once, only after a fresh affordability check at the pad.
    ctx.log("UPGRADE_PROMPT", "before=" .. current.prompt.ObjectText .. " price=" .. current.price)
    attemptedPart,attemptedPrice,attemptedUntil=current.part,current.price,os.clock()+30
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    ctx.pause(os.clock()+0.6)
    ctx.log("UPGRADE_RESULT", "after=" .. current.prompt.ObjectText .. " money=" .. tostring(ctx.money())
        .. " (input sent; purchase not confirmed)")
end
end
]=],
        ["utilities"] = [=[
-- Adonis Hub / utilities
return function(ctx)
local player = ctx.player
local pg = ctx.pg
local function amount(...) return ctx.amount(...) end
local function click(...) return ctx.click(...) end
local function closeAnimals(...) return ctx.closeAnimals(...) end
local function find(...) return ctx.find(...) end
local function log(...) return ctx.log(...) end
local function money(...) return ctx.money(...) end
local function onScreen(...) return ctx.onScreen(...) end
local function pause(...) return ctx.pause(...) end
local function rootPart(...) return ctx.rootPart(...) end
local function ui(...) return ctx.ui(...) end
local function visible(...) return ctx.visible(...) end
local function waitFor(...) return ctx.waitFor(...) end

local allInOneFeatures={Train=true,X2=true,Throw=true}
function ctx.featureEnabled(name)
    local cfg=ctx.cfg or {}
    return cfg[name]==true or (cfg.AllInOne==true and allInOneFeatures[name]==true)
end
function ctx.actionActive(name)
    return ctx.state.alive and ctx.state.running and ctx.featureEnabled(name)
        and not (name=="Sell" and ctx.purchaseInterruptReady and ctx.purchaseInterruptReady())
        and not (ctx.state.actionFeature==name and ctx.state.actionRevision~=ctx.state.controlRevision)
end
function ctx.checkAction()
    assert(ctx.state.alive and ctx.state.running,"Stopped")
    local name=ctx.state.actionFeature
    if name and not ctx.state.cinemaPending then assert(ctx.actionActive(name),"Action changed") end
end

function ctx.find(root, dotted)
    for name in dotted:gmatch("[^.]+") do
        root = root and root:FindFirstChild(name)
        if not root then return nil end
    end
    return root
end
function ctx.ui(path) return find(pg, path) end
function ctx.visible(obj)
    if not obj then return false end
    while obj and obj ~= pg do
        if obj:IsA("GuiObject") and not obj.Visible then return false end
        if obj:IsA("ScreenGui") and not obj.Enabled then return false end
        obj = obj.Parent
    end
    return true
end
function ctx.rootPart()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    assert(hum and hum.Health > 0, "Character unavailable")
    return assert(char:FindFirstChild("HumanoidRootPart"), "Character root unavailable")
end
function ctx.waitFor(fn, seconds)
    local deadline = os.clock() + seconds
    repeat
        ctx.checkAction()
        local result = fn()
        if result then return result end
        task.wait(0.05)
    until os.clock() >= deadline
    error("Timed out: " .. ctx.view.status.Text, 0)
end
function ctx.pause(seconds)
    waitFor(function() return os.clock() >= seconds end, math.max(0.1, seconds-os.clock()+1))
end
function ctx.onScreen(obj)
    if not visible(obj) then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local p, s = obj.AbsolutePosition, obj.AbsoluteSize
    return s.X > 0 and s.Y > 0 and p.X+s.X > 0 and p.Y+s.Y > 0
        and p.X < cam.ViewportSize.X and p.Y < cam.ViewportSize.Y
end
function ctx.closeAnimals()
    local equipPath = "AnimalsPanelGui.AnimalsPanel.Body.Content.EquipBest"
    if not onScreen(ui(equipPath)) then return end
    for attempt = 1, 2 do
        local close = ui("AnimalsPanelGui.AnimalsPanel.Body.Header.CloseButton")
        assert(close, "Animals CloseButton not found")
        click(close)
        local deadline = os.clock()+2
        repeat
            pause(os.clock()+0.1)
            if not onScreen(ui(equipPath)) then return end
        until os.clock() > deadline
        log("CLOSE_RETRY", "My Animals attempt=" .. attempt)
    end
    error("My Animals did not close", 0)
end
-- Explicit short-scale suffixes; unknown formats remain unknown, never zero.
local suffix = {k=1e3,m=1e6,b=1e9,t=1e12,qa=1e15,qi=1e18,sx=1e21,sp=1e24,
    oc=1e27,no=1e30,dc=1e33,ud=1e36,dd=1e39,td=1e42,qad=1e45,qid=1e48,
    sxd=1e51,spd=1e54,ocd=1e57,nod=1e60,vg=1e63}
function ctx.plainText(str)
    return str:gsub("<[^>]*>", ""):gsub("\194\160", " "):gsub("\226\128\175", " ")
end
function ctx.amount(str)
    str = ctx.plainText(str):gsub(",", "")
    local start, finish, n = str:find("(%d+%.?%d*)")
    if not n or str:sub(1,start-1):match("%-%s*$") then return nil end
    local rest = str:sub(finish+1)
    if rest:match("^%.%d") then return nil end
    local exponent = rest:match("^([eE][%+%-]?%d+)")
    if exponent then n = n .. exponent; rest = rest:sub(#exponent+1) end
    local s = rest:match("^%s*([%a]*)"):lower()
    if (s ~= "" and not suffix[s]) or (exponent and s ~= "") then return nil end
    local value = tonumber(n)
    value = value and value*(suffix[s] or 1)
    return value and value == value and value < math.huge and value or nil
end
function ctx.currencyAmount(str)
    local text = ctx.plainText(str)
    local at = text:find("$",1,true)
    if not at or not text:sub(at+1):match("^%s*%d") then return nil end
    return amount(text:sub(at+1))
end
function ctx.rateAmount(str)
    local text = ctx.plainText(str)
    if not text:lower():match("/%s*s") then return nil end
    if text:find("$",1,true) then return ctx.currencyAmount(text) end
    return amount(text)
end

-- Price signs may be PlayerGui billboards adorning world parts, rather than
-- descendants of the world part. Index GUI hosts once and maintain by events.
local worldGuis = {}
local function indexGui(obj)
    if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then worldGuis[obj] = true end
end
if pg and ctx.connections then
    for _, obj in ipairs(pg:GetDescendants()) do indexGui(obj) end
    table.insert(ctx.connections, pg.DescendantAdded:Connect(indexGui))
    table.insert(ctx.connections, pg.DescendantRemoving:Connect(function(obj) worldGuis[obj] = nil end))
end
function ctx.attachedGuis(target)
    local result = {}
    if not target then return result end
    for gui in pairs(worldGuis) do
        if gui.Parent then
            local anchor = gui.Adornee
            while anchor do
                if anchor == target then table.insert(result,gui); break end
                anchor = anchor.Parent
            end
        end
    end
    return result
end
function ctx.dataSample(root, limit)
    local result = {}
    if not root then return {"missing root"} end
    local objects = {root}
    for _, obj in ipairs(root:GetDescendants()) do table.insert(objects,obj) end
    for _, obj in ipairs(objects) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.Text ~= "" then
                table.insert(result,obj:GetFullName() .. " text=" .. string.format("%q",obj.Text:sub(1,180)))
            end
        end
        if #result >= limit then break end
    end
    return result
end
function ctx.worldGuiSample(limit)
    local result = {}
    for gui in pairs(worldGuis) do
        if gui.Parent then
            local anchor = gui.Adornee
            table.insert(result,gui:GetFullName() .. " adornee=" .. (anchor and anchor:GetFullName() or "nil"))
            if #result >= limit then break end
        end
    end
    return result
end
local reportedData = {}
function ctx.dataIssue(feature, reason, details)
    -- Small once-per-feature evidence, never recurring full-tree dumps or writes.
    if reportedData[feature] or not ctx.log then return end
    reportedData[feature] = true
    ctx.log("DATA_ISSUE",feature .. ": " .. reason)
    if details then
        local ok, lines = pcall(details)
        if ok then
            for i=1,math.min(16,#lines) do ctx.log("DATA_RAW",feature .. " " .. lines[i]) end
        else ctx.log("DATA_RAW",feature .. " diagnostic failed: " .. tostring(lines)) end
    end
end
function ctx.money()
    local l = ui("StatsGui.Container.MoneyDisplay.ValueLabel")
    local value = l and (ctx.currencyAmount(l.Text) or amount(l.Text))
    if not value then
        ctx.dataIssue("money","Unreadable money label",function()
            return {l and l:GetFullName() .. " text=" .. string.format("%q",l.Text) or "Money label missing"}
        end)
    end
    return value
end

end
]=],
    }
    local loaded = {}
    local function loadModule(name)
        if loaded[name] then return loaded[name] end
        local source = assert(sources[name], "Missing Adonis module: " .. name)
        local chunk, err = loadstring(source, "@AdonisHub/src/modules/" .. name .. ".lua")
        assert(chunk, err)
        local init = chunk()
        assert(type(init) == "function", "Module must return initializer: " .. name)
        loaded[name], sources[name] = init, nil
        return init
    end
    local mainChunk, err = loadstring([=[
-- Initializes feature modules. The build embeds their sources in the executable.
return function(loadModule)
    assert(game.PlaceId == 120219252362013, "Adonis Hub: wrong game")
    local services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UIS = game:GetService("UserInputService"),
        Http = game:GetService("HttpService"),
        Lighting = game:GetService("Lighting"),
        TweenService = game:GetService("TweenService"),
    }
    local env = type(getgenv) == "function" and getgenv() or _G
    local previous = env.AdonisHub
    if previous and type(previous.Unload) == "function" then
        local ok, err = pcall(previous.Unload)
        assert(ok, "Adonis Hub: previous instance did not unload: " .. tostring(err))
    end
    local player = services.Players.LocalPlayer
    local ctx = {
        services = services,
        player = player,
        pg = player:WaitForChild("PlayerGui"),
        env = env,
        state = {
            alive = true, running = false, busy = false,
            completedThrows = 0, equippedThroughThrow = 0,
            cinemaPending = false, cinemaContinueSerial = 0, cinemaInterrupted = false,
            cinemaObserved = false,
        },
        view = {}, connections = {}, disposers = {},
    }
    local handle
    local function unload()
        if not ctx.state.alive then return end
        ctx.state.alive, ctx.state.running = false, false
        for _, connection in ipairs(ctx.connections) do pcall(function() connection:Disconnect() end) end
        for _, dispose in ipairs(ctx.disposers) do pcall(dispose) end
        if ctx.log then pcall(ctx.log, "UNLOAD", "Instance unloaded/replaced") end
        if ctx.flushLog then pcall(ctx.flushLog) end
        if ctx.view.gui then pcall(function() ctx.view.gui:Destroy() end) end
        if env.AdonisHub == handle then env.AdonisHub = nil end
    end
    handle = {Unload = unload, Version = "3-modular"}
    env.AdonisHub = handle
    local ok, err = xpcall(function()
        local order = {
            "config", "logging", "utilities", "branding", "ui", "input", "training", "plots",
            "cinema", "cinema_view", "presentation", "pet_observer", "throw", "equipment", "selling", "upgrade", "plot_upgrade", "food", "boost_fps", "controller", "diagnostics",
        }
        for _, name in ipairs(order) do
            local init = loadModule(name)
            assert(type(init) == "function", "Invalid module: " .. name)
            init(ctx)
        end
        ctx.syncAutomation()
    end, debug.traceback)
    if not ok then unload(); error(err, 0) end
    return handle
end
]=], "@AdonisHub/src/main.lua")
    assert(mainChunk, err)
    return mainChunk()(loadModule)
end)()
