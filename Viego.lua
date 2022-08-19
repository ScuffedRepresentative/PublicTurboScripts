local PredExtentions = require "predExtentions"

local Viego = {}

function Viego.Load()

    print("[Turbo Scripts - Viego] Loaded")

    local HitchanceMenu = { [0] = HitChance.Low, HitChance.Medium, HitChance.High, HitChance.VeryHigh, HitChance.DashingMidAir }

    function Viego:DebugPrint(...)
        print("[Turbo Scripts - Viego] " .. ...)
    end

    function Viego:__init()

        self.castTime = { [0] = 0, 0, 0, 0 }
        self.passiveTime = 0

        self.qData = {
            delay = (player.attackCastDelay/100)*140,
            type = spellType.linear,
            rangeType = SpellRangeType.Edge,
            range = 600,
            radius = 62
        }
        self.wData = {
            delay = 0,
            type = spellType.linear,
            range = 900,
            speed = 1300,
            radius = 60,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.Hard,
                tower = SpellCollisionType.None,

                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }
        self.rData = {
            delay = 0.5,
            type = spellType.circular, -- if not defined -> default = spellType.linear
            range = 500, -- if not defined -> default = math.huge
            radius = 300, -- if not defined -> math.huge
            boundingRadiusMod = false
        }

        self.ViegoMenu = self:CreateMenu()

        self.viegoCompatibilityMode = false

        self.callbacks = {{},{}}

        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Viego:OnTick(...) end)
        table.insert(self.callbacks[1], cb.drawWorld)
        table.insert(self.callbacks[2], function(...) Viego:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Viego:OnDrawGUI(...) end)
        table.insert(self.callbacks[1], cb.buff)
        table.insert(self.callbacks[2], function(...) Viego:OnBuff(...) end)
        table.insert(self.callbacks[1], cb.processSpell)
        table.insert(self.callbacks[2], function(...) Viego:OnCastSpell(...) end)
        table.insert(self.callbacks[1], cb.playAnimation)
        table.insert(self.callbacks[2], function(...) Viego:OnPlayAnimation(...) end)

        print("[Turbo Scripts - Viego] initialized")
    end

    function Viego:CreateMenu()
        local mm = menu.create('turbo_Viego', 'Turbo Viego')

        mm:spacer("turbotech", "TurboTech BETA")

        mm:header('combo', 'Combo Mode')
        mm.combo:spacer("combo_menu_spacer1", "Q")
        mm.combo:boolean('q_use', 'Use Q', true)
        mm.combo:list('q_hitchance', 'Q Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        mm.combo:spacer("combo_menu_spacer2", "W")
        mm.combo:boolean('w_use', 'Use W', true)
        mm.combo:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)
        mm.combo:slider('w_overcharge', "Overcharge by X percent", 20, 0, 100, 1)
        mm.combo:slider('w_startcharge', "Start charing at X percent of range", 80, 0, 100, 1)
        mm.combo:header('advanced', 'Advanced')
        mm.combo.advanced:spacer("menu_spacer420", "decrease for casting more at max range, increase for casting less")
        mm.combo.advanced:slider('w_time_modifier', "Max range modifier", 75, 0, 100, 1)

        mm.combo:spacer("combo_menu_spacer3", "R")
        mm.combo:boolean('r_use', 'Killsteal R', true)
        mm.combo:list('r_hitchance', 'R Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)
        mm.combo:header('r_blacklist', 'R in Transformation Blacklist')
        mm.combo.r_blacklist:boolean('r_transformed_use', "Don't use if transformed", false)
        mm.combo.r_blacklist:spacer("blacklist_menu_spacer1", "BLACKLIST")
        for _, hero in pairs(objManager.heroes.enemies.list) do
            if hero then
                mm.combo.r_blacklist:boolean(hero.skinHash .. 'r_transformed_use', "Don't use R if " .. hero.skinName, false)
            end
        end


        mm:header('harass', 'Harass Mode')
        mm.harass:spacer("harass_menu_spacer1", "Q")
        mm.harass:boolean('q_use', 'Use Q', true)
        mm.harass:list('q_hitchance', 'Q Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)


        mm:header('clear', 'Clear Mode')
        mm.clear:spacer("clear_menu_spacer1", "Q")
        mm.clear:boolean('q_use', 'Use Q', true)
        mm.clear:list('q_hitchance', 'Q Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)

        mm.clear:spacer("clear_menu_spacer2", "W")
        mm.clear:boolean('w_use', 'Use W', true)
        mm.clear:list('w_hitchance', 'W Hitchance', { 'Low', 'Medium', 'High', 'Very High', 'Undodgeable' }, 2)
        mm.clear:slider('w_overcharge', "Overcharge by X percent", 20, 0, 100, 1)

        mm:header('soulsmanager', 'Soul Manager')
        mm.soulsmanager:boolean('pickup', 'Auto Transform', true)
        mm.soulsmanager:header('blacklist', 'Auto Transform Blacklist')
        mm.soulsmanager.blacklist:spacer("blacklist_menu_spacer1", "BLACKLIST")
        for _, hero in pairs(objManager.heroes.enemies.list) do
            if hero then
                mm.soulsmanager.blacklist:boolean(hero.skinName .. 'soulsmanager_blacklsit', "Don't auto pickup: " .. hero.skinName, false)
            end
        end

        mm.harass:boolean('discard_ult', 'Auto R on passive end', true):tooltip("this won't waste r as r will go on cooldown when passive ends anyways")


        mm:header('drawings', 'Drawings')
        mm.drawings:boolean('q_range', 'Draw Q Range', true)
        mm.drawings:color('q_color', 'Q Color', graphics.argb(210, 20, 165, 228))
        mm.drawings:boolean('w_range', 'Draw E Range', true)
        mm.drawings:color('w_color', 'E Color', graphics.argb(255, 255, 0, 0))
        mm.drawings:boolean('r_range', 'Draw R Range', true)
        mm.drawings:color('r_color', 'R Color', graphics.argb(255, 60, 255, 0))
        mm.drawings:boolean('r_dmg', 'Draw R Damage', true)
        mm.drawings:color('r_dmg_color', 'R Damage Color', graphics.argb(255, 60, 255, 0))

        return mm
    end

    function Viego:IsTransformed()
        if player:findBuff("viegopassivetransform") and player.skinHash ~= 0x9662a07a then
            return true
        end
        return false
    end

    function Viego:RDmg(target)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end


        if self:IsTransformed() then
            local percentageDamage = 8 + 4 * spell.level + (math.floor(self.LoggedAD / 100) * 3)

            local hpDamage = ((target.maxHealth - target.health) / 100) * percentageDamage

            local aoeDamage = math.floor(self.LoggedAD * 1.2) + (math.floor(self.LoggedAD * 1.2) * self.LoggedCrit)

            local damage = hpDamage + aoeDamage

            return damageLib.magical(player, target, damage)
        else
            local percentageDamage = 8 + 4 * spell.level + (math.floor(player.totalAttackDamage / 100) * 3)

            local hpDamage = ((target.maxHealth - target.health) / 100) * percentageDamage

            local aoeDamage = math.floor(player.totalAttackDamage * 1.2) + (math.floor(player.totalAttackDamage * 1.2) * player.characterIntermediate.crit)

            local damage = hpDamage + aoeDamage

            return damageLib.magical(player, target, damage)
        end
    end


    function Viego:OnTick()
        Time = os.clock()

        if(self.isChargingWBuff) then
            if(self.wData.range < 900) then
                self.wData.range = (game.time - self.isChargingWBuff.startTime) * 400 + 500
            else
                self.wData.range = 900
            end
        end

        if player.isDead or player.teleportType ~= TeleportType.Null then return end

        self:SoulTaker()
        self:SoulDiscard()

        self:Combo()

        if self:IsTransformed() then return end
        self:Harass()
        self:Clear()
    end

    function Viego:Combo()
        if orb.isComboActive == false then return end

        self:CastR()

        if self:IsTransformed() then return end
        self:CastQ("combo")
        self:CastW()
    end

    function Viego:Harass()
        if orb.harassKeyDown == false then return end

        self:CastQ("harass")
    end

    function Viego:Clear()
        if orb.laneClearKeyDown == false then return end
        self:CastQClear()
        self:CastWClear()
    end

    function Viego:CastQ(mode)
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end

        if self.ViegoMenu[mode].q_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.15 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end -- try the next target

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            if player:isInAttackRange(enemy) and enemy:findBuff("viegoqmark") then goto continue end

            local prediction = pred.getPrediction(enemy, self.qData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.ViegoMenu[mode].q_hitchance:get()] then
                self:DebugPrint("Cast Q with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                self.castTime[SpellSlot.Q] = os.clock()

                break
            end

            ::continue::
        end
    end


    function Viego:CastW()
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.ViegoMenu.combo.w_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.W] < 0.15 then return end


        for _, enemy in pairs(ts.getTargets()) do
            if ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end -- try the next target


            if self.isChargingWBuff == nil then

                if not enemy:isValidTarget(self.wData.range / 100 * self.ViegoMenu.combo.w_startcharge:get(), true, player.pos) then goto continue end

                if player:isInAttackRange(enemy) and enemy:findBuff("viegoqmark") then goto continue end

                player:castSpell(SpellSlot.W, game.cursorPos)
                self.castTime[SpellSlot.W] = os.clock()
                break
            else

                if (self.wData.range ~= 900) then
                    if not enemy:isValidTarget((self.wData.range/100)*(self.ViegoMenu.combo.w_overcharge:get() + 100), true, player.pos) then goto continue end
                else
                    if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end
                end

                local prediction = pred.getPrediction(enemy, self.wData)

                if not (prediction and prediction.castPosition.isValid) then goto continue end

                if prediction.hitChance >= HitchanceMenu[self.ViegoMenu.combo.w_hitchance:get()] then
                    if player.pos:distance(enemy.pos) + PredExtentions:GetMissileTime(prediction.castPosition, self.wData) * enemy.characterIntermediate.moveSpeed * (self.ViegoMenu.combo.advanced.w_time_modifier:get()/100) < self.wData.range then
                        self:DebugPrint("Cast W with quick missiletime and hitchance " .. prediction.hitChance)
                        player:updateChargeableSpell(SpellSlot.W, prediction.castPosition, false, false)
                        self.castTime[SpellSlot.W] = os.clock()
                        break
                    elseif prediction.hitChance >= HitChance.High then
                        self:DebugPrint("Cast W with long missiletime and hitchance " .. prediction.hitChance)
                        player:updateChargeableSpell(SpellSlot.W, prediction.castPosition, false, false)
                        self.castTime[SpellSlot.W] = os.clock()
                        break
                    end
                end
            end

            ::continue::
        end
    end


    function Viego:CastQClear()
        if player:spellSlot(SpellSlot.Q).state ~= 0 then return end

        if self.ViegoMenu.clear.q_use:get() == false then return end

        if player.isWindingUp then return end
        if player.canAttack == false then return end

        if Time - self.castTime[SpellSlot.Q] < 0.15 then return end

        for _, minion in pairs(objManager.minions.list) do

            if not minion:isValidTarget(800, false, player.pos) then goto continue end

            if not minion.team == 300 then goto continue end


            if minion.isLaneMinion then goto continue end
            if minion.isWard then goto continue end
            if minion.isPlant then goto continue end
            if minion.isPet then goto continue end

            if player:isInAttackRange(minion) and minion:findBuff("viegoqmark") then goto continue end

            local prediction = pred.getPrediction(minion, self.qData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.ViegoMenu.clear.q_hitchance:get()] then
                self:DebugPrint("Cast Q on monster with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                self.castTime[SpellSlot.Q] = os.clock()

                break
            end

            ::continue::
        end
    end


    function Viego:CastWClear()
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end

        if self.ViegoMenu.combo.w_use:get() == false then return end

        if player.isWindingUp then return end

        if Time - self.castTime[SpellSlot.W] < 0.15 then return end



        for _, minion in pairs(objManager.minions.list) do

            if not minion:isValidTarget(800, false, player.pos) then goto continue end

            if not minion.team == 300 then goto continue end


            if minion.isLaneMinion then goto continue end
            if minion.isWard then goto continue end
            if minion.isPlant then goto continue end
            if minion.isPet then goto continue end

            if self.isChargingWBuff == nil then

                if not minion:isValidTarget(self.wData.range, false, player.pos) then goto continue end

                if player:isInAttackRange(minion) and minion:findBuff("viegoqmark") then goto continue end

                player:castSpell(SpellSlot.W, game.cursorPos)
                self.castTime[SpellSlot.W] = os.clock()
                break
            else

                if (self.wData.range ~= 900) then
                    if not minion:isValidTarget((self.wData.range/100)*(self.ViegoMenu.clear.w_overcharge:get() + 100), false, player.pos) then goto continue end
                else
                    if not minion:isValidTarget(math.huge, false, player.pos) then goto continue end
                end

                local prediction = pred.getPrediction(minion, self.wData)

                if not (prediction and prediction.castPosition.isValid) then goto continue end

                if prediction.hitChance >= HitchanceMenu[self.ViegoMenu.clear.w_hitchance:get()] then
                    self:DebugPrint("Cast W on monster with hitchance " .. prediction.hitChance)
                    player:updateChargeableSpell(SpellSlot.W, prediction.castPosition, false, false)
                    self.castTime[SpellSlot.W] = os.clock()
                    break
                end
            end

            ::continue::
        end
    end

    function Viego:CastR()
        if player:spellSlot(SpellSlot.R).state ~= 0 then return end

        if self.ViegoMenu.combo.r_use:get() == false then return end


        if Time - self.castTime[SpellSlot.R] < 0.5 then return end

        if self:IsTransformed() then
            if self.ViegoMenu.combo.r_blacklist.r_transformed_use:get() then
                return
            else
                if(self.ViegoMenu.combo.r_blacklist[player.skinHash .. 'r_transformed_use']:get()) then
                    return
                end
            end
        end

        for _, enemy in pairs(ts.getTargets()) do
            if ts.selected and
                    enemy.handle ~= ts.selected.handle and
                    ts.selected.isDead == false
            then goto continue end -- try the next target

            if not enemy:isValidTarget(math.huge, true, player.pos) then goto continue end

            if enemy:hasBuffOfType(BuffType.SpellImmunity) then goto continue end
            if enemy:hasBuffOfType(BuffType.Invulnerability) then goto continue end


            local targetHP = enemy.health + enemy.characterIntermediate.hpRegenRate * 3 + enemy.allShield

            if targetHP >= self:RDmg(enemy) then goto continue end

            local prediction = pred.getPrediction(enemy, self.rData)

            if not (prediction and prediction.castPosition.isValid) then goto continue end

            if prediction.hitChance >= HitchanceMenu[self.ViegoMenu.combo.r_hitchance:get()] then
                self:DebugPrint("Cast R with hitchance " .. prediction.hitChance)
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                self.castTime[SpellSlot.R] = os.clock()

                break
            end

            ::continue::
        end
    end

    function Viego:OnDrawGUI()

        if player:spellSlot(SpellSlot.R).state == 0 and self.ViegoMenu.drawings.r_dmg:get() then
            for _, enemy in pairs(objManager.heroes.enemies.list) do

                if not enemy.isDead and enemy.isHealthBarVisible then
                    enemy:drawDamage(self:RDmg(enemy), self.ViegoMenu.drawings.r_dmg_color:get())
                end
            end
        end
    end

    function Viego:OnDraw()

        if self.ViegoMenu.drawings.r_range:get() then
            graphics.drawCircle(player.pos, self.rData.range, 1, self.ViegoMenu.drawings.r_color:get())
        end

        if self:IsTransformed() then return end

        if self.ViegoMenu.drawings.q_range:get() then
            graphics.drawCircle(player.pos, self.qData.range, 1, self.ViegoMenu.drawings.q_color:get())
        end
        if self.ViegoMenu.drawings.w_range:get() then
            graphics.drawCircle(player.pos, 900, 1, self.ViegoMenu.drawings.w_color:get())
        end

    end

    function Viego:OnBuff(sender, buff, gain)
        if self:IsTransformed() then return end
        if sender.handle ~= player.handle then return end

        if not buff then return end

        if buff.name == "ViegoW" then
            if gain then
                self.wData.range = 500
                self.isChargingWBuff = buff
            else
                self.isChargingWBuff = nil
                self.wData.range = 900
            end
        end
    end

    function Viego:OnCastSpell(sender, spellCastInfo)

        if self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end
        self.castTime[spellCastInfo.slot] = os.clock()
        self:DebugPrint("Casting spell: " .. spellCastInfo.name)
    end

    function Viego:OnPlayAnimation(sender, animationName)

        if self:IsTransformed() then return end

        if sender.handle ~= player.handle then return end

        if animationName == 'Passive_Attack' then
            self.LoggedAD = player.totalAttackDamage
            self.LoggedCrit = player.characterIntermediate.crit
        end
    end

    function Viego:SoulTaker()
        if player.canAttack == false then return end
        if orb.canAttack == false then return end
        if player.isTargetable == false then return end

        if Time - self.passiveTime < 0.05 then return end

        for _, minion in pairs(objManager.minions.list) do
            if minion.skinName == "ViegoSoul" and not self.isChargingWBuff then

                if self.ViegoMenu.soulsmanager.pickup:get() == false then
                    print("pickup false")
                    break
                elseif(self.ViegoMenu.soulsmanager.blacklist[minion.characterDataStack.currentData.modelName .. 'soulsmanager_blacklsit']:get()) then
                        print("heroblacklist")
                        break
                end

                if player:isInAttackRange(minion) then
                    player:attack(minion, true, true)
                    self.passiveTime = os.clock()
                    break
                else
                    break
                end
            end
        end
    end

    function Viego:SoulDiscard()
        local buff = player:findBuff("viegopassivetransform")

        if Time - self.castTime[SpellSlot.R] < 0.5 then return end

        if buff and buff.remainingTime <= 0.5 then
            player:castSpell(SpellSlot.R, game.cursorPos, false, false)
            self.castTime[SpellSlot.R] = os.clock()
        end
    end

    print("[Turbo Scripts - Viego] initializing")
    Viego:__init()
end

function Viego.Unload()
    menu.delete('turbo_Viego')
end

return Viego
