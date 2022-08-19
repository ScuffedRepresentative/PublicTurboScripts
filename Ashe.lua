local PredExtentions = require "predExtentions"

local Ashe = {}

function Ashe.Load(viegoCompatibility)

    viegoCompatibility = viegoCompatibility or false

    print("[Turbo Scripts - Ashe] Loaded")

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingEnd }

    function Ashe:DebugPrint(...)
        print("[Turbo Scripts - Ashe] " .. ...)
    end

    function Ashe:__init()

        self.castTime = { [0] = 0, 0, 0, 0 }

        self.qData = {
            type = spellType.self,
        }
        self.wData = {
            delay = 0.25, -- if not defined -> default = 0
            type = spellType.linear, -- if not defined -> default = spellType.linear
            rangeType = SpellRangeType.Edge, -- if not defined -> default = SpellRangeType.Center
            range = 1270, -- if not defined -> default = math.huge
            speed = 2000, -- if not defined -> default = math.huge
            radius = 20, -- if not defined -> math.huge
            --width = 100, -- width = radius * 2, can be used instead of radius
            collision = { -- if not defined -> no collision calcs
                hero = SpellCollisionType.Hard,
                -- Hard = Collides with object and stops on collision
                minion = SpellCollisionType.Hard,
                -- Soft = Collides with object and passes through them.
                tower = SpellCollisionType.None,
                -- None = Doesn't collide with object. Also default if not defined
                extraRadius = 10, -- if not defined -> default = 0
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum) -- defaults to none
            },
        }
        self.eData = {
            delay = 0.25,
            type = spellType.linear,
            rangeType = SpellRangeType.Center,
            speed = 1400,
            radius = 25,
            collision = {
                hero = SpellCollisionType.None,
                minion = SpellCollisionType.None,
                tower = SpellCollisionType.None,
                extraRadius = 0,
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira)
            },
            boundingRadiusMod = false
        }
        self.rData = {
            delay = 0.25,
            type = spellType.linear,
            rangeType = SpellRangeType.Edge,
            speed = 1600,
            radius = 130,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.None,
                tower = SpellCollisionType.None,
                extraRadius = 20,
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }

        self.AsheMenu = self:CreateMenu()

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Ashe:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) Ashe:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) Ashe:OnCastSpell(...) end)
        table.insert(self.callbacks[1], cb.orbAfterAttack)
        table.insert(self.callbacks[2], function(...) Ashe:OnOrbAfterAttack(...) end)

        print("[Turbo Scripts - Ashe] initialized")
    end

    function Ashe:CreateMenu()
        local mm = menu.create('turbo_Ashe', 'Turbo Ashe')

        mm:spacer("turbotech", "TurboTech BETA")

        mm:header('combo', 'Combo Mode')
        mm.combo:spacer("combo_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)
        mm.combo:list('q_mode', 'Q Mode', { 'Both', 'AA reset', 'Before AA' }, 1)

        mm.combo:spacer("combo_menu_spacer2", "W")
        mm.combo:boolean('w_use', 'Use W', true)
        mm.combo:boolean('w_dpscheck', "Dps Check", true):tooltip("Don't cast if you lose single target dps")
        mm.combo:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 0)
        mm.combo:header('advanced', 'Advanced')
        mm.combo.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for sending less")
        mm.combo.advanced:slider('w_time_modifier', "Max range modifier", 75, 0, 100, 1) --:tooltip("Max Projectile Time Before Forcing VeryHigh Hitchance (miliseconds)")

        if viegoCompatibility == false then
            mm.combo:spacer("combo_menu_spacer3", "R")
            mm.combo:boolean('r_use', 'Use R', true)
            mm.combo:boolean('r_use_cc', 'Use R On CrowdControl', true)
            mm.combo:slider('r_use_auto_range', "R Range", 2000, 0, 15000, 5)
            mm.combo:list('r_hitchance', 'R Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 4)

        end


        mm:header('harass', 'Harass Mode')
        mm.harass:boolean('w_use', 'Use W', true)
        mm.harass:boolean('w_dpscheck', "Dps Check", true):tooltip("Don't cast if you lose single target dps")
        mm.harass:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 0)
        mm.harass:header('advanced', 'Advanced')
        mm.harass.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for casting less")
        mm.harass.advanced:slider('w_time_modifier', "Max range modifier", 75, 0, 100, 1) --:tooltip("Max Projectile Time Before Forcing VeryHigh Hitchance (miliseconds)")

        if viegoCompatibility == false then
            mm:header('misc', 'Misc')
            mm.misc:keybind('r_use_manuel', 'Use Manuel R', 0x47, false, false)
            mm.misc:boolean('r_use_manuel_checkmouse', 'Manuel R Mouse Check', true)
            mm.misc:slider('r_use_manuel_scanrange', "Manuel R Mouse Radius", 600, 0, 2000, 1)
            mm.misc:list('r_hitchance', 'R Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 3)
        end


        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('w_range', 'Draw W Range', true)
        mm.drawings:color('w_color', 'W Color', graphics.argb(210, 20, 165, 228))
        if viegoCompatibility == false then
            mm.drawings:boolean('r_range', 'Draw Auto R Range', true)
            mm.drawings:color('r_color', 'R Auto Color', graphics.argb(255, 255, 0, 0))
            mm.drawings:boolean('r_manuel_range', 'Draw R Manuel Range', true)
            mm.drawings:color('r_manuel_color', 'R Manual Color', graphics.argb(255, 60, 255, 0))

        end

        return mm
    end

    function Ashe:IsTransformed()
        if viegoCompatibility == false then return true end
        if player:findBuff("viegopassivetransform") then
            if player.skinHash == 0xda1e294f then
                return true
            end
        end
        return false
    end

    function Ashe:OnTick()
        Time = os.clock()

        if player.isDead or player.teleportType ~= TeleportType.Null then return end

        if not self:IsTransformed() then return end

        self:ManuelR()

        self:Combo()
        self:Harass()
    end

    function Ashe:Combo()
        if orb.isComboActive == false then return end

        self:BeforeQ()
        self:CastR()
        self:CastW("combo")
    end

    function Ashe:Harass()
        if orb.harassKeyDown == false then return end

        self:CastW("harass")
    end

    function Ashe:BeforeQ()
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end
        if self.AsheMenu.combo.q_mode:get() == 1 then return end
        if self.AsheMenu.combo.q_use:get() == false then return end

        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.10 then return end

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius

            if enemy:isValidTarget(range, true, player.pos) then

                self:DebugPrint("Attempting aa reset on: " .. enemy.name)
                player:castSpell(SpellSlot.Q, false, false)
                self.castTime[SpellSlot.Q] = os.clock()
                break
            end
            ::contiune::
        end
    end

    function Ashe:ManuelR()
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if(viegoCompatibility) then return end

        if self.AsheMenu.misc.r_use_manuel:get() == false then return end

        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.R] < 0.25 then return end

        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            if enemy:hasBuffOfType(BuffType.SpellImmunity) then goto continue end

            local rangesqr = self.AsheMenu.misc.r_use_manuel_scanrange:get() ^ 2;

            if (self.AsheMenu.misc.r_use_manuel_checkmouse:get() == true and
                    enemy.position:distance2DSqr(game.cursorPos) >= rangesqr) then goto continue end

            local prediction = pred.getPrediction(enemy, self.rData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.AsheMenu.misc.r_hitchance:get()] then
                self:DebugPrint("Cast Manuel R with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                self.castTime[SpellSlot.R] = os.clock()
                break
            end
            ::continue::
        end
    end

    function Ashe:WdpsCheck(target)
        local basicAttackDamage = player.totalAttackDamage

        if player:findBuff("AsheQAttack") then
            basicAttackDamage = basicAttackDamage * (1+(0.05*player:spellSlot(SpellSlot.Q).level))
        end

        if player:hasItem(3124) then -- rageblade
            basicAttackDamage = basicAttackDamage + basicAttackDamage * 1.7 -- this is fucking horrible, but works well enough
        else
            basicAttackDamage = basicAttackDamage + (basicAttackDamage * player.characterIntermediate.crit * player.characterIntermediate.critDamageMultiplier)
        end

        if player:hasItem(3091) then -- wits end
            basicAttackDamage = basicAttackDamage + (8 + player.level * 4)
        end

        if player:hasItem(3153) then -- bork
            basicAttackDamage = basicAttackDamage + (target.health * 0.08)
        end

        local asheAADmg = (0.658 * player.characterIntermediate.attackSpeedMod) * basicAttackDamage * 0.25
        local asheWDmg = 5 + (15 * player:spellSlot(SpellSlot.W).level) + player.totalAttackDamage

        if asheWDmg > asheAADmg then return true end
        return false
    end

    function Ashe:CastW(mode)
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.AsheMenu[mode].w_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end


        for _, hero in pairs(ts.getTargets()) do
            if hero.pos:distanceSqr(player.pos) <= (player:getAttackRange(hero))^2 then
                if self:WdpsCheck(hero) == false and self.AsheMenu[mode].w_dpscheck:get() then
                    return
                end
            end
        end

        if Time - self.castTime[SpellSlot.W] < 0.25 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            local prediction = pred.getPrediction(enemy, self.wData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance <= HitchanceMenu[self.AsheMenu[mode].w_hitchance:get()] then goto continue end

            if player.pos:distance(enemy.pos) + PredExtentions:GetMissileTime(prediction.castPosition, self.wData) * enemy.characterIntermediate.moveSpeed * (self.AsheMenu[mode].advanced.w_time_modifier:get()/100) < self.wData.range then -- if the missile is going to take over X amount of time to reach it's target force it to atleast use very high hitchance, else use the hitchance from menu
                self:DebugPrint("Cast W quick missiletime with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                self.castTime[SpellSlot.W] = os.clock()
                break
            elseif prediction.hitChance >= HitChance.High then
                self:DebugPrint("Cast W long missiletime with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                self.castTime[SpellSlot.W] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Ashe:CastR()
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if(viegoCompatibility) then return end

        if self.AsheMenu.combo.r_use:get() == false then return end

        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.R] < 0.25 then return end

        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(self.AsheMenu.combo.r_use_auto_range:get(), true, player.pos) then goto continue end

            if enemy:hasBuffOfType(BuffType.SpellImmunity) then goto continue end

            local prediction = pred.getPrediction(enemy, self.rData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if (prediction.hitChance >= 8 and self.AsheMenu.combo.r_use_cc:get()) then
                self:DebugPrint("Cast R on cc")
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                self.castTime[SpellSlot.R] = os.clock()
                break
            end

            if prediction.hitChance >= HitchanceMenu[self.AsheMenu.combo.r_hitchance:get()] then
                self:DebugPrint("Cast R with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                self.castTime[SpellSlot.R] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Ashe:OnOrbAfterAttack()

        if not self:IsTransformed() then return end

        if orb.isComboActive ~= true then return end
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end
        if self.AsheMenu.combo.q_use:get() == false then return end
        if self.AsheMenu.combo.q_mode:get() == 2 then return end

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius

            if enemy:isValidTarget(range, true, player.pos) then

                self:DebugPrint("Attempting aa reset on: " .. enemy.name)
                player:castSpell(SpellSlot.Q, false, false)
                self.castTime[SpellSlot.Q] = os.clock()

                break
            end
            ::contiune::
        end
    end

    function Ashe:OnDraw()

        if not self:IsTransformed() then return end

        if self.AsheMenu.drawings.w_range:get() then
            graphics.drawCircle(player.pos, 1270, 1, self.AsheMenu.drawings.w_color:get()) -- 1320 = 1200 + 70 (ashe w spawner der, kan også være bounding box i fremtidige scripts)
        end

        if(viegoCompatibility == false) then
            if self.AsheMenu.drawings.r_range:get() then
                graphics.drawCircle(player.pos, self.AsheMenu.combo.r_use_auto_range:get(), 1,
                        self.AsheMenu.drawings.r_color:get())
            end

            if self.AsheMenu.drawings.r_manuel_range:get() and self.AsheMenu.misc.r_use_manuel:get() then
                graphics.drawCircle(game.cursorPos, self.AsheMenu.misc.r_use_manuel_scanrange:get(), 1,
                        self.AsheMenu.drawings.r_manuel_color:get())
            end
        end
    end

    function Ashe:OnCastSpell(sender, spellCastInfo)

        if not self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end
        self.castTime[spellCastInfo.slot] = os.clock()
        self:DebugPrint("Casting spell: " .. spellCastInfo.name)

        if spellCastInfo.hash == 1084488269 then
            self:DebugPrint("Orb Reset")
            orb.reset()
        end
    end

    print("[Turbo Scripts - Ashe] initializing")
    Ashe:__init()

end

function Ashe.Unload()
    menu.delete('turbo_Ashe')
end

return Ashe
