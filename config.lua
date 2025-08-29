local addonName, addon = ...
local debug = 0
local AceGUI = LibStub("AceGUI-3.0")
local playerFaction = UnitFactionGroup("player")

-- Main options panel
etPanel = CreateFrame("Frame")
etPanel.name = addonName
InterfaceOptions_AddCategory(etPanel)

local title = etPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(addonName)

-- local etPanelText = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
-- etPanelText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
-- etPanelText:SetText("EasyTrade Options")

local usageText = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
usageText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -65)
usageText:SetJustifyH("LEFT")
usageText:SetText("Shift+Click items from bags to assign items to auto-trade for each class.\nIf adding multiple stacks of the same item, insert the item for each stack.")

local usageText2 = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
usageText2:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -353)
usageText2:SetJustifyH("LEFT")
usageText2:SetText("Shift+Click items from bags to assign items to the Quick Trade slots.")

-- local usageText3 = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
-- usageText3:SetPoint("TOPLEFT", usageText, "BOTTOMLEFT", 0, -5)
-- usageText3:SetJustifyH("LEFT")
-- usageText3:SetText("(*Items must be entered with Shift+Click to capture their ItemID*)")

-- Checkbox for Auto Trade
local etAutoCheck = CreateFrame("CheckButton", "etAutoCheck_GlobalName", etPanel, "InterfaceOptionsCheckButtonTemplate")
etAutoCheck_GlobalNameText:SetText("Enable auto trade")
etAutoCheck.tooltipText = "Check to enable automatic placing of items in trade window based on class"

-- Load the current checkbox state when the options panel opens
etAutoCheck:SetScript("OnShow", 
	function()
		local auto = EasyTrade:getAutoTradeStatus()
		
		if ( auto == 1 ) then
			etAutoCheck:SetChecked(true)
		else
			etAutoCheck:SetChecked(false)
		end
	end
)
etAutoCheck:SetPoint("TOPLEFT", etPanel, "TOPLEFT", 20, -40)

-- Store checkbox state in SavedVariables
etAutoCheck:SetScript("OnClick", 
	function()
		if (etAutoCheck:GetChecked()) then 
			if ( debug >= 1 ) then print("Checked!") end
			autoTbl = {
				autoTrade = 1,
			}

			EasyTradeDB["autoTrade"] = autoTbl
		else 
			if ( debug >= 1 ) then print("Unchecked :(") end
			autoTbl = {
				autoTrade = 0,
			}

			EasyTradeDB["autoTrade"] = autoTbl
		end
	end
);


-- Checkbox for minimap button
local etMapCheck = CreateFrame("CheckButton", "etMapCheck_GlobalName", etPanel, "InterfaceOptionsCheckButtonTemplate")
etMapCheck_GlobalNameText:SetText("Show minimap button")
etMapCheck.tooltipText = "Show or Hide the minimap button"

-- Load the current checkbox state when the options panel opens
etMapCheck:SetScript("OnShow", 
	function()
		local maptbl = EasyTradeDB["minimap"]
		
		if ( maptbl.icon == 1 ) then
			etMapCheck:SetChecked(true)
		else
			etMapCheck:SetChecked(false)
		end
	end
)
etMapCheck:SetPoint("TOPLEFT", etPanel, "TOPLEFT", 20, -60)

-- Store checkbox state in SavedVariables
etMapCheck:SetScript("OnClick", 
	function()
		if (etMapCheck:GetChecked()) then 
			if ( debug >= 1 ) then print("Checked!") end
			mapTbl = {
				icon = 1,
			}

			EasyTradeDB["minimap"] = mapTbl
			local tog = 1
			EasyTrade:maptoggle(tog)
		else 
			if ( debug >= 1 ) then print("Unchecked :(") end
			mapTbl = {
				icon = 0,
			}

			EasyTradeDB["minimap"] = mapTbl
			local tog = 0
			EasyTrade:maptoggle(tog)
		end
		
	end
);



-- Events
local function onevent(self, event, arg1, ...)
	if(event == "ADDON_LOADED" and arg1 == "EasyTrade") then
		itemtbl = EasyTradeDB["tradeItems"]
		if itemtbl == nil then
			itemtbl = {}
		end
		
		-----------------------------------
		--- Class Icons and Input Boxes ---
		-----------------------------------
		etPanel.druidButton = etPanel:CreateClassIcon("TOP", etPanel, "TOP", -270, -135, "Druid", nil)
		etPanel.druidBox = etPanel:CreateClassInput("LEFT", etPanel.druidButton, "RIGHT", 10, 0, "Druid", nil)
		
		etPanel.hunterButton = etPanel:CreateClassIcon("TOP", etPanel.druidButton, "BOTTOM", 0, -5, "Hunter", nil)
		etPanel.hunterBox = etPanel:CreateClassInput("LEFT", etPanel.hunterButton, "RIGHT", 10, 0, "Hunter", nil)
		
		etPanel.mageButton = etPanel:CreateClassIcon("TOP", etPanel.hunterButton, "BOTTOM", 0, -5, "Mage", nil)
		etPanel.mageBox = etPanel:CreateClassInput("LEFT", etPanel.mageButton, "RIGHT", 10, 0, "Mage", nil)
		
		if playerFaction == "Alliance" then
			etPanel.paladinButton = etPanel:CreateClassIcon("TOP", etPanel.mageButton, "BOTTOM", 0, -5, "Paladin", nil)
			etPanel.paladinBox = etPanel:CreateClassInput("LEFT", etPanel.paladinButton, "RIGHT", 10, 0, "Paladin", nil)
		else
			etPanel.shamanButton = etPanel:CreateClassIcon("TOP", etPanel.mageButton, "BOTTOM", 0, -5, "Shaman", nil)
			etPanel.shamanBox = etPanel:CreateClassInput("LEFT", etPanel.shamanButton, "RIGHT", 10, 0, "Shaman", nil)
		end
		
		etPanel.priestButton = etPanel:CreateClassIcon("TOP", etPanel.mageButton, "BOTTOM", 0, -35, "Priest", nil)
		etPanel.priestBox = etPanel:CreateClassInput("LEFT", etPanel.priestButton, "RIGHT", 10, 0, "Priest", nil)
		
		etPanel.rogueButton = etPanel:CreateClassIcon("TOP", etPanel.priestButton, "BOTTOM", 0, -5, "Rogue", nil)
		etPanel.rogueBox = etPanel:CreateClassInput("LEFT", etPanel.rogueButton, "RIGHT", 10, 0, "Rogue", nil)
		
		etPanel.warlockButton = etPanel:CreateClassIcon("TOP", etPanel.rogueButton, "BOTTOM", 0, -5, "Warlock", nil)
		etPanel.warlockBox = etPanel:CreateClassInput("LEFT", etPanel.warlockButton, "RIGHT", 10, 0, "Warlock", nil)
		
		etPanel.warriorButton = etPanel:CreateClassIcon("TOP", etPanel.warlockButton, "BOTTOM", 0, -5, "Warrior", nil)
		etPanel.warriorBox = etPanel:CreateClassInput("LEFT", etPanel.warriorButton, "RIGHT", 10, 0, "Warrior", nil)

		---------------------------
		----- Quick Buttons -------
		---------------------------
		
		-- Create Edit Boxes for each quick trade button		
		etPanel.qButton1 = etPanel:CreateQuickEdit("TOP", etPanel.warriorButton, "BOTTOM", 110, -34, "qButton1", 1)
		etPanel.qButton2 = etPanel:CreateQuickEdit("TOP", etPanel.qButton1, "BOTTOM", 0, 0, "qButton2", 1)
		etPanel.qButton3 = etPanel:CreateQuickEdit("TOP", etPanel.qButton2, "BOTTOM", 0, 0, "qButton3", 1)
		etPanel.qButton4 = etPanel:CreateQuickEdit("TOP", etPanel.qButton3, "BOTTOM", 0, 0, "qButton4", 1)
		etPanel.qButton5 = etPanel:CreateQuickEdit("LEFT", etPanel.qButton1, "RIGHT", 45, 0, "qButton5", 1)
		etPanel.qButton6 = etPanel:CreateQuickEdit("TOP", etPanel.qButton5, "BOTTOM", 0, 0, "qButton6", 1)
		etPanel.qButton7 = etPanel:CreateQuickEdit("TOP", etPanel.qButton6, "BOTTOM", 0, 0, "qButton7", 1)
		
		-- Add a label to each box
		local qButton1Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton1Text:SetPoint("RIGHT", etPanel.qButton1, "LEFT", 0, 0); qButton1Text:SetText("1:  ")
		local qButton2Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton2Text:SetPoint("RIGHT", etPanel.qButton2, "LEFT", 0, 0); qButton2Text:SetText("2:  ")
		local qButton3Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton3Text:SetPoint("RIGHT", etPanel.qButton3, "LEFT", 0, 0); qButton3Text:SetText("3:  ")
		local qButton4Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton4Text:SetPoint("RIGHT", etPanel.qButton4, "LEFT", 0, 0); qButton4Text:SetText("4:  ")
		local qButton5Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton5Text:SetPoint("RIGHT", etPanel.qButton5, "LEFT", 0, 0); qButton5Text:SetText("5:  ")
		local qButton6Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton6Text:SetPoint("RIGHT", etPanel.qButton6, "LEFT", 0, 0); qButton6Text:SetText("6:  ")
		local qButton7Text = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); qButton7Text:SetPoint("RIGHT", etPanel.qButton7, "LEFT", 0, 0); qButton7Text:SetText("7:  ")

		---------------------------------
		--- EditBox for Trade Message ---
		---------------------------------
		local broadcastMessage = addon:getBroadcastMessage()

		-- Broadcast label
		local broadcastText = etPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		broadcastText:SetPoint("TOPLEFT", qButton4Text, "BOTTOMLEFT", 0, -20)
		broadcastText:SetText("Broadcast:  ")
		
		-- Broadcast message box
		etPanel.broadcastBox = CreateFrame("EditBox", "etPanel.broadcastBox", etPanel, "InputBoxTemplate")
		etPanel.broadcastBox:SetWidth(300)
		etPanel.broadcastBox:SetHeight(30)
		etPanel.broadcastBox:SetPoint("LEFT", broadcastText, "RIGHT", 5, 0)
		etPanel.broadcastBox:SetMaxLetters(255)
		etPanel.broadcastBox:SetHyperlinksEnabled(false)
		etPanel.broadcastBox:SetText(broadcastMessage)
		etPanel.broadcastBox:SetAutoFocus(false)
		etPanel.broadcastBox:SetCursorPosition(0)
		
		----------------------------------------
		-- Drop Down Menu broadcast channels ---
		-----------------------------------------
		channel = EasyTrade:getBroadcastChannel()
		if channel == 1 then
			channel = "SAY"
		end
		
		print(channel)

		if not broadcastChannels then
		   CreateFrame("Button", "broadcastChannels", etPanel, "UIDropDownMenuTemplate")
		end
		 
		broadcastChannels:ClearAllPoints()
		broadcastChannels:SetPoint("LEFT", etPanel.broadcastBox, "RIGHT", 0, 0)
		broadcastChannels:Show()

		-- list of choices
		channelTbl = {
			channel,
			"RAID",
			"PARTY",
			"INSTANCE",
			"SAY",
		}
		
		--broadcastChannels:SetText("test")

		local customChannels = ""
		for i = 1, 10 do	-- i have no clue how many channels you're allowed to be in at once so i just put 10
			local chanID, chanName = GetChannelName(i)
			if chanName ~= nil then
				if not string.match(chanName, "LookingForGroup") then
					--print(chanName)
					--customChannels = customChannels .. chanName .. ","
					table.insert(channelTbl, chanName)
				end
			end
		end

		-- return dropdown selection
		local function OnClick(self)
			UIDropDownMenu_SetSelectedID(broadcastChannels, self:GetID(), text, value)
			channel = self.value
			if ( debug == 2 ) then print(channel) end
			return channel
		end

		-- dropdown box properties
		local function initialize(self, level)
			local info = UIDropDownMenu_CreateInfo()
			for k,v in pairs(channelTbl) do
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				UIDropDownMenu_AddButton(info, level)
			end
		end

		UIDropDownMenu_Initialize(broadcastChannels, initialize)
		UIDropDownMenu_SetWidth(broadcastChannels, 100);
		UIDropDownMenu_SetButtonWidth(broadcastChannels, 124)
		UIDropDownMenu_SetSelectedID(broadcastChannels, 1)
		UIDropDownMenu_JustifyText(broadcastChannels, "LEFT")

		--------------------------------------------
		--- Intercept the Shift+Click of an item ---
		--- Stolen from Tinypad!                 ---
		--------------------------------------------
		local old_ChatEdit_InsertLink = ChatEdit_InsertLink
		function ChatEdit_InsertLink(text)
			if etPanel.druidBox:HasFocus() then
				etPanel.druidBox:Insert(text)
				return true -- prevents the stacksplit frame from showing
			elseif etPanel.hunterBox:HasFocus() then
				etPanel.hunterBox:Insert(text)
				return true
			elseif etPanel.mageBox:HasFocus() then
				etPanel.mageBox:Insert(text)
				return true
			elseif etPanel.paladinBox ~= nil and etPanel.paladinBox:HasFocus() then
				etPanel.paladinBox:Insert(text)
				return true
			elseif etPanel.priestBox:HasFocus() then
				etPanel.priestBox:Insert(text)
				return true
			elseif etPanel.rogueBox:HasFocus() then
				etPanel.rogueBox:Insert(text)
				return true
			elseif etPanel.shamanBox ~= nil and etPanel.shamanBox:HasFocus() then
				etPanel.shamanBox:Insert(text)
				return true
			elseif etPanel.warlockBox:HasFocus() then
				etPanel.warlockBox:Insert(text)
				return true
			elseif etPanel.warriorBox:HasFocus() then
				etPanel.warriorBox:Insert(text)
				return true
			elseif etPanel.qButton1:HasFocus() then
				etPanel.qButton1:Insert(text)
				return true
			elseif etPanel.qButton2:HasFocus() then
				etPanel.qButton2:Insert(text)
				return true
			elseif etPanel.qButton3:HasFocus() then
				etPanel.qButton3:Insert(text)
				return true
			elseif etPanel.qButton4:HasFocus() then
				etPanel.qButton4:Insert(text)
				return true
			elseif etPanel.qButton5:HasFocus() then
				etPanel.qButton5:Insert(text)
				return true
			elseif etPanel.qButton6:HasFocus() then
				etPanel.qButton6:Insert(text)
				return true
			elseif etPanel.qButton7:HasFocus() then
				etPanel.qButton7:Insert(text)
				return true
			elseif etPanel.broadcastBox:HasFocus() then
				etPanel.broadcastBox:Insert(text)
				return true
			else
				return old_ChatEdit_InsertLink(text)
			end
		end

		-----------------------------------
		--- Drop Down Menu for Profiles ---
		-----------------------------------
		local profiletbl = EasyTradeDB["tradeProfile"]
		if profiletbl == nil then
			profiletbl = {}
		end
				
		if ( profiletbl.profileName == nil ) then
			profile = "Profile 1"
		else
			profile = profiletbl.profileName
		end

		if not profileSelect then
		   CreateFrame("Button", "profileSelect", etPanel, "UIDropDownMenuTemplate")
		end
		 
		profileSelect:ClearAllPoints()
		profileSelect:SetPoint("TOPRIGHT", -15, -20)
		profileSelect:Show()

		-- list of choices
		local profiles = {
			profile,
			"Profile 1",
			"Profile 2",
			"Profile 3",
			"Profile 4",
		}

		-- return dropdown selection
		local function OnClick(self)
			UIDropDownMenu_SetSelectedID(profileSelect, self:GetID(), text, value)
			profile = self.value
			if ( debug == 2 ) then print(profile) end
			updateBox(profile)
			return profile
		end

		-- dropdown box properties
		local function initialize(self, level)
			local info = UIDropDownMenu_CreateInfo()
			for k,v in pairs(profiles) do
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				UIDropDownMenu_AddButton(info, level)
			end
		end

		UIDropDownMenu_Initialize(profileSelect, initialize)
		UIDropDownMenu_SetWidth(profileSelect, 100);
		UIDropDownMenu_SetButtonWidth(profileSelect, 124)
		UIDropDownMenu_SetSelectedID(profileSelect, 1)
		UIDropDownMenu_JustifyText(profileSelect, "LEFT")
		
	end
end

--------------------------------------------------
--- Save items when the Okay button is pressed ---
--------------------------------------------------
etPanel.okay = function (self)
	if debug >= 1 then print("saving...") end
	print(profile)
	
	-- Save trade items
	if playerFaction == "Alliance" then
		txtTbl = {
			Druid = etPanel.druidBox:GetText(),
			Hunter = etPanel.hunterBox:GetText(),
			Mage = etPanel.mageBox:GetText(),
			Paladin = etPanel.paladinBox:GetText(),
			Priest = etPanel.priestBox:GetText(),
			Rogue = etPanel.rogueBox:GetText(),
			Warlock = etPanel.warlockBox:GetText(),
			Warrior = etPanel.warriorBox:GetText(),
			qButton1 = etPanel.qButton1:GetText(),
			qButton2 = etPanel.qButton2:GetText(),
			qButton3 = etPanel.qButton3:GetText(),
			qButton4 = etPanel.qButton4:GetText(),
			qButton5 = etPanel.qButton5:GetText(),
			qButton6 = etPanel.qButton6:GetText(),
			qButton7 = etPanel.qButton7:GetText(),
			broadcast = etPanel.broadcastBox:GetText(),
			broadcastChannel = channel,
		}
	else
		txtTbl = {
			Druid = etPanel.druidBox:GetText(),
			Hunter = etPanel.hunterBox:GetText(),
			Mage = etPanel.mageBox:GetText(),
			Priest = etPanel.priestBox:GetText(),
			Rogue = etPanel.rogueBox:GetText(),
			Shaman = etPanel.shamanBox:GetText(),
			Warlock = etPanel.warlockBox:GetText(),
			Warrior = etPanel.warriorBox:GetText(),
			qButton1 = etPanel.qButton1:GetText(),
			qButton2 = etPanel.qButton2:GetText(),
			qButton3 = etPanel.qButton3:GetText(),
			qButton4 = etPanel.qButton4:GetText(),
			qButton5 = etPanel.qButton5:GetText(),
			qButton6 = etPanel.qButton6:GetText(),
			qButton7 = etPanel.qButton7:GetText(),
			broadcast = etPanel.broadcastBox:GetText(),
			broadcastChannel = channel,
		}
	end

	EasyTradeDB["tradeItems"] = txtTbl

	-- Save profile
	profileTbl = {
		profileName = profile,
	}
	
	EasyTradeDB["tradeProfile"] = profileTbl	
	EasyTradeDB[profile] = txtTbl
	
	if debug >= 1 then print("saved") end
end

----------------------------------
--- Create Class Icon function ---
----------------------------------
function etPanel:CreateClassIcon(point, relativeFrame, relativePoint, xOffset, yOffset, className, idx)

		-- Class Icon
		iconPath = "Interface/Icons/ClassIcon_" .. className .. ".blp"
		local classButton = CreateFrame("Button", nil, etPanel)
		classButton:SetSize(25,25)
		classButton:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
		classButton.t = classButton:CreateTexture(nil, "BACKGROUND")
		classButton.t:SetTexture(iconPath)
		classButton.t:SetAllPoints()
		
		return classButton
end

---------------------------------------
--- Create Class Input Box function ---
---------------------------------------
function etPanel:CreateClassInput(point, relativeFrame, relativePoint, xOffset, yOffset, className, classButton)
	classtbl = EasyTradeDB["tradeItems"]
	if classtbl == nil then
		classtbl = {}
		classText = ""
	else
		-- Table exists, get the value if it is defined
		classText = classtbl[className]
		if classText == nil then
			classText = ""
		end
	end

	local classBox = CreateFrame("EditBox", nil, etPanel, "InputBoxTemplate")
	classBox:SetWidth(500)
	classBox:SetHeight(30)
	classBox:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	classBox:SetMaxLetters(500)
	classBox:SetHyperlinksEnabled(false)
	classBox:SetText(classText)
	classBox:SetAutoFocus(false)
	classBox:SetCursorPosition(0)
	
	return classBox
end

------------------------------
--- Create Button function ---
------------------------------
function etPanel:CreateQuickEdit(point, relativeFrame, relativePoint, xOffset, yOffset, qButtonName, idx)
	-- Make sure the table exists
	qbuttontbl = EasyTradeDB["tradeItems"]
	if qbuttontbl == nil then
		qbuttontbl = {}
		qbText = ""
	else
		-- Table exists, get the value if it is defined
		qbText = qbuttontbl[qButtonName]
		if qbText == nil then
			qbText = ""
		end
	end

	-- Create the edit box
	local qEditBox = CreateFrame("EditBox", nil, etPanel, "InputBoxTemplate");
	qEditBox:SetWidth(200)
	qEditBox:SetHeight(30)
	qEditBox:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	qEditBox:SetMaxLetters(300)
	qEditBox:SetHyperlinksEnabled(false)
	qEditBox:SetText(qbText)
	qEditBox:SetAutoFocus(false)
	qEditBox:SetCursorPosition(0)
	
	return qEditBox
end

--------------------------
--- Load profile items ---
--------------------------
function updateBox(profile)
	classtbl = EasyTradeDB[profile]
	
	if classtbl == nil then
		-- Profile not defined, return blanks
		classtbl = {}
		
		etPanel.druidBox:SetText("")
		etPanel.hunterBox:SetText("")
		etPanel.mageBox:SetText("")
		etPanel.paladinBox:SetText("")
		etPanel.priestBox:SetText("")
		etPanel.rogueBox:SetText("")
		etPanel.warlockBox:SetText("")
		etPanel.warriorBox:SetText("")
		etPanel.qButton1:SetText("")
		etPanel.qButton2:SetText("")
		etPanel.qButton3:SetText("")
		etPanel.qButton4:SetText("")
		etPanel.qButton5:SetText("")
		etPanel.qButton6:SetText("")
		etPanel.qButton7:SetText("")
		etPanel.broadcastBox:SetText("")
		channel = "SAY"
		
	else
		-- profile exists, retrieve the info
		etPanel.druidBox:SetText(classtbl.Druid)
		etPanel.hunterBox:SetText(classtbl.Hunter)
		etPanel.mageBox:SetText(classtbl.Mage)
		etPanel.paladinBox:SetText(classtbl.Paladin)
		etPanel.priestBox:SetText(classtbl.Priest)
		etPanel.rogueBox:SetText(classtbl.Rogue)
		etPanel.warlockBox:SetText(classtbl.Warlock)
		etPanel.warriorBox:SetText(classtbl.Warrior)
		etPanel.qButton1:SetText(classtbl.qButton1)
		etPanel.qButton2:SetText(classtbl.qButton2)
		etPanel.qButton3:SetText(classtbl.qButton3)
		etPanel.qButton4:SetText(classtbl.qButton4)
		etPanel.qButton5:SetText(classtbl.qButton5)
		etPanel.qButton6:SetText(classtbl.qButton6)
		etPanel.qButton7:SetText(classtbl.qButton7)
		etPanel.broadcastBox:SetText(classtbl.broadcast)
		channel = classtbl.broadcastChannel
		
		
		local index={}
		for k,v in pairs(channelTbl) do
		   index[v]=k
		   --print(v)
		   --print(k)
		end
		idx = index[channel]
		print(channel)
		print(idx)
		UIDropDownMenu_Initialize(broadcastChannels, initialize)
		UIDropDownMenu_SetSelectedID(broadcastChannels, idx, channel)

	end
end

etPanel:RegisterEvent("ADDON_LOADED")
etPanel:SetScript("OnEvent", onevent)




