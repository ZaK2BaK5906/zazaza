local ESX = exports['es_extended']:getSharedObject()
local T = require("locales." .. Config.Language)

-- Variables serveur
local activeMissions = {}
local lastGlobalGoFast = 0
local playerCooldowns = {}

print('^2========================================^7')
print('^2[GOFAST]^7 ' .. T.welcome)
print('^2[GOFAST]^7 Version: 1.0.0')
print('^2[GOFAST]^7 Missions disponibles: ' .. #Config.Missions)
print('^2========================================^7')

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

function Debug(msg)
    if Config.Debug then
        print('^3[DEBUG]^7 ' .. msg)
    end
end

function GetMissionByName(missionName)
    for _, mission in ipairs(Config.Missions) do
        if mission.name == missionName then
            return mission
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

-- Callback pour vérifier le nombre de policiers
ESX.RegisterServerCallback('gofast:getMinPolice', function(source, cb)
    local xPlayers = ESX.GetPlayers()
    local policeCount = 0

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job then
            -- Vérifier si le job est dans la liste des jobs police
            for _, policeJob in ipairs(Config.PoliceJobName) do
                if xPlayer.job.name == policeJob then
                    policeCount = policeCount + 1
                    break
                end
            end
        end
    end

    Debug('Nombre de policiers/sheriffs en ligne: ' .. policeCount)
    cb(policeCount)
end)

-- =====================================================
-- EVENTS
-- =====================================================

-- Event pour démarrer une mission
RegisterNetEvent('gofast:startMission')
AddEventHandler('gofast:startMission', function(missionName)
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

    -- Récupérer les infos de la mission
    local missionType = GetMissionByName(missionName)
    if not missionType then
        Debug('Mission invalide: ' .. tostring(missionName))
        return
    end

    -- Créer la plaque
    local plate = Config.Vehicle.platePrefix .. math.random(1000, 9999)

    -- Calculer la récompense aléatoire entre min et max
    local reward = math.random(missionType.rewardMin, missionType.rewardMax)

    -- Enregistrer la mission
    activeMissions[_source] = {
        missionType = missionType,
        reward = reward,
        startTime = os.time(),
        plate = plate
    }

    Debug(string.format('Mission démarrée: %s | Mission: %s | Récompense: $%d',
        xPlayer.getName(), missionType.label, reward))

    -- Envoyer au client
    TriggerClientEvent('gofast:startMission', _source, missionType, plate)

    -- Mettre à jour les cooldowns
    lastGlobalGoFast = currentTime
    playerCooldowns[_source] = currentTime
end)

-- Event pour compléter une livraison
RegisterNetEvent('gofast:completeDelivery')
AddEventHandler('gofast:completeDelivery', function()
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
    local missionType = mission.missionType

    -- Donner la récompense
    local reward = mission.reward

    if Config.RewardType == 'black_money' then
        xPlayer.addAccountMoney('black_money', reward)
    else
        xPlayer.addMoney(reward)
    end

    -- Log
    local deliveryTime = os.time() - mission.startTime
    local logMessage = string.format(
        '%s a livré %s pour $%d (%s) (temps: %ds)',
        xPlayer.getName(),
        missionType.label,
        reward,
        Config.RewardType,
        deliveryTime
    )
    print('^2[GOFAST]^7 ' .. logMessage)

    -- Notifier le joueur
    TriggerClientEvent('gofast:deliveryCompleted', _source, reward)

    -- Supprimer la mission
    activeMissions[_source] = nil

    Debug('Mission complétée pour: ' .. xPlayer.getName())
end)

-- Event pour alerter la police/sheriff
RegisterNetEvent('gofast:alertPolice')
AddEventHandler('gofast:alertPolice', function()
    local _source = source
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job then
            -- Vérifier si le job est dans la liste des jobs police
            for _, policeJob in ipairs(Config.PoliceJobName) do
                if xPlayer.job.name == policeJob then
                    TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                        title = T.police_alert_title,
                        description = T.police_alert_description,
                        type = 'inform',
                        duration = 5000,
                        position = Config.NotifyPosition
                    })
                    break
                end
            end
        end
    end

    Debug('Alerte police/sheriff déclenchée par: ' .. _source)
end)

-- Event pour mettre à jour le blip police/sheriff
RegisterNetEvent('gofast:updatePoliceBlip')
AddEventHandler('gofast:updatePoliceBlip', function(coords)
    local _source = source
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and xPlayer.job then
            -- Vérifier si le job est dans la liste des jobs police
            for _, policeJob in ipairs(Config.PoliceJobName) do
                if xPlayer.job.name == policeJob then
                    TriggerClientEvent('gofast:showPoliceBlip', xPlayer.source, coords)
                    break
                end
            end
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
        if xPlayer and xPlayer.job then
            -- Vérifier si le job est dans la liste des jobs police
            for _, policeJob in ipairs(Config.PoliceJobName) do
                if xPlayer.job.name == policeJob then
                    TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                        title = T.police_alert_title,
                        description = T.police_signal_lost,
                        type = 'inform',
                        duration = 5000,
                        position = Config.NotifyPosition
                    })
                    break
                end
            end
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
                    '^2[%d]^7 %s - %s - $%d - %ds',
                    playerId,
                    player.getName(),
                    mission.missionType.label,
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
