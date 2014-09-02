-- jps.MultiTarget for Chakra: Sanctuary 81206
-- jps.Interrupts for "Semblance spectrale" 112833
-- jps.UseCDs for "Divine Star" Holy 110744 Shadow 122121 ONLY on LowestImportantUnit
-- jps.Defensive Heal table is { "player","focus","target","targettarget","mouseover" }

local L = MyLocalizationTable
local spellTable = {}
local parseMoving = {}
local parseControl = {}
local parseControlFocus = {}
local parseDispel = {}
local parseDamage = {}

local UnitIsUnit = UnitIsUnit
local canDPS = jps.canDPS
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local ipairs = ipairs
local GetUnitName = GetUnitName
local tinsert = table.insert
local UnitClass = UnitClass

local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin

local POH = tostring(select(1,GetSpellInfo(596)))
local Hymn = tostring(select(1,GetSpellInfo(64843))) -- "Divine Hymn" 64843
local Serenity = tostring(select(1,GetSpellInfo(88684))) -- "Holy Word: Serenity" 88684
local Chastise = tostring(select(1,GetSpellInfo(88625))) -- Holy Word: Chastise 88625
local Santuary = tostring(select(1,GetSpellInfo(88685))) -- Holy Word: Sanctuary 88685

local ChakraSanctuary = tostring(select(1,GetSpellInfo(81206))) -- Chakra: Sanctuary 81206
local ChakraChastise = tostring(select(1,GetSpellInfo(81209))) -- Chakra: Chastise 81209
local ChakraSerenity = tostring(select(1,GetSpellInfo(81208))) -- Chakra: Serenity 81208

local sanctuaryPOH = "/cast "..ChakraSanctuary.."\n".."/cast "..POH
local sanctuaryHymn = "/cast "..ChakraSanctuary.."\n".."/cast "..Hymn
local macroSerenity = "/cast "..Serenity
local macroChastise = "/cast "..Chastise
local macroCancelaura = "/cancelaura "..ChakraSerenity.."\n".."/cancelaura "..ChakraSanctuary -- takes 1 GCD
local macroCancelauraChastise = macroCancelaura.."\n"..macroChastise -- takes 2 GCD

local ClassEnemy = {
	["WARRIOR"] = "cac",
	["PALADIN"] = "caster",
	["HUNTER"] = "cac",
	["ROGUE"] = "cac",
	["PRIEST"] = "caster",
	["DEATHKNIGHT"] = "cac",
	["SHAMAN"] = "caster",
	["MAGE"] = "caster",
	["WARLOCK"] = "caster",
	["MONK"] = "caster",
	["DRUID"] = "caster"
}

local EnemyCaster = function(unit)
	if not jps.UnitExists(unit) then return false end
	local _, classTarget, classIDTarget = UnitClass(unit)
	return ClassEnemy[classTarget]
end

----------------------------
-- ROTATION
----------------------------

local priestHolyPvP = function()

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	local timerShield = jps.checkTimer("ShieldTimer")
	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER > 2 sec
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	-- if jps.Defensive Heal table is { "player","focus","target","targettarget","mouseover" }
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(priest.get("HealthRaid")/100) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local PlayerIsFacingLowest = jps.PlayerIsFacing(LowestImportantUnit,30)	-- Angle value between 10-180

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

--	local ShieldTarget = nil
--	local ShieldTargetHealth = 100
--	for _,unit in ipairs(FriendUnit) do
--		if priest.unitForShield(unit) then
--			local unitHP = jps.hp(unit)
--			if unitHP < ShieldTargetHealth then
--				ShieldTarget = unit
--				ShieldTargetHealth = unitHP
--			end
--		end
--	end

	local MendingTarget = nil
	local MendingTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingTargetHealth then
				MendingTarget = unit
				MendingTargetHealth = unitHP
			end
		end
	end
	
	local BindingHealTarget = nil
	local BindingHealTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForBinding(unit) then -- Health < priest.AvgAmountFlashHeal
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealTargetHealth then
				BindingHealTarget = unit
				BindingHealTargetHealth = unitHP
			end
		end
	end
	
	-- {"Magic", "Poison", "Disease", "Curse"}
	--local DispelTarget = jps.FindMeDispelTarget( {"Magic"} )
	local DispelTargetRole = nil
	for _,unit in ipairs(FriendUnit) do 
		if jps.RoleInRaid(unit) == "HEALER" and jps.canDispel(unit,{"Magic"}) then
			DispelTargetRole = unit
		break end
	end

	local DispelFriendlyTarget = nil
	local DispelFriendlyTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		local unitHP = jps.hp(unit)
		if jps.DispelFriendlyRBG(unit) then
			if unitHP < DispelFriendlyTargetHealth then
				DispelFriendlyTarget = unit
				DispelFriendlyTargetHealth = unitHP
			end
		end
	end
	if DispelFriendlyTarget == nil then
		for _,unit in ipairs(FriendUnit) do
			local unitHP = jps.hp(unit)
			if jps.DispelFriendly(unit,1) then
				if unitHP < DispelFriendlyTargetHealth then
					DispelFriendlyTarget = unit
					DispelFriendlyTargetHealth = unitHP
				end
			end
		end	
	end

	local LeapFriendFlag = nil 
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.hp(unit) < 0.50 then
			if jps.buff(23335,unit) or jps.buff(23333,unit) then -- 23335/alliance-flag -- 23333/horde-flag 
				LeapFriendFlag = unit
			elseif jps.RoleInRaid(unit) == "HEALER" then
				LeapFriendFlag = unit
			end
		end
	end
	
	local RenewTarget = nil
	local RenewTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		local unitHP = jps.hp(unit)
		if not jps.buff(139,unit) and jps.FriendAggro(unit) then
			if unitHP < RenewTargetHealth then
				RenewTarget = unit
				RenewTargetHealth = unitHP
			end
		end
	end
	
	local HealTarget = nil
	for _,unit in ipairs(FriendUnit) do
		if jps.buff(139,unit) and jps.buffDuration(139,unit) < 6 and jps.buffId(81208) then
			HealTarget = unit
		break end
	end
	
	-- "Holy Spark" 131567 "Etincelle sacrée"
	-- On Initial Target increases the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
	local HolySparkTarget = nil
	for _,unit in ipairs(FriendUnit) do
		if jps.buff(131567,unit) then
			HolySparkTarget = unit
		break end
	end

---------------------
-- ENEMY TARGET
---------------------
	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default

	-- set focus an enemy targeting you
	if canDPS("mouseover") and not jps.UnitExists("focus") and jps.UnitIsUnit("mouseovertarget","player") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffAttack Player set as FOCUS")
	end
	
	-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
	if jps.UnitExists("focus") and not canDPS("focus") then
		if jps.getConfigVal("keep focus") == 0 then jps.Macro("/clearfocus") end 
	end

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("focus") then rangedTarget =  "focus"
	elseif canDPS("mouseover") then rangedTarget = "mouseover"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	end
	-- if your target is friendly keep it as target
	if not jps.canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local DeathEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canShadowWordDeath(unit) and LowestImportantUnitHpct > 0.25 then 
			DeathEnemyTarget = unit
		break end
	end

	local DispelOffensiveEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if jps.DispelOffensive(unit) and LowestImportantUnitHpct > priest.get("HealthDPS")/100 then
			DispelOffensiveEnemyTarget = unit
		break end
	end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING
----------------------------------------------------------

	local InterruptTable = {
		{priest.Spell.flashHeal, priest.get("HealthEmergency")/100 , jps.buff(27827) },
		{priest.Spell.greaterHeal, priest.get("HealthDPS")/100 , jps.buff(27827) },
		{priest.Spell.heal, 1 , false },
		{priest.Spell.prayerOfHealing, priest.get("HealthDPS")/100 , jps.MultiTarget or jps.buffId(81206) or jps.buff(27827) }
	}

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )
	
----------------------------
-- MESSAGE FRAME TABLE
----------------------------

	local ImportantUnitName = GetUnitName(LowestImportantUnit)
	local MessageInfo = {
		{jps.buffId(81208),"SERENITY:|cffa335ee "..ImportantUnitName},
		{jps.buffId(81209),"CHASTISE:|cffa335ee "},
		{jps.buffId(81206),"SANCTUARY"},
	}

	if CountInRange > 2 and AvgHealthLoss < priest.get("HealthRaid")/100 and jps.cooldown(126135) == 0 then
		tinsert(MessageInfo,1,{true,"LIGHTWELL"})
	elseif CountInRange > 2 and AvgHealthLoss < priest.get("HealthRaid")/100 and jps.cooldown(64843) == 0 then
		tinsert(MessageInfo,1,{true,"HYMNE"})
	end
	jps.MessageInfo = setmetatable(MessageInfo, {__index = function(t, index) return index end})

------------------------
-- LOCAL TABLES
------------------------

	parseControl = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ 88625, not jps.buffId(81208) and not jps.buffId(81206) , rangedTarget  , "|cFFFF0000Chastise_NO_Chakra_"..rangedTarget },
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_Chakra_"..rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseControlFocus = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ 88625, not jps.buffId(81208) and not jps.buffId(81206) , "focus"  , "|cFFFF0000Chastise_NO_Chakra_".."focus" },
		{ 88625, jps.buffId(81209) , "focus" , "|cFFFF0000Chastise_Chakra_".."focus" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear("focus") , "focus" , "Fear_".."focus" },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, EnemyCaster("focus") == "cac" and priest.canFear("focus") , "focus" },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, EnemyCaster("focus") == "cac" and priest.canFear("focus") , "focus" },
	}

	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelTargetRole) == "string" , DispelTargetRole , "|cff1eff00DispelTargetRole_MultiUnit_" },
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00DispelFriendlyTarget_MultiUnit_" },
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , priest.get("Leap") and type(LeapFriendFlag) == "string" , LeapFriendFlag , "|cff1eff00Leap_MultiUnit_" },
	}
	
	parseDamage = {
		-- Chakra: Chastise 81209
		{ 81209, not jps.buffId(81209) , "player" , "|cffa335eeChakra_Chastise" },
		-- "Chastise" 88625 -- Chakra: Chastise 81209
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_"..rangedTarget },
		-- "Flammes sacrées" 14914
		{ 14914, jps.buffId(81209) , rangedTarget },
		-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
		{ 129250, jps.buffId(81209) , rangedTarget },
		-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 targeted enemy 
		{ 589, priest.get("ShadowPain") and TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget  },
		-- "Châtiment" 585
		{ 585, jps.buffId(81209) and not jps.Moving , rangedTarget  },
	}

------------------------
-- SPELL TABLE ---------
------------------------

-- Set Holy Word: Sanctuary 88685 as NextSpell if I cast manually Chakra Sanctuary
-- if jps.buffId(81206) and jps.cooldown(88685) == 0 then jps.NextSpell = Santuary end
	
local spellTable = {

	-- "Esprit de rédemption" 27827/spirit-of-redemption
	{ "nested", jps.buff(27827) , 
		{
			-- "Divine Hymn" 64843
			{ 64843, CountInRange > 2 and AvgHealthLoss < priest.get("HealthRaid")/100 , "player" },
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit },
			-- "Prayer of Healing" 596
			{ 596, (type(POHTarget) == "string") and jps.buffStacks(63735,"player") == 2 , POHTarget },
			-- "Soins supérieurs" 2060
			{ 2060, jps.buffStacks(63735,"player") == 2 , LowestImportantUnit  },
			-- "Prière de guérison" 33076
			{ 33076, not jps.buffTracker(33076) , LowestImportantUnit },
			-- "Soins rapides" 2061
			{ 2061, LowestImportantUnitHpct < priest.get("HealthDPS")/100 , LowestImportantUnit },
			-- "Renew" 139
			{ 139, type(RenewTarget) == "string" , RenewTarget },
			-- "Soins rapides" 2061
			{ 2061, true , LowestImportantUnit },
		},
	},
	-- "Spectral Guise" gives buff 119032
	{"nested", not jps.Combat and not jps.buff(119032,"player") , 
		{
			-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Inner Fire" 588 Keep Inner Fire up 
			{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, jps.buffMissing(21562) , "player" },
			-- "Enhanced Intellect" 79640 -- "Alchemist's Flask 75525
			{ {"macro","/use item:75525"}, jps.buffDuration(79640,"player") < 900 , "player" },
		},
	},

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), playerIsStun and jps.useTrinketBool(1) , "player" },
	-- "Guardian Spirit"
	{ 47788, playerIsStun and not jps.useTrinketBool(1) and jps.hp("player") < 0.40 , "player" },
	{ 47788, playerIsStun and not jps.useTrinketBool(1) and LowestImportantUnitHpct < 0.40 , LowestImportantUnit },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 110744, playerIsInterrupt and jps.IsSpellKnown(110744) and jps.hp("player") < priest.get("HealthEmergency")/100 , "player" , "Interrupt_DivineStar" },
	{ 110744, playerIsInterrupt and jps.IsSpellKnown(110744) and PlayerIsFacingLowest and CheckInteractDistance(LowestImportantUnit,4) == 1 , LowestImportantUnit , "FACING_Interrupt_DivineStar_" },
	-- "Spectral Guise" -- "Semblance spectrale" 112833 -- fast out of combat drinking
	{ 112833, jps.Interrupts and playerAggro and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },

	-- FOCUS CONTROL -- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
	{ {"macro",macroCancelaura}, jps.checkTimer("Chastise") == 0 and not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) and jps.buffId(81208) and jps.cooldown(81208) == 0 , "player"  , "Cancelaura_Chakra_" },
	{ {"macro",macroCancelaura}, jps.checkTimer("Chastise") == 0 and not jps.LoseControl("focus") and canDPS("focus") and jps.buffId(81206) and jps.cooldown(81206) == 0 , "player"  , "Cancelaura_Chakra_" },
	-- Chastise is in ParseControl -- rangedTarget returns "target" by default, sometimes could be friend
	{ "nested", LowestImportantUnitHpct > 0.40 and not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },
	{ "nested", LowestImportantUnitHpct > 0.40 and not jps.LoseControl("focus") and canDPS("focus") , parseControlFocus },

	-- Chakra: Serenity 81208 -- "Holy Word: Serenity" 88684
	{ 81208, not jps.buffId(81208) and jps.FinderLastMessage("Chastise_NO") == true , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and LowestImportantUnitHpct < priest.get("HealthDPS")/100 and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and not jps.FaceTarget and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },
	
	-- DISPEL	
	{ "nested", LowestImportantUnitHpct > priest.get("HealthEmergency")/100 , parseDispel },

	-- "Guardian Spirit"
	{ 47788, jps.FriendAggro(LowestImportantUnit) and LowestImportantUnitHpct < 0.40 , LowestImportantUnit },
	-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
	{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit , "Serenity_"..LowestImportantUnit },
	-- "Soins rapides" 2061 "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and (jps.buffDuration(114255) < 4) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Void Shift" 108968
	{ 108968, not playerAggro and UnitIsUnit(LowestImportantUnit,"player")~=1 and LowestImportantUnitHpct < 0.40 and jps.hp("player") > 0.85 , LowestImportantUnit , "Emergency_VoidShift_"..LowestImportantUnit },

	-- "Prière de guérison" 33076 -- UnitAffectingCombat("player") == 1
	{ 33076, not jps.buffTracker(33076) and jps.FriendAggro(LowestImportantUnit) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },
	-- "Holy Spark" 131567 "Etincelle sacrée"
	{ "nested", jps.buffId(81208) and type(HolySparkTarget) == "string" and jps.hp(HolySparkTarget) < priest.get("HealthEmergency")/100 , 
		{
			-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
			{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , HolySparkTarget , "HolySparkTarget_" },
			-- "Soins supérieurs" 2060
			{ 2060, not jps.Moving and jps.buffStacks(63735,"player") == 2 , HolySparkTarget , "HolySparkTarget_" },
			-- "Soins rapides" 2061
			{ 2061, not jps.Moving and jps.buffStacks(63735,"player") < 2 , HolySparkTarget , "HolySparkTarget_" },
		},
	},

	-- PLAYER AGGRO
	{ "nested", playerAggro and jps.hp("player") < priest.get("HealthDPS")/100 ,
		{
			-- "Pierre de soins" 5512
			{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
			-- "Prière du désespoir" 19236
			{ 19236, select(2,GetSpellBookItemInfo(priest.Spell["Desesperate"]))~=nil , "player" },
			-- "Prière de guérison" 33076
			{ 33076, not jps.buff(33076) , "player" , "Aggro_Mending_Player" },
			-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
			-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
			{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
			{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },

			{ "nested", jps.hp("player") < priest.get("HealthEmergency")/100 ,
				{
					-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
					{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , "player" , "Aggro_Serenity_Player" },
					-- "Soins rapides" 2061 "From Darkness, Comes Light"
					{ 2061, jps.buff(114255) , "player" },
					-- "Circle of Healing" 34861
					{ 34861, true , "player" , "Aggro_COH_Player" },
					-- "Divine Star" Holy 110744 Shadow 122121
					{ 110744, jps.IsSpellKnown(110744) and jps.hp("player") < 0.50 , "player" , "Aggro_DivineStar" },
					-- "Soins rapides" 2061 "Holy Spark" 131567 "Etincelle sacrée" -- increases the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
					{ 2061, not jps.Moving and jps.buff(131567) ,"player" , "Aggro_SoinsRapides_HolySpark_Player" },
					-- "Power Word: Shield" 17 
					{ 17, jps.hp("player") < 0.50 and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield_Player" },
					-- "Soins rapides" 2061
					{ 2061, not jps.Moving and jps.hp("player") < 0.50 , "player" , "Aggro_SoinsRapides_Player" },
				},
			},
			-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
			{ 139, not jps.buff(139,"player") , "player" ,"Aggro_Renew_Player" },
			-- "Don des naaru" 59544
			{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) , "player" , "Aggro_Naaru_Player" },
			-- Dispel Player 527
			{ 527, not playerIsStun and jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Dispel_Player" },
		},
	},
	
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) and LowestImportantUnitHpct > priest.get("HealthDPS")/100 , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },
	{ 528, jps.castEverySeconds(528,10) and type(DispelOffensiveEnemyTarget) == "string"  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
	{ 32379, priest.canShadowWordDeath(rangedTarget) and LowestImportantUnitHpct > 0.25 , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },
	
	-- "Infusion de puissance" 10060 
	{ 10060, AvgHealthLoss < priest.get("HealthRaid")/100 , "player" , "POWERINFUSION_" },

	-- GROUP HEAL
	{ "nested", CountInRange > 2 and AvgHealthLoss < priest.get("HealthRaid")/100 ,
		{
			-- "Lightwell" 126135
			--{ 126135, LowestImportantUnitHpct < 0.50 , "player" ,"Lightwell" },
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit ,"COH_"..LowestImportantUnit , "COH_GROUP_" },
			-- "Cascade" Holy 121135
			{ 121135, jps.IsSpellKnown(121135) , LowestImportantUnit },
			
			{ "nested", not jps.Moving and jps.MultiTarget and (type(POHTarget) == "string") ,
				{
					-- "Divine Hymn" 64843 -- Chakra: Sanctuary 81206
					--{ {"macro",sanctuaryHymn}, not playerAggro and not jps.buffId(81206) and jps.cooldown(81206) == 0 and jps.cooldown(64843) == 0 and AvgHealthLoss < 0.50 , "player" , "|cffa335eeSanctuary_HYMN"},
					-- "Prayer of Healing" 596 -- Chakra: Sanctuary 81206 -- increase 25 % Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
					{ {"macro",sanctuaryPOH}, not jps.buffId(81206) and jps.cooldown(81206) == 0 and jps.cooldown(596) == 0 , POHTarget , "|cffa335eeSanctuary_POH"},
					{ 596, true , POHTarget },
				},
			},
		},
	},

	{ "nested", LowestImportantUnitHpct < priest.get("HealthDPS")/100 ,
		{
			-- "Divine Star" Holy 110744 Shadow 122121
			{ 110744, jps.UseCDs and priest.unitForBinding(LowestImportantUnit) and jps.IsSpellKnown(110744) and PlayerIsFacingLowest and CheckInteractDistance(LowestImportantUnit,4) == 1 , LowestImportantUnit , "FACING_DivineStar_" },
			-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
			{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit , "Emergency_Serenity_"..LowestImportantUnit },
			-- "Prière de guérison" 33076 
			{ 33076, (type(MendingTarget) == "string") , MendingTarget , "Emergency_MendingTarget_" },
			{ "nested", not jps.Moving and LowestImportantUnitHpct < priest.get("HealthEmergency")/100 , 
				{
					-- "Soins supérieurs" 2060
					{ 2060,  jps.buffStacks(63735,"player") == 2 , LowestImportantUnit , "Emergency_SoinsSup_"..LowestImportantUnit  },
					-- "Soins de lien"
					{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "Emergency_Lien_" },
					-- "Soins rapides" 2061
					{ 2061, (LowestImportantUnitHpct < 0.50) , LowestImportantUnit , "Emergency_SoinsRapides_40%_"..LowestImportantUnit },
					-- "Soins rapides" 2061
					{ 2061, jps.buffStacks(63735,"player") < 2, LowestImportantUnit , "Emergency_SoinsRapides_"..LowestImportantUnit },
				},
			},
			-- "Power Word: Shield" 17 
			{ 17, LowestImportantUnitHpct < 0.40 and not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
			-- "Circle of Healing" 34861
			{ 34861, AvgHealthLoss < priest.get("HealthRaid")/100 , LowestImportantUnit , "Emergency_COH_"..LowestImportantUnit },
			{ 34861, CountInRange > 2 , LowestImportantUnit , "Emergency_COH_"..LowestImportantUnit },
			-- "Don des naaru" 59544
			{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) , LowestImportantUnit , "Emergency_Naaru_"..LowestImportantUnit },
			-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
			{ 139, not jps.buff(139,LowestImportantUnit) , LowestImportantUnit , "Emergency_Renew_"..LowestImportantUnit },
		},
	},
	
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- DAMAGE -- Chakra: Chastise 81209
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > priest.get("HealthDPS")/100 , parseDamage },

	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, type(RenewTarget) == "string" , RenewTarget , "Renew_Target_" },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") , "player" },
	-- "Soins" 2050
	{ 2050, type(HealTarget) == "string" , HealTarget , "Heal_Renew_" },
	{ 2050, LowestImportantUnitHealth > priest.AvgAmountHeal , LowestImportantUnit },

}

	local spell = nil
	local target = nil
	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","HOLY", priestHolyPvP, "Holy Priest Custom", false , true)

-- Haste at least 12.51% (4721) preferably up to 16.66% (7082) cap
-- to ensure we get additional ticks from HW: Sanctuary and the Glyphed Renew.

-- Chakra: Serenity 81208
-- Increases the healing done by your single-target healing spells by 25%
-- causes them to refresh the duration of your Renew on the target, and transforms your Holy Word: Chastise spell into Holy Word: Serenity.
-- "Holy Word: Serenity" 88684
-- Instantly heals the target for 12367 to 14517 (+ 130% of Spell power)
-- "Holy Word: Serenity" increases the critical effect chance of your healing spells on the target by 25% for 6 sec. 10 sec cooldown.

-- Chakra: Sanctuary 81206
-- Increases the healing done by your area of effect healing spells by 25% -- Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
-- reduces the cooldown of your Circle of Healing spell by 2 sec, and transforms your Holy Word: Chastise spell into Holy Word: Sanctuary
-- Holy Word: Sanctuary 88685
-- Blesses the ground with divine light, healing all within it for 461 to 547 (+ 5.83% of Spell power) every 2 sec for 30 sec.
-- Only one Sanctuary can be active at a time  Healing effectiveness diminishes for each player beyond 6 within the area.

-- Chakra: Chastise 81209
-- Increases the damage done by your Shadow and Holy spells by 50%, grants a 10% chance for Smite to reset the cooldown of Holy Word: Chastise
-- reduces the mana cost of Smite and Holy Fire by 90%, and transforms your Holy Word spell back into Holy Word: Chastise
-- Holy Word: Chastise 88625
-- Chastise the target for 627 to 702 (+ 61.4% of Spell power) Holy damage, and disorients them for 3 sec -- 30 sec cooldown.

-- "Serendipity" 63735
-- When you heal with Binding Heal or Flash Heal, the cast time of your next Greater Heal or Prayer of Healing spell is reduced by 20% 
-- and mana cost reduced by 20%. Stacks up to 2 times. Lasts 20 sec.

-- "Guardian Spirit" 47788
-- Calls a guardian spirit to watch over the friendly target. The spirit increases the healing received by the target by 60%
-- and also prevents the target from dying by sacrificing. Lasts 10 sec. Castable while stunned.

-- "Lightwell" This spell can be used while Tanking, Kiting, Blinded, Stunned, Disoriented, Sapped, Casting another heal or spell

-- "Holy Spark" 131567 (Priest PvP Healing 2P Bonus Holy Spark). When you cast Prayer of Mending, the initial target is blessed with a Holy Spark
-- increasing the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
-- 1.Serenity -- 2.PoM -- 3.Greater Heal which uses your HOLY SPARK buff proc the greater heal which is also likely to crit due to Serenity buff

-- From Darkness, Comes Light has been buffed this patch increasing it's procs when using Renew, Circle of Healing, Prayer of Mending, and Prayer of Healing

-- "Divine Insight" 109175
-- When you cast Greater Heal or Prayer of Healing, there is a 40% chance
-- your next Prayer of Mending will not trigger its cooldown, and will jump to each target instantly.

-- priest.Spell.renew = 139; 
local spellStaticTable = {
		{ 139, 'not jps.buff(priest.Spell.renew)' , "player" },
		{ 585, 'priest.get("Chastise") and jps.buffDuration(priest.Spell.renew) > 0 and not jps.Moving' , "target" },
		--{ 139, 'not jps.buff(139)' , "player" },
		--{ 585, 'jps.buffId(588)' , "target" }, 
	}

jps.registerRotation("PRIEST","HOLY", function()

	local spell = nil
	local target = nil
	local spell,target = parseStaticSpellTable(spellStaticTable)
	return spell,target

end, "Holy Priest Static" )
