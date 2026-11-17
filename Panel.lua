local _, G = ...
local sliderWidth = 106
local panel, rows, status
local white = "Interface\\Buttons\\WHITE8X8"
local accent = {1, 0.82, 0}

local function Text(parent, text, x, y, width, size, muted)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetTextColor(muted and 0.65 or 0.95, muted and 0.61 or 0.90, muted and 0.53 or 0.80)
    label:SetText(text)
    return label
end

local function Surface(frame, r, g, b, border)
    frame:SetBackdrop({bgFile = white, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 9})
    frame:SetBackdropColor(r, g, b, 1)
    frame:SetBackdropBorderColor(border or 0.85, border or 0.72, border or 0.50, 1)
end

local function Button(parent, text, width, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function RefreshRow(row)
    local current = G.Read(row.option[1])
    row.syncing = true
    row.slider:SetValue(tonumber(current) or row.option[3])
    row.input:SetText(current or "N/A")
    row.slider:SetEnabled(current ~= nil)
    row.input:SetEnabled(current ~= nil)
    row.card:SetAlpha(current and 1 or 0.4)
    row.syncing = false
end

local function Refresh()
    for _, row in ipairs(rows) do RefreshRow(row) end
end

local function Result(row, ok, message)
    status:SetText(message)
    status:SetTextColor(ok and 0.65 or 1, ok and 0.85 or 0.35, ok and 0.45 or 0.25)
    if row then RefreshRow(row) else Refresh() end
end

local function CreatePanel()
    panel = CreateFrame("Frame", "ForeverGraphicsPanel", UIParent, "BackdropTemplate")
    panel:Hide()
    panel:SetSize(640, 310)
    -- Fit the panel on smaller UI canvases without changing the user's UI scale.
    panel:SetScale(math.min(1, (UIParent:GetWidth() - 40) / 640, (UIParent:GetHeight() - 40) / 310))
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    Surface(panel, 0.075, 0.065, 0.05)
    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetSize(590, 42)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() panel:StartMoving() end)
    header:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    local title = Text(header, "GFX Settings", 16, -14, 500, 20)
    title:SetTextColor(unpack(accent))
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -12, -12)
    table.insert(UISpecialFrames, "ForeverGraphicsPanel")
    local groups = {
        {title = "Ground & atmosphere", options = {1, 2, 3, 4, 5, 6}},
        {title = "Scenery & finish", options = {7, 8, 9, 10, 11, 12}},
    }
    rows = {}
    for column, group in ipairs(groups) do
        local x = 16 + (column - 1) * 310
        local heading = Text(panel, group.title, x, -48, 298, 11)
        heading:SetTextColor(unpack(accent))
        for index, optionIndex in ipairs(group.options) do
            local option = G.options[optionIndex]
            local card = CreateFrame("Frame", nil, panel, "BackdropTemplate")
            card:SetPoint("TOPLEFT", x, -66 - (index - 1) * 33)
            card:SetSize(298, 30)
            Surface(card, 0.11, 0.095, 0.075, 0.42)
            local row = {option = option, card = card}
            rows[#rows + 1] = row
            Text(card, option[2], 10, -9, 124, 11)
            local slider = CreateFrame("Slider", nil, card)
            row.slider = slider
            slider:SetOrientation("HORIZONTAL")
            slider:SetPoint("LEFT", card, "LEFT", 138, 0)
            slider:SetSize(sliderWidth, 18)
            slider:SetMinMaxValues(option[3], option[4])
            slider:SetValueStep(option[5])
            slider:SetObeyStepOnDrag(true)
            local track = slider:CreateTexture(nil, "BACKGROUND")
            track:SetColorTexture(0.20, 0.17, 0.12, 1)
            track:SetPoint("LEFT")
            track:SetSize(sliderWidth, 3)
            local fill = slider:CreateTexture(nil, "ARTWORK")
            fill:SetColorTexture(0.55, 0.43, 0.22, 1)
            fill:SetPoint("LEFT")
            fill:SetSize(1, 3)
            slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            local thumb = slider:GetThumbTexture()
            thumb:SetSize(16, 24)
            local ok, rawDefault = pcall(C_CVar.GetCVarDefault or GetCVarDefault, option[1])
            local default = ok and tonumber(rawDefault)
            if default and default >= option[3] and default <= option[4] then
                local fraction = (default - option[3]) / (option[4] - option[3])
                local marker = slider:CreateTexture(nil, "ARTWORK", nil, 1)
                marker:SetColorTexture(1, 0.94, 0.78, 0.55)
                marker:SetSize(1, 10)
                -- The thumb centre travels between half-thumb insets at each end.
                marker:SetPoint("CENTER", slider, "LEFT", 8 + fraction * (sliderWidth - 16), 0)
            end
            slider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(slider, "ANCHOR_TOP")
                GameTooltip:SetText(option[2])
                GameTooltip:AddLine(option[6], 0.9, 0.93, 0.94, true)
                GameTooltip:AddLine("Console: " .. option[1], 0.6, 0.6, 0.6)
                GameTooltip:Show()
            end)
            slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
            local input = CreateFrame("EditBox", nil, card, "BackdropTemplate")
            row.input = input
            input:SetSize(40, 20)
            input:SetPoint("LEFT", slider, "RIGHT", 6, 0)
            Surface(input, 0.045, 0.035, 0.025)
            input:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
            input:SetTextColor(0.95, 0.90, 0.80)
            input:SetJustifyH("CENTER")
            input:SetAutoFocus(false)
            input:SetMaxLetters(12)
            input:SetScript("OnEditFocusGained", function() input:SetBackdropBorderColor(unpack(accent)) end)
            input:SetScript("OnEditFocusLost", function() input:SetBackdropBorderColor(0.85, 0.72, 0.50, 1) end)
            slider:SetScript("OnValueChanged", function(_, value)
                fill:SetWidth(math.max(1, math.min(sliderWidth, sliderWidth * (value - option[3]) / (option[4] - option[3]))))
                if not row.syncing then
                    Result(row, G.Write(option, string.format(option[5] < 1 and "%.1f" or "%.0f", value)))
                end
            end)
            local function Apply()
                input:ClearFocus()
                Result(row, G.Write(option, input:GetText()))
            end
            input:SetScript("OnEnterPressed", Apply)
            input:SetScript("OnEscapePressed", function() input:ClearFocus(); RefreshRow(row) end)
        end
    end
    Button(panel, "Refresh", 80, 16, -270, Refresh)
    local restore = Button(panel, "Restore originals", 126, 104, -270, function() Result(nil, G.Restore()) end)
    -- Panel buttons can use multiple texture regions instead of a normal texture.
    for _, region in ipairs({restore:GetRegions()}) do
        if region:IsObjectType("Texture") then region:SetDesaturated(true) end
    end
    status = Text(panel, "", 242, -276, 252, 10)
    local creditPrefix = Text(panel, "made by", 506, -277, 48, 10, true)
    creditPrefix:SetJustifyH("RIGHT")
    local credit = CreateFrame("Button", nil, panel)
    credit:SetPoint("TOPLEFT", 554, -270)
    credit:SetSize(70, 24)
    local handle = Text(credit, "@proevilz", 0, -7, 70, 10)
    handle:SetJustifyH("RIGHT")
    creditPrefix:ClearAllPoints()
    creditPrefix:SetPoint("TOPRIGHT", handle, "TOPRIGHT", -handle:GetStringWidth() - 4, 0)
    handle:SetTextColor(unpack(accent))
    credit:SetScript("OnEnter", function() handle:SetTextColor(1, 1, 1) end)
    credit:SetScript("OnLeave", function() handle:SetTextColor(unpack(accent)) end)
    credit:SetScript("OnClick", function()
        StaticPopupDialogs.FOREVERGRAPHICS_PROFILE = {
            text = "Copy this URL to open my profile in your browser:",
            button1 = "Close", hasEditBox = true, editBoxWidth = 260,
            timeout = 0, whileDead = true, hideOnEscape = true,
            OnShow = function(dialog)
                local editBox = dialog.editBox or dialog.EditBox
                editBox:SetText("https://x.com/proevilz")
                editBox:SetFocus()
                editBox:HighlightText()
            end,
        }
        StaticPopup_Show("FOREVERGRAPHICS_PROFILE")
    end)
    panel:SetScript("OnShow", Refresh)
end

SLASH_FOREVERGRAPHICS1 = "/gfx"
SLASH_FOREVERGRAPHICS2 = "/graphicscontrols"
SlashCmdList.FOREVERGRAPHICS = function()
    if not panel then CreatePanel() end
    panel:SetShown(not panel:IsShown())
end
