local _, playerClass = UnitClass("player")
if playerClass ~= "MAGE" then
	return 0
end

-- Get localized class name
mageClassName = UnitClass("player")

local locale = GetLocale()
if locale == "ruRU" or locale == "koKR" or locale == "zhCN" or locale == "zhTW" then
	locale = "other"
end

------------------
--- Main frame ---
------------------
combustConfig = CreateFrame("Frame", "combustFrame", UIParent)
combustConfig:SetMovable(true)
combustConfig:EnableMouse(true)
combustConfig:RegisterForDrag("LeftButton")
combustConfig:SetScript("OnDragStart", combustConfig.StartMoving)
combustConfig:SetScript("OnDragStop", combustConfig.StopMovingOrSizing)
-- SetPoint is done after ADDON_LOADED

combustIcons = {}
combustMages = {}

mageCount = 1
for i = 1, GetNumGroupMembers() do
	name, _, _, _, class = GetRaidRosterInfo(i)
	if class == mageClassName then
		combustMages[name] = mageCount
		mageCount = mageCount + 1
	end
end

function createCombustIcon(x_loc, y_loc)
	local combustIcon = CreateFrame("Button", nil, UIParent)
	combustIcon:SetSize(30,30)
	combustIcon:SetPoint("TOPLEFT", scorchbar, "BOTTOMLEFT", x_loc, y_loc)
	combustIcon:SetNormalTexture("Interface/Icons/spell_fire_sealoffire.BLP")

	if locale ~= "other" then
		combustIcon.tf = combustIcon:CreateFontString(nil, "OVERLAY")
		combustIcon.tf:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	else
		combustIcon.tf = combustIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end
	combustIcon.tf:SetPoint("TOP", combustIcon, "BOTTOM", 0, 0)
	combustIcon.tf:SetJustifyH("CENTER")
	combustIcon.tf:SetShadowOffset(1, -1)
	combustIcon.tf:SetTextColor(.41, .80, .94)
	combustIcon.tf:SetText("")
	
	if locale ~= "other" then
		combustIcon.tf2 = combustIcon:CreateFontString(nil, "OVERLAY")
		combustIcon.tf2:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
	else
		combustIcon.tf2 = combustIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end
	combustIcon.tf2:SetPoint("BOTTOM", combustIcon, "BOTTOM", 0, 2)
	combustIcon.tf2:SetJustifyH("CENTER")
	combustIcon.tf2:SetShadowOffset(1, -1)
	combustIcon.tf2:SetTextColor(1, 1, 1)
	combustIcon.tf2:SetText("")

	return combustIcon
end

----------------------------
---        Events        ---
----------------------------
local function onevent(self, event, prefix, msg, channel, sender, ...)
	-- Stuff to do after addon is loaded
	if(event == "ADDON_LOADED" and prefix == "IgniteTracker") or event == "RAID_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
		-- Hide icons if they already exist
		if combustIcons[1] then
			for idx = 1, 12 do
				combustIcons[idx]:Hide()
			end
		end
		
		-- Get mages in the group/raid
		mageCount = 1
		for i = 1, GetNumGroupMembers() do
			name, _, _, _, class = GetRaidRosterInfo(i)
			if class == mageClassName then
				combustMages[name] = mageCount
				mageCount = mageCount + 1
			end
		end
		
		-- Build Icons, 2 rows of 6
		local xOffset = 0
		local yOffset = 0
		for idx = 1, 12 do
			combustIcons[idx] = createCombustIcon(xOffset, yOffset)
			if idx == 6 then
				xOffset = 0
				yOffset = -40
			else
				xOffset = xOffset + 30
			end

			combustIcons[idx]:Hide()
		end
	end
end

combustConfig:RegisterEvent("ADDON_LOADED")
combustConfig:RegisterEvent("RAID_ROSTER_UPDATE")
combustConfig:RegisterEvent("GROUP_ROSTER_UPDATE")
combustConfig:SetScript("OnEvent", onevent)
