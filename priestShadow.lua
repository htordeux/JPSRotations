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

local spell = nil
local target = nil

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
local playerIsInterrupt = jps.checkTimer("PlayerInterrupt")
local playerhealth =  jps.hp("player","abs")
local playerhealthpct = jps.hp("player")
local playermana = UnitPower ("player",0)/UnitPowerMax ("player",0)
	
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

local HealerEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	local unitguid = UnitGUID(unit)
	if jps.EnemyHealer[unitguid] then
		HealerEnemyTarget = unit
	break end
end

if type(HealerEnemyTarget) == "string" and not jps.UnitExists("focus") and canDPS(HealerEnemyTarget) then
	jps.Macro("/focus "..HealerEnemyTarget)
end

-- set focus an enemy targeting you
if jps.UnitExists("mouseover") and not jps.UnitExists("focus") and canDPS("mouseover") then
	if jps.UnitIsUnit("mouseovertarget","player") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end
if not canDPS("focus") then jps.Macro("/clearfocus") end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("focustarget") then rangedTarget = "focustarget"
elseif canDPS("mouseover") then rangedTarget = "mouseover"
end

if canDPS(rangedTarget) then
	jps.Macro("/target "..rangedTarget)
end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

local FearEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if priest.canFear(unit) and not jps.LoseControl(unit) then
		if jps.IsCastingControl(unit) then
			FearEnemyTarget = unit
		elseif jps.shouldKickDelay(unit) then
			FearEnemyTarget = unit
		end
	break end
end

local SilenceEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if not jps.LoseControl(unit) and jps.shouldKickDelay(unit) then 
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
	if not jps.myDebuff(589,unit) and not jps.myLastCast(589) then 
		PainEnemyTarget = unit
	break end
end

local VampEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if not jps.myDebuff(34914,unit) and not jps.myLastCast(34914) then
		VampEnemyTarget = unit
	break end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

local LeapFriend = nil
local LeapFriendFlag = nil 
for _,unit in ipairs(FriendUnit) do
	if priest.unitForLeap(unit) and jps.FriendAggro(unit) then
		if jps.buff(23335,unit) or jps.buff(23333,unit) then -- 23335/alliance-flag -- 23333/horde-flag 
			LeapFriendFlag = unit
		else
			LeapFriend = unit
		end
	end
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
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "FEAR_MultiUnit_" },
	{ 8122, priest.canFear(rangedTarget) , rangedTarget , "Fear_"..rangedTarget },
	-- "Silence" 15487
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit_" },
	{ 15487, EnemyCaster(rangedTarget) == "caster" , rangedTarget , "Silence_Caster_"..rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.canCast(64044,rangedTarget) and EnemyCaster(rangedTarget) == "cac" and Orbs < 2 , rangedTarget , "Psychic Horror_"..rangedTarget },
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
	{ 64044, jps.canCast(64044,"focus") and EnemyCaster("focus") == "caster" and Orbs < 2 , "focus" , "Psychic Horror_".."focus" },
}

local parseHeal = {
	-- "Prière du désespoir" 19236
	{ 19236, select(2,GetSpellBookItemInfo(Desesperate))~=nil , "player" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" , "Healthstone_" },
	-- "Vampiric Embrace" 15286
	{ 15286, AvgHealthLoss < priest.get("HealthDPS")/100 , "player" },
	-- "Power Word: Shield" 17	
	{ 17, playerAggro and not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" },
	-- "Renew" 139 Self heal when critical 
	{ 139, not jps.buff(139,"player"), "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	{ 33076, playerAggro and not jps.buff(33076,"player") , "player" },
}

local parseAggro = {
	-- "Dispersion" 47585
	{ 47585,  playerhealthpct < 0.40 , "player" , "Aggro_Dispersion_" },
	-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
	{ 586, jps.IsSpellKnown(108942) and playerhealthpct < priest.get("HealthEmergency")/100 , "player" , "Aggro_Oubli" },
	{ 586, jps.glyphInfo(55684) and playerhealthpct < priest.get("HealthEmergency")/100 , "player" , "Aggro_Oubli" },
	-- "Semblance spectrale" 108968
	{ 112833, jps.IsSpellKnown(112833) and playerhealthpct < priest.get("HealthDPS")/100 , "player" , "Aggro_Spectral_" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	{"nested", not jps.Combat , 
		{
			-- "Dispersion" 47585
			{ 47585, playermana < 0.50 , "player" , "Dispersion_Mana" },
			-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Inner Fire" 588 Keep Inner Fire up 
			{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, not jps.buff(21562,"player") , "player" },
			-- "Shadowform" 15473
			{ 15473, not jps.buff(15473) , "player" },
		},
	},

	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, playerIsInterrupt > 0 , "player" , "Interrupt_DivineStar_" },
	-- "Devouring Plague" 2944
	{ 2944, Orbs == 3 , rangedTarget , "ORBS_3" },
	-- "Devouring Plague" 2944 -- orbs < 3 if timetodie < few sec
	{ 2944, Orbs > 0 and jps.hp(rangedTarget) < 0.20 and not jps.buff(124430) , rangedTarget , "ORBS_20%_NoBuff" },
	{ 2944, Orbs > 1 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "ORBS_2_" },
	{ 2944, Orbs > 1 and jps.myDebuffDuration(34914,rangedTarget) > (6 + jps.GCD*3) and jps.myDebuffDuration(589,rangedTarget) > (6 + jps.GCD*3) , rangedTarget , "ORBS_2_Buff_" },
	
	-- FOCUS CONTROL
	{ "nested", canDPS("focus") and not jps.LoseControl("focus") , parseControlFocus },
	{ "nested", not jps.LoseControl(rangedTarget) , parseControl },
	{ "nested", playerAggro , parseAggro },

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
	{ 73510, jps.buff(87160) and jps.buffDuration(87160) < (jps.GCD*4) , rangedTarget },
	{ 73510, jps.buff(87160) and jps.myDebuff(34914,rangedTarget) , rangedTarget }, -- debuff "Vampiric Touch" 34914
	{ 73510, jps.buff(87160) and jps.myDebuff(589,rangedTarget) , rangedTarget }, -- debuff "Shadow Word: Pain" 589
	
	-- "Vampiric Touch" 34914
	{ 34914, not jps.Moving and playermana < 0.50 and type(VampEnemyTarget) == "string" , VampEnemyTarget , "Vamp_MultiUnit_Mana_" },

	{ "nested", playerhealthpct < priest.get("HealthEmergency")/100 , parseHeal },
	-- "Vampiric Embrace" 15286
	{ 15286, AvgHealthLoss < priest.get("HealthDPS")/100 , "player" },

	-- "Mass Dispel" 32375 "Dissipation de masse"
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },
	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325 , type(LeapFriendFlag) == "string" , LeapFriendFlag , "|cff1eff00Leap_MultiUnit_" },
	{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
	-- "Dispel" "Purifier" 527 -- UNAVAILABLE IN SHADOW FORM 15473

	-- "Vampiric Touch" 34914 Keep VT up with duration
	{ 34914, not jps.Moving and UnitHealth(rangedTarget) > 120000 and jps.myDebuff(34914,rangedTarget) and jps.myDebuffDuration(34914,rangedTarget) < (jps.GCD*2) and not jps.myLastCast(34914) , rangedTarget , "VT_Keep_" },
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and jps.myDebuffDuration(589,rangedTarget) < (jps.GCD*2) and not jps.myLastCast(589) , rangedTarget , "Pain_Keep_"..rangedTarget },
	-- "Vampiric Touch" 34914 
	{ 34914, not jps.Moving and UnitHealth(rangedTarget) > 120000 and not jps.myDebuff(34914,rangedTarget) and not jps.myLastCast(34914) , rangedTarget , "VT_On_" },
	-- "Shadow Word: Pain" 589 Keep up
	{ 589, (not jps.myDebuff(589,rangedTarget)) and not jps.myLastCast(589) , rangedTarget , "Pain_On_"..rangedTarget},
	
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, EnemyCount > 3 and priest.get("Cascade") , rangedTarget , "Cascade_"  },
	-- "MindSear" 48045
	{  48045, not jps.Moving and jps.MultiTarget and EnemyCount > 4 and priest.get("MindSear") , rangedTarget  },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },	
	-- "Vampiric Touch" 34914
	{ 34914, not jps.Moving and type(VampEnemyTarget) == "string" , VampEnemyTarget , "Vamp_MultiUnit_" },

	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, UnitAffectingCombat("player")==1 , "player" },

	-- "Mind Flay" 15407 -- "Devouring Plague" 2944 -- "Shadow Word: Pain" 589
	{ 15407, jps.IsSpellKnown(139139) and jps.debuff(2944,rangedTarget) and jps.myDebuffDuration(2944,rangedTarget) < jps.myDebuffDuration(589,rangedTarget) and jps.myDebuff(34914,rangedTarget) , rangedTarget , "MINDFLAYORBS_" },

	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Inner Fire" 588 Keep Inner Fire up 
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget },
}

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