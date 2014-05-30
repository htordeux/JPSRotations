local L = MyLocalizationTable
local canDPS = jps.canDPS

local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitChannelInfo = UnitChannelInfo

local ClassEnemy = {
	["WARRIOR"] = false,
	["PALADIN"] = true,
	["HUNTER"] = false,
	["ROGUE"] = false,
	["PRIEST"] = true,
	["DEATHKNIGHT"] = true,
	["SHAMAN"] = true,
	["MAGE"] = true,
	["WARLOCK"] = true,
	["MONK"] = true,
	["DRUID"] = true
}

local EnemyCaster = function(unit)
	local _, classTarget, classIDTarget = UnitClass(unit)
	if ClassEnemy[classTarget] then return true end
return false
end

local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin

----------------------------
-- ROTATION
----------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.90)
local playerIsInterrupt = jps.checkTimer("PlayerInterrupt")
local playerhealth =  jps.hp("player","abs")
local playerhealthpct = jps.hp("player")
	
----------------------
-- HELPER
----------------------

local Orbs = UnitPower("player",13)
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
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER
local playerControlled = jps.LoseControl("player",{"CC"})

----------------------
-- TARGET ENEMY
----------------------

local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default
local EnemyCount = jps.RaidEnemyCount()

if canDPS("mouseover") and jps.RoleClass("mouseover") == "HEALER" then rangedTarget = "mouseover"
elseif canDPS("target") then rangedTarget =  "target"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("focustarget") then rangedTarget = "focustarget"
elseif canDPS("mouseover") then rangedTarget = "mouseover"
end

if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

local FearEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if priest.canFear(unit) and not jps.LoseControl(unit) then
		FearEnemyTarget = unit
	break end
end

local SilenceEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if EnemyCaster(unit) and not jps.LoseControl(unit) then 
		SilenceEnemyTarget = unit
	break end
end

local DeathEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if priest.canShadowWordDeath(unit) then 
		DeathEnemyTarget = unit
	break end
end

local PainEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if not jps.myDebuff(589,unit) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) then 
		PainEnemyTarget = unit
	break end
end

local VampEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if not jps.myDebuff(34914,unit) and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) then 
		VampEnemyTarget = unit
	break end
end

local MassDispellTarget = nil
for _,unit in ipairs(EnemyUnit) do
	if jps.buff(divineshield,unit) then
		MassDispellTarget = unit
		jps.Macro("/target "..MassDispellTarget)
	break end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

local VoidShiftFriend = nil
for _,unit in ipairs(FriendUnit) do
	local role = UnitGroupRolesAssigned(unit)
	if role == "HEALER" then
		if jps.hp(unit) < 0.35 and not playerAggro and UnitIsUnit(unit,"player")~=1 and jps.hp("player") > 0.85 and jps.UseCDs then 
			VoidShiftFriend = unit
		break end
	end
end

local LeapFriend = nil
for _,unit in ipairs(FriendUnit) do
	if priest.unitForLeap(unit) then 
		LeapFriend = unit
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

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------

local parseControl = {
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget , "Fear_"..rangedTarget },
	{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "Fear_MultiUnit_" },
	-- "Psychic Horror" 64044 "Horreur psychique"
	{ 64044, priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) and Orbs > 0 , rangedTarget , "Psychic Horror_"..rangedTarget },
	-- "Silence" 15487
	{ 15487, EnemyCaster(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget , "Silence_"..rangedTarget },
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit_" },
	-- "Psyfiend" 108921 Démon psychique
	{ 108921, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
}

local parseHeal = {
	-- "Prière du désespoir" 19236
	{ 19236, playerhealthpct < 0.55 and select(2,GetSpellBookItemInfo(Desesperate))~=nil , "player" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
	-- "Vampiric Embrace" 15286
	{ 15286, true , "player" },
	-- "Power Word: Shield" 17	
	{ 17, not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" }, -- Shield
	-- "Renew" 139 Self heal when critical 
	{ 139, not jps.buff(139,"player"), "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	{ 33076, not jps.buff(33076,"player") , "player" },
}

local parseAggro = {
	-- "Dispersion" 47585
	{ 47585,  playerhealthpct < 0.35 , "player" , "Aggro_Dispersion_" },
	-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
	{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
	{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
	-- "Semblance spectrale" 108968
	{ 112833, jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral_" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and playerIsStun , "player" },
	
	{ "nested", jps.PvP , parseControl },
	{ "nested", playerAggro , parseAggro },

	-- "Void Shift" 108968
	--{ 108968, type(VoidShiftFriend) == "string" , VoidShiftFriend , "Emergency_VoidShift_" },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, EnemyCount > 2 and priest.get("Cascade") , rangedTarget , "Cascade_"  },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, playerIsInterrupt > 0 , "player" , "Interrupt_DivineStar_" },
	-- "Devouring Plague" 2944
	{ 2944, Orbs > 0 and UnitHealth(rangedTarget) < 120000 , rangedTarget },
	{ 2944, Orbs == 3 , rangedTarget },
	{ 2944, Orbs >= 2 and jps.myDebuffDuration(34914,rangedTarget) > 6 and jps.myDebuffDuration(589,rangedTarget) > 6 , rangedTarget },
	-- "Mind Blast" 8092 -- "Glyph of Mind Spike" 33371 gives buff 81292 
	{ 8092, (jps.buffStacks(81292) == 2) , rangedTarget , "Blast" },
	-- "Mind Blast" 8092 -- "Divine Insight" 109175 gives buff 124430 Attaque mentale est instantanée et ne coûte pas de mana.
	{ 8092, jps.buff(124430) , rangedTarget , "Divine Insight" }, -- "Divine Insight" Clairvoyance divine 109175
	-- "Mind Spike" 73510 -- "From Darkness, Comes Light" 109186 gives BUFF -- "Surge of Darkness" 87160
	{ 73510, jps.buff(87160) , rangedTarget }, -- buff 87160 "Surge of Darkness"
	-- "Shadow Word: Death " "Mot de l'ombre : Mort" 32379
	{ 32379, jps.hp(rangedTarget) < 0.20 , rangedTarget, "castDeath_"..rangedTarget },
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "Death_MultiUnit_" },

	{ "nested", playerhealthpct < 0.75 , parseHeal },

	{ "nested", jps.Interrupts ,
		{
			-- "Mass Dispel" 32375 "Dissipation de masse"
			{ 32375 , type(MassDispellTarget) == "string" , MassDispellTarget , "|cff1eff00MassDispell_MultiUnit_" },
		
			-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
			{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget }, -- (jps.LastCast ~= priest.Spell["DispelMagic"])
			-- "Leap of Faith" 73325 -- "Saut de foi"
			{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
			-- "Dispel" "Purifier" 527 -- UNAVAILABLE IN SHADOW FORM 15473
		},
	},

	-- "Mind Blast" 8092
	{ 8092, true , rangedTarget },
	-- "Dispersion" 47585
	{ 47585, (UnitPower ("player",0)/UnitPowerMax ("player",0) < 0.50) and jps.cooldown(8092) > 6 , "player" , "Dispersion_Mana" },
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },

	-- MOVING
	{ "nested", jps.Moving ,
		{
			-- "Shadow Word: Pain" 589 Keep SW:P up with duration
			{ 589, jps.myDebuff(589,rangedTarget) and jps.myDebuffDuration(589,rangedTarget) < 2 and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget , "Move_Pain_Expire_"..rangedTarget },
			-- "Shadow Word: Pain" 589 Keep up
			{ 589, (not jps.myDebuff(589,rangedTarget)) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget , "Move_Pain_New_"..rangedTarget},
		}
	},
	
	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, UnitAffectingCombat("player")==1 and (UnitPower ("player",0)/UnitPowerMax ("player",0) > 0.20) , "player" },

	-- MULTITARGET
	{  48045, jps.MultiTarget and EnemyCount > 4 and priest.get("MindSear") , rangedTarget  },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },	
	-- "Vampiric Touch" 34914
	{ 34914, type(VampEnemyTarget) == "string" , VampEnemyTarget , "Vamp_MultiUnit_" },

	-- "Mind Flay" 15407 -- "Devouring Plague" 2944 -- "Shadow Word: Pain" 589
	{ 15407, jps.IsSpellKnown(139139) and jps.debuff(2944,rangedTarget) and jps.myDebuffDuration(2944,rangedTarget) < jps.myDebuffDuration(589,rangedTarget) and jps.myDebuff(34914,rangedTarget) , rangedTarget , "MINDFLAYORBS_" },

	-- APPLY and MAINTAIN Shadow Word: Pain and Vampiric Touch
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and jps.myDebuffDuration(589,rangedTarget) < 2 and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget , "Pain_Expire_"..rangedTarget },
	-- "Shadow Word: Pain" 589
	{ 589, not jps.myDebuff(589,rangedTarget) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget , "Pain_New_"..rangedTarget },
	-- "Vampiric Touch" 34914 Keep VT up with duration
	{ 34914, UnitHealth(rangedTarget) > 120000 and jps.myDebuff(34914,rangedTarget) and jps.myDebuffDuration(34914,rangedTarget) < 2.2 and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },
	-- "Vampiric Touch" 34914 
	{ 34914, UnitHealth(rangedTarget) > 120000 and not jps.myDebuff(34914,rangedTarget) and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },

	-- "Inner Fire" 588 Keep Inner Fire up 
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget },
}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest Custom", false, true)

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