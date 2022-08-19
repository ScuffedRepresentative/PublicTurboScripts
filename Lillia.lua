local PredExtentions = require "predExtentions"

local Lillia = {}

function Lillia.Load(viegoCompatibility)

    viegoCompatibility = viegoCompatibility or false

    print("[Turbo Scripts - Lillia] Loaded")

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingEnd }

    function Lillia:DebugPrint(...)
        print("[Turbo Scripts - Lillia] " .. ...)
    end

    function Lillia:__init()

        self.castTime = { [0] = 0, 0, 0, 0 }

        self.qData = {
            delay = 0.25,
            type = spellType.circular,
            rangeType = SpellRangeType.Center,
            range = 0,
            radius = 475,
            boundingRadiusMod = false
        }
        self.wData = {
            delay = 0.75,
            type = spellType.linear,
            rangeType = SpellRangeType.Center,
            range = 500,
            radius = 55,
            collision = {
                flags = CollisionFlags.Terrain
            },
        }
        self.eLobData = {
            delay = 0.4,
            type = spellType.circular,
            rangeType = SpellRangeType.Center,
            range = 700,
            speed = 1400,
            radius = 150,
            collision = {
                flags = CollisionFlags.Braum
            }
        }
        self.rData = {
            type = spellType.self
        }

        self.LilliaMenu = self:CreateMenu()

        self.viegoCompatibilityMode = false

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Lillia:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) Lillia:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) Lillia:OnCastSpell(...) end)

        print("[Turbo Scripts - Lillia] initialized")
    end

    function Lillia:CreateMenu()
        local mm = menu.create('turbo_Lillia', 'Turbo Lillia')

        mm:header('combo', 'Combo Mode')

        mm.combo:spacer("harass_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)

        mm.combo:spacer("harass_menu_spacer2", "W")
        mm.combo:boolean('w_use', 'Use W', true)
        mm.combo:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 1) -- todo check if path is safe

        mm.combo:spacer("harass_menu_spacer3", "E")
        mm.combo:boolean('e_use', 'Use E', true)
        mm.combo:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        if viegoCompatibility == false then
            mm.combo:spacer("combo_menu_spacer4", "R")
            mm.combo:slider('r_use_auto', "R on X enemies", 3, 0, 5, 1)
        end


        mm:header('harass', 'Harass Mode')
        mm.harass:spacer("harass_menu_spacer1", "Q")
        mm.harass:boolean('q_use', 'Use Q', true)

        mm.harass:spacer("harass_menu_spacer3", "E")
        mm.harass:boolean('e_use', 'Use E', true)
        mm.harass:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        mm:header('clear', 'Clear Mode')

        mm.clear:spacer("harass_menu_spacer1", "Q")
        mm.clear:boolean('q_use', 'Use Q', true)

        mm.clear:spacer("harass_menu_spacer2", "W")
        mm.clear:boolean('w_use', 'Use W', true)
        mm.clear:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        mm.clear:spacer("harass_menu_spacer3", "E")
        mm.clear:boolean('e_use', 'Use E', true)
        mm.clear:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        if viegoCompatibility == false then
            mm:header('misc', 'misc')
            mm.misc:keybind('disableaa', 'Disable AA', 0x47, false, true)
            mm.misc:keybind('disablew', 'Save W for killable', 0x05, false, true)
        end


        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('q_range', 'Draw Q Range', true)
        mm.drawings:color('q_color', 'Q Color', graphics.argb(210, 20, 165, 228))
        mm.drawings:boolean('w_range', 'Draw W Range', true)
        mm.drawings:color('w_color', 'W Color', graphics.argb(210, 20, 165, 228))
        mm.drawings:boolean('e_range', 'Draw E Range', true)
        mm.drawings:color('e_color', 'E Color', graphics.argb(210, 20, 165, 228))

        local window = permaShow.create('permashowLillia', 'Keybind', vec2(500,500))
        window:add("Disable AA", mm.misc.disableaa)
        window:add("Killable W", mm.misc.disablew)

        return mm
    end

    function Lillia:IsTransformed()
        if viegoCompatibility == false then return true end
        if player:findBuff("viegopassivetransform") then
            if player.skinHash == 0xd23b335 then
                return true
            end
        end
        return false
    end

    function Lillia:WDmg(target)
        local spell = player:spellSlot(SpellSlot.W)
        if spell.level == 0 then return 0 end
        local damage = ((spell.level * 60 + 180) + (player.totalAbilityPower * 1.05))
        return damageLib.magical(player, target, damage)
    end

    function Lillia:OnTick()
        Time = os.clock()

        if player.isDead or player.teleportType ~= TeleportType.Null then return end

        if not self:IsTransformed() then return end

        self:Combo()
        self:Harass()
        self:Clear()
    end

    function Lillia:Combo()
        if orb.isComboActive == false then return end

        if self.LilliaMenu.misc.disableaa:get() then
            orb.setAttackPause(0.2)
        end

        self:CastQ("combo")
        self:CastW()
        self:CastE("combo")
        self:CastR()
    end

    function Lillia:Harass()
        if orb.harassKeyDown == false then return end

        self:CastQ("harass")
        self:CastE("harass")
    end

    function Lillia:Clear()
        if orb.laneClearKeyDown == false then return end
        self:CastClearQ()
        self:CastClearW()
        self:CastClearE()
    end

    function Lillia:CastQ(mode)
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end

        if self.LilliaMenu[mode].q_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.10 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            local predictedPos = pred.positionAfterTime(enemy, self.qData.delay) -- get prediction

            if not (predictedPos and predictedPos.isValid) then goto continue end -- if we didn't get a proper prediction go next target

            if predictedPos:distanceSqr(player.pos) >= self.qData.radius ^ 2 then goto continue end -- if we predicted that they go out of radius before we cast ult

            if player.pos:distanceSqr(enemy.pos) > 50625 then -- 225 ^ 2
                player:castSpell(SpellSlot.Q, false, false)
                print("casting q")
                self.castTime[SpellSlot.Q] = os.clock()
                break
            end
            ::continue::
        end
    end

    function Lillia:CastW()
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.LilliaMenu.combo.w_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.W] < 0.25 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            local targetHP = enemy.health + enemy.allShield + enemy.characterIntermediate.hpRegenRate * 3

            if self.LilliaMenu.misc.disablew:get() and (enemy.isInvulnerable or targetHP >= self:WDmg(enemy)) then goto continue end

            --local predictedPos = pred.positionAfterTime(enemy, 0.75) -- get prediction
            --
            --if not (predictedPos and predictedPos.isValid) then goto continue end -- if we didn't get a proper prediction go next target
            --
            --self.wData.speed = PredExtentions:GetMissileSpeed(predictedPos, 0.75, 0)

            local prediction = pred.getPrediction(enemy, self.wData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.LilliaMenu.combo.w_hitchance:get()] then
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                print("casting w")
                self.castTime[SpellSlot.W] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Lillia:CastE(mode)
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end

        if self.LilliaMenu[mode].e_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.E] < 0.25 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end
            if player.canAttack == false then return end

            local prediction = pred.getPrediction(enemy, self.eLobData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.LilliaMenu[mode].e_hitchance:get()] then
                player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                print("casting e")
                self.castTime[SpellSlot.E] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Lillia:CastR() -- this is the exact same as killsteal with minor adjustments, if you're confused go look at killsteal
        if(viegoCompatibility) then return end
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end


        if self.LilliaMenu.combo.r_use_auto:get() == 0 then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end


        if Time - self.castTime[SpellSlot.R] < 0.15 then return end

        local whoresToHit = 0 -- creates a local number that starts at zero, we will add all the shield of the enemies around us together in the following for loop

        for _, enemy in pairs(ts.getTargets()) do

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            if enemy:findBuff("LilliaPDoT") then
                whoresToHit = whoresToHit + 1
            end

            ::continue::
        end

        if whoresToHit >= self.LilliaMenu.combo.r_use_auto:get() then -- checks if we've got above the shield threshold defined in the menu
            player:castSpell(SpellSlot.R, false, false)
            self.castTime[SpellSlot.R] = os.clock()
            return
        end
    end

    function Lillia:CastClearQ()
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end

        if self.LilliaMenu.clear.q_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.Q] < 0.10 then return end


        for _, minion in pairs(objManager.minions.list) do

            if not minion:isValidTarget(1000, false, player.pos) then goto continue end

            if not minion.team == 300 then goto continue end

            if minion.isLaneMinion then goto continue end
            if minion.isWard then goto continue end
            if minion.isPlant then goto continue end
            if minion.isPet then goto continue end

            local predictedPos = pred.positionAfterTime(minion, self.qData.delay) -- get prediction

            if not (predictedPos and predictedPos.isValid) then goto continue end -- if we didn't get a proper prediction go next target

            if predictedPos:distance2DSqr(player.pos) >= self.qData.radius ^ 2 then goto continue end -- if we predicted that they go out of radius before we cast ult

            if player.pos:distance2DSqr(minion.pos) > 225^2 then
                player:castSpell(SpellSlot.Q, false, false)
                self.castTime[SpellSlot.Q] = os.clock()
                break
            end
            ::continue::
        end
    end

    function Lillia:CastClearW()
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.LilliaMenu.clear.w_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.W] < 0.25 then return end



        for _, minion in pairs(objManager.minions.list) do -- todo: fix this it'll cast on friendly rift


            if not minion:isValidTarget(1000, false, player.pos) then goto continue end

            if not minion.team == 300 then goto continue end

            if minion.isLaneMinion then goto continue end
            if minion.isWard then goto continue end
            if minion.isPlant then goto continue end
            if minion.isPet then goto continue end

            local prediction = pred.getPrediction(minion, self.wData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.LilliaMenu.clear.w_hitchance:get()] then
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                self.castTime[SpellSlot.W] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Lillia:CastClearE()
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end

        if self.LilliaMenu.clear.e_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.E] < 0.25 then return end


        for _, minion in pairs(objManager.minions.list) do


            if not minion:isValidTarget(1000, false, player.pos) then goto continue end

            if not minion.team == 300 then goto continue end

            if minion.isLaneMinion then goto continue end
            if minion.isWard then goto continue end
            if minion.isPlant then goto continue end
            if minion.isPet then goto continue end

            local prediction = pred.getPrediction(minion, self.eLobData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.LilliaMenu.clear.e_hitchance:get()] then
                player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                self.castTime[SpellSlot.E] = os.clock()
                break
            end

            ::continue::
        end
    end

    function Lillia:OnDraw()

        if not self:IsTransformed() then return end

        if self.LilliaMenu.drawings.q_range:get() then
            graphics.drawCircle(player.pos, self.qData.radius, 1, self.LilliaMenu.drawings.q_color:get())
        end
        if self.LilliaMenu.drawings.w_range:get() then
            graphics.drawCircle(player.pos, self.wData.range, 1, self.LilliaMenu.drawings.w_color:get())
        end
        if self.LilliaMenu.drawings.e_range:get() then
            graphics.drawCircle(player.pos, self.eLobData.range, 1, self.LilliaMenu.drawings.e_color:get())
        end
    end

    function Lillia:OnCastSpell(sender, spellCastInfo)

        if not self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end
        self.castTime[spellCastInfo.slot] = os.clock()
        self:DebugPrint("Casting spell: " .. spellCastInfo.name)
    end

    print("[Turbo Scripts - Lillia] initializing")
    Lillia:__init()

end

function Lillia.Unload()
    permaShow.delete('permashowLillia')
    menu.delete('turbo_Lillia')
end

return Lillia
