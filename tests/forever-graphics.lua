local addonRoot = ... or "."
local G, values, writes, combat, reject, clamp = {}, {groundEffectDensity = "32", weatherDensity = "3"}, 0
C_CVar = {
    GetCVar = function(name) return values[name] end,
    SetCVar = function(name, value)
        writes = writes + 1
        if reject then error("protected") end
        values[name] = clamp and "64" or (value == "0.3" and "0.300000012" or value)
    end,
}
InCombatLockdown = function() return combat end
assert(loadfile(addonRoot .. "/Core.lua"))("ForeverGraphics", G)
local grass, weather = G.options[1], G.options[4]
assert(writes == 0, "loading must not change graphics")
assert(not G.Write(grass, "bad"))
assert(not G.Write(grass, 0/0))
assert(not G.Write(grass, 257))
assert(G.options[10][1] == "rippleDetail" and G.options[10][4] == 2, "ripples must stop at the observed client maximum")
local rippleOK, rippleMessage = G.Write(G.options[10], 3)
assert(not rippleOK and rippleMessage == "Use a value from 0 to 2.", "reject ripple 3 before calling the client")
assert(not G.Write(G.options[3], 100), "unavailable CVar")
assert(writes == 0)
reject = true
assert(not G.Write(weather, 1))
assert(not (ForeverGraphicsDB and ForeverGraphicsDB.weatherDensity), "rejected unchanged value must not create undo")
reject = false
assert(G.Write(grass, 128))
assert(G.Write(grass, 256))
assert(G.Write(weather, 0.3), "float formatting is not a clamp")
assert(ForeverGraphicsDB.groundEffectDensity == "32", "original must survive multiple edits")
combat = true
assert(not G.Write(weather, 0))
assert(not G.Restore())
assert(ForeverGraphicsDB.groundEffectDensity == "32", "failed restore must retain backup")
combat = false
clamp = true
assert(not G.Write(grass, 100), "client clamp must be reported")
clamp = false
reject = true
assert(not G.Write(grass, 100))
reject = false
assert(G.Restore())
assert(values.groundEffectDensity == "32")
assert(next(ForeverGraphicsDB) == nil)
values.groundEffectDensity = "512"
assert(G.Write(grass, 128))
assert(G.Restore(), "restore must accept original outside slider range")
assert(values.groundEffectDensity == "512")

-- Build and exercise the actual panel without a WoW renderer.
local methods = {}
local function frame() return setmetatable({scripts = {}, Low = {}, High = {}, Text = {}}, {__index = methods}) end
local noop = function() end
for _, name in ipairs({"SetScale", "SetAlpha", "SetFont", "SetBackdropBorderColor", "SetOrientation", "SetColorTexture", "SetVertexColor", "SetPoint", "SetWidth", "SetJustifyH", "SetSize", "SetFrameStrata", "SetClampedToScreen", "SetMovable", "EnableMouse", "RegisterForDrag", "SetBackdrop", "SetBackdropColor", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetAutoFocus", "SetMaxLetters", "ClearFocus", "SetTextColor"}) do methods[name] = noop end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:ClearAllPoints() end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:SetValue(value) self.value = value; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:IsShown() return self.shown end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:CreateFontString() return frame() end
local markers = {}
C_CVar.GetCVarDefault = function(name)
    return ({groundEffectDensity = "128", weatherDensity = "4"})[name]
end
function methods:CreateTexture(_, _, _, sublevel)
    local texture = frame()
    if sublevel == 1 then
        texture.SetPoint = function(_, _, _, _, x) markers[#markers + 1] = x end
    end
    return texture
end
function methods:SetThumbTexture() self.thumb = frame() end
function methods:GetThumbTexture() return self.thumb end
function methods:GetNormalTexture() return nil end
function methods:GetPushedTexture() return nil end
function methods:GetRegions()
    self.regions = self.regions or {frame(), frame(), frame()}
    self.regions[1].kind, self.regions[2].kind, self.regions[3].kind = "Texture", "Texture", "FontString"
    return unpack(self.regions)
end
function methods:IsObjectType(kind) return self.kind == kind end
function methods:SetDesaturated(value) self.desaturated = value end
local controls = {}
CreateFrame = function(_, name)
    local f = frame()
    f.Low, f.High, f.Text = frame(), frame(), frame()
    if name then _G[name] = f end
    controls[#controls + 1] = f
    return f
end
unpack = table.unpack or unpack
UIParent, UISpecialFrames, SlashCmdList = {GetWidth = function() return 1920 end, GetHeight = function() return 1080 end}, {}, {}
assert(loadfile(addonRoot .. "/Panel.lua"))("ForeverGraphics", G)
local previousWrites = writes
SlashCmdList.FOREVERGRAPHICS()
assert(ForeverGraphicsPanel:IsShown())
assert(#markers == 1 and markers[1] == 53, "mark the midpoint and skip missing or out-of-range defaults")
assert(writes == previousWrites, "opening panel must not write CVars")
SlashCmdList.FOREVERGRAPHICS()
assert(not ForeverGraphicsPanel:IsShown())
for _, control in ipairs(controls) do
    if control.scripts.OnValueChanged then
        control:SetValue(80)
        assert(values.groundEffectDensity == "80" and writes == previousWrites + 1)
        assert(ForeverGraphicsDB.groundEffectDensity == "512")
        break
    end
end
assert(#controls == 42 and writes == previousWrites + 1)
local restoreButton = controls[#controls - 1]
assert(restoreButton.regions[1].desaturated and restoreButton.regions[2].desaturated)
assert(not restoreButton.regions[3].desaturated, "leave button text unchanged")
StaticPopupDialogs = {}
local profileBox = {SetText = methods.SetText, SetFocus = function(self) self.focused = true end,
    HighlightText = function(self) self.selected = true end}
StaticPopup_Show = function(name)
    StaticPopupDialogs[name].OnShow({editBox = profileBox})
end
controls[#controls].scripts.OnClick()
assert(profileBox.text == "https://x.com/proevilz" and profileBox.focused and profileBox.selected)
print("Forever Graphics: validation, undo, failures, client clamping, and panel smoke checks passed")
