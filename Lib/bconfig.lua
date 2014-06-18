------------------------------------
-- BUTTON
------------------------------------

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
		if info[1] then
			MessageInfoFrame:Show()
			MessageInfoFrame.text:SetText(info[2])
		break end
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








	




