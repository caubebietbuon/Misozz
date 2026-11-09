local hub = "https://raw.githubusercontent.com/caubebietbuon/Misozz/main/"
local routes = {
    games = {},
    places = { [120219252362013] = hub .. "Adonis-TFFA.lua" },
}

local address = routes.games[game.GameId] or routes.places[game.PlaceId]
if not address then return end

for attempt = 1, 3 do
    local fetched, body = pcall(function() return game:HttpGet(address) end)
    if fetched and type(body) == "string" and body ~= "" then
        local launch, message = loadstring(body)
        assert(launch, message)
        return launch()
    end
    if attempt < 3 then task.wait(0.5) end
end
warn("[Adonis HUB] Khong tai duoc script. Hay thu lai.")
