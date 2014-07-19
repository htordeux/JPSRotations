------------------------------------
-- MARKER
------------------------------------

--	  0 - Clear any raid target markers
--    1 - Star
--    2 - Circle
--    3 - Diamond
--    4 - Triangle
--    5 - Moon
--    6 - Square
--    7 - Cross
--    8 - Skull

-- {"skull",false,8} keep it for target to kill
local MarkerTable = { {"Circle",false,2}, {"star",false,1}, {"triangle",false,4}, {"cross",false,7} }
local resetMarkerTable = function()
	MarkerTable = { {"Circle",false,2}, {"star",false,1}, {"triangle",false,4}, {"cross",false,7} }
end

hooksecurefunc("SetRaidTarget",function(unit, index)
	SetRaidTarget(unit, index)
end)

jps.TargetMarker = function(unit,num)
	if unit == nil then return end
	local playerAssistRaid = jps.PlayerIsLeader()
	if not playerAssistRaid then return end
	if IsControlKeyDown() then SetRaidTarget("target",0) return end

	if type(num) == "number" then
		if GetRaidTargetIndex(unit) == nil then SetRaidTarget(unit, num)
		elseif GetRaidTargetIndex(unit) ~= num then SetRaidTarget(unit, num) end
	return end

	if GetRaidTargetIndex(unit) == nil then
		for _,index in ipairs(MarkerTable) do
			if index[2] == false then
				SetRaidTarget(unit, index[3])
				index[2] = true
			break end
		end
	end
	-- if all MarkerTable are true reset the table
	if GetRaidTargetIndex(unit) == nil then
		resetMarkerTable()
	end
end

------------------------------------
-- BUTTON for Mconfig
------------------------------------

local button = CreateFrame("Button","MacroButton", UIParent, "SecureActionButtonTemplate")

button:ClearAllPoints()
button:SetSize(36, 36)
button:SetPoint("TOP",0,-50) -- button:SetPoint(point, ofsx, ofsy)

button:EnableMouse(true)
button:SetMovable(true)
button:RegisterForClicks("LeftButtonUp","RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", button.StartMoving)
button:SetScript("OnDragStop", button.StopMovingOrSizing) 

button.texture = button:CreateTexture("ARTWORK") -- create the icon texture
button.texture:SetPoint('TOPRIGHT', button, -2, -2)
button.texture:SetPoint('BOTTOMLEFT', button, 2, 2)
button.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- cut off the blizzard border
button.texture:SetTexture("INTERFACE/TARGETINGFRAME/UI-RaidTargetingIcon_8") -- set the default texture

button:SetAttribute("type","macro")
button:SetAttribute("macrotext", "/pd");
--button:SetAttribute("macro","Marker") -- Name of Macro

--button:Hide()

------------------------------------
-- MESSAGEINFOFRAME http://wowprogramming.com/forums/development/633
------------------------------------

local MessageInfoFrame = CreateFrame("frame","MessageInfoFrame", UIParent)

MessageInfoFrame:SetBackdrop({
	bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = 1, tileSize = 32, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
MessageInfoFrame:SetBackdropColor(0,0,0,0)

MessageInfoFrame:ClearAllPoints()
MessageInfoFrame:SetSize(250,50)
MessageInfoFrame:SetPoint("CENTER", 0, 200)
MessageInfoFrame:SetFrameStrata("FULLSCREEN_DIALOG")

MessageInfoFrame:EnableMouse(true)
MessageInfoFrame:SetMovable(true)
MessageInfoFrame:RegisterForDrag("LeftButton")
MessageInfoFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
MessageInfoFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

MessageInfoFrame.text = MessageInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MessageInfoFrame.text:SetAllPoints()
MessageInfoFrame.text:SetFont("Fonts\\FRIZQT__.TTF",24)
MessageInfoFrame.text:SetJustifyH("CENTER") -- CENTER LEFT RIGHT
MessageInfoFrame.text:SetJustifyV("MIDDLE") -- BOTTOM MIDDLE TOP

MessageInfoFrame:Hide()

jps.MessageInfo = {}
jps.listener.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", function() jps.MessageInfo = {} end)
local UpdateMessageInfo = function ()
	for _,info in ipairs(jps.MessageInfo) do
		if info[1] == true then
			MessageInfoFrame:Show()
			MessageInfoFrame.text:SetText(info[2])
		break end
		MessageInfoFrame:Hide()
	end
	if not jps.Combat then MessageInfoFrame:Hide() end
end

local MessageInfoFrame_OnUpdate = CreateFrame("Frame")
MessageInfoFrame_OnUpdate:SetScript("OnUpdate", function(self, elapsed)
	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	if (self.TimeSinceLastUpdate > jps.UpdateInterval) then
		if jps.Combat then
			self.TimeSinceLastUpdate = 0
		end
		UpdateMessageInfo()
	end
end)

------------------------------------
-- AFK
------------------------------------

jps.listener.registerEvent("PLAYER_FLAGS_CHANGED", function(unit)
	if unit == "player" then
		jps.createTimer("AFK",10)
	end
end)
-- JumpOrAscendStop() -- MoveBackwardStart() -- MoveBackwardStop()
local playerIsAFK = function(self)
	if jps.checkTimer("AFK") > 0 and UnitIsAFK("player") == 1 then
		JumpOrAscendStart()
	end
end

jps.registerOnUpdate(jps.cachedValue(playerIsAFK,5))






	




