-- Adonis HUB | Universal Loader

local scripts = {
    [120219252362013] =
        "https://raw.githubusercontent.com/caubebietbuon/Misozz/main/Adonis-TFFA.lua",
}

local url = scripts[game.PlaceId]

if not url then
    warn("[Adonis HUB] Game nay chua duoc ho tro.")
    return
end

local source

for attempt = 1, 3 do
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    if ok and type(result) == "string" and result ~= "" then
        source = result
        break
    end

    if attempt < 3 then
        task.wait(1)
    end
end

if not source then
    error("[Adonis HUB] Khong tai duoc script. Hay thu lai.")
end

local run, compileError = loadstring(source, "@AdonisHub/TFFA")

if not run then
    error("[Adonis HUB] Loi bien dich: " .. tostring(compileError))
end

return run()
