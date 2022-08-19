local PredExtentions = require "predExtentions"

local MissFortune = {}

function MissFortune.Load(viegoCompatibility)

    viegoCompatibility = viegoCompatibility or false

    print("[Turbo Scripts - MissFortune] Loaded")

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingEnd }

    function MissFortune:DebugPrint(...)
        print("[Turbo Scripts - MissFortune] " .. ...)
    end

    function MissFortune:__init()

        self.castTime = { [0] = 0, 0, 0, 0 }

        self.qData = {
            delay = 0.25, -- if not defined -> default = 0
            speed = 1400
        }
        self.wData = {
            type = spellType.self
        }
        self.eData = {
            delay = 0.25, -- if not defined -> default = 0
            type = spellType.circular, -- if not defined -> default = spellType.linear
            range = 1000, -- if not defined -> default = math.huge
            radius = 200, -- if not defined -> math.huge
            boundingRadiusMod = false
        }

        self.MissFortuneMenu = self:CreateMenu()

        self.viegoCompatibilityMode = false

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) MissFortune:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) MissFortune:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.orbAfterAttack)
        table.insert(self.callbacks[2], function(...) MissFortune:OnOrbAfterAttack(...) end)
        table.insert(self.callbacks[1], cb.buff)
        table.insert(self.callbacks[2], function(...) MissFortune:OnBuff(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) MissFortune:OnCastSpell(...) end)

        print("[Turbo Scripts - MissFortune] initialized")
    end

    function MissFortune:CreateMenu()
        local mm = menu.create('turbo_MissFortune', 'Turbo MissFortune')

        mm:spacer("turbotech", "TurboTech BETA")

        mm:header('combo', 'Combo Mode')
        mm.combo:spacer("combo_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)
        mm.combo:boolean('q_use_extended', 'Use Extended Q', false):tooltip("doesn't work for now")

        mm.combo:spacer("combo_menu_spacer2", "W")
        mm.combo:boolean('w_use', 'Use W', true)

        mm.combo:spacer("combo_menu_spacer3", "E")
        mm.combo:boolean('e_use', 'Use E', true)
        mm.combo:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 1)


        mm:header('harass', 'Harass Mode')

        mm.harass:spacer("harass_menu_spacer1", "Q")
        mm.harass:boolean('q_use', 'Use Q', true)
        mm.harass:boolean('q_use_extended', 'Use Extended Q', true):tooltip("doesn't work for now")

        mm.harass:spacer("harass_menu_spacer3", "E")
        mm.harass:boolean('e_use', 'Use E', true)
        mm.harass:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 1)


        if viegoCompatibility == false then
            mm:header('misc', 'misc')

            mm.misc:boolean('r_disable_evade', 'Disable Evade in R', true)
            mm.misc:boolean('r_disable_orbwalker', 'Disable Orbwalker in R', true)
        end

        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('q_range', 'Draw Q Range', true)
        mm.drawings:color('q_color', 'Q Color', graphics.argb(210, 20, 165, 228))
        mm.drawings:boolean('e_range', 'Draw E Range', true)
        mm.drawings:color('e_color', 'E Color', graphics.argb(255, 255, 0, 0))
        if viegoCompatibility == false then
            mm.drawings:boolean('r_range', 'Draw R Range', true)
            mm.drawings:color('r_color', 'R Color', graphics.argb(255, 60, 255, 0))

        end

        return mm
    end

    function MissFortune:IsTransformed()
        if viegoCompatibility == false then return true end
        if player:findBuff("viegopassivetransform") then
            if player.skinHash == 0x1e5a725 then
                return true
            end
        end
        return false
    end

    function MissFortune:OnTick()
        Time = os.clock()

        if player.isDead or player.teleportType ~= TeleportType.Null then return end


        if not self:IsTransformed() then return end

        self:Combo()
        self:Harass()
    end

    function MissFortune:Combo()
        if orb.isComboActive == false then return end

        self:CastQ("combo")
        --self:CastQExtended("combo")
        self:CastE("combo")
    end

    function MissFortune:Harass()
        if orb.harassKeyDown == false then return end

        self:CastQ("harass")
        --self:CastQExtended("harass")
        self:CastE("harass")
    end

    function MissFortune:CastE(mode)
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end

        if self.MissFortuneMenu[mode].e_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.E] < 0.25 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            local prediction = pred.getPrediction(enemy, self.eData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.MissFortuneMenu[mode].e_hitchance:get()] then
                player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                self.castTime[SpellSlot.E] = os.clock()
                break
            end

            ::continue::
        end
    end

    function MissFortune:CastQ(mode)
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end

        if self.MissFortuneMenu[mode].q_use:get() == false then return end
        if self.MissFortuneMenu[mode].q_use_extended:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.25 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            if player:isInAttackRange(enemy) then
                player:castSpell(SpellSlot.Q, enemy, false, false)
                self.castTime[SpellSlot.Q] = os.clock()
                break
            end


            ::continue::
        end
    end

    function MissFortune:OnOrbAfterAttack()

        if not self:IsTransformed() then return end

        if orb.isComboActive ~= true then return end
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end
        if self.MissFortuneMenu.combo.w_use:get() == false then return end

        player:castSpell(SpellSlot.W, false, false)
    end

    function MissFortune:OnBuff(sender, buff, gain)

        if not self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end

        if not buff then return end

        if buff.name == "missfortunebulletsound" then
            if gain then
                if self.MissFortuneMenu.misc.r_disable_evade:get() then evade.setEnabled(false) end
                if self.MissFortuneMenu.misc.r_disable_orbwalker:get() then orb.setPause(10) end
            else
                if self.MissFortuneMenu.misc.r_disable_evade:get() then evade.setEnabled(true) end
                if self.MissFortuneMenu.misc.r_disable_orbwalker:get() then orb.setPause(0) end
            end
        end
    end

    function MissFortune:OnDraw()

        if not self:IsTransformed() then return end

        if self.MissFortuneMenu.drawings.e_range:get() then
            graphics.drawCircle(player.pos, self.eData.range, 1, self.MissFortuneMenu.drawings.e_color:get())
        end
        if viegoCompatibility == false then
            if self.MissFortuneMenu.drawings.r_range:get() then
                graphics.drawCircle(player.pos, 1450, 1, self.MissFortuneMenu.drawings.r_color:get())

            end
        end
    end

    function MissFortune:OnCastSpell(sender, spellCastInfo)

        if not self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end
        self.castTime[spellCastInfo.slot] = os.clock()
        self:DebugPrint("Casting spell: " .. spellCastInfo.name)
    end

    print("[Turbo Scripts - MissFortune] initializing")
    MissFortune:__init()

end

function MissFortune.Unload()
    menu.delete('turbo_MissFortune')
end

return MissFortune
