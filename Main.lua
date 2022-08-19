local champs = {
    ['Ashe'] = require "Ashe",
    ['Blitzcrank'] = require "Blitzcrank",
    ['Camille'] = require "Camille",
    ['MissFortune'] = require "MissFortune",
    ['Viego'] = require "Viego",
    ['Lillia'] = require "Lillia",
}

local loadedChamps = {}

cb.add(cb.load, function()
            if (player.skinName ~= 'Viego') then
                local champ = champs[player.skinName]
                print("[Turbo Scripts Loading] " .. player.skinName)

                champ.Load()

                table.insert(loadedChamps, champ)

                for index, value in pairs(champ.callbacks[1]) do
                    cb.add(value, champ.callbacks[2][index])
                end
            else
                print("[Turbo Scripts Loading] Viego")

                local viegoChamp = champs['Viego']

                viegoChamp.Load()
                table.insert(loadedChamps, viegoChamp)

                for index, value in pairs(viegoChamp.callbacks[1]) do
                    cb.add(value, viegoChamp.callbacks[2][index])
                end


                for name, champModule in pairs(champs) do
                    for _, hero in pairs(objManager.heroes.enemies.list) do
                        if hero.skinName ~= 'Viego' and hero.skinName == name then
                            print("[Turbo Scripts Loading] " .. hero.skinName)

                            champModule.Load(true)

                            table.insert(loadedChamps, champModule)

                            for index, value in pairs(champModule.callbacks[1]) do
                                cb.add(value, champModule.callbacks[2][index])
                            end
                        end
                    end
                end
            end
end)

cb.add(cb.unload, function()
    for name, loadedChamp in pairs(loadedChamps) do
        print("[Turbo Scripts - Main] Unloading " .. name)

        loadedChamp.Unload()

        for index, value in pairs(loadedChamp.callbacks[1]) do
            cb.remove(value, loadedChamp.callbacks[2][index])
        end

    end
    loadedChamps = {}
end)