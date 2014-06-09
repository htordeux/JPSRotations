------------------------------------
-- BUTTON
------------------------------------

	local button = CreateFrame("Button","RotationButton", UIParent, "SecureActionButtonTemplate")

    button:ClearAllPoints()
    --button:SetWidth(32)
	--button:SetHeight(32)
	button:SetSize(36, 36)
	button:SetPoint("CENTER") -- button:SetPoint(point, ofsx, ofsy)
	
	button:EnableMouse(true)
	button:SetMovable(true)
	button:RegisterForClicks("LeftButtonUp","RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", button.StartMoving)
	button:SetScript("OnDragStop", button.StopMovingOrSizing)

--	local backdrop = {
--		-- path to the background texture
--		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background", 
--		-- path to the border texture
--		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
--		-- true to repeat the background texture to fill the frame, false to scale it
--		tile = true,
--		-- size (width or height) of the square repeating background tiles (in pixels)
--		tileSize = 32,
--		-- thickness of edge segments and square size of edge corners (in pixels)
--		edgeSize = 36,
--		-- distance from the edges of the frame to those of the background texture (in pixels)
--		insets = { left = 4, right = 4, top = 4, bottom = 4 }
--	}

--	button:SetBackdropColor(0,1,0,0) -- frame:SetBackdropColor(red,green,blue,alpha);
--	button:SetBackdropBorderColor(1,0,0,0) -- frame:SetBackdropBorderColor(red,green,blue,alpha)
--  Alpha (opacity) for the graphic (0.0 = fully transparent, 1.0 = fully opaque) (number) 

	button.texture = button:CreateTexture("ARTWORK") -- create the icon texture
	button.texture:SetPoint('TOPRIGHT', button, -2, -2) -- inset it by 2px or pt or w/e the game uses
	button.texture:SetPoint('BOTTOMLEFT', button, 2, 2)
	button.texture:SetTexCoord(0.07, 0.92, 0.07, 0.93) -- cut off the blizzard border
	button.texture:SetTexture("Interface\\AddOns\\JPS\\Media\\basquiat.tga") -- set the default texture
	
	button.border = button:CreateTexture(nil, "OVERLAY") -- create the border texture
	button.border:SetParent(button) -- link it with the icon frame so it drags around with it
	button.border:SetPoint('TOPRIGHT', button, 1, 1) -- outset the points a bit so it goes around the spell icon
	button.border:SetPoint('BOTTOMLEFT', button, -1, -1)
	button.border:SetTexture(jps.GUIborder) -- set the texture

	button:SetScript("OnEnter",  function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText("Click for Options")
		GameTooltip:AddLine("Rotation", 1, 1, 1)
		GameTooltip:Show()
    end)

    button:SetScript("OnLeave",  function (self)
        GameTooltip:Hide()
    end)
    
	button:SetAttribute("type", "macro")                        
	button:SetAttribute("macro", false)
	button:SetAttribute("macrotext", macro)

	button:Hide()

------------------------------------
-- MESSAGEINFOFRAME http://wowprogramming.com/forums/development/633
------------------------------------

local MessageInfoFrame = CreateFrame("MessageFrame","MessageInfoFrame", UIParent)

MessageInfoFrame:ClearAllPoints()
MessageInfoFrame:SetSize(250,50)
MessageInfoFrame:SetPoint("CENTER", 0, 200)
MessageInfoFrame:SetFrameStrata("FULLSCREEN_DIALOG")

MessageInfoFrame:SetBackdrop({
	bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = 1, tileSize = 32, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
MessageInfoFrame:SetBackdropColor(0,0,0,0)

MessageInfoFrame:EnableMouse(true)
MessageInfoFrame:SetMovable(true)
MessageInfoFrame:RegisterForDrag("LeftButton")
MessageInfoFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
MessageInfoFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

MessageInfoFrame:SetAllPoints()
MessageInfoFrame:SetFont("Fonts\\FRIZQT__.TTF",28)
--MessageInfoFrame:SetJustifyH("CENTER") -- CENTER LEFT RIGHT
MessageInfoFrame:SetJustifyV("BOTTOM") -- BOTTOM MIDDLE TOP
MessageInfoFrame:Hide()

jps.MessageInfo = {}
jps.listener.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", function() jps.MessageInfo = {} end)
local UpdateMessageInfo = function ()
	for _,info in ipairs(jps.MessageInfo) do
		if info[1] then
			MessageInfoFrame:Show()
			MessageInfoFrame:AddMessage(info[2])
		break end
		MessageInfoFrame:Clear()
	end
	if not jps.Combat then
		MessageInfoFrame:Hide()
		MessageInfoFrame:Clear()
	end
end

--MessageInfoFrame:SetScript("OnUpdate", function(self, elapsed)
--	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
--	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
--	if (self.TimeSinceLastUpdate > jps.UpdateInterval) then
--		if jps.Combat then
--			self.TimeSinceLastUpdate = 0
--		end
--		UpdateMessageInfo()
--	end
--end)

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








	




