function events.GenerateItem(t)
	--get party average level
	Handled = true
	--calculate party experience
	if Map.MapStatsIndex==0 then return end
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLevel=vars.MM8LVL
		elseif currentWorld==2 then
			partyLevel=vars.MM7LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM6LVL
		end

	--nerf if item is strong
	if partyLevel<(t.Strength-3)*20 and t.Strength<7 then
		t.Strength=t.Strength-1
	end
	if (t.Strength-2)*20>partyLevel and t.Strength>2 and t.Strength<7 then
		roll=math.random((t.Strength-3)*20,(t.Strength-2)*20)
		if roll>partyLevel then
			t.Strength=t.Strength-1
		end
	end
end

--create tables to calculate special enchant
function events.GameInitialized2()
	--calculate totals by enchant type
	totBonus2={}
	for k=0,3 do
		totBonus2[k]={}
		for v=0, 11 do
			totBonus2[k][v]=0
			for i=0, Game.SpcItemsTxt.High do
				lvl=Game.SpcItemsTxt[i].Lvl
				if lvl==k then
					totBonus2[k][v]=totBonus2[k][v]+Game.SpcItemsTxt[i].ChanceForSlot[v]
				end
			end
		end
	end
	
	--calculate total of each item level per item type
	itemStrength={}	
	itemStrength[3]={}
	itemStrength[4]={}
	itemStrength[5]={}
	itemStrength[6]={}
	for v=0, 11 do	
		itemStrength[3][v]=totBonus2[0][v]+totBonus2[1][v]
		itemStrength[4][v]=totBonus2[0][v]+totBonus2[1][v]+totBonus2[2][v]
		itemStrength[5][v]=totBonus2[1][v]+totBonus2[2][v]+totBonus2[3][v]
		itemStrength[6][v]=totBonus2[3][v]
	end
	--list of possible enchants per item level
	enchants={}
	enchants[3]={0,1}
	enchants[4]={0,1,2}
	enchants[5]={1,2,3}
	enchants[6]={3}
end

--create enchant table
encStrDown={1,1,3,6,10,15,20,24,28,32,36,40,44,48,52,56,60,64,68,76}
encStrUp={3,5,8,12,17,25,30,35,40,45,50,55,60,65,70,75,80,85,90,100}


enc1Chance={20,30,40,50,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80}
enc2Chance={20,30,35,40,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60}
spcEncChance={0,0,15,20,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40}


function events.ItemGenerated(t)
if Map.MapStatsIndex==0 then 
return end
	if t.Strength==7 then 
		return
	end
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then
		t.Handled=true
		--reset enchants
		t.Item.Bonus=0
		t.Item.Bonus2=0
		t.Item.BonusStrength=0
		Game.ShowStatusText("success")
		--calculate party level
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLevel=vars.MM7LVL+vars.MM6LVL
		elseif currentWorld==2 then
			partyLevel=vars.MM8LVL+vars.MM6LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM8LVL+vars.MM7LVL
		end
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		t.Item.MaxCharges=math.min(math.floor(partyLevel/5),255)
		local partyLevel=math.min(math.floor(partyLevel/20),14)
		--adjust loot Strength
		pseudoStr=t.Strength+partyLevel
		if pseudoStr==1 then 
			return 
		end
		roll1=math.random(1,100)
		roll2=math.random(1,100)
		rollSpc=math.random(1,100)
		
		--apply enchant1
		if enc1Chance[pseudoStr]>roll1 then
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			if math.random(1,10)==10 then
				t.Item.Bonus=math.random(17,24)
				t.Item.BonusStrength=math.ceil(t.Item.BonusStrength^0.5)
			end
		end
		--apply enchant2
		if enc2Chance[pseudoStr]>roll2 then
			t.Item.Charges=math.random(1,16)*1000
			t.Item.Charges=t.Item.Charges+math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			if math.random(1,10)==10 then
				t.Item.Charges=math.random(17,24)*1000
				t.Item.Charges=t.Item.Charges+math.round(math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])^0.5)
			end
		end
		--make it standard bonus if no standard bonus
		if t.Item.Bonus==0 then
			t.Item.Bonus=math.floor(t.Item.Charges/1000)
			t.Item.BonusStrength=t.Item.Charges%1000
			t.Item.Charges=0
		end
				
		--ancient item
		ancient=math.random(1,50)
		if ancient<=t.Strength-4 then
			t.Item.Charges=math.random(math.round(encStrUp[partyLevel+6]+1),math.round(encStrUp[partyLevel+6]*1.25))+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(math.round(encStrUp[partyLevel+6]+1),math.round(encStrUp[partyLevel+6]*1.25))
			rollSpc=0
		end
		--apply special enchant
		if spcEncChance[pseudoStr]>rollSpc then
			n=t.Item.Number
			c=Game.ItemsTxt[n].EquipStat
			if c<12 and t.Strength>=3 then
				totB2=itemStrength[t.Strength][c]
				roll=math.random(1,totB2)
				tot=0
				for i=0,Game.SpcItemsTxt.High do
					if roll<=tot then
						t.Item.Bonus2=i
						goto continue
					elseif table.find(enchants[t.Strength], Game.SpcItemsTxt[i].Lvl) then
						tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
					end
				end	
			end	
		end
		::continue::
		
		
		
		--primordial item
		primordial=math.random(1,100)
		if primordial<=t.Strength-4 then
			t.Item.Charges=math.round(encStrUp[partyLevel+6]*1.25)+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.round(encStrUp[partyLevel+6]*1.25)
			if t.Item.Number>60 then
				t.Item.Bonus2=math.random(1,2)
				else
				t.Item.Bonus2=41
			end
		end			
		
		--buff to hp and mana items
		if t.Item.Bonus==8 or t.Item.Bonus==9 then
			t.Item.BonusStrength=t.Item.BonusStrength*2
		end
		if t.Item.Charges%1000==7 or t.Item.Charges%1000==8 then
			t.Item.Charges=t.Item.Charges+t.Item.Charges%1000
		end
	end
end



--apply charges effect
function events.CalcStatBonusByItems(t)
	for it in t.Player:EnumActiveItems() do
		if it.Charges > 1000 then
			stat=math.floor(it.Charges/1000)-1
			bonus=it.Charges%1000
			if t.Stat==stat then
				if stat>=10 and stat<=15 then
					t.Result = t.Result + bonus * 2
				else
					t.Result = t.Result + bonus
				end
			end

		end
	end
end

----------------------
--weapon rework
----------------------
function events.GameInitialized2()
--Weapon upscaler 
	for i=1,2200 do
		if (i>=1 and i<=83) or (i>=803 and i<=865) or (i>=1603 and i<=1665) then
			upTierDifference=0
			downTierDifference=0
			downDamage=0
			--set goal damage for weapons (end game weapon damage)
			goalDamage=35
			if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" then
				goalDamage=goalDamage*2
			end
			currentDamage = (Game.ItemsTxt[i].Mod1DiceCount *Game.ItemsTxt[i]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i].Mod2 

				for v=1,4 do
					if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[i+v].NotIdentifiedName then
					upTierDifference=upTierDifference+1
					end
					if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[math.max(i-v,0)].NotIdentifiedName then
					downTierDifference=downTierDifference+1
					downDamage = (Game.ItemsTxt[i-v].Mod1DiceCount *Game.ItemsTxt[i-v]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i-v].Mod2
					elseif downTierDifference==0 then
							downDamage = currentDamage
					end
				end

			--calculate expected value
			tierRange=upTierDifference+downTierDifference+1
			damageRange=goalDamage-downDamage
			expectedDamageIncrease=damageRange*(downTierDifference/(tierRange-1))
			Game.ItemsTxt[i].Mod1DiceSides = Game.ItemsTxt[i].Mod1DiceSides + (expectedDamageIncrease / Game.ItemsTxt[i].Mod1DiceCount)
			Game.ItemsTxt[i].Mod2=expectedDamageIncrease/2

			end 
		end

	------------
	--tooltips
	------------
	Game.SpcItemsTxt[3].BonusStat="Adds 6-8 points of Cold damage."
	Game.SpcItemsTxt[4].BonusStat="Adds 18-24 points of Cold damage."
	Game.SpcItemsTxt[5].BonusStat="Adds 36-48 points of Cold damage."
	Game.SpcItemsTxt[6].BonusStat="Adds 4-10 points of Electrical damage."
	Game.SpcItemsTxt[7].BonusStat="Adds 12-30 points of Electrical damage."
	Game.SpcItemsTxt[8].BonusStat="Adds 24-60 points of Electrical damage."
	Game.SpcItemsTxt[9].BonusStat="Adds 2-12 points of Fire damage."
	Game.SpcItemsTxt[10].BonusStat="Adds 6-36 points of Fire damage."
	Game.SpcItemsTxt[11].BonusStat="Adds 12-72 points of Fire damage."
	Game.SpcItemsTxt[12].BonusStat="Adds 10 points of Body damage."
	Game.SpcItemsTxt[13].BonusStat="Adds 24 points of Body damage."
	Game.SpcItemsTxt[14].BonusStat="Adds 48 points of Body damage."

end

--ENCHANTS HERE
--MELEE bonuses
enchantbonusdamage = {}
enchantbonusdamage[4] = 2
enchantbonusdamage[5] = 3
enchantbonusdamage[6] = 4
enchantbonusdamage[7] = 2
enchantbonusdamage[8] = 3
enchantbonusdamage[9] = 4
enchantbonusdamage[10] = 2
enchantbonusdamage[11] = 3
enchantbonusdamage[12] = 4
enchantbonusdamage[13] = 2
enchantbonusdamage[14] = 3
enchantbonusdamage[15] = 4
enchantbonusdamage[46] = 4

function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
    if data and data.Player and t.DamageKind ~= 4 and data.Object == nil and t.ByPlayer==true and t.Melee==true then
	n=1
	bonusDamage2=1
        for i = 0,1 do
			it=data.Player:GetActiveItem(i)
			bonusDamage=0
			-- calculation
			if it then
				if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46  then
				local bonusDamage1 = bonusDamage+enchantbonusdamage[it.Bonus2] or 0
				bonusDamage2=(bonusDamage2*bonusDamage1)^(1/n)
				n=n+1
				end
			end
        end	
		
		if n~=0 and bonusDamage2~=0 then
		t.Result = bonusDamage2*t.Result
		end
    end
end

--bows 
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
    if data and data.Player and t.DamageKind ~= 0 and data.Object~=nil then
			if data.Object.Spell==100 then
			it=data.Player:GetActiveItem(2)
			-- calculation
			if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46 then
			local bonusDamage = enchantbonusdamage[it.Bonus2] or 0
			t.Result=t.Result*bonusDamage
			end	
		end
	end
 end

spellbonusdamage={}
spellbonusdamage[13] = 10
spellbonusdamage[14] = 24
spellbonusdamage[15] = 48

aoespells = {6, 7, 8, 9, 10, 15, 22, 26, 32, 41, 43, 84, 92, 97, 98, 99}
function events.CalcSpellDamage(t)
data=WhoHitMonster()
	if data and data.Player then
		it=data.Player:GetActiveItem(1)
		if it then
			if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46 then
				spellbonusdamage[4] = math.random(6, 8)
				spellbonusdamage[5] = math.random(18, 24)
				spellbonusdamage[6] = math.random(36, 48)
				spellbonusdamage[7] = math.random(4, 10)
				spellbonusdamage[8] = math.random(12, 30)
				spellbonusdamage[9] = math.random(24, 60)
				spellbonusdamage[10] = math.random(2, 12)
				spellbonusdamage[11] = math.random(6, 36)
				spellbonusdamage[12] = math.random(12, 72)
				spellbonusdamage[46] = math.random(40, 80)
				buffed=0
				bonusDamage = spellbonusdamage[it.Bonus2] or 0
				for i = 1, #aoespells do
					if aoespells[i] == t.Spell then
						t.Result = t.Result+bonusDamage/5
						buffed=1
						break
					end
				end
				if buffed==0 then
				t.Result = t.Result+bonusDamage
				end
			end
		end
	end
end


--change tooltip
function events.GameInitialized2()
	--menu stats
	if ColouredStats==true then
		Game.GlobalTxt[144]=StrColor(255,0,0,"Might")
		Game.GlobalTxt[116]=StrColor(255,128,0,"Intellect")
		Game.GlobalTxt[163]=StrColor(0,127,255,"Personality")
		Game.GlobalTxt[75]=StrColor(0,255,0,"Endurance")
		Game.GlobalTxt[1]=StrColor(255,255,0,"Accuracy")
		Game.GlobalTxt[211]=StrColor(127,0,255,"Speed")
		Game.GlobalTxt[136]=StrColor(255,255,255,"Luck")
		Game.GlobalTxt[108]=StrColor(0,255,0,"Hit Points")
		Game.GlobalTxt[212]=StrColor(0,100,255,"Spell Points")
		Game.GlobalTxt[12]=StrColor(230,204,128,"Armor Class")
	end
end

-----------------------------
---IMMUNITY REWORK
-----------------------------

function events.DoBadThingToPlayer(t)
    local protectionMessages = {
        [18] = { [9] = "disease", [10] = "disease", [11] = "disease", [1] = "curse" },
        [19] = { [5] = "insanity", [22] = "spell drain" },
        [20] = { [12] = "paralysis", [23] = "fear" },
        [21] = { [6] = "poison", [7] = "poison", [8] = "poison", [2] = "weakness" },
        [22] = { [3] = "sleep", [13] = "unconscious" },
        [23] = { [15] = "stone", [21] = "premature ageing" },
        [25] = { [14] = "death", [16] = "eradication" },
    }

    for it in t.Player:EnumActiveItems() do
        if protectionMessages[it.Bonus2] and protectionMessages[it.Bonus2][t.Thing] then
            t.Allow = false
            local protectionType = protectionMessages[it.Bonus2][t.Thing]
            Game.ShowStatusText(string.format("Enchantment protects %s from %s", t.Player.Name, protectionType))
        end
    end
end


--------------------
--STATUS REWORK (needs to stay after status immunity)
--------------------

function events.LoadMap(wasInGame)
local function poisonTimer() 

vars.poisonTime=vars.poisonTime or {}
	for i = 0, Party.High do
		if Party[i].Poison3>0 then
			if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
			vars.poisonTime[i]=25
			end
			if vars.poisonTime[i]>0 then
			vars.poisonTime[i]=vars.poisonTime[i]-1
			end
			if vars.poisonTime[i]==0 then			
			Party[i].Poison3=0
			Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
			else
			Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.06)
			end 
		else if Party[i].Poison2>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
				vars.poisonTime[i]=25
				end
				if vars.poisonTime[i]>0 then
				vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
				Party[i].Poison2=0
				Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
				Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.04)
				end 
			else if Party[i].Poison1>0 then
					if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=25
					end
					if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
					end
					if vars.poisonTime[i]==0 then			
					Party[i].Poison1=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
					else
					Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.02)
					end 
				else vars.poisonTime[i]=0
				end
			end
		end
	end
end
Timer(poisonTimer, const.Minute) 

function events.DoBadThingToPlayer(t)
		if (t.Thing==6 or t.Thing==7 or t.Thing==8) and t.Allow then
		if vars.poisonTime[t.PlayerIndex]==nil or vars.poisonTime[t.PlayerIndex]==0 then
		vars.poisonTime[t.PlayerIndex]=25
		else
		vars.poisonTime[t.PlayerIndex]=math.min(vars.poisonTime[t.PlayerIndex]+5,50)
		end
	end
end

--hp and sp regen
function events.LoadMap(wasInGame)
local function restoreHPEnchant() 
	for _, pl in Party do 
	HPregen=0
	totHP=pl:GetFullHP()
		for it in pl:EnumActiveItems() do
			if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 then		
				HPregen=math.max(HPregen+totHP*0.005,HPregen+1)	
			end
		end
	HPregen=math.max(HPregen-1,0)
	pl.HP=math.min(pl.HP+math.round(HPregen),totHP)
	end 
end
Timer(restoreHPEnchant, const.Minute*5) 


local function restoreSPEnchant() 
	for _, pl in Party do 
	SPregen=0
	totSP=pl:GetFullSP()
		for it in pl:EnumActiveItems() do
			if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
				SPregen=math.max(SPregen+totSP*0.005,SPregen+1)
			end
		end
	SPregen=math.max(SPregen-1,0)
	pl.SP=math.min(pl.SP+math.round(SPregen),totSP)
	end 
end
Timer(restoreSPEnchant, const.Minute*5) 
end

end

--carnage fix
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
	if data and data.Player and data.Object ~= nil then
		if data.Object.Item.Bonus2==3 then
			t.Result=t.Result/2
		end
	end
end
function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end

------------------------------------------
--TOOLTIPS--
------------------------------------------
function events.BuildItemInformationBox(t)
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then 
		if t.Type then
			t.Type = t.Type
			--add code to increase base stats based on bolster enchant
			--ARMORS
			if t.Item.MaxCharges>0 then
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat>=3 and equipStat<=9 then
				local ac=txt.Mod2+txt.Mod1DiceCount 
					if ac>0 then
						if t.Item.MaxCharges <= 20 then
							local bonusAC=ac*(t.Item.MaxCharges/20)
							ac=ac+math.round(bonusAC)
						else
							local bonusAC=ac*2+ac*2*((t.Item.MaxCharges-20)/20)
							ac=ac+math.round(bonusAC)
						end
						t.BasicStat= "Armors: +" .. ac
					end
				end
			end
			--WEAPONS
			if t.Item.MaxCharges>0 then
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat<=2 then
				local bonus=txt.Mod2
					--attack/+damage
					if t.Item.MaxCharges <= 20 then
						local bonusATK=bonus*(t.Item.MaxCharges/20)
						bonus=bonus+math.round(bonusATK)
					else
						local bonusATK=bonus*2+bonus*2*((t.Item.MaxCharges-20)/20)
						bonus=bonus+math.round(bonusATK)
					end
					--dicesides
					sides=txt.Mod1DiceSides
					if t.Item.MaxCharges <= 20 then
						local sidesBonus=sides*(t.Item.MaxCharges/20)
						sides=sides+math.round(sidesBonus)
					else
						local sidesBonus=sides*2+sides*2*((t.Item.MaxCharges-20)/20)
						sides=sides+math.round(sidesBonus)
					end
					t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
				end
			end
			
			
			--add code to build enchant list
			t.Enchantment=""
			if t.Item.Bonus>0 then
				if t.Item.Bonus>=11 and t.Item.Bonus<=16 then --% values for resistances
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. t.Item.BonusStrength/2 .. "%" 
				else
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. t.Item.BonusStrength
				end
			end
			if t.Item.Charges>1000 then
				local bonus=math.floor(t.Item.Charges/1000)
				local strength=t.Item.Charges%1000
				if bonus>=11 and bonus<=16 then --% values for resistances
					strength=strength/2
					t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "%" .. "\n" .. t.Enchantment
				else
					t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
				end
			end
		elseif t.Name then
			--add enchant Name
			t.Name = Game.ItemsTxt[t.Item.Number].Name
			if t.Item.Bonus2>0 then
				t.Name= t.Name .. " " .. Game.SpcItemsTxt[t.Item.Bonus2-1].NameAdd
			elseif t.Item.Bonus>0 then
				t.Name= t.Name .. " " .. Game.StdItemsTxt[t.Item.Bonus-1].NameAdd
			end
			--choose colour
			local bonus=0
			if t.Item.Bonus>0 then
				bonus=bonus+1
			end
			if t.Item.Bonus2>0 then
				bonus=bonus+1
			end
			if t.Item.Charges>1000 then
				bonus=bonus+1
			end
			if bonus==3 then
				t.Name=StrColor(163,53,238,t.Name)
			elseif bonus==2 then
				t.Name=StrColor(0,150,255,t.Name)
			elseif bonus==1 then
				t.Name=StrColor(30,255,0,t.Name)
			else
				t.Name=StrColor(255,255,255,t.Name)
			end
		elseif t.Description then
			if t.Item.Bonus2>0 then	
				if t.Item.MaxCharges>0 and bonusEffects[t.Item.Bonus2]~= nil then
					text=checktext(t.Item.MaxCharges,t.Item.Bonus2)
				else
					text=Game.SpcItemsTxt[t.Item.Bonus2-1].BonusStat
				end
				t.Description = StrColor(255,255,153,text) .. "\n\n" .. t.Description
			end
		end
	end
end


--colours
function events.GameInitialized2()
	itemStatName = {}
	itemStatName[1] = StrColor(255, 0, 0, "Might")
	itemStatName[2] = StrColor(255, 128, 0, "Intellect")
	itemStatName[3] = StrColor(0, 127, 255, "Personality")
	itemStatName[4] = StrColor(0, 255, 0, "Endurance")
	itemStatName[5] = StrColor(255, 255, 0, "Accuracy")
	itemStatName[6] = StrColor(127, 0, 255, "Speed")
	itemStatName[7] = StrColor(255, 255, 255, "Luck")
	itemStatName[8] = StrColor(0, 255, 0, "Hit Points")
	itemStatName[9] = StrColor(0, 100, 255, "Spell Points")
	itemStatName[10] = StrColor(230, 204, 128, "Armor Class")
	itemStatName[11] = StrColor(255, 70, 70, "Fire Resistance")
	itemStatName[12] = StrColor(173, 216, 230, "Air Resistance")
	itemStatName[13] = StrColor(100, 180, 255, "Water Resistance")
	itemStatName[14] = StrColor(153, 76, 0, "Earth Resistance")
	itemStatName[15] = StrColor(200, 200, 255, "Mind Resistance")
	itemStatName[16] = StrColor(255, 192, 203, "Body Resistance")
	itemStatName[17] = StrColor(255,255,153, "Alchemy skill")
	itemStatName[18] = StrColor(255,255,153, "Stealing skill")
	itemStatName[19] = StrColor(255,255,153, "Disarm skill")
	itemStatName[20] = StrColor(255,255,153, "ID Item skill")
	itemStatName[21] = StrColor(255,255,153, "ID Monster skill")
	itemStatName[22] = StrColor(255,255,153, "Armsmaster skill")
	itemStatName[23] = StrColor(255,255,153, "Dodge skill")
	itemStatName[24] = StrColor(255,255,153, "Unarmed skill")
	itemStatName[25] = StrColor(255,255,153, "Great might")
end


function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end

--max charges empower items base stats by 2 every 100 levels (every 5 levels bolster level you get 1 maxcharges)
--apply MAXcharges effect
function events.CalcStatBonusByItems(t)
	if t.Stat==9 then
		for it in t.Player:EnumActiveItems() do
			if it.MaxCharges > 0 then
				local equipStat=Game.ItemsTxt[it.Number].EquipStat
				if equipStat>=3 and equipStat<=9 then
					local ac=Game.ItemsTxt[it.Number].Mod2+Game.ItemsTxt[it.Number].Mod1DiceCount 
					if it.MaxCharges <= 20 then
						local bonusAC=ac*(it.MaxCharges/20)
						t.Result=t.Result+math.round(bonusAC)
					else
						local bonusAC=ac*2+ac*2*((it.MaxCharges-20)/20)
						t.Result=t.Result+math.round(bonusAC)
					end
				end
			end
		end
	end
end



--visual changes in stats menu for scaled weapon
function events.CalcStatBonusByItems(t)
	--increase damage depending on max CHARGES, only visual (except for attack)
	local cs = const.Stats
	if t.Stat==cs.MeleeDamageMin or t.Stat==cs.MeleeDamageMax or t.Stat==cs.MeleeAttack then
		for i=0,1 do
			local it=t.Player:GetActiveItem(i)
			if	it then
				if it.MaxCharges>0 then
					local data=Game.ItemsTxt[it.Number]
					if data.EquipStat<=2 then
						--add fix damage
						local bonus=data.Mod2
						if it.MaxCharges <= 20 then
							local bonus=bonus*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)
						else
							local bonus=bonus+bonus*2*((it.MaxCharges-20)/20)
							t.Result=t.Result+math.round(bonus)
						end
						--calculate random damage
						if t.Stat==cs.MeleeDamageMax then
							local bonus=data.Mod1DiceSides
							local dices=data.Mod1DiceCount
							if it.MaxCharges <= 20 then
								local bonus=bonus*(it.MaxCharges/20)
								t.Result=t.Result+math.round(bonus)*dices
							else
								local bonus=bonus+bonus*2*((it.MaxCharges-20)/20)
								t.Result=t.Result+math.round(bonus)*dices
							end
						end
					end
				end
			end
		end
	end
	--same for bows
	if t.Stat==cs.RangedDamageMin or t.Stat==cs.RangedDamageMax or t.Stat==cs.RangedAttack then
		local it=t.Player:GetActiveItem(2)
		if	it then
			if it.MaxCharges>0 then
				local data=Game.ItemsTxt[it.Number]
				if data.EquipStat<=2 then
					--add fix damage
					local bonus=data.Mod2
					if it.MaxCharges <= 20 then
						local bonus=bonus*(it.MaxCharges/20)
						t.Result=t.Result+math.round(bonus)
					else
						local bonus=bonus+bonus*2*((it.MaxCharges-20)/20)
						t.Result=t.Result+math.round(bonus)
					end
					--calculate random damage
					if t.Stat==cs.MeleeDamageMax then
						local bonus=data.Mod1DiceSides
						local dices=data.Mod1DiceCount
						if it.MaxCharges <= 20 then
							local bonus=bonus*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)*dices
						else
							local bonus=bonus+bonus*2*((it.MaxCharges-20)/20)
							t.Result=t.Result+math.round(bonus)*dices
						end
					end
				end
			end
		end
	end
end

					
--recalculate actual damage
function events.ModifyItemDamage(t)
	bonusDamage=0
	if t.Item then
		if t.Item.MaxCharges>0 then
			if t.Item.MaxCharges <= 20 then
				mult=1+t.Item.MaxCharges/20
			else
				mult=2+2*(t.Item.MaxCharges-20)/20
			end
			local txt=Game.ItemsTxt[t.Item.Number]
			bonusDamage=txt.Mod2*mult
			sides=txt.Mod1DiceSides*mult
			--calculate dices
			for i=1,txt.Mod1DiceCount do
				bonusDamage=bonusDamage+math.random(1,sides)
			end
		end
	end
	t.Result=bonusDamage
end

--fix to enchant2 not applying correctly if same bonus is on the item
--fix to special enchants

bonusEffects = {
    [1] = { bonusType = 1, bonusRange = {11, 16}, statModifier = 10 },
    [2] = { bonusType = 2, bonusRange = {1, 7}, statModifier = 10 },
    [42] = { bonusType = 42, bonusRange = {1, 16}, statModifier = 1 },
    [43] = { bonusType = 43, bonusValues = {4, 8, 10}, statModifier = 10 },
    [44] = { bonusType = 44, bonusValues = {8}, statModifier = 10 },
    [45] = { bonusType = 45, bonusValues = {5, 6}, statModifier = 5 },
    [46] = { bonusType = 46, bonusValues = {1}, statModifier = 25 },
    [47] = { bonusType = 47, bonusValues = {9}, statModifier = 10 },
    [48] = { bonusType = 48, bonusValues = {4, 10}, statModifier = {15, 5} },
    [49] = { bonusType = 49, bonusValues = {2, 7}, statModifier = 10 },
    [50] = { bonusType = 50, bonusValues = {11}, statModifier = 30 },
    [51] = { bonusType = 51, bonusValues = {2, 6, 9}, statModifier = 10 },
    [52] = { bonusType = 52, bonusValues = {4, 5}, statModifier = 10 },
    [53] = { bonusType = 53, bonusValues = {1, 3}, statModifier = 10 },
    [54] = { bonusType = 54, bonusValues = {4}, statModifier = 15 },
    [55] = { bonusType = 55, bonusValues = {7}, statModifier = 15 },
    [56] = { bonusType = 56, bonusValues = {1, 4}, statModifier = 5 },
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 5 }
}

function events.CalcStatBonusByItems(t)
    for it in t.Player:EnumActiveItems() do
        local bonusData = bonusEffects[it.Bonus2]
        if bonusData then
            if bonusData.bonusRange then
                local lower, upper = bonusData.bonusRange[1], bonusData.bonusRange[2]
                if it.Bonus >= lower and it.Bonus <= upper then
                    if t.Stat == it.Bonus - 1 then
                        t.Result = t.Result + bonusData.statModifier
                    end
                end
            elseif bonusData.bonusValues then
                for _, value in ipairs(bonusData.bonusValues) do
                    if it.Bonus == value then
                        if t.Stat == it.Bonus - 1 then
                            if type(bonusData.statModifier) == "table" then
                                t.Result = t.Result + bonusData.statModifier[value]
                            else
                                t.Result = t.Result + bonusData.statModifier
                            end
                        end
                    end
                end
            end
        end
    end
end




--make enchant 2 scale with maxcharges
function events.CalcStatBonusByItems(t)
    for it in t.Player:EnumActiveItems() do
		if it.MaxCharges>0 then
			local bonusData = bonusEffects[it.Bonus2]
			if bonusData then
				if it.MaxCharges <= 20 then
					mult=it.MaxCharges/20
				else
					mult=1+2*(it.MaxCharges-20)/20
				end
				if bonusData.bonusRange then
					local lower, upper = bonusData.bonusRange[1], bonusData.bonusRange[2]
					if t.Stat>=lower-1 and t.Stat<upper then
						t.Result = t.Result + bonusData.statModifier * mult
					end
				elseif bonusData.bonusValues then
					for i =1, 3 do
						if bonusData.bonusValues[i] then
							if bonusData.bonusValues[i]-1==t.Stat then
								local modifier = bonusData.statModifier
								if type(modifier) == "table" then
									t.Result = t.Result + modifier[i] * mult
								else
									t.Result = t.Result + modifier * mult
								end
							end
						end
					end
				end
			end
		end
    end
end


--create dictionary with description list
function checktext(MaxCharges,bonus2)
	if MaxCharges <= 20 then
		mult=1+MaxCharges/20
	else
		mult=2+2*(MaxCharges-20)/20
	end
	bonus2txt={
		[1] =  " +" .. bonusEffects[1].statModifier * mult .. " to all Resistances.",
		[2] = " +" .. bonusEffects[2].statModifier * mult .. " to all Seven Statistics.",
		[42] = " +" .. bonusEffects[42].statModifier * mult .. " to Seven Stats, HP, SP, Armor, Resistances.",
		[43] = " +" .. bonusEffects[43].statModifier * mult .. " to Endurance, Armor, Hit points.",
		[44] = " +" .. bonusEffects[44].statModifier * mult .. " Hit points and Regenerate Hit points over time.",
		[45] = " +" .. bonusEffects[45].statModifier * mult .. " Speed and Accuracy.",
		[46] = "Adds 10-20 points of Fire damage and +" .. bonusEffects[46].statModifier * mult.. " Might.",
		[47] = " +" .. bonusEffects[47].statModifier * mult .. " Spell points and Regenerate Spell points over time.",
		[48] = " +" .. bonusEffects[48].statModifier[1] * mult .. " Endurance and" .. " +" .. bonusEffects[48].statModifier[2] * mult.. " Armor.",
		[49] = " +" .. bonusEffects[49].statModifier * mult .. " Intellect and Luck.",
		[50] = " +" .. bonusEffects[50].statModifier * mult .. " Fire Resistance and Regenerate Hit points over time.",
		[51] = " +" .. bonusEffects[51].statModifier * mult .. " Spell points, Speed, Intellect.",
		[52] = " +" .. bonusEffects[52].statModifier * mult .. " Endurance and Accuracy.",
		[53] = " +" .. bonusEffects[53].statModifier * mult .. " Might and Personality.",
		[54] = " +" .. bonusEffects[54].statModifier * mult .. " Endurance and Regenerate Hit points over time.",
		[55] = " +" .. bonusEffects[55].statModifier * mult .. " Luck and Regenerate Spell points over time.",
		[56] = " +" .. bonusEffects[56].statModifier * mult .. " Might and Endurance.",
		[57] = " +" .. bonusEffects[57].statModifier * mult .. " Intellect and Personality.",
	}
	return bonus2txt[bonus2]
end

--calculate price
function events.CalcItemValue(t)
	--base value
	basePrice=Game.ItemsTxt[t.Item.Number].Value
	--add enchant price
	bonus1=t.Item.BonusStrength*100
	if t.Item.Bonus==8 or t.Item.Bonus==9 then
		bonus1=bonus1/2
	end
	bonus2=(t.Item.Charges%1000)*100
	if math.floor(t.Item.Charges/1000)==8 or math.floor(t.Item.Charges/1000)==9 then
		bonus1=bonus1/2
	end
	
	MaxCharges=t.Item.MaxCharges
	if MaxCharges <= 20 then
		mult=1+MaxCharges/20
	else
		mult=2+2*(MaxCharges-20)/20
	end
	basePrice=basePrice*mult
	if t.Item.Bonus2>0 then
		special=Game.SpcItemsTxt[t.Item.Bonus2-1].Value
		if bonusEffects[t.Item.Bonus2]~=nil then
			special=special*mult
		end
		if special<11 then
			basePrice=basePrice*special
		else
			basePrice=basePrice+special
		end
	end
	t.Value=basePrice+bonus1+bonus2
end
