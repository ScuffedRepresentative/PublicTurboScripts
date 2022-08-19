local PredExtentions = require "predExtentions"

local Camille = {}

function Camille.Load(viegoCompatibility)

    viegoCompatibility = viegoCompatibility or false

    print("[Turbo Scripts - Camille] Loaded")

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingEnd }

    function Camille:DebugPrint(...)
        print("[Turbo Scripts - Camille] " .. ...)
    end

    function Camille:__init()

        self.castTime = { [0] = 0, 0, 0, 0 }

        self.qData = {
            type = spellType.self,
        }
        -- q1 hash: 1846733
        -- q2 hash: 727476333


        self.wData = {
            delay = 0.25, -- if not defined -> default = 0
            type = spellType.linear, -- if not defined -> default = spellType.linear
            range = 650, -- if not defined -> default = math.huge
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
            boundingRadiusMod = false
        }
        self.e1Data = {
            delay = 0,
            type = spellType.linear,
            rangeType = SpellRangeType.Edge,
            range = 950,
            speed = 1050, -- probably 1050
            radius = 100,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.None,
                tower = SpellCollisionType.None,
            }
        }
        self.e2Data = {
            delay = 0,
            type = spellType.linear,
            rangeType = SpellRangeType.Edge,
            range = 950,
            speed = 1050,
            radius = 100,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.None,
                tower = SpellCollisionType.None,
            }
        }
        -- e1 = 3961261649
        -- e2 = 3391392961

        self.rData = {
            rangeType = SpellRangeType.Center,
            range = 475,
            boundingRadiusMod = false
        }

        self.CamilleMenu = self:CreateMenu()

        self.viegoCompatibilityMode = false

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Camille:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) Camille:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) Camille:OnCastSpell(...) end)
        table.insert(self.callbacks[1], cb.orbAfterAttack)
        table.insert(self.callbacks[2], function(...) Camille:OnOrbAfterAttack(...) end)
        table.insert(self.callbacks[1], cb.buff)
        table.insert(self.callbacks[2], function(...) Camille:OnBuff(...) end)

        print("[Turbo Scripts - Camille] initialized")
    end

    function Camille:CreateMenu()
        local mm = menu.create('turbo_Camille', 'Turbo Camille')

        mm:spacer("turbotech", "TurboTech BETA")

        mm:header('combo', 'Combo Mode')
        mm.combo:spacer("combo_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)

        mm.combo:spacer("combo_menu_spacer3", "E")
        mm.combo:boolean('e_use', 'Use E', true):tooltip("Will auto use e2, must hit wall manually with e1")
        mm.combo:list('e_hitchance', 'E Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 1)
        mm.combo:header('advanced', 'Advanced')
        mm.combo.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for casting less")
        mm.combo.advanced:slider('e_time_modifier', "Max range modifier", 75, 0, 100, 1) --:tooltip("Max Projectile Time Before Forcing VeryHigh Hitchance (miliseconds)")


        mm:header('misc', 'Misc')

        if viegoCompatibility == false then
            mm.misc:spacer("misc_space1", "R")
            mm.misc:keybind('r_use_manuel', 'Semi Manuel R', 0x52, false, false)

        end
        --mm.misc:keybind('assassin_combo', 'Engage combo', 0x06, false, false) -- todo - also make w pop right before we hit them so it does more max hp dmg

        mm.misc:spacer("combo_menu_spacer2", "W")
        mm.misc:keybind('w_use_manuel', 'Semi Manuel W', 0x05, false, false)
        --mm.misc:boolean('w_magnet', 'Magnet', true)  -- todo


        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('w_range', 'Draw W Range', true)
        mm.drawings:color('w_color', 'W Color', graphics.argb(100, 20, 165, 228))
        mm.drawings:boolean('e_range', 'Draw E Range', true)
        mm.drawings:color('e_color', 'E Color', graphics.argb(255, 255, 255, 0))

        if viegoCompatibility == false then
            mm.drawings:boolean('r_range', 'Draw R Range', true)
            mm.drawings:color('r_color', 'R Color', graphics.argb(255, 255, 0, 0))

        end

        return mm
    end

    function Camille:IsTransformed()
        if viegoCompatibility == false then return true end
        if player:findBuff("viegopassivetransform") then
            if player.skinHash == 0x6ff5cbeb then
                return true
            end
        end
        return false
    end

    function Camille:Q1Dmg(target)
        local spell = player:spellSlot(SpellSlot.Q)
        if spell.level == 0 then return 0 end
        local damage = player.totalAttackDamage + spell.level * 0.05 + 0.15 * player.totalAttackDamage
        return damageLib.physical(player, target, damage)
    end

    function Camille:Q2Dmg(target)
        if self.q2Buff then
            local spell = player:spellSlot(SpellSlot.Q)
            if spell.level == 0 then return 0 end
            local damage = player.totalAttackDamage + spell.level * 0.05 + 0.15 * player.totalAttackDamage
            return damageLib.physical(player, target, damage)
        else
            local spell = player:spellSlot(SpellSlot.Q)
            if spell.level == 0 then return 0 end
            local damage = player.totalAttackDamage + spell.level * 0.1 + 0.30 * player.totalAttackDamage
            local physdamage = 0
            if player.level >= 16 then
                physdamage = damage * (1-(0.36+0.04*player.level))
            end
            local trueDamage = damage - physdamage

            local dmgLibDmg = damageLib.physical(player, target, physdamage)

            return dmgLibDmg + trueDamage
        end
    end

    function Camille:OnTick()
        Time = os.clock()

        if player.isDead or player.teleportType ~= TeleportType.Null then return end

        if not self:IsTransformed() then return end

        self:ManuelR()
        self:ManuelW()

        self:Combo()
        self:Harass()
    end

    function Camille:Combo()
        if orb.isComboActive == false then return end

        self:CastE()
        self:BeforeQ()

    end

    function Camille:Harass()
        if orb.harassKeyDown == false then return end

        self:BeforeQ()


    end

    function Camille:BeforeQ()
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end
        if self.CamilleMenu.combo.q_use:get() == false then return end

        if orb.canAttack == false then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.10 then return end

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius

            if player:spellSlot(SpellSlot.Q).hash ~= 1846733 then range = range + 50 end

            if enemy:isValidTarget(range, true, player.pos) == false then goto continue end

            if enemy.isInvulnerable then goto continue end


            local targetHP = enemy.health + enemy.allShield + enemy.characterIntermediate.hpRegenRate * 3 -- get target health with some leeway

            if player:spellSlot(SpellSlot.Q).hash == 1846733 then
                if targetHP <= self:Q2Dmg(enemy) then  -- if we can kill them
                    player:castSpell(SpellSlot.Q, false, false)
                    self.castTime[SpellSlot.Q] = os.clock()
                    break
                end
            else
                if targetHP <= self:Q1Dmg(enemy) then  -- if we can kill them
                    player:castSpell(SpellSlot.Q, false, false)
                    self.castTime[SpellSlot.Q] = os.clock()
                    break
                end
            end

            ::continue::
        end
    end

    function Camille:CastE()
        if player:spellSlot(SpellSlot.E).state ~= 0 then return end

        if self.CamilleMenu.combo.e_use:get() == false then return end

        if player:hasBuffOfType(BuffType.Grounded) then return end
        if player:hasBuffOfType(BuffType.Snare) then return end

        if Time - self.castTime[SpellSlot.E] < 0.1 then return end

        if player:spellSlot(SpellSlot.E).hash ~= 3391392961 then return end
        if self.e1Buff then return end

        self.e2Data.speed = 1050 + player.characterIntermediate.moveSpeed

        for _, enemy in pairs(ts.getTargets()) do
            if
            ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            local prediction = pred.getPrediction(enemy, self.e2Data)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.CamilleMenu.combo.e_hitchance:get()] then
                if player.pos:distance(enemy.pos) + PredExtentions:GetMissileTime(prediction.castPosition, self.e2Data) * enemy.characterIntermediate.moveSpeed * (self.CamilleMenu.combo.advanced.e_time_modifier:get()/100) < self.e2Data.range then -- if the missile is going to take over X amount of time to reach it's target force it to atleast use very high hitchance, else use the hitchance from menu
                    self:DebugPrint("Cast E with hitchance QUICK " .. prediction.hitChance)
                    player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                    self.castTime[SpellSlot.E] = os.clock()
                    break
                elseif prediction.hitChance >= HitChance.High then
                    self:DebugPrint("Cast E with hitchance LONG " .. prediction.hitChance)
                    player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                    self.castTime[SpellSlot.E] = os.clock()
                    break
                end
            end

            ::continue::
        end
    end

    function Camille:ManuelW()

        if(viegoCompatibility) then return end

        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.CamilleMenu.misc.w_use_manuel:get() == false then return end

        if Time - self.castTime[SpellSlot.W] < 0.25 then return end

        for _, enemy in pairs(ts.getTargets()) do
            if ts.selected and enemy.handle ~= ts.selected.handle and ts.selected.isDead == false then goto continue end

            if enemy:isValidTarget(self.wData.range, true, player.pos) then

                if enemy.path.isDashing then goto continue end

                if player.pos:distanceSqr(enemy.pos) < 350^2 then goto continue end

                player:castSpell(SpellSlot.W, enemy, false, false)
                self.castTime[SpellSlot.W] = os.clock()
                break
            end
            ::continue::
        end
    end

    function Camille:ManuelR()

        if(viegoCompatibility) then return end

        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if self.CamilleMenu.misc.r_use_manuel:get() == false then return end

        if Time - self.castTime[SpellSlot.R] < 0.25 then return end

        if player:hasBuffOfType(BuffType.Grounded) then return end

        for _, enemy in pairs(ts.getTargets()) do
            if ts.selected and enemy.handle ~= ts.selected.handle and ts.selected.isDead == false then goto continue end

            if not enemy:isValidTarget(475, true, player.pos) then goto continue end

            if enemy:hasBuffOfType(BuffType.SpellImmunity) == false then

                player:castSpell(SpellSlot.R, enemy, false, false)
                self.castTime[SpellSlot.R] = os.clock()
                break
            end
            ::continue::
        end
    end

    function Camille:OnOrbAfterAttack()

        if not self:IsTransformed() then return end

        if orb.isComboActive ~= true then return end
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end
        if self.CamilleMenu.combo.q_use:get() == false then return end

        if self.q2Buff then return end

        for _, enemy in pairs(ts.getTargets()) do

            local range = player.boundingRadius + player.characterIntermediate.attackRange + enemy.boundingRadius


            if(player:spellSlot(SpellSlot.Q).hash == 1846733) then
                range = range + 50
            end

            if enemy:isValidTarget(range, true, player.pos) then

                self:DebugPrint("Attempting aa reset on: " .. enemy.name)
                player:castSpell(SpellSlot.Q, false, false)
                self.castTime[SpellSlot.Q] = os.clock()

                break
            end
            ::continue::
        end
    end

    function Camille:OnCastSpell(sender, spellCastInfo)
        if not self:IsTransformed() then return end
        if sender.handle ~= player.handle then return end
        self.castTime[spellCastInfo.slot] = os.clock()
        self:DebugPrint("Casting spell: " .. spellCastInfo.name .. " " .. spellCastInfo.hash)

        if spellCastInfo.slot == SpellSlot.Q then
            self:DebugPrint("Orb Reset")
            orb.reset()
        end

        if spellCastInfo.name == "CamilleE" then
            orb.setPause(10)
        elseif spellCastInfo.name == "CamilleW" then
            orb.setAttackPause(10)
        end

    end

    function Camille:OnBuff(sender, buff, gain)
        if not self:IsTransformed() then return end
        if sender.handle ~= player.handle then return end

        if not buff then return end

        if buff.name == "camilleqprimingstart" then
            if gain then
                self.q2Buff = buff
            else
                self.q2Buff = nil
            end
        elseif buff.name == "camilleedash1" then
            if gain then
                self.e1Buff = buff
            else
                self.e1Buff = nilS
            end
        elseif buff.name == "camilleedashtoggle" then
            if gain then
                self.camilleedashtoggle = buff
            else
                self.camilleedashtoggle = nil
                orb.setPause(0)
            end
        elseif buff.name == "camillewconeslashcharge" then
            if gain == false and self.camilleedashtoggle == nil then
                orb.setAttackPause(0)
            end
        end
    end


    function Camille:OnDraw()
        if not self:IsTransformed() then return end
        if self.CamilleMenu.drawings.w_range:get() then
            graphics.drawCircle(player.pos, 650, 1, self.CamilleMenu.drawings.w_color:get())
        end

        if self.CamilleMenu.drawings.e_range:get() then
            if player:spellSlot(SpellSlot.E).hash == 3391392961 then
                graphics.drawCircle(player.pos, self.e2Data.range, 1, self.CamilleMenu.drawings.e_color:get())
            else
                graphics.drawCircle(player.pos, 1000, 1, self.CamilleMenu.drawings.e_color:get())
            end
        end

        if self.CamilleMenu.drawings.r_range:get() then
            graphics.drawCircle(player.pos, 475, 1,
                    self.CamilleMenu.drawings.r_color:get())
        end

    end

    print("[Turbo Scripts - Camille] initializing")
    Camille:__init()

end

function Camille.Unload()
    menu.delete('turbo_Camille')
end

return Camille
