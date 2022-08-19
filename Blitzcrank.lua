local PredExtentions = require "predExtentions" -- this assigns getPredExtentions to the return of predExtentions which is a table containing functions that i'd like to use throughout my aio

local Blitzcrank = {} -- This is purely so we can return everything at the bottom if we we're to require this file and use some of the functions. (also the example did it lmao)

function Blitzcrank.Load(viegoCompatibility) -- when the script loads

    viegoCompatibility = viegoCompatibility or false

    print("[Turbo Scripts - Blitzcrank] Loaded") -- write that we are loading to console (most of these prints are debugging reminants from me testing things)

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingMidAir } -- this creates a table that starts at 0 lining up with the hitchanes in our menu, really makes it easy going from hitchance in menu to actual hitchance.

    function Blitzcrank:DebugPrint(...) -- idfk it's cool
        print("[Turbo Scripts - Blitzcrank] " .. ...)
    end

    function Blitzcrank:__init()

        self.castTime = { [0] = 0, 0, 0, 0 } -- creates a table with the last time starts at 0 again to be compatible with the cpp core

        -- https://raw.communitydragon.org/12.14/game/data/characters/blitzcrank/blitzcrank.bin.json note that these are usually very wrong, so use it as a baseline and test yourself
        self.qData = {
            delay = 0.25,
            type = spellType.linear,
            rangeType = SpellRangeType.Edge,
            range = 1120,
            speed = 1800,
            radius = 64,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.Hard,
                tower = SpellCollisionType.None,

                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }
        self.wData = {
            type = spellType.self
        }
        self.eData = {
            type = spellType.self
        }
        self.rData = {
            delay = 0.25,
            type = spellType.circular,
            rangeType = SpellRangeType.Center,
            range = 0,
            radius = 600,
            boundingRadiusMod = false
        }

        self.BlitzcrankMenu = self:CreateMenu()

        self.viegoCompatibilityMode = false

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Blitzcrank:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) Blitzcrank:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) Blitzcrank:OnCastSpell(...) end)
        table.insert(self.callbacks[1], cb.orbAfterAttack)
        table.insert(self.callbacks[2], function(...) Blitzcrank:OnOrbAfterAttack(...) end)
        -- this is disgusting, i hope i never have to do this shit again

        print("[Turbo Scripts - Blitzcrank] initialized")
    end

    function Blitzcrank:CreateMenu()
        print("[Turbo Scripts - Blitzcrank] creating menu")
        local mm = menu.create('turbo_blitzcrank', 'Turbo Blitzcrank')

        mm:spacer("turbotech", "TurboTech BETA")

        mm:header('combo', 'Combo Mode')
        mm.combo:spacer("combo_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)
        mm.combo:list('q_hitchance', 'Q Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2) -- these fuckers start at 0 compared to lua starting at 1, be aware of that
        mm.combo:header('advanced', 'Advanced')
        mm.combo.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for casting less")
        mm.combo.advanced:slider('q_time_modifier', "Max range modifier", 75, 0, 100, 1) --:tooltip("Max Projectile Time Before Forcing VeryHigh Hitchance (miliseconds)")

        mm.combo:spacer("combo_menu_spacer2", "E")
        mm.combo:boolean('e_use', 'Use E', true)
        mm.combo:list('e_mode', 'E Mode', { 'AA reset', 'Before AA' }, 0)

        if viegoCompatibility == false then
            mm.combo:spacer("combo_menu_spacer3", "R")
            mm.combo:boolean('r_killsteal', 'Killsteal R', false)
            mm.combo:slider('r_use_auto', "R on X enemies", 3, 1, 5, 1) --:tooltip("1 disables")
            mm.combo:slider('r_use_shield', "R if removes X shield", 500, 0, 1000, 1) --:tooltip("0 disables")

        end


        mm:header('harass', 'Harass Mode')
        mm.harass:spacer("harass_menu_spacer1", "Q")
        mm.harass:boolean('q_use', 'Use Q', true)
        mm.harass:list('q_hitchance', 'Q Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2) -- these fuckers start at 0 compared to lua starting at 1, be aware of that
        mm.harass:header('advanced', 'Advanced')
        mm.harass.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for casting less")
        mm.harass.advanced:slider('q_time_modifier', "Max range modifier", 75, 0, 100, 1) --:tooltip("Max Projectile Time Before Forcing VeryHigh Hitchance (miliseconds)")

        mm.harass:spacer("harass_menu_spacer2", "E")
        mm.harass:boolean('e_use', 'Use E', true)
        mm.harass:list('e_mode', 'E Mode', { 'AA reset', 'Before AA' }, 0)


        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('q_range', 'Draw W Range', true)
        mm.drawings:color('q_color', 'W Color', graphics.argb(210, 20, 165, 228))
        if viegoCompatibility == false then
            mm.drawings:boolean('r_range', 'Draw Auto R Range', true)
            mm.drawings:color('r_color', 'R Color', graphics.argb(255, 255, 0, 0))

        end

        print("[Turbo Scripts - Blitzcrank] menu created")
        return mm
    end

    function Blitzcrank:IsTransformed()
        if viegoCompatibility == false then return true end
        if player:findBuff("viegopassivetransform") then
            if player.skinHash == 0x9d92842a then
                return true
            end
        end
        return false
    end

    function Blitzcrank:RDmg(target) -- this just gets the damage of r
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local damage = 150 + 125 * spell.level + player.totalAbilityPower
        return damageLib.magical(player, target, damage)
    end

    function Blitzcrank:OnTick()
        Time = os.clock() -- this will be used to check if our spells are being spammed, i have no idea if this should be global or even executed here, but fuck it 

        if player.isDead or player.teleportType ~= TeleportType.Null then return end -- we don't want to be doing shit if we're dead or teleporting

        if not self:IsTransformed() then return end

        self:Combo()
        self:Harass()
    end

    function Blitzcrank:Combo()
        if orb.isComboActive == false then return end -- checks if we're holding down the key to combo


        self:KillstealR()

        self:AutoR()
        self:ShieldR()
        self:CastQ("combo")
        self:CastE("combo")
    end

    function Blitzcrank:Harass()
        if orb.harassKeyDown == false then return end -- checks if we're holding down the key to combo

        self:CastQ("harass")
        self:CastE("harass")
    end

    function Blitzcrank:CastQ(mode)
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end -- if q isn't ready

        if self.BlitzcrankMenu[mode].q_use:get() == false then return end -- if q isn't set to be used in the menu

        if player.isWindingUp then return end -- checks if we're going to cancel an aa
        if player.canAttack == false then return end -- checks if we're in the middle of a spellcast

        if Time - self.castTime[SpellSlot.Q] < 0.30 then return end -- this function prevents us from spamming q too much while doing the cast animation


        for _, enemy in pairs(ts.getTargets()) do -- gets each target ordered by best to worst (according to the target selector)
            if ts.selected and -- if we have a forced target (with left click)
                    enemy.handle ~= ts.selected.handle and -- and it isn't the target currently being tested
                    ts.selected.isDead == false -- and the target we've clicked on hasn't died already
            then goto continue end -- try the next target

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end -- if our target isn't valid try next target

            if enemy:hasBuffOfType(BuffType.SpellImmunity) then goto continue end -- checks if they're immune to spells don't want to waste anything :P

            local prediction = pred.getPrediction(enemy, self.qData) -- get our prediction with the data from q

            if not (prediction and prediction.castPosition.isValid) then goto continue end -- if we didn't get a proper prediction go next target

            if prediction.hitChance <= HitchanceMenu[self.BlitzcrankMenu[mode].q_hitchance:get()] then goto continue end -- if we don't meet the base hitchance requirement set in the menu try new target

            if player.pos:distance(enemy.pos) + PredExtentions:GetMissileTime(prediction.castPosition, self.qData) * enemy.characterIntermediate.moveSpeed * (self.BlitzcrankMenu[mode].advanced.q_time_modifier:get()/100) < self.qData.range then -- if the missile is going to take over X amount of time to reach it's target force it to atleast use very high hitchance, else use the hitchance from menu
                self:DebugPrint("Cast Q quick missiletime with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.Q, prediction.castPosition, false, false) -- throw the shit at the spot
                self.castTime[SpellSlot.Q] = os.clock()
                break
            elseif prediction.hitChance >= HitChance.High then
                self:DebugPrint("Cast Q long missiletime with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                self.castTime[SpellSlot.Q] = os.clock()
                break
            end

            ::continue:: -- this is the "checkpoint" we goto to continue the loop
        end
    end

    function Blitzcrank:KillstealR()
        if(viegoCompatibility) then return end
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end -- if R isn't ready

        if self.BlitzcrankMenu.combo.r_killsteal:get() == false then return end -- if killsteal with r isn't enabled in menu

        if player.isWindingUp then return end -- checks if we're going to cancel an aa
        if player.canAttack == false then return end -- checks if we're in the middle of a spellcast


        if Time - self.castTime[SpellSlot.R] < 0.30 then return end -- this function prevents us from spamming R too much while doing the cast animation

        for _, enemy in pairs(ts.getTargets()) do

            if not enemy:isValidTarget(self.rData.radius, true, player.pos) then goto continue end -- if they're not valid go next target
            if enemy.isInvulnerable then goto continue end -- if they're invulnerable no need to try to kill them 

            local predictedPos = pred.positionAfterTime(enemy, self.rData.delay) -- get prediction 

            if not (predictedPos and predictedPos.isValid) then goto continue end -- if we didn't get a proper prediction go next target

            if predictedPos:distance2DSqr(player.pos) >= self.rData.radius ^ 2 then goto continue end -- if we predicted that they go out of radius before we cast ult

            local targetHP = enemy.health + enemy.characterIntermediate.hpRegenRate * 3 -- get target health with some leeway

            if targetHP <= self:RDmg(enemy) then  -- if we can't kill them

                self:DebugPrint("Cast R Killsteal On: " .. enemy.name)
                player:castSpell(SpellSlot.R, false, false)
                self.castTime[SpellSlot.R] = os.clock()
                break
                self:DebugPrint("if we see this text go pray")
            end
            ::continue::
        end
    end

    function Blitzcrank:ShieldR() -- this is the exact same as killsteal with minor adjustments, if you're confused go look at killsteal
        if(viegoCompatibility) then return end
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if self.BlitzcrankMenu.combo.r_use_shield:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end


        if Time - self.castTime[SpellSlot.R] < 0.30 then return end

        local totalShield = 0 -- creates a local number that starts at zero, we will add all the shield of the enemies around us together in the following for loop

        for _, enemy in pairs(ts.getTargets()) do

            if not enemy:isValidTarget(self.rData.radius, true, player.pos) then goto continue end


            local predictedPos = pred.positionAfterTime(enemy, self.rData.delay)

            if not (predictedPos and predictedPos.isValid) then goto continue end

            if predictedPos:distance2DSqr(player.pos) >= self.rData.radius ^ 2 then goto continue end

            totalShield = totalShield + enemy.allShield

            ::continue::
        end

        if totalShield >= self.BlitzcrankMenu.combo.r_use_shield:get() then -- checks if we've got above the shield threshold defined in the menu
            self:DebugPrint("Cast R removing " .. totalShield .. " shield hitpoints")
            player:castSpell(SpellSlot.R, false, false)
            self.castTime[SpellSlot.R] = os.clock()
            return
        end
    end


    function Blitzcrank:AutoR() -- this is the exact same as shield r, but we don't count shield just enemies
        if(viegoCompatibility) then return end
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if self.BlitzcrankMenu.combo.r_use_auto:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end


        if Time - self.castTime[SpellSlot.R] < 0.30 then return end

        local enemiesCounted = 0

        for _, enemy in pairs(ts.getTargets()) do

            if not enemy:isValidTarget(self.rData.radius, true, player.pos) then goto continue end

            local predictedPos = pred.positionAfterTime(enemy, self.rData.delay)

            if not (predictedPos and predictedPos.isValid) then goto continue end

            if predictedPos:distance2DSqr(player.pos) >= self.rData.radius ^ 2 then goto continue end

            enemiesCounted = enemiesCounted + 1

            ::continue::
        end

        if enemiesCounted >= self.BlitzcrankMenu.combo.r_use_auto:get() then
            self:DebugPrint("Cast R on " .. enemies .. " enemies")
            player:castSpell(SpellSlot.R, false, false)
            self.castTime[SpellSlot.R] = os.clock()
            return

        end
    end

    function Blitzcrank:OnOrbAfterAttack() -- this is our auto attack cancel callback, super useful
        if not self:IsTransformed() then return end
        local mode = false

        if orb.isComboActive == true then mode = "combo" end -- checks if we're in combo
        if orb.harassKeyDown == true then mode = "harass" end -- checks if we're in harass
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end -- E is used for the aa reset

        if mode == false then return end

        if self.BlitzcrankMenu[mode].e_use:get() == false then return end -- if we have disabled e usage in the menu for the mode
        if self.BlitzcrankMenu[mode].e_mode:get() ~= 0 then return end -- we don't want to aa reset if e usage is in before e mode in the respective orbwalker mode

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius -- defines the range where we can find enemies

            if enemy:isValidTarget(range, true, player.pos) == false then goto contiune end -- checks someone is in the range previously defined and a valid target
            if enemy:hasBuffOfType(BuffType.SpellImmunity) == false then  -- checks if they're immune to spells don't want to waste any incase they are

                self:DebugPrint("Attempting aa reset on: " .. enemy.name)
                player:castSpell(SpellSlot.E, false, false)
                self.castTime[SpellSlot.E] = os.clock()

                -- at this point some would do orb.reset to reset the aa timer completeing the aa reset, but we do that in OnCastSpell to also catch manual e's

                break
            end
            ::contiune::
        end
    end

    function Blitzcrank:CastE(mode)
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end -- E is used for the aa reset
        if self.BlitzcrankMenu[mode].e_mode:get() ~= 1 then return end -- we don't want to aa reset if e usage is in before e mode
        if self.BlitzcrankMenu[mode].e_use:get() == false then return end -- if we have disabled e usage in the menu

        if player.canAttack == false then return end -- this checks if we currently casting a spell 

        if Time - self.castTime[SpellSlot.E] < 0.10 then return end -- this is again so we don't spam e while in cast animation (since e has 0 cast animation this is just dependent on ping, it will continue to try to cast e until server tells us that e spellstate changes)

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius -- defines the range where we can find enemies 

            if enemy:isValidTarget(range, true, player.pos) == false then goto contiune end -- checks someone is in the range previously defined and a valid target
            if enemy:hasBuffOfType( BuffType.SpellImmunity) == false then -- checks if they're immune to spells, if so we don't want to waste some

                self:DebugPrint("Attempting aa reset on: " .. enemy.name)
                player:castSpell(SpellSlot.E, false, false)
                self.castTime[SpellSlot.E] = os.clock()

                -- at this point some would do orb.reset to reset the aa timer completeing the aa reset, but we do that in OnCastSpell to also catch manual e's

                break
            end
            ::contiune::
        end

    end

    function Blitzcrank:OnDraw()
        if not self:IsTransformed() then return end
        if self.BlitzcrankMenu.drawings.q_range:get() then -- if menu says we draw the range
            graphics.drawCircle(player.pos, self.qData.range, 1, self.BlitzcrankMenu.drawings.q_color:get()) -- draw the range :P
        end

        if viegoCompatibility == false then
            if self.BlitzcrankMenu.drawings.r_range:get() then
                graphics.drawCircle(player.pos, self.rData.radius, 1, self.BlitzcrankMenu.drawings.r_color:get())
            end

        end
    end

    function Blitzcrank:OnCastSpell(sender, spellCastInfo) -- this gets called everytime we cast a spell
        if not self:IsTransformed() then return end
        if sender.handle ~= player.handle then return end -- if we didn't cast it we don't care

        self.castTime[spellCastInfo.slot] = os.clock() -- Puts a spell we casted in the table we created earlier with the "key" of the spellslot, this is what lets us stop spamming spells

        self:DebugPrint("Casting spell: " .. spellCastInfo.name .. " with hash: " .. spellCastInfo.hash)

        if spellCastInfo.hash == 2406449588 then -- this is the has for blitzcrank e, this lets us reset the orbwalker each time we cast e making all aa resets (even manual) consistant
            self:DebugPrint("Orb Reset")
            orb.reset()
        end
    end

    print("[Turbo Scripts - Blitzcrank] initializing")
    Blitzcrank:__init() -- this is called once every single function in the script has been "gone through" thereby being able to start initializing the script, connecting cb to functions

end

function Blitzcrank.Unload() -- unloads each function we use and deletes the menu
    menu.delete('turbo_blitzcrank')
end

return Blitzcrank -- returns so we can require this scripts functions outside of this file
