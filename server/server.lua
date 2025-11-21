local ESX = exports['es_extended']:getSharedObject()
local T = require("locales." .. Config.Language)

-- Variables serveur
local activeMissions = {}
local lastGlobalGoFast = 0
local playerCooldowns = {}

print('^2========================================^7')
print('^2[GOFAST]^7 ' .. T.welcome)
print('^2[GOFAST]^7 Version: 1.0.0')
print('^2[GOFAST]^7 Drogues configurées: ' .. #Config.Drugs)
print('^2========================================^7')

-- =====================================================
-- HOOK OX_INVENTORY POUR LE SAC GO-FAST
-- =====================================================

local hookId = exports.ox_inventory:registerHook('createItem', function(payload)
    if payload.item.name == Config.GofastBagItem then
        local metadata = payload.metadata or {}
        metadata.label = 'Sac Go-Fast'
        metadata.description = string.format(
            "Drogue: %s\nQuantité: %d\nS/N: %d",
            metadata.drugLabel or T.unknown_drug,
            metadata.amount or 0,
            metadata.sn or 0
        )
        return metadata
    end
end, {
    print = false,
    itemFilter = {
        [Config.GofastBagItem] = true
    }
})

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

function Debug(msg)
    if Config.Debug then
        print('^3[DEBUG]^7 ' .. msg)
    end
end

function GetDrugByName(drugName)
    for _, drug in ipairs(Config.Drugs) do
        if drug.name == drugName then
            return drug
        end
    end
    return nil
end

function CleanupMissions()
    local currentTime = os.time()
    for playerId, mission in pairs(activeMissions) do
        if currentTime - mission.startTime > 3600 then -- 1 heure de timeout
            Debug('Nettoyage mission abandonnée: ' .. playerId)
            activeMissions[playerId] = nil
        end
    end
end

-- =====================================================
-- CALLBACKS ESX
-- =====================================================

-- Callback pour récupérer la liste des drogues disponibles
ESX.RegisterServerCallback('gofast:getDrugList', function(source, cb)
    local availableDrugs = {}

    for _, drug in ipairs(Config.Drugs) do
        local count = exports.ox_inventory:GetItem(source, drug.name, nil, true)

        if count and count >= drug.minAmount then
            local drugInfo = {
                name = drug.name,
                label = drug.label,
                description = drug.description,
                rewardPerUnit = drug.rewardPerUnit,
                minAmount = drug.minAmount,
                maxAmount = drug.maxAmount,
                playerAmount = count,
                icon = drug.icon,
                color = drug.color
            }
            table.insert(availableDrugs, drugInfo)
        end
    end

    Debug('Liste de drogues pour ' .. source .. ': ' .. #availableDrugs .. ' disponibles')
    cb(availableDrugs)
end)

-- Callback pour vérifier le nombre de policiers
ESX.RegisterServerCallback('gofast:getMinPolice', function(source, cb)
    local xPlayers = ESX.GetPlayers()
    local policeCount = 0

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.PoliceJobName then
            policeCount = policeCount + 1
        end
    end

    Debug('Nombre de policiers en ligne: ' .. policeCount)
    cb(policeCount)
end)

-- =====================================================
-- EVENTS
-- =====================================================

-- Event pour démarrer une mission
RegisterNetEvent('gofast:startMission')
AddEventHandler('gofast:startMission', function(drugName, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        return
    end

    local currentTime = os.time()

    -- Vérifier cooldown global
    if currentTime - lastGlobalGoFast < Config.GlobalCooldown then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.come_back_later_global,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Vérifier cooldown joueur
    if playerCooldowns[_source] and currentTime - playerCooldowns[_source] < Config.PlayerCooldown then
        local timeLeft = Config.PlayerCooldown - (currentTime - playerCooldowns[_source])
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = string.format(T.come_back_later_player .. ' (%d min)', math.ceil(timeLeft / 60)),
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Vérifier si déjà en mission
    if activeMissions[_source] then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.mission_in_progress,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Récupérer les infos de la drogue
    local drugType = GetDrugByName(drugName)
    if not drugType then
        Debug('Drogue invalide: ' .. tostring(drugName))
        return
    end

    -- Vérifier que le joueur a la drogue
    local count = exports.ox_inventory:GetItem(_source, drugType.name, nil, true)
    if not count or count < amount then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.not_enough_drugs,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Vérifier les limites
    if amount < drugType.minAmount or amount > drugType.maxAmount then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = string.format(T.invalid_quantity_range, drugType.minAmount, drugType.maxAmount),
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Retirer la drogue
    local removed = exports.ox_inventory:RemoveItem(_source, drugType.name, amount)
    if not removed then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.drug_removal_error,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Créer le sac go-fast
    local totalReward = amount * drugType.rewardPerUnit
    local plate = Config.Vehicle.platePrefix .. math.random(1000, 9999)
    local sn = math.random(100000, 999999)

    local metadata = {
        drugType = drugType.name,
        drugLabel = drugType.label,
        amount = amount,
        sn = sn
    }

    local success = exports.ox_inventory:AddItem(_source, Config.GofastBagItem, 1, metadata)

    if success then
        -- Enregistrer la mission
        activeMissions[_source] = {
            drugType = drugType,
            amount = amount,
            reward = totalReward,
            startTime = os.time(),
            plate = plate,
            sn = sn
        }

        Debug(string.format('Mission démarrée: %s | Drogue: %s x%d | Récompense: $%d',
            xPlayer.getName(), drugType.label, amount, totalReward))

        -- Envoyer au client
        TriggerClientEvent('gofast:startMission', _source, drugType, amount, plate)

        -- Mettre à jour les cooldowns
        lastGlobalGoFast = currentTime
        playerCooldowns[_source] = currentTime
    else
        -- Rembourser si échec
        exports.ox_inventory:AddItem(_source, drugType.name, amount)
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.gofast_bag_creation_error,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
    end
end)

-- Event pour compléter une livraison
RegisterNetEvent('gofast:completeDelivery')
AddEventHandler('gofast:completeDelivery', function(drugName, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        return
    end

    -- Vérifier mission active
    if not activeMissions[_source] then
        Debug('Aucune mission active pour: ' .. xPlayer.getName())
        TriggerClientEvent('gofast:missionCancelled', _source, T.mission_completion_error)
        return
    end

    local mission = activeMissions[_source]

    -- Vérifier correspondance
    if mission.drugType.name ~= drugName or mission.amount ~= amount then
        Debug('Données de mission non correspondantes pour: ' .. xPlayer.getName())
        TriggerClientEvent('gofast:missionCancelled', _source, T.mission_completion_error)
        activeMissions[_source] = nil
        return
    end

    -- Récupérer l'inventaire et chercher le sac
    local inventory = exports.ox_inventory:GetInventory(_source)
    local gofast_bag = nil

    if inventory and inventory.items then
        for _, item in pairs(inventory.items) do
            if item.name == Config.GofastBagItem then
                gofast_bag = item
                break
            end
        end
    end

    -- Vérifier le sac
    if not gofast_bag or not gofast_bag.metadata then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.gofast_bag_not_found,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Vérifier métadata du sac
    if gofast_bag.metadata.drugType ~= drugName or gofast_bag.metadata.amount ~= amount then
        Debug('Métadata du sac invalide pour: ' .. xPlayer.getName())
        TriggerClientEvent('gofast:missionCancelled', _source, T.mission_completion_error)
        activeMissions[_source] = nil
        return
    end

    -- Retirer le sac
    local removed = exports.ox_inventory:RemoveItem(_source, Config.GofastBagItem, 1)
    if not removed then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = T.gofast_title,
            description = T.gofast_bag_removal_error,
            type = 'error',
            duration = 5000,
            position = Config.NotifyPosition
        })
        return
    end

    -- Donner la récompense
    local reward = mission.reward
    exports.ox_inventory:AddItem(_source, Config.RewardType, reward)

    -- Log
    local deliveryTime = os.time() - mission.startTime
    local logMessage = string.format(
        '%s a livré %s x%d pour $%d (temps: %ds)',
        xPlayer.getName(),
        mission.drugType.label,
        amount,
        reward,
        deliveryTime
    )
    print('^2[GOFAST]^7 ' .. logMessage)

    -- Notifier le joueur
    TriggerClientEvent('gofast:deliveryCompleted', _source, reward)

    -- Supprimer la mission
    activeMissions[_source] = nil

    Debug('Mission complétée pour: ' .. xPlayer.getName())
end)

-- Event pour alerter la police
RegisterNetEvent('gofast:alertPolice')
AddEventHandler('gofast:alertPolice', function()
    local _source = source
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.PoliceJobName then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = T.police_alert_title,
                description = T.police_alert_description,
                type = 'inform',
                duration = 5000,
                position = Config.NotifyPosition
            })
        end
    end

    Debug('Alerte police déclenchée par: ' .. _source)
end)

-- Event pour mettre à jour le blip police
RegisterNetEvent('gofast:updatePoliceBlip')
AddEventHandler('gofast:updatePoliceBlip', function(coords)
    local _source = source
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.PoliceJobName then
            TriggerClientEvent('gofast:showPoliceBlip', xPlayer.source, coords)
        end
    end
end)

-- Event pour signal perdu
RegisterNetEvent('gofast:signalLost')
AddEventHandler('gofast:signalLost', function()
    local _source = source
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.PoliceJobName then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = T.police_alert_title,
                description = T.police_signal_lost,
                type = 'inform',
                duration = 5000,
                position = Config.NotifyPosition
            })
        end
    end

    Debug('Signal perdu pour: ' .. _source)
end)

-- =====================================================
-- COMMANDES ADMIN
-- =====================================================

RegisterCommand('gofastmissions', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        return
    end

    -- Vérifier permissions
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        print('^3=== Missions Gofast Actives ===^7')
        local count = 0

        for playerId, mission in pairs(activeMissions) do
            count = count + 1
            local player = ESX.GetPlayerFromId(playerId)
            if player then
                print(string.format(
                    '^2[%d]^7 %s - %s x%d - $%d - %ds',
                    playerId,
                    player.getName(),
                    mission.drugType.label,
                    mission.amount,
                    mission.reward,
                    os.time() - mission.startTime
                ))
            end
        end

        if count == 0 then
            print('^1Aucune mission active^7')
        end

        print('^3================================^7')

        TriggerClientEvent('chat:addMessage', source, {
            args = {'Gofast', count .. ' mission(s) active(s) - Voir console serveur'}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Erreur', 'Vous n\'avez pas la permission'}
        })
    end
end, false)

-- =====================================================
-- EVENTS SYSTÈME
-- =====================================================

-- Nettoyer quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local _source = source

    if activeMissions[_source] then
        Debug('Nettoyage mission du joueur déconnecté: ' .. _source)
        activeMissions[_source] = nil
    end

    if playerCooldowns[_source] then
        playerCooldowns[_source] = nil
    end
end)

-- Nettoyer les missions abandonnées toutes les 15 minutes
CreateThread(function()
    while true do
        Wait(900000) -- 15 minutes
        CleanupMissions()
    end
end)
