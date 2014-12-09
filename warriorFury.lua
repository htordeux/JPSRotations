-- mConfig:createConfig(titleText,addOn,key,slashCommands)
local addOn = "WARRIOR"
local key = "Default"
warriorConfig = mConfig:createConfig("warrior Config",addOn,key,{"/wf"})

-- mConfig:addSlider(key, text, tooltip, minValue, maxValue, defaultValue,stepSize)
warriorConfig:addText("Rage levels")
warriorConfig:addSlider("RageLevel", "RageLevel Threshold" , " RageLevel for Heroic Strike" , 35, 100, 60, 5)
warriorConfig:addSlider("Health", "HealthLoss Threshold" , " % Health Loss" , 55, 95, 75, 5)

--spell usage checkboxes
warriorConfig:addText("Spell Usage")	
warriorConfig:addCheckBox("Avatar", "use Avatar", "Use Avatar in combat", true)

function warrior.get(name)
    return warriorConfig:get(name)
end

local slashId = "MCONFIG_"..addOn.."_"..key
print("macro for WARRIOR config : ",_G["SLASH_"..slashId.."1"])
-- classDisplayName, class, classID = UnitClass("unit");
-- class String - Localization-independent class name, used as some table keys; e.g. "MAGE", "WARRIOR", "DEATHKNIGHT".
local classPlayer = select(2,UnitClass("player"))
if classPlayer == "WARRIOR" then
	addMacroUIButton("INTERFACE/TARGETINGFRAME/UI-RaidTargetingIcon_8", _G["SLASH_"..slashId.."1"])
end
	
----------------------------
-- ROTATION
----------------------------
	
jps.registerRotation("WARRIOR","FURY",function()

	local spell = nil
	local target = nil
	local player = "player"
	local playerhealth_deficiency =  jps.hp(player,"abs") -- UnitHealthMax(player) - UnitHealth(player)
	local playerhealth_pct = jps.hp(player) 
	local rangedTarget = warrior.rangedTarget()
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
	
	local playerAggro = jps.FriendAggro("player")
	local Rage = jps.buff(12880) -- "Enrage" 12880 "Enrager"
	local playerIsStun = jps.StunEvents() -- return true/false
	local enemycount = jps.RaidEnemyCount()  
	local isboss = UnitLevel(rangedTarget) == -1 or UnitClassification(rangedTarget) == "elite"
	
	jps.Macro("/target "..rangedTarget)
	--jps.Macro("/startattack")
	--jps.Macro("/target "..rangedTarget.."\n/startattack")

	------------------------
	-- SPELL TABLE ---------
	------------------------
	
	-- "Bloodsurge" 46916 "Afflux sanguin"
	-- "Meat Cleaver" 12950 "Fendoir à viande"

	local spellTable = {
	
		-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14  -- Do not use while Dispersion jps.checkTimer(47585) == 0
		--{ jps.useTrinket(0), jps.UseCds },
		--{ jps.useTrinket(1), jps.UseCds },
		-- "Pierre de soins" 5512
		{ {"macro","/use item:5512"} , UnitAffectingCombat("player") == true and select(1,IsUsableItem(5512)) == true and jps.itemCooldown(5512)==0 and (jps.hp("player") < 0.50) , "player" , "_UseItem"},

		-- "Pummel" 6552 "Volée de coups"
		{ warrior.spells["Pummel"], jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
		-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
		{ warrior.spells["MassSpellReflection"], jps.IsCasting(rangedTarget)  and jps.UnitIsUnit("targettarget","player") , rangedTarget , "_Mass Spell Reflection" },
		-- "Shattering Throw" 64382 "Lancer fracassant"
		{ warrior.spells["ShatteringThrow"], jps.rage() > 30 and not jps.debuff(64382,rangedTarget) and (jps.hp(rangedTarget,"abs") > 200000) , rangedTarget , "_Shattering Throw" },

		-- "Brise-genou" 1715 "Hamstring"
		--{ warrior.spells["Hamstring"] , jps.rage() > 10 and (jps.myDebuffDuration(1715) < 3)  , rangedTarget , "_Hamstring" },

		-- "Berserker Rage" 18499 "Rage de berserker"
		{ warrior.spells["BerserkerRage"] , not Rage , "player" , "_Berserker Rage" },		
		-- "Commanding Shout" 469 "Cri de commandement"
		{ warrior.spells["CommandingShout"] , jps.rage() < 70 and not jps.buff(469) , "player" , "_Commanding Shout" },	
		-- "Avatar" 107574
		{ warrior.spells["Avatar"], jps.rage() > 30 and (jps.hp(rangedTarget,"abs") > 200000) , rangedTarget , "_Avatar" },
		-- "Stoneform" 20594 "Forme de pierre"
		{ warrior.spells["Stoneform"] , playerAggro , "player" , "_Stoneform" },
		-- "Lifeblood" 74497 same ID spell & buff -- Herbalist.
		{ warrior.spells["Lifeblood"] , UnitAffectingCombat("player") == true , "player" , "_Lifeblood" },
		-- "Victory Rush" 34428 "Ivresse de la victoire"
		{ warrior.spells["VictoryRush"] , true , rangedTarget , "_VictoryRush" },
		
		
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.MultiTarget and (enemycount > 1) and CheckInteractDistance(rangedTarget, 3) == true, rangedTarget , "_Shockwave" },
		-- "Bladestorm" 46924
		{ warrior.spells["Bladestorm"], jps.MultiTarget and (enemycount > 1) and jps.rage() > 60 , rangedTarget , "_Bladestorm" },
		-- "Whirlwind" 1680
		{ warrior.spells["Whirlwind"], jps.MultiTarget and (enemycount > 1) and jps.rage() > 60 , rangedTarget , "_Whirlwind" },

		-- "Heroic Throw" 57755 "Lancer héroïque"
		{ warrior.spells["HeroicThrow"] , true , rangedTarget , "_Heroic Throw" },	
		-- "Charge" 100
		{ 100, jps.UseCDs and not CheckInteractDistance(rangedTarget, 3) , rangedTarget , "_Charge"},
		-- "Recklessness" 1719 "Témérité" -- buff Raging Blow! 131116 -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["Recklessness"], jps.UseCDs and (jps.buff(131116) or jps.buff(46916)) and jps.rage() > 30 and (jps.hp(rangedTarget,"abs") > 200000) , "player" , "_Recklessness" },
		-- "Execute" 5308 "Exécution"
		{ warrior.spells["Execute"], jps.hp(rangedTarget) < 0.20 , rangedTarget , "Execute" },

		-- "Wild Strike" 100130 "Frappe sauvage"
		{ warrior.spells["WildStrike"] , jps.rage() > 80 , rangedTarget ,"_Wild Strike Rage" },
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
		{ warrior.spells["RagingBlow"] , jps.buffStacks(131116) == 2 , rangedTarget , "_Raging Blow Stacks" },

		
		-- "Bloodthirst" 23881 "Sanguinaire"
		{ warrior.spells["Bloodthirst"], true , rangedTarget , "_Bloodthirst" },
		-- "Ravager" 152277  -- Talent Choice
		{ warrior.spells["Ravager"] , true , rangedTarget , "_Ravager" },
		-- "Siegebreaker" 176289 -- Talent Choice
		{ warrior.spells["Siegebreaker"] , true , rangedTarget , "_Siegebreaker" },

		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
		{ warrior.spells["RagingBlow"] , jps.buff(131116) , rangedTarget , "_Raging Blow" },
		-- "Wild Strike" 100130 "Frappe sauvage"
		{ warrior.spells["WildStrike"] , true , rangedTarget ,"_Wild Strike" },
		-- "StormBolt" "107570"
		{ warrior.spells["StormBolt"] , true , rangedTarget ,"_StormBolt" },
		


	}

		spell,target = parseSpellTable(spellTable)
		return spell,target
end, "Warrior Custom PvP" , false, true)


	-- "Victorieux" 32216 " Victorious -- Ivresse de la victoire activée -- Attaque instantanément la cible, lui inflige 1246 points de dégâts et vous soigne pour un montant égal à 20% de votre maximum de points de vie
	-- "Enrage" 13046 12880 "Enrager" -- Les coups critiques de FRAPPE MORTELLE, DE SANGUINAIRE ET DE FRAPPE DU COLOSSE ainsi que les blocages critiques vous font enrager 
	-- "Enrage" 13046 12880 "Enrager" -- augmente les dégâts physiques infligés de 10% pendant 6 s
	-- "Flurry" buff 12968 "Rafale" -- Vos coups critiques en mêlée ont 9% de chances d'augmenter votre vitesse d'attaque de 25% pour les 3 prochains coups
	-- "Commanding Shout" 469 "Cri de commandement" -- Augmente de 10% l’Endurance de tous les membres du groupe et du raid dans un rayon de 100 mètres. Dure 5 min. Génère 20 points de rage.
	-- "Bloodsurge" 46916 "Afflux sanguin" -- Vos coups réussis avec Sanguinaire ont 101% de chances d’abaisser le temps de recharge global à 1 s et de réduire le coût en rage de vos 3 prochaines Frappes sauvages de 20

	-- "Deadly Calm" 85730 "Calme mortel" -- vos 3 prochaines attaques avec Frappe héroïque ou Enchaînement d’avoir un coût en rage réduit de 10 points
	-- "Heroic Throw" 57755 "Lancer héroïque" -- Vous lancez votre arme sur l'ennemi et lui infligez 50% des dégâts de l’arme
	-- Glyphe d’imposition du silence -- Volée de coups et Lancer héroïque réduisent aussi la cible au silence pendant 3 s. Ne fonctionne pas contre les personnages-joueurs.
	-- "Charge" 100 -- Vous chargez un ennemi et l’étourdissez pendant 1 s. Génère 20 points de rage.
	-- "Impending Victory" 103840 "Victoire imminente" -- Attaque instantanément la cible et lui inflige 1246 points de dégâts tout en vous rendant 20% de votre maximum de points de vie
	-- "Berserker Rage" 18499 "Rage de berserker" -- Vous devenez Enragé, ce qui vous fait générer 10 points de rage. si vous étiez apeuré, assommé ou stupéfié, vous en êtes libéré et vous devenez insensible à ces types d'effet pendant la durée de la Rage de berserker

	-- "Pummel" 6552 "Volée de coups" -- interrompt l'incantation en cours et empêche le lancement de tout sort de cette école de magie pendant 4 s
	-- "Dragon Roar" 118000 "Rugissement de dragon" -- inflige 126 points de dégâts à tous les ennemis à moins de 8 mètres et les fait tomber à la renverse
	-- "Disrupting Shout" 102060 "Cri perturbant" -- Interrompt toutes les incantations de sorts à moins de 10 mètres et empêche tout sort de la même école d’être lancé pendant 4 s
	-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse" BUFF same ID -- Renvoie le prochain sort lancé sur vous et les membres du groupe ou raid à moins de 20 mètres d’un sort unique pendant 5 s.
	-- "Stoneform" 20594 "Forme de pierre" -- réduit tous les dégâts subis de 10% pendant 8 s

	-- "Raging Blow" 85288 "Coup déchaîné" -- Le fait de devenir Enragé permet une utilisation de Coup déchaîné.
	-- "Colossus Smash" 86346 "Frappe du colosse" -- permet à vos attaques d'ignorer 100% de son armure pendant 6 s
	-- "Recklessness" 1719 "Témérité" -- Confère à vos attaques spéciales 50% de chances supplémentaires d’être critiques. Dure 12 s.

	-- "Thunder Clap" 6343 "Coup de tonnerre" -- Foudroie les ennemis à moins de 8 mètres, leur infligeant 312 points de dégâts, et applique sur eux l'effet Coups affaiblis
	-- "Heroic Strike" 78 "Frappe héroïque" -- 
	-- Glyphe de coups gênants -- Frappe héroïque et Enchaînement diminuent aussi la vitesse de déplacement de la cible de 50% pendant 8 s
	-- "Wild Strike" 100130 "Frappe sauvage" -- donne DEBUFF "Mortal Wounds" 115804 "Blessures mortelles" -- Healing effects received reduced by 25%
	-- "Bloodthirst" 23881 "Sanguinaire" -- Vous avez deux fois plus de chances d’infliger un coup critique avec Sanguinaire.

	-- "Shattering Throw" 64382 "Lancer fracassant" -- réduire son armure de 20% pendant 10 s ou d'annuler les invulnérabilités.
	-- "Die by the Sword" 118038 "Par le fil de l’épée" -- Augmente vos chances de parer de 100% et réduit les dégâts subis de 20% pendant 8 s.
	-- "Whirlwind" 1680 "Tourbillon" -- Dans un tourbillon d'acier, vous attaquez tous les ennemis se trouvant à moins de 8 mètres et infligez 85% des dégâts des armes à chacun d'eux.
	-- "Enraged Regeneration" 55694 "Régénération enragée" -- Vous rend instantanément 10% de votre total de points de vie, plus 10% supplémentaires en 5 s. Peut être utilisé pendant que vous êtes étourdi. Ne coûte pas de rage lorsque vous êtes Enragé.
