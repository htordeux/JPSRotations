-- jps.MultiTarget for "MindSear" 48045
-- jps.Interrupts for "Semblance spectrale" 112833 -- because lose the orbs in Kotmogu Temple
-- jps.UseCDs for "Shadow Word: Pain" 589 on "mouseover"

local L = MyLocalizationTable
local canDPS = jps.canDPS

local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitChannelInfo = UnitChannelInfo
local UnitGUID = UnitGUID

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

local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin

----------------------------
-- ROTATION
----------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
local playerhealth =  jps.hp("player","abs")
local playerhealthpct = jps.hp("player")
local playermana = jps.roundValue(UnitPower("player",0)/UnitPowerMax("player",0),2)
	
----------------------
-- HELPER
----------------------

local Orbs = UnitPower("player",13) -- SPELL_POWER_SHADOW_ORBS 	13
local NaaruGift = tostring(select(1,GetSpellInfo(59544))) -- NaaruGift 59544
local Desesperate = tostring(select(1,GetSpellInfo(19236))) -- "Prière du désespoir" 19236
local MindBlast = tostring(select(1,GetSpellInfo(8092))) -- "Mind Blast" 8092
local VampTouch = tostring(select(1,GetSpellInfo(34914)))
local ShadowPain = tostring(select(1,GetSpellInfo(589)))
local MindSear = tostring(select(1,GetSpellInfo(48045)))

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER > 2 sec
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

----------------------
-- TARGET ENEMY
----------------------

local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default
local EnemyCount = jps.RaidEnemyCount()

-- set focus an enemy targeting you
if canDPS("mouseover") and not jps.UnitExists("focus") and jps.UnitIsUnit("mouseovertarget","player") then
	jps.Macro("/focus mouseover")
	local name = GetUnitName("focus")
	print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
-- set focus an enemy healer
elseif canDPS("mouseover") and not jps.UnitExists("focus") and jps.EnemyHealer("mouseover") then
	jps.Macro("/focus mouseover")
	local name = GetUnitName("focus")
	print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
end

-- CONFIG priest.get("KeepFocus") check if you want keep focus set manually
if jps.UnitExists("focus") and not canDPS("focus") then
	if not priest.get("KeepFocus") then jps.Macro("/clearfocus") end
end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS("focus") then rangedTarget =  "focus"
elseif canDPS("mouseover") then rangedTarget = "mouseover"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("focustarget") then rangedTarget = "focustarget"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

local fnPainEnemyTarget = function(unit)
	if canDPS(unit) and not jps.myDebuff(589,unit) and not jps.myLastCast(589) then
		return true end
	return false
end

local fnVampEnemyTarget = function(unit)
	if canDPS(unit) and not jps.myDebuff(34914,unit) and not jps.myLastCast(34914) then
		return true end
	return false
end

-- if enemy is casting sure is not under control ^^
local SilenceEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do
	if jps.canCast(15487,unit) then
		if jps.IsCastingHeal(unit) then
			SilenceEnemyTarget = unit
		break end
	end
end
if SilenceEnemyTarget == nil then
	for _,unit in ipairs(EnemyUnit) do
		if jps.canCast(15487,unit) then
			if jps.ShouldKick(unit) then -- jps.IsCastingControl(unit)
				SilenceEnemyTarget = unit
			break end
		end
	end
end

local DeathEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if priest.canShadowWordDeath(unit) then 
		DeathEnemyTarget = unit
	break end
end

local PainEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if fnPainEnemyTarget(unit) then 
		PainEnemyTarget = unit
	break end
end

local VampEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if fnVampEnemyTarget(unit) then
		VampEnemyTarget = unit
	break end
end

local DispelOffensiveEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if jps.DispelOffensive(unit) then
		DispelOffensiveEnemyTarget = unit
	break end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

local LeapFriendFlag = nil 
for _,unit in ipairs(FriendUnit) do
	if priest.unitForLeap(unit) and jps.FriendAggro(unit) and jps.LoseControl(unit) then
		if jps.buff(23335,unit) or jps.buff(23333,unit) then -- 23335/alliance-flag -- 23333/horde-flag 
			LeapFriendFlag = unit
		end
	end
end

local isArena, _ = IsActiveBattlefieldArena()
local RenewFriend = nil 
for _,unit in ipairs(FriendUnit) do
	if isArena == 1 and jps.hp(unit) < priest.get("HealthEmergency")/100 and not jps.buff(139,unit) then
		RenewFriend = unit
	break end
end

-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- SPELLSTOPCASTING
----------------------------------------------------------

if jps.buff(47585,"player") then return end -- "Dispersion" 47585
	
--	SpellStopCasting() -- "Mind Flay" 15407 -- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
local canCastMindBlast = false
local channeling = select(1,UnitChannelInfo("player")) -- "Mind Flay" is a channeling spell 
if channeling == tostring(select(1,GetSpellInfo(15407))) and not jps.debuff(2944,rangedTarget) then -- not debuff "Devouring Plague" 2944
	-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
	if (jps.cooldown(8092) == 0) and jps.buff(81292,"player") then 
		canCastMindBlast = true
	-- "Divine Insight" proc "Mind Blast" 8092 -- "Divine Insight" Clairvoyance divine 109175 gives BUFF 124430
	elseif jps.buff(124430) then
		canCastMindBlast = true
	-- "Mind Blast" 8092
	elseif (jps.cooldown(8092) == 0) and (Orbs < 3) then 
		canCastMindBlast = true
	end
end

if canCastMindBlast then
	SpellStopCasting()
	spell = 8092;
	target = rangedTarget;
return end

-- Avoid interrupt Channeling
if jps.ChannelTimeLeft() > 0 then return nil end


----------------------------
-- MESSAGE FRAME TABLE
----------------------------

	local ManaPlayer = false
	if playermana < 0.50 then ManaPlayer = true end
	local MessageInfo = {
		{ManaPlayer ,"LOW MANA:|cffa335ee "..playermana},
	}
	
	jps.MessageInfo = setmetatable(MessageInfo, {__index = function(t, index) return index end})

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------

local fnOrbs = function(unit)
	if not jps.UseCDs then return false end
	if jps.LoseControl(unit) then return false end
	if Orbs == 0 then return false end
	if Orbs < 3 and jps.hp(unit) < 0.20 then return true end
	if Orbs < 3 and jps.EnemyHealer(unit) then return true end
	if Orbs < 3 and jps.UnitIsUnit(unit.."target","player") then return true end
	return false
end

local parseControl = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear(rangedTarget) , rangedTarget },
	-- "Silence" 15487
	{ 15487, EnemyCaster(rangedTarget) == "caster" , rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.canCast(64044,rangedTarget) and fnOrbs(rangedTarget)  , rangedTarget , "Psychic Horror_"..rangedTarget },
	-- "Psyfiend" 108921 Démon psychique
	{ 108921, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
}

local parseControlFocus = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear("focus") , "focus" , "Fear_".."focus" },
	-- "Silence" 15487
	{ 15487, EnemyCaster("focus") == "caster" , "focus" , "Silence_Caster_".."focus" },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.canCast(64044,"focus") and fnOrbs("focus")  , "focus" , "Psychic Horror_".."focus" },
	-- "Psyfiend" 108921 Démon psychique
	{ 108921, playerAggro and priest.canFear("focus") ,"focus"},
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear("focus") , "focus" },
}

local parseHeal = {
	-- "Prière du désespoir" 19236
	{ 19236, select(2,GetSpellBookItemInfo(Desesperate))~=nil , "player" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" , "Healthstone_" },
	-- "Power Word: Shield" 17	
	{ 17, playerAggro and not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" },
	-- "Renew" 139 Self heal when critical 
	{ 139, not jps.buff(139,"player") , "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	{ 33076, playerAggro and not jps.buff(33076,"player") , "player" },
}

local parseAggro = {
	-- "Semblance spectrale" 112833
	{ 112833, jps.Interrupts and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral_" },
	-- "Dispersion" 47585
	{ 47585,  playerhealthpct < 0.40 , "player" , "Aggro_Dispersion_" },
	-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
	-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
	{ 586, jps.IsSpellKnown(108942) and playerhealthpct < priest.get("HealthEmergency")/100 , "player" , "Aggro_Oubli" },
	{ 586, jps.glyphInfo(55684) and playerhealthpct < priest.get("HealthEmergency")/100 , "player" , "Aggro_Oubli" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {
	-- "Shadowform" 15473 -- UnitAffectingCombat("player") == 1
	{ 15473, not jps.buff(15473) , "player" },
	-- "Spectral Guise" gives buff 119032
	{"nested", not jps.Combat and not jps.buff(119032,"player") , 
		{
			-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Inner Fire" 588 Keep Inner Fire up 
			{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, not jps.buff(21562,"player") , "player" },
			-- "Renew" 139 Self heal when critical 
			{ 139, playerhealthpct < 0.90 and not jps.buff(139,"player"), "player" },
			-- "Enhanced Intellect" 79640 -- "Alchemist's Flask 75525
			{ {"macro","/use item:75525"}, jps.buffDuration(79640,"player") < 900 , "player" },
		},
	},
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, jps.IsSpellKnown(110744) and playerIsInterrupt , "player" , "Interrupt_DivineStar_" },
	
	-- FOCUS CONTROL
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "SILENCE_MultiUnit_" },
	{ "nested", canDPS("focus") and not jps.LoseControl("focus") , parseControlFocus },
	{ "nested", canDPS(rangedTarget) and not jps.LoseControl(rangedTarget) , parseControl },
	-- Offensive Dispel -- "Dissipation de la magie" 528 -- includes canDPS
	{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive("focus") , "focus" , "|cff1eff00DispelOffensive_".."focus" },
	{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },
	{ 528, jps.castEverySeconds(528,2) and type(DispelOffensiveEnemyTarget) == "string"  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },

	-- PLAYER AGGRO
	{ "nested", playerAggro , parseAggro },

	-- "Devouring Plague" 2944
	{ 2944, Orbs == 3 , rangedTarget , "ORBS_3_" },
	-- "Devouring Plague" 2944 -- orbs < 3 if timetodie < few sec
	{ 2944, Orbs == 2 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "ORBS_2_LowHealth_" },
	{ 2944, Orbs == 2 and jps.myDebuffDuration(34914,rangedTarget) > (6 + jps.GCD*3) and jps.myDebuffDuration(589,rangedTarget) > (6 + jps.GCD*3) , rangedTarget , "ORBS_2_Buff_" },

	-- "Mind Blast" 8092 -- "Glyph of Mind Spike" 33371 gives buff 81292 
	{ 8092, (jps.buffStacks(81292) == 2) , rangedTarget , "Blast" },
	-- "Mind Blast" 8092 -- "Divine Insight" 109175 gives buff 124430 Attaque mentale est instantanée et ne coûte pas de mana.
	{ 8092, jps.buff(124430) , rangedTarget , "Divine Insight" }, -- "Divine Insight" Clairvoyance divine 109175
	-- "Mind Blast" 8092 -- 8 sec cd
	{ 8092, not jps.Moving , rangedTarget },
	-- "Shadow Word: Death " "Mot de l'ombre : Mort" 32379
	{ 32379, jps.hp(rangedTarget) < 0.20 , rangedTarget, "castDeath_"..rangedTarget },
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "Death_MultiUnit_" },
	
	-- "Mind Spike" 73510 -- "From Darkness, Comes Light" 109186 gives buff -- "Surge of Darkness" 87160 -- 10 sec
	{ 73510, jps.buffStacks(87160,"player") == 2 , rangedTarget },
	{ 73510, jps.buff(87160) and jps.buffDuration(87160) < (jps.GCD*4) , rangedTarget },
	{ 73510, jps.buff(87160) and jps.myDebuff(34914,rangedTarget) , rangedTarget }, -- debuff "Vampiric Touch" 34914

	-- "Vampiric Embrace" 15286
	{ 15286, AvgHealthLoss < priest.get("HealthDPS")/100 , "player" },
	-- SELF HEAL
	{ "nested", playerhealthpct < priest.get("HealthEmergency")/100 , parseHeal },
	-- "Renew" 139 FriendUnit in Arena
	{ 139, type(RenewFriend) == "string" , RenewFriend },

	-- "Mass Dispel" 32375 "Dissipation de masse"
	-- "Dispel" "Purifier" 527 -- UNAVAILABLE IN SHADOW FORM 15473
	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325 , type(LeapFriendFlag) == "string" , LeapFriendFlag , "|cff1eff00Leap_MultiUnit_" },

	-- "Vampiric Touch" 34914
	{ 34914, not jps.Moving and type(VampEnemyTarget) == "string" , VampEnemyTarget , "Vamp_MultiUnit_" },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },
	{ 589, jps.UseCDs and fnPainEnemyTarget("mouseover") and playermana > 0.75 , "mouseover" , "Pain_MultiUnit_MOUSEOVER_" },	

	-- "Vampiric Touch" 34914 Keep VT up with duration
	{ 34914, not jps.Moving and UnitHealth(rangedTarget) > 120000 and jps.myDebuff(34914,rangedTarget) and jps.myDebuffDuration(34914,rangedTarget) < (jps.GCD*2) and not jps.myLastCast(34914) , rangedTarget , "VT_Keep_" },
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and jps.myDebuffDuration(589,rangedTarget) < (jps.GCD*2) and not jps.myLastCast(589) , rangedTarget , "Pain_Keep_"..rangedTarget },
	-- "Vampiric Touch" 34914 
	{ 34914, not jps.Moving and UnitHealth(rangedTarget) > 120000 and not jps.myDebuff(34914,rangedTarget) and not jps.myLastCast(34914) , rangedTarget , "VT_On_" },
	-- "Shadow Word: Pain" 589 Keep up
	{ 589, (not jps.myDebuff(589,rangedTarget)) and not jps.myLastCast(589) , rangedTarget , "Pain_On_"..rangedTarget},

	-- "Mind Flay" 15407 -- "Devouring Plague" 2944 -- "Shadow Word: Pain" 589
	{ 15407, jps.IsSpellKnown(139139) and jps.debuff(2944,rangedTarget) and jps.myDebuffDuration(2944,rangedTarget) < jps.myDebuffDuration(589,rangedTarget) and jps.myDebuff(34914,rangedTarget) , rangedTarget , "MINDFLAYORBS_" },
	
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },

	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, EnemyCount > 3 and priest.get("Cascade") , rangedTarget , "Cascade_"  },
	-- "MindSear" 48045
	{  48045, not jps.Moving and jps.MultiTarget and EnemyCount > 4 and priest.get("MindSear") , rangedTarget  },

	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, UnitAffectingCombat("player")==1 , "player" },

	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Inner Fire" 588 Keep Inner Fire up 
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
	-- "Fortitude" 21562 Keep Fortitude up 
	{ 21562, jps.buffMissing(21562) , "player" },
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget },
}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest Custom", false, true)

-- Vampiric Touch is your primary means of mana regeneration. Casting it costs 3% of your base mana, and it returns 2% of your maximum mana with each tick

-- "Psychic Horror" 6404 -- Consumes all Shadow Orbs to terrify the target, causing them to tremble in horror for 1 sec plus 1 sec per Shadow Orb consumed
-- and to drop their weapons and shield for 8 sec.

-- "Plume angélique" 121536 Angelic Feather gives buff 121557 -- local charge = GetSpellCharges(121536)

-- The only cap we deal with in pvp is the 6% Hit cap
-- Haste > Crit > mastery
-- Transforms your Shadowfiend and Mindbender into a Sha Beast. Not only on changing the aspect of your Shadowfiend/Mindbender, but also removing it from the gcd

-- sPRIEST haste cap? 14873 + 3 ticks Shadow Word Pain(14846) and Devouring Plague(14873)
-- there are two breakpoints that you can reach. The first is at 8,085 Haste Rating and earns you +1 tick to Vampiric Touch and +2 ticks to both Shadow Word Pain and Devouring Plague.
-- The next breakpoint is at 10,124 Haste Rating and earns 2nd extra tick on Vampiric Touch.
-- This is the most important Haste value to reach as it has a large impact on your DPS, but Haste beyond this point continues to remain quite valuable.
-- 18200 is a 3 ticks Vampiric Touch breakpoint, 18215 is the haste cap (50%).

-- Vampiric Embrace -- 3-minute cooldown with a 15-second duration. It causes all the single-target damage you deal to heal nearby allies for 50% of the damage
-- Void Shift  -- allows you to swap health percentages with your target raid or party member. It can be used to save raid members, by trading your life with theirs, or to save yourself in the same way
-- Dispersion  -- use Dispersion immediately after using Mind Blast and while none of your DoTs need to be refreshed. In this way, Dispersion will essentially take the place of  Mind Flay in your rotation, which is your weakest spell
-- Divine Insight 109175 -- reset the cooldown on Mind Blast and cause your next Mind Blast within 12 sec to be instant cast and cost no mana.
-- "From Darkness, Comes Light" 109186 gives BUFF -- "Surge of Darkness" 87160 87160 -- Les dégâts périodiques de votre Toucher vampirique ont 20% de chances de permettre à votre prochaine Pointe mentale de ne pas consommer vos effets de dégâts sur la durée, d’être incantée instantanément, de ne pas coûter de mana et d’infliger 50% de dégâts supplémentaires. Limité à 2 charges.
-- "Glyph of Mind Spike" 33371 gives buff 81292 -- non-instant Mind Spikes, reduce the cast time of your next Mind Blast within 9 sec by 50%. This effect can stack up to 2 times.