-- debug, set debug level
-- 0: no debug, 1: minimal, 2: all
local debug = 0

local _, playerClass = UnitClass("player")
if playerClass ~= "MAGE" then
	print("IgniteTracker disabled, you are not a mage :(")
	return 0
end

-- Saved Variables
IgniteTrackerDB = {}

local AceGUI = LibStub("AceGUI-3.0")
IgniteTracker = LibStub("AceAddon-3.0"):NewAddon("IgniteTracker", "AceEvent-3.0")
local addonName, addon = ...
local ldb = LibStub("LibDataBroker-1.1")
local channel = "RAID"
local igniteMinimapIcon = LibStub("LibDBIcon-1.0")
local db

-- Set some variable defaults
local igniteOwner = ""
local scorchStack = 0
local currentTargetID = nil
local currentTarget = "nobody"
local scorchTable = {}
local igniteTable = {}
local igniters = {}
local endTime = 0
local critTable = {}
local igniteTick = " "
local igniteSpellIcon = 135818
local igniteTotal = 0
local crits = "       "
local igniteTalented = 0
local scorchTalented = 0
local talentCheckPage = 2
local talentCheckNumber = 3
local spellSchoolCheck = 4
local tickCount = 0
local tickTime = 0
local ticksSinceRefresh = 0
local ticksRemaining = 2
local combustCrits = {}
local igniteTimer, scorchTimer = 0, 0

local locale = GetLocale()
if locale == "ruRU" or locale == "koKR" or locale == "zhCN" or locale == "zhTW" then
	locale = "other"
end

-- Get localized names for spells: 12654 = Ignite, 22959 = Fire Vulnerability (Scorch)
local igniteName = GetSpellInfo(12654)
local fireVulnName = GetSpellInfo(22959)
local scorchName = GetSpellInfo(10207)
local combustName = GetSpellInfo(11129)

-- Store SpellID's for all ranks of Scorch for easy lookup
-- 1 = 2948, 2 = 8444, 3 = 8445, 4 = 8446, 5 = 10205, 6 = 10206, 7 = 10207
local scorchSpellTable = { [10207] = true, [10206] = true, [10205] = true,
					  [8446] = true, [8445] = true, [8444] = true, [2948] = true }

_G[addonName] = addon
addon.healthCheck = true

-- slash commands
SlashCmdList["IgniteTracker"] = function(inArgs)

	local wArgs = strtrim(inArgs)
	if wArgs == "" then
		--ShowUIPanel(igniteFrame)
		print("usage: /ignitetracker lock|move|unlock|minimap 1|minimap 0|frostmode on|frostmode off")
	elseif wArgs == "minimap 1" or wArgs == "minimap 0" then
		cmdarg, tog = string.split(" ", wArgs)
		IgniteTracker:maptoggle(tog)
	elseif wArgs == "unlock" or wArgs == "move" then
		igniteTimeStart = GetTime() + 60
		igniteTimer = 60
		ignitebar:Show()
		ignitebar.tf:SetText("/ignitetracker lock")
		igniteIcon:Show()
		ignitebar:SetMovable(true)
		ignitebar:EnableMouse(true)
		scorchTimeStart = GetTime() + 60
		scorchTimer = 60
		scorchbar:Show()
		scorchIcon:Show()
		lockStatus = 0	
	elseif wArgs == "lock" then		local _, _, relativePoint, xPos, yPos = ignitebar:GetPoint()
		ignitebar:Hide()
		igniteIcon:Hide()
		igniteTimer = 0
		ignitebar:SetMovable(false)
		ignitebar:EnableMouse(false)
		ignitebar.tf:SetText("")
		scorchbar:Hide()
		scorchIcon:Hide()
		scorchTimer = 0
		addon:setAnchorPosition("position", relativePoint, xPos, yPos)
		lockStatus = 1
	elseif wArgs == "crit" then
		if critFrame:IsVisible() then
			critFrame:Hide()
			addon:crittoggle(0)
		else
			local relativePoint, xPos, yPos = addon:getAnchorPosition("critFrame")
			critFrame:SetPoint(relativePoint, UIParent, relativePoint, xPos, yPos)
			critFrame:Show()
			addon:crittoggle(1)
		end
	elseif wArgs == "frostmode on" or wArgs == "frostmode 1" then
		addon:frosttoggle(1)
	elseif wArgs == "frostmode off" or wArgs == "frostmode 0" then
		addon:frosttoggle(0)
	elseif wArgs == "reset" then
		addon:setAnchorPosition("position", "CENTER", 0, -65)
		addon:setAnchorPosition("critFrame", "CENTER", 0, -200)
		ignitebar:SetPoint("CENTER", UIParent, "CENTER", 0, -65)
		critFrame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
	else
		print("usage: /ignitetracker lock|move|unlock")
	end

end
SLASH_IgniteTracker1 = "/ignitetracker"



------------------
--- Main frame ---
------------------
igniteConfig = CreateFrame("Frame", "igniteFrame", UIParent)
igniteConfig:SetMovable(true)
igniteConfig:EnableMouse(true)
igniteConfig:RegisterForDrag("LeftButton")
igniteConfig:SetScript("OnDragStart", igniteConfig.StartMoving)
igniteConfig:SetScript("OnDragStop", igniteConfig.StopMovingOrSizing)
-- SetPoint is done after ADDON_LOADED

igniteFrame.texture = igniteFrame:CreateTexture(nil, "BACKGROUND")
igniteFrame.texture:SetAllPoints(igniteFrame)
--igniteFrame.texture:SetTexture("Interface\\AddOns\\Assign\\Media\\black.tga")
igniteFrame:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]]})
igniteFrame:SetBackdropColor(0, 0, 0, 1)

if locale ~= "other" then
	igniteFrame.tf = igniteFrame:CreateFontString(nil, "OVERLAY")
	igniteFrame.tf:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
else
	igniteFrame.tf = igniteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
end
igniteFrame.tf:SetPoint("CENTER", igniteFrame, "CENTER", 0, 0)
igniteFrame.tf:SetJustifyH("CENTER")
igniteFrame.tf:SetShadowOffset(1, -1)
igniteFrame.tf:SetTextColor(1, 1, 1)
igniteFrame.tf:SetText("/ignitetracker lock")


----------------------------
---        Events        ---
----------------------------
local function onevent(self, event, prefix, msg, channel, sender, ...)
	--print(event)
	
	-- Stuff to do after addon is loaded
	if(event == "ADDON_LOADED" and prefix == "IgniteTracker") then
		-- Get anchor position
		local relativePoint, xPos, yPos = addon:getAnchorPosition("position")
		igniteConfig:SetSize(180, 16)
		igniteConfig:SetPoint(relativePoint, UIParent, relativePoint, xPos, yPos)
		igniteConfig:Hide()

		-- Create Ignite Bar
		-- local _, _, _, iframex, iframey = igniteFrame:GetPoint()
		-- print(iframex, iframey)
		
		ignitebar = CreateFrame("StatusBar", nil, UIParent)
		ignitebar:SetSize(180, 16)
		ignitebar:SetPoint("CENTER", UIParent, relativePoint, xPos, yPos)
		ignitebar:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]]})
		ignitebar:SetBackdropColor(0, 0, 0, 0.7)
		ignitebar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		ignitebar:SetStatusBarColor(1, 0, 0)
		ignitebar:SetMinMaxValues(0, 4)
		ignitebar:RegisterForDrag("LeftButton")
		ignitebar:SetScript("OnDragStart", igniteConfig.StartMoving)
		ignitebar:SetScript("OnDragStop", igniteConfig.StopMovingOrSizing)
		
		-- Ignite Bar text
		if locale ~= "other" then
			ignitebar.tf = ignitebar:CreateFontString(nil, "OVERLAY")
			ignitebar.tf:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		else
			ignitebar.tf = ignitebar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		end		
		ignitebar.tf:SetPoint("CENTER", ignitebar, "CENTER", 0, 0)
		ignitebar.tf:SetJustifyH("CENTER")
		ignitebar.tf:SetShadowOffset(1, -1)
		ignitebar.tf:SetTextColor(1, 1, 1)
		
		ignitebar:Hide()
		
		-- Ignite Icon
		igniteIcon = CreateFrame("Button", nil, UIParent)
		igniteIcon:SetSize(16,16)
		igniteIcon:SetPoint("RIGHT", ignitebar, "LEFT", 0, 0)
		igniteIcon:SetNormalTexture("Interface/Icons/SPELL_FIRE_INCINERATE.BLP")
		igniteIcon:Hide()
		
		-- Ignite Bar threat text
		if locale ~= "other" then
			ignitebar.threat = ignitebar:CreateFontString(nil, "OVERLAY")
			ignitebar.threat:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			ignitebar.threat = ignitebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		end
		ignitebar.threat:SetPoint("RIGHT", igniteIcon, "LEFT", 0, 0)
		ignitebar.threat:SetJustifyH("CENTER")
		ignitebar.threat:SetShadowOffset(1, -1)
		ignitebar.threat:SetTextColor(1, 1, 1)
		
		-- Ignite Bar stack text
		if locale ~= "other" then
			ignitebar.stack = ignitebar:CreateFontString(nil, "OVERLAY")
			ignitebar.stack:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			ignitebar.stack = ignitebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		end
		ignitebar.stack:SetPoint("LEFT", igniteIcon, "RIGHT", 0, 0)
		ignitebar.stack:SetJustifyH("CENTER")
		ignitebar.stack:SetShadowOffset(1, -1)
		ignitebar.stack:SetTextColor(1, 1, 1)
		
		-- Ignite Bar timer text
		if locale ~= "other" then
			ignitebar.timer = ignitebar:CreateFontString(nil, "OVERLAY")
			ignitebar.timer:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			ignitebar.timer = ignitebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		end
		ignitebar.timer:SetPoint("LEFT", ignitebar, "RIGHT", 0, 0)
		ignitebar.timer:SetJustifyH("CENTER")
		ignitebar.timer:SetShadowOffset(1, -1)
		ignitebar.timer:SetTextColor(1, 1, 1)
		
		-- Scorch Bar
		scorchbar = CreateFrame("StatusBar", TOP, UIParent)
		scorchbar:SetSize(180, 16)
		scorchbar:SetPoint("TOP", ignitebar, "BOTTOM", 0, -1)
		scorchbar:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]]})
		scorchbar:SetBackdropColor(0, 0, 0, 0.7)
		scorchbar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		scorchbar:SetStatusBarColor(.9, .3, .1)
		scorchbar:SetMinMaxValues(0, 30)
		
		-- Scorch Bar text
		if locale ~= "other" then
			scorchbar.tf = scorchbar:CreateFontString(nil, "OVERLAY")
			scorchbar.tf:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		else
			scorchbar.tf = scorchbar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		end
		scorchbar.tf:SetPoint("CENTER", scorchbar, "CENTER", 0, 0)
		scorchbar.tf:SetJustifyH("CENTER")
		scorchbar.tf:SetShadowOffset(1, -1)
		scorchbar.tf:SetTextColor(1, 1, 1)
		scorchbar.tf:SetText(stack)
		
		scorchbar:Hide()
		
		-- Scorch Icon
		scorchIcon = CreateFrame("Button", nil, UIParent)
		scorchIcon:SetSize(16,16)
		scorchIcon:SetPoint("RIGHT", scorchbar, "LEFT", 0, 0)
		scorchIcon:SetNormalTexture("Interface/Icons/Spell_Fire_SoulBurn.blp")
		scorchIcon:Hide()
		
		-- Scorch Bar threat text
		if locale ~= "other" then
			scorchbar.threat = scorchbar:CreateFontString(nil, "OVERLAY")
			scorchbar.threat:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			scorchbar.threat = scorchbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		end
		scorchbar.threat:SetPoint("RIGHT", scorchIcon, "LEFT", 0, 0)
		scorchbar.threat:SetJustifyH("CENTER")
		scorchbar.threat:SetShadowOffset(1, -1)
		scorchbar.threat:SetTextColor(1, 1, 1)
		
		-- Scorch Bar timer text
		if locale ~= "other" then
			scorchbar.timer = scorchbar:CreateFontString(nil, "OVERLAY")
			scorchbar.timer:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			scorchbar.timer = scorchbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		end
		scorchbar.timer:SetPoint("LEFT", scorchbar, "RIGHT", 0, 0)
		scorchbar.timer:SetJustifyH("CENTER")
		scorchbar.timer:SetShadowOffset(1, -1)
		scorchbar.timer:SetTextColor(1, 1, 1)
		
		-------------------------------
		--- Frame for crit tracking ---
		-------------------------------
		critFrame = CreateFrame("Frame", "critFrame", UIParent)
		critFrame:SetMovable(true)
		critFrame:EnableMouse(true)
		critFrame:RegisterForDrag("LeftButton")
		critFrame:SetScript("OnDragStart", critFrame.StartMoving)
		critFrame:SetScript("OnDragStop", function(self)
			--local settings
			self:StopMovingOrSizing()
			--critFrame:ClearAllPoints()
			--local relativePoint, xPos, yPos = getAnchorPosition("critFrame")
			local _, _, relativePoint, xPos, yPos = critFrame:GetPoint()
			addon:setAnchorPosition("critFrame", relativePoint, xPos, yPos)
		end)
		critFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
			--edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		critFrame:SetBackdropColor(0,0,0,.6);
		critFrame:SetSize(145, 188)
		local relativePoint, cfXPos, cfYPos = addon:getAnchorPosition("critFrame")
		critFrame:ClearAllPoints()
		--critFrame:SetPoint("Center", UIParent, "CENTER", 0, 0)
		critFrame:SetPoint(relativePoint, UIParent, relativePoint, cfXPos, cfYPos)
		
		if locale ~= "other" then
			critFrame.crit1 = critFrame:CreateFontString(nil, "ARTWORK")
			critFrame.crit1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		else
			critFrame.crit1 = critFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		end
		critFrame.crit1:SetPoint("TOP", critFrame, "TOP", 0, -7)
		critFrame.crit1:SetJustifyH("CENTER")
		critFrame.crit1:SetShadowOffset(1, -1)
		
		local cfStatus = addon:getSV("critFrameShow", "critframe")
		if cfStatus == 1 then
			critFrame:Show()
		else
			critFrame:Hide()
		end
		
		------------------
		-- Data Broker ---
		------------------
		local lockStatus = 1
		db = LibStub("AceDB-3.0"):New("IgniteTrackerDB", SettingsDefaults)
		IgniteTrackerDB.db = db;
		IgniteTrackerMinimapData = ldb:NewDataObject("IgniteTracker",{
			type = "data source",
			text = "IgniteTracker",
			icon = "Interface/Icons/SPELL_FIRE_INCINERATE.BLP",
			OnClick = function(self, button)
				if button == "RightButton" then
					if IsShiftKeyDown() then
						IgniteTracker:maptoggle("0")
						print("IgniteTracker: Hiding icon, re-enable with: /ignitetracker minimap 1")
					else
						if frostmode == 0 then
							addon:frosttoggle(1)
							frostmode = 1
						else
							addon:frosttoggle(0)
							frostmode = 0
						end
					end
				elseif button == "LeftButton" then
					if IsShiftKeyDown() then
						if critFrame:IsVisible() then
							critFrame:Hide()
							addon:crittoggle(0)
						else
							local relativePoint, xPos, yPos = addon:getAnchorPosition("critFrame")
							critFrame:SetPoint(relativePoint, UIParent, relativePoint, xPos, yPos)
							critFrame:Show()
							addon:crittoggle(1)
						end
					else
						if lockStatus == 1 then
							igniteTimeStart = GetTime() + 60
							igniteTimer = 60
							ignitebar:Show()
							ignitebar.tf:SetText("/ignitetracker lock")
							igniteIcon:Show()
							ignitebar:SetMovable(true)
							ignitebar:EnableMouse(true)
							scorchTimeEnd = GetTime() + 60
							scorchTimer = 60
							scorchbar:Show()
							scorchIcon:Show()
							lockStatus = 0
						else
							local _, _, relativePoint, xPos, yPos = ignitebar:GetPoint()
							ignitebar:Hide()
							igniteIcon:Hide()
							igniteTimer = 0
							ignitebar:SetMovable(false)
							ignitebar:EnableMouse(false)
							ignitebar.tf:SetText("")
							scorchbar:Hide()
							scorchIcon:Hide()
							scorchTimer = 0
							--igniteConfig:Hide()
							
							addon:setAnchorPosition("position", relativePoint, xPos, yPos)
							--ignitebar:SetPoint(relativePoint, UIParent, relativePoint, xPos, yPos)
							lockStatus = 1
						end
					end
				end
			end,
			
			-- Minimap Icon tooltip
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("|cffff0000IgniteTracker|r\n|cffffffffLeft-click:|r lock/unlock.\n|cffffffffShift+Left-click:|r toggle crit tracker frame.\n|cffffffffRight-click:|r toggle Frostmode on/off.\n|cffffffffShift+Right-click|r hide minimap button.")
			end,
		})
		
		-- display the minimap icon?
		local mmap = addon:getSV("minimap", "icon")
		if mmap == 1 or mmap == "1" then
			igniteMinimapIcon:Register("igniteIcon", IgniteTrackerMinimapData, IgniteTrackerDB)
			addon:maptoggle(1)
		else
			addon:maptoggle(0)
		end
		
		
		--------------------------------------------------------
		-- Frostmode - show frost spell crits instead of fire --
		--------------------------------------------------------
		-- Get saved value, if it doesn't exist set it to 0
		local frostmodeTbl = IgniteTrackerDB["frostmode"]
		if frostmodeTbl == nil then
			frostmode = 0
		else
			frostmode = frostmodeTbl["frostmode"]
		end

		if frostmode == 1 then
			-- checks for Improved Frostbolt, change talentCheckNumber to 3 for Elemental Precision
			talentCheckPage = 3
			talentCheckNumber = 2
			spellSchoolCheck = 16
		end
	end
	
	
	local eventType, sourceGUID, sourceName, spellID, spellName, damageAmount, spellCrit
	if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
		_, eventType, _, sourceGUID, sourceName, _, destName, destGUID, deadName, _, _, spellID, spellName, _, damageAmount, _, spellSchool, _, _, _, spellCrit = CombatLogGetCurrentEventInfo()

		-- Detect Ignite damage from party members
		if (eventType == "SPELL_PERIODIC_DAMAGE" and spellName == igniteName) and (UnitInParty(sourceName) or GetNumGroupMembers() == 0) then
			if damageAmount ~= nil or igniteTick ~= "" then
				igniteTick = damageAmount
				igniteTotal = igniteTotal + igniteTick
				
				--tickCount = tickCount + 1
				tickTime = GetTime()
				--print("tickTime", tickTime)
				--ticksSinceRefresh = ticksSinceRefresh + 1
				ticksRemaining = ticksRemaining - 1
				--print("> ", ticksRemaining)
			end
			local threat = addon:checkThreat(igniteOwner) or 0
			ignitebar.tf:SetText(igniteOwner .. " -> " .. igniteTick)
			ignitebar.threat:SetText(threat .. "%")
		end
		
		
		-- We only care about Ignite and Scorch events from within our party or raid (or solo)
		-- Match on localized spell name defined at start of file
		if ((eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_APPLIED_DOSE") and (spellName == igniteName or spellName == fireVulnName) and (UnitInParty(sourceName) or GetNumGroupMembers() == 0) and (igniters[sourceName] ~= 0)) then
		
			--------------------
			--- Ignite Timer ---
			--------------------
			
			-- New Ignite, get the source and blank the total
			if eventType == "SPELL_AURA_APPLIED" and spellName == igniteName then
				igniteTick = " "
				igniteOwner = sourceName
				ticksRemaining = 2
				igniteTimeStart = GetTime() + 4
				--print("> ", ticksRemaining)
				igniteStack = 1
			end
			
			if spellName == igniteName and destGUID == currentTarget then
				-- Get the name of the player who started the Ignite, start the timer	
				if ticksRemaining == 2 then
					--print("2 ticks remaining, do not refresh")
				elseif ticksRemaining == 1 then
					igniteTimeStart = GetTime() + igniteTimer + 2
					--print("1 tick remaining, add 1 tick -- new duration:", igniteTimeStart)
					ticksRemaining = 2
				elseif ticksRemaining == 0 then
					--print("0 ticks remaining, add 2 ticks")
					igniteTimeStart = GetTime() + 4
					ticksRemaining = 2
				else
					print("This shouldn't happen")
				end
					
				
				--igniteTimeStart = GetTime() + 4
				timeSinceTick = GetTime() - tickTime
				
				
				-- if ticksSinceRefresh == 0 then
					-- print("refresh - ticksSinceRefresh:", ticksSinceRefresh)
				-- else
					-- print("don't refresh - ticksSinceRefresh:", ticksSinceRefresh)
				-- end
				
				

				-- Show the bar and apply text
				ignitebar:Show()
				igniteIcon:Show()
				local threat = addon:checkThreat(igniteOwner) or 0
				ignitebar.tf:SetText(igniteOwner .. " -> " .. igniteTick)
				ignitebar.threat:SetText(threat .. "%")
				ignitebar.stack:SetText(igniteStack)
				igniteStack = igniteStack + 1

				-- Decrement the timer until it expires
				ignitebar:SetScript("OnUpdate", function(self, elapsed)
					igniteTimer = igniteTimeStart - GetTime()
					self:SetValue(igniteTimer)
					igniteTimerDisplay = string.format("%.2f", igniteTimer)
					ignitebar.timer:SetText(igniteTimerDisplay)
					if igniteTimer <= 0.02 then
						igniteIcon:Hide()
						ignitebar:Hide()
						return 0
					elseif igniteTimer <= 0 then
						tickCount = 0
					end
				end)
			
			--------------------
			--- Scorch Timer ---
			--------------------
			elseif spellName == fireVulnName then
				-- Increment number of Scorch stacks, capping at 5
				if scorchTable[destGUID .. "_stack"] == nil then
					scorchTable[destGUID .. "_stack"] = 1
				elseif scorchTable[destGUID .. "_stack"] < 5 then
					scorchTable[destGUID .. "_stack"] = scorchTable[destGUID .. "_stack"] + 1
				end
				--print(destGUID, scorchTable[destGUID .. "_stack"])

				--scorchTimeEnd = addon:getDebuffTimeRemaining("Fire Vulnerability") -- does not work with Classic API
				
				-- Set time to 30 seconds, store stack count and timer in table
				scorchTimeEnd = GetTime() + 30
				--scorchTable[destGUID .. "_stack"] = scorchStack
				scorchTimer = scorchTimeEnd - GetTime()
				scorchTable[destGUID .. "_time"] = scorchTimer
				
				-- Only update the bar if it is current target
				if destGUID == currentTarget then
					scorchbar.tf:SetText(scorchTable[destGUID .. "_stack"])
					scorchbar:Show()
					scorchIcon:Show()

					-- Decrement the timer until it expires, update stored value as we go
					scorchbar:SetScript("OnUpdate", function(self, elapsed)
						scorchTimer = scorchTimeEnd - GetTime()
						scorchTable[destGUID .. "_time"] = scorchTimer
						
						self:SetValue(scorchTimer)
						scorchTimerDisplay = string.format("%.1f", scorchTimer)
						--print(scorchTimerDisplay)
						scorchbar.timer:SetText(scorchTimerDisplay)
						--print(scorchTimerDisplay)
						if scorchTimer <= 0.02 then
							scorchbar:Hide()
							scorchIcon:Hide()
							scorchTable[destGUID .. "_stack"] = 0
						end
						
						local threat = addon:checkThreat("player") or 0
						scorchbar.threat:SetText(threat .. "%")
					end)
				end
			end
		end
		
		-- Add timers for Combustion for all raid members. Since Combustion does not have a duration, these actually count up to know when it was used.
		-- Icons are created in CombustTracker.lua, from left to right, based on raidID.
		if (sourceName == UnitName("player") or UnitInParty(sourceName)) and (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REMOVED") and spellName == combustName then
			-- Get the icon index of the mage who used Combustion, truncate their name to first three characters
			local idx = combustMages[sourceName] or 1
			combustCrits[sourceName] = 0
			combustIcons[idx].tf:SetText(string.sub(sourceName, 1, 3))
			
			-- Show the icon and record the starting time
			combustIcons[idx]:Show()
			local startTime = GetTime()
			
			combustIcons[idx]:SetScript("OnUpdate", function(self, elapsed)
				if eventType == "SPELL_AURA_REMOVED" or (GetTime() - startTime > 180) then
					-- Hide icon if Combustion ends or if it's been over 3 minutes, in case the owner is out of range when it ends
					combustIcons[idx]:Hide()
					return
				else
					-- Update the timer
					combustIcons[idx].tf2:SetText(math.floor(GetTime() - startTime) .. "\n" .. combustCrits[sourceName])
				end
			end)
		end
		
		-- Need to check all ranks of Scorch
		if eventType == "SPELL_DAMAGE" and (scorchSpellTable[spellID] or spellName == scorchName) then
			-- Only need to do this if the stack count is 5
			-- APPLY_AURA_DOSE is easier for 1-5, but does not update once at 5
			if scorchTable[destGUID .. "_stack"] == 5 then
				-- Set time to 30 seconds, store stack count in table
				scorchTimeEnd = GetTime() + 30
				scorchTimer = scorchTimeEnd - GetTime()
				scorchTable[destGUID .. "_time"] = scorchTimer
				--scorchTable[destGUID .. "_stack"] = scorchStack
				
				-- Only update the timer if current target
				if destGUID == currentTarget then
					scorchbar.tf:SetText(scorchTable[destGUID .. "_stack"])
					
					scorchbar:Show()
					scorchIcon:Show()

					-- Update the Scorch bar
					scorchbar:SetScript("OnUpdate", function(self, elapsed)
						scorchTimer = scorchTimeEnd - GetTime()
						scorchTable[destGUID .. "_time"] = scorchTimer
						scorchTimerDisplay = string.format("%.1f", scorchTimer)
						--print(scorchTimerDisplay)
						scorchbar.timer:SetText(scorchTimerDisplay)
						self:SetValue(scorchTimer)
						if scorchTimer <= 0.02 then
							scorchbar:Hide()
							scorchIcon:Hide()
							scorchTable[destGUID .. "_stack"] = 0
						end
						
						local threat = addon:checkThreat("player") or 0
						scorchbar.threat:SetText(threat .. "%")
					end)
				end
			end
		end

		
		-- Add fire spell crits (from mages) to the crit window, if Ignite is talented (stored in igniters table)
		-- Make sure the source is in the group, or the player is solo
		-- If source isn't using IgniteTracker, we won't know if they have Ignite, so just assume they do if they're using fire spells
		if (eventType == "SPELL_DAMAGE" and spellSchool == spellSchoolCheck and select(2, UnitClass(sourceName)) == "MAGE" and spellCrit and (UnitInParty(sourceName) or GetNumGroupMembers() == 0) and igniters[sourceName] ~= 0) then
			local _, _, spellIcon = GetSpellInfo(spellID)
			if spellIcon == nil then
				if spellName == "Blast Wave" then
					spellIcon = 135903
				else
					_, _, spellIcon = GetSpellInfo(spellName)
				end
				
				if spellIcon == nil then spellIcon = 134400 end
			end
			if combustCrits[sourceName] then
				combustCrits[sourceName] = combustCrits[sourceName] + 1
			end
			table.insert(critTable, sourceName .. " " .. damageAmount .. " " .. spellIcon)
			
			crits = "       "
			for k, v in pairs(critTable) do
				local name, amount, icon = string.split(" ", v)
				if k > 14 then
					table.remove(critTable, 1)
				end
				crits = "|T"..icon..":0|t " .. "|cff3fc6ea" .. name .. "|r " .. amount .. "\n" .. crits
			end
			critFrame.crit1:SetText(crits)
		end
		
		-- Add the total Ignite to the crit window
		if (eventType == "SPELL_AURA_REMOVED") then
			if spellName == igniteName then
				-- Sometimes the final tick of the Ignite comes after the AURA_REMOVED in the combat log
				-- since they come at the exact same time - put in a small delay to catch it.
				C_Timer.After(0.1, function()
					if igniteTotal > 0 then
						table.insert(critTable, igniteOwner .. " " .. "|c00ffff00" .. igniteTotal .. "|r " .. igniteSpellIcon)
						
						crits = "       "
						for k, v in pairs(critTable) do
							local name, amount, icon = string.split(" ", v)
							if k > 9 then
								table.remove(critTable, 1)
							end
							crits = "|T"..icon..":0|t " .. "|cff3fc6ea" .. name .. "|r " .. amount .. "\n" .. crits
						end
						critFrame.crit1:SetText(crits)
						
						igniteTotal = 0
					end
				end)
			elseif spellName == fireVulnName then
				scorchTable[destGUID .. "_stack"] = 0
			end
		end

		-- Need to alert if the "Fire Vulnerability" piece of Scorch was resisted
		if (eventType == "SPELL_MISSED" and spellName == fireVulnName) then
			-- Flash a notifcation in the bar
			scorchbar:SetStatusBarColor(.2, .3, .9)
			scorchbar.tf:SetText("** Fire Vuln Resist **")
			
			-- Put the normal bar and stack count back
			C_Timer.After(1.5, function()
				scorchbar:SetStatusBarColor(.9, .3, .1)
				if currentTarget ~= nil then
					scorchbar.tf:SetText(scorchTable[currentTarget .. "_stack"])
				end
			end);
		
		end
		
		-- Target died, clear Ignite and Scorch bars
		if eventType == "UNIT_DIED" and destGUID == currentTarget then
			igniteIcon:Hide()
			ignitebar:Hide()
			scorchbar:Hide()
			scorchIcon:Hide()
			scorchStack = 0
			
			scorchTable[destGUID .. "_time"] = nil
			scorchTable[destGUID .. "_storedTime"] = nil
			scorchTable[destGUID .. "_stack"] = nil
		end
	end
	
	-- Update the Ignite and Scorch bars when target is changed
	if event == "PLAYER_TARGET_CHANGED" then
		if currentTarget ~= nil then
			scorchTable[currentTarget .. "_storedTime"] = GetTime()
		end
		
		--print("t")
		--addon:checkThreat("player")
		
		
		-- Get the ID of the current target
		currentTarget = UnitGUID("target")
		
		-- Hide currently active timers
		igniteIcon:Hide()
		ignitebar:Hide()
		scorchbar:Hide()
		scorchIcon:Hide()
		scorchStack = 0
		endTime = 0

		if currentTarget == nil then
			-- do nothing if no target
		elseif scorchTable[currentTarget .. "_stack"] == nil or scorchTable[currentTarget .. "_stack"] == 0 then
			-- Set Scorch stacks to 0 for a new target
			scorchTable[currentTarget .. "_stack"] = 0
		else
			-- Get stored values for this unit from the table
			scorchStack = scorchTable[currentTarget .. "_stack"]
			timeLeft = scorchTable[currentTarget .. "_time"]
			storedTime = scorchTable[currentTarget .. "_storedTime"]
			
			--print(currentTarget, scorchStack, timeLeft, storedTime)

			-- Calculate what time the current Scorch debuff will end
			if timeLeft ~= nil and storedTime ~= nil then
				endTime = GetTime() + timeLeft - (GetTime() - storedTime)
			end
			
			-- Update the bar
			
			scorchbar:Show()
			scorchIcon:Show()
			scorchbar.tf:SetText(scorchStack)
			
			-- Start a new timer loop starting at the current value
			scorchbar:SetScript("OnUpdate", function(self, elapsed)
				scorchTimer = endTime - GetTime()
				scorchTable[currentTarget .. "_time"] = scorchTimer
				scorchTable[currentTarget .. "_storedTime"] = GetTime()

				self:SetValue(scorchTimer)
				
				-- Timer is up, hide the bar and set stored values to nil
				if scorchTimer <= 0.05 then
					scorchbar:Hide()
					scorchIcon:Hide()
					scorchStack = 0
					scorchTable[currentTarget .. "_time"] = nil
					scorchTable[currentTarget .. "_storedTime"] = nil
					scorchTable[currentTarget .. "_stack"] = nil
				end
			end)
			
		end
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		--local talenName, talentID, row, column, selected, maxpoints, unknown, something = GetTalentInfo(2, 3)
		
		-- Check players talents and see if Ignite (2,3) and Improved Scorch (2,10) are talented
		_, _, _, _, igniteTalented = GetTalentInfo(talentCheckPage, talentCheckNumber)
		_, _, _, _, scorchTalented = GetTalentInfo(2, 10)
		
		-- Let other users of IgniteTracker know
		C_ChatInfo.SendAddonMessage("IGNITETRACKER", igniteTalented .. "," .. scorchTalented, "RAID")

		if debug > 0 then
			if igniteTalented >= 1 then	print("Ignite talented") else print("Ignite not talented") end
			if scorchTalented >= 1 then print("Improved Scorch talented") else print("Improved Scorch not talented") end
		end
	end
	
	-- Receive messages from other IgniteTracker users
	if event == "CHAT_MSG_ADDON" then
		if prefix == "IGNITETRACKER" then
			local hasIgnite, hasScorch = string.split(",", msg)
			sender, _ = string.split("-", sender)
			if hasIgnite ~= "0" then
				igniters[sender] = 1
			else
				igniters[sender] = 0
			end
		end
	end
	
	if event == "PLAYER_REGEN_ENABLED" then
		for idx = 1, 6 do
			combustIcons[idx]:Hide()
		end
	end
	
	-- if event == "INSPECT_READY" then
		---- Seems that Classic API can't inspect other's talents
		-- print("Inspect Ready")
		-- local tname, _, _, _, talented = GetTalentInfo(3, 3, 1, isInspect, "target")
		-- print(tname)
	-- end
		
end

-- This does not work under Classic API
function addon:getDebuffTimeRemaining(spellname)
	for i=1,40 do
		local name, icon, stack, _, _, etime = UnitDebuff("target",i)
		if name == spellname then
			--print("entered time function")
			debuffTime = etime-GetTime()
			return debuffTime
		end
	end
	return 0
end

-------------------------
---     Functions     ---
-------------------------

-- Minimap toggle function
function addon:maptoggle(mtoggle)
	if ( debug == 1 ) then print("icon state: " .. mtoggle) end
	
	local mmTbl = {
		icon = mtoggle
	}
	
	IgniteTrackerDB["minimap"] = mmTbl
	
	if mtoggle == "0" or mtoggle == 0 then
		if ( debug >= 1 ) then print("hiding icon") end
		igniteMinimapIcon:Hide("igniteIcon")
	else
		if (igniteMinimapIcon:IsRegistered("igniteIcon")) then
			igniteMinimapIcon:Show("igniteIcon")
		else
			igniteMinimapIcon:Register("igniteIcon", IgniteTrackerMinimapData, IgniteTrackerDB)
			igniteMinimapIcon:Show("igniteIcon")
		end
	end
end

-- Frostmode toggle function
function addon:frosttoggle(fmtoggle)
	if ( debug == 1 ) then print("frostmode state: " .. fmtoggle) end

	local fmTbl = {
		frostmode = fmoggle
	}
	
	IgniteTrackerDB["frostmode"] = fmTbl
	
	if fmtoggle == 0 then
		frostmode = 0
		talentCheckPage = 2
		talentCheckNumber = 3
		spellSchoolCheck = 4
		print("Frost Mode disabled")
	else
		talentCheckPage = 3
		talentCheckNumber = 2
		spellSchoolCheck = 16
		print("Frost Mode enabled")
	end
end

-- Crit frame toggle function
function addon:crittoggle(cftoggle)
	if ( debug == 1 ) then print("crit frame state: " .. cftoggle) end

	local cfTbl = {
		critframe = cftoggle
	}
	
	IgniteTrackerDB["critFrameShow"] = cfTbl
	
	-- if cftoggle == 0 then
		-- critFrame:Show()
	-- else
		-- critFrame:Hide()
	-- end
end

-- Get Anchor Postion
function addon:getAnchorPosition(anchor)
	local posTbl = IgniteTrackerDB[anchor]

	if posTbl == nil then
		return "CENTER", 0, 0
	else
		-- Table exists, get the value if it is defined
		relativePoint = posTbl["relativePoint"] or "CENTER"
		xPos = posTbl["xPos"] or "-100"
		yPos = posTbl["yPos"] or "0"
		return relativePoint, xPos, yPos
	end
end

function addon:setAnchorPosition(anchor, relativePoint, xPos, yPos)
	posTbl = {
		relativePoint = relativePoint,
		xPos = xPos,
		yPos = yPos,
	}

	ignitebar:SetPoint(relativePoint, xPos, yPos)

	IgniteTrackerDB[anchor] = posTbl
end

-- Function to retrieve Saved Variables
function addon:getSV(category, variable)
	local vartbl = IgniteTrackerDB[category]
	
	if vartbl == nil then
		vartbl = {}
	end
	
	if ( vartbl[variable] ~= nil ) then
		return vartbl[variable]
	else
		return nil
	end
end

-- Get threat
function addon:checkThreat(unit)
	if unit == "player" or UnitName("player") == unit or UnitInParty(unit) then
		local _, _, threatPercent, _, _ = UnitDetailedThreatSituation(unit, "target")
		threatPercent = threatPercent or 0
		return string.format("%02d", threatPercent)
	else
		return 0
	end
end

---------------------
-- Register Events --
---------------------
igniteConfig:RegisterEvent("ADDON_LOADED")
igniteConfig:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
igniteConfig:RegisterEvent("PLAYER_TARGET_CHANGED")
igniteConfig:RegisterEvent("PLAYER_ENTERING_WORLD")
igniteConfig:RegisterEvent("PLAYER_REGEN_ENABLED")
C_ChatInfo.RegisterAddonMessagePrefix("IGNITETRACKER")
igniteConfig:RegisterEvent("CHAT_MSG_ADDON")
--igniteConfig:RegisterEvent("INSPECT_READY")
igniteConfig:SetScript("OnEvent", onevent)