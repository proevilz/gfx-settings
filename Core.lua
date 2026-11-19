local _, G = ...
-- Each slider specifies its CVar, label, minimum, maximum, drag step and tooltip.
G.options = {
    {"groundEffectDensity", "Grass density", 0, 256, 1, "Amount of grass and small ground plants. Higher values cost performance."},
    {"groundEffectDist", "Grass distance", 0, 500, 5, "How far away ground plants are drawn."},
    {"groundEffectFade", "Grass fade distance", 0, 500, 5, "Where grass begins fading. Keep below Grass distance."},
    {"weatherDensity", "Weather density", 0, 3, 0.1, "Rain and snow intensity. Does not change the zone's weather."},
    {"terrainLodDist", "Terrain detail distance", 100, 1000, 25, "Distance at which terrain retains more detail."},
    {"lodObjectFadeScale", "Object detail distance", 10, 200, 5, "Higher values retain distant object detail longer."},
    {"lodObjectCullSize", "Small object culling", 1, 100, 1, "Lower values keep smaller distant objects visible."},
    {"doodadLodScale", "Scenery detail", 10, 200, 5, "Detail distance for scenery such as trees and props."},
    {"reflectionMode", "Reflections", 0, 2, 1, "Reflection mode, from disabled to more detailed. Hardware support varies."},
    {"rippleDetail", "Water ripples", 0, 2, 1, "Water ripple detail. Hardware support varies."},
    {"ResampleAlwaysSharpen", "Always sharpen", 0, 1, 1, "0 = off, 1 = on. Enables sharpening without lowering render scale."},
    {"shadowBlendCascades", "Blend shadow edges", 0, 1, 1, "0 = off, 1 = on. Blends transitions between shadow layers."},
    {"farclip", "World draw distance", 1000, 10000, 100, "How far the world is drawn. Higher values can reduce frame rate."},
    {"horizonStart", "Horizon fog distance", 0, 6000, 100, "Moves distance fog farther out as the value increases."},
    {"horizonClip", "Horizon draw distance", 1000, 10000, 100, "How far the distant horizon is drawn."},
    {"wmoLodDist", "Building detail range", 100, 800, 25, "How far buildings and large structures retain more detail."},
    {"shadowTextureSize", "Shadow resolution", 512, 2048, 256, "Higher values produce sharper shadow maps when supported."},
    {"ffxDeath", "Grayscale while dead", 0, 1, 1, "0 = off, 1 = on. Controls the grayscale screen effect while dead."},
    {"volumeFogLevel", "Volumetric fog", 0, 4, 1, "Rendering quality of volumetric fog. Higher levels can reduce frame rate."},
    {"volumeFogInterior", "Indoor volumetric fog", 0, 1, 1, "0 = off, 1 = on. Controls volumetric fog in interiors where supported."},
    {"SkyCloudLOD", "Cloud texture detail", 0, 3, 1, "Controls cloud texture resolution."},
    {"particulatesEnabled", "Ambient particles", 0, 1, 1, "0 = off, 1 = on. Controls floating particles such as dust and motes."},
}

function G.Read(name)
    local ok, value = pcall(C_CVar.GetCVar, name)
    if ok and tonumber(value) then return value end
end

function G.Write(option, value, restoring)
    if InCombatLockdown() then return false, "Change graphics settings outside combat." end
    local number = tonumber(value)
    if not number or number ~= number or math.abs(number) == math.huge then
        return false, "Enter a valid number."
    end
    if not restoring and (number < option[3] or number > option[4]) then
        return false, "Use a value from " .. option[3] .. " to " .. option[4] .. "."
    end
    local name = option[1]
    local before = G.Read(name)
    if not before then return false, "Unavailable in this client." end
    local ok = pcall(C_CVar.SetCVar, name, tostring(number))
    local actual = G.Read(name)
    -- A clamp can change the setting even when the requested value was rejected.
    if tonumber(actual) ~= tonumber(before) or not actual then
        ForeverGraphicsDB = ForeverGraphicsDB or {}
        if ForeverGraphicsDB[name] == nil then ForeverGraphicsDB[name] = before end
    end
    if not ok or not actual then return false, "Client rejected this setting." end
    -- The client may return a float such as 0.300000012 for a requested 0.3.
    if math.abs(tonumber(actual) - number) > 0.000001 then
        return false, "Client kept " .. actual .. " (requested " .. number .. ")."
    end
    return true, option[2] .. " set to " .. actual .. "."
end

function G.Restore()
    local failures = 0
    for _, option in ipairs(G.options) do
        local value = ForeverGraphicsDB and ForeverGraphicsDB[option[1]]
        if value then
            local ok = G.Write(option, value, true)
            if ok then ForeverGraphicsDB[option[1]] = nil else failures = failures + 1 end
        end
    end
    return failures == 0, failures == 0 and "Original settings restored." or "Some settings could not be restored. Their original values are saved."
end
