local ESX = exports['es_extended']:getSharedObject()
local T = require("locales." .. Config.Language)

-- Variables locales
local isOnMission = false
local currentMission = nil
local missionVehicle = nil
local deliveryBlip = nil
local vehicleBlip = nil
local ped = nil
local policeAlertActive = false
local drugProp = nil -- Prop de drogue dans le coffre

-- Variables d'optimisation
local sleep = 1000
local isNearPed = false

print(T.welcome)

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

function Debug(msg)
    if Config.Debug then
        print('^3[DEBUG]^7 ' .. msg)
    end
end

function Notify(title, description, type, duration)
    lib.notify({
        title = title,
        description = description,
        type = type or 'info',
        duration = duration or 5000,
        position = Config.NotifyPosition
    })
end

function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- =====================================================
-- SPAWN DU PNJ
-- =====================================================

function SpawnPed()
    local model = GetHashKey(Config.Ped.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    ped = CreatePed(4, model, Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z - 1.0, Config.Ped.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedDiesWhenInjured(ped, false)
    SetPedKeepTask(ped, true)

    if Config.Ped.scenario then
        TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
    end

    Debug('PNJ spawné à ' .. tostring(Config.Ped.coords))

    -- Blip
    if Config.Ped.blip.enabled then
        local blip = AddBlipForCoord(Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z)
        SetBlipSprite(blip, Config.Ped.blip.sprite)
        SetBlipColour(blip, Config.Ped.blip.color)
        SetBlipScale(blip, Config.Ped.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Ped.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Ox_target ou marker classique
    if Config.Ped.useOxTarget then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'start_gofast',
                icon = 'fas fa-car',
                label = T.start_gofast,
                distance = 1.5,
                onSelect = function()
                    CheckPoliceAndShowMenu()
                end
            }
        })
    end
end

-- =====================================================
-- VÉRIFICATION ET MENU
-- =====================================================

function CheckPoliceAndShowMenu()
    if isOnMission then
        Notify(T.gofast_title, T.mission_in_progress, 'error')
        return
    end

    ESX.TriggerServerCallback('gofast:getMinPolice', function(minPolice)
        if minPolice >= Config.MinPolice then
            CheckDrugsAndShowMenu()
        else
            Notify(T.unknown_title, T.come_back_later, 'error')
        end
    end)
end

function CheckDrugsAndShowMenu()
    -- Pas besoin de callback serveur, on affiche directement les missions
    OpenMissionMenu()
end

-- =====================================================
-- MENU OX_LIB
-- =====================================================

function OpenMissionMenu()
    Debug('Ouverture du menu des missions')

    -- Préparer les options du menu
    local menuOptions = {}

    for i, mission in ipairs(Config.Missions) do
        table.insert(menuOptions, {
            title = mission.icon .. ' ' .. mission.label,
            description = mission.description .. '\n💰 Récompense: $' .. mission.reward .. '\n🎯 Difficulté: ' .. mission.difficulty,
            icon = 'car',
            iconColor = mission.color,
            onSelect = function()
                Debug('Mission sélectionnée: ' .. mission.name)
                TriggerServerEvent('gofast:startMission', mission.name)
            end
        })
    end

    -- Enregistrer et afficher le menu
    lib.registerContext({
        id = 'gofast_menu',
        title = '🚗 ' .. T.gofast_title,
        options = menuOptions
    })

    lib.showContext('gofast_menu')
end

-- =====================================================
-- DÉMARRAGE DE MISSION
-- =====================================================

RegisterNetEvent('gofast:startMission')
AddEventHandler('gofast:startMission', function(missionType, plate)
    Debug('=== EVENT gofast:startMission REÇU ===')

    if not missionType then
        Debug('ERREUR: missionType est nil!')
        return
    end

    if not plate then
        Debug('ERREUR: plate est nil!')
        return
    end

    Debug('missionType.name: ' .. tostring(missionType.name))
    Debug('missionType.reward: ' .. tostring(missionType.reward))
    Debug('plate: ' .. tostring(plate))

    if isOnMission then
        Debug('Le joueur est déjà en mission, abandon')
        return
    end

    Debug('Mission démarrée: ' .. missionType.name .. ' - Récompense: $' .. missionType.reward)

    isOnMission = true
    currentMission = {
        missionType = missionType,
        plate = plate
    }

    Notify(T.gofast_title, T.mission_started, 'success')

    Debug('Appel de SpawnVehicle...')
    -- Spawn véhicule
    SpawnVehicle(plate)
end)

-- =====================================================
-- SPAWN PROPS DE DROGUE
-- =====================================================

function SpawnDrugProp(vehicle, propConfig)
    local propModel = GetHashKey(propConfig.model)

    RequestModel(propModel)
    local timeout = 0
    while not HasModelLoaded(propModel) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(propModel) then
        Debug('ERREUR: Impossible de charger le modèle de prop ' .. propConfig.model)
        return
    end

    -- Créer le prop
    drugProp = CreateObject(propModel, 0.0, 0.0, 0.0, false, false, false)

    -- Attacher le prop au coffre du véhicule
    AttachEntityToEntity(
        drugProp,
        vehicle,
        GetEntityBoneIndexByName(vehicle, 'boot'), -- Os du coffre
        propConfig.offset.x,
        propConfig.offset.y,
        propConfig.offset.z,
        propConfig.rotation.x,
        propConfig.rotation.y,
        propConfig.rotation.z,
        false,
        false,
        false,
        false,
        2,
        true
    )

    SetModelAsNoLongerNeeded(propModel)
    Debug('Prop de drogue créé et attaché au coffre')
end

function DeleteDrugProp()
    if drugProp and DoesEntityExist(drugProp) then
        DeleteObject(drugProp)
        drugProp = nil
        Debug('Prop de drogue supprimé')
    end
end

-- =====================================================
-- SPAWN VÉHICULE
-- =====================================================

function SpawnVehicle(plate)
    Debug('Début spawn véhicule avec plaque: ' .. plate)

    local modelName = Config.Vehicle.models[math.random(#Config.Vehicle.models)]
    local model = GetHashKey(modelName)

    Debug('Modèle sélectionné: ' .. modelName .. ' (hash: ' .. model .. ')')

    RequestModel(model)

    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        Debug('ERREUR: Impossible de charger le modèle ' .. modelName)
        Notify(T.gofast_title, 'Erreur: Véhicule introuvable', 'error')
        CancelMission()
        return
    end

    Debug('Modèle chargé avec succès')

    local spawnPoint = Config.Vehicle.spawnPoint

    Debug('Point de spawn: ' .. tostring(spawnPoint))

    -- Nettoyer la zone
    local vehicle = GetClosestVehicle(spawnPoint.x, spawnPoint.y, spawnPoint.z, 3.0, 0, 71)
    if DoesEntityExist(vehicle) then
        Debug('Nettoyage véhicule existant')
        ESX.Game.DeleteVehicle(vehicle)
    end

    Debug('Création du véhicule...')
    missionVehicle = CreateVehicle(model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)

    if not DoesEntityExist(missionVehicle) then
        Debug('ERREUR: Le véhicule n\'a pas été créé')
        Notify(T.gofast_title, 'Erreur: Impossible de créer le véhicule', 'error')
        SetModelAsNoLongerNeeded(model)
        CancelMission()
        return
    end

    Debug('Véhicule créé avec succès, ID: ' .. missionVehicle)

    SetVehicleNumberPlateText(missionVehicle, plate)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleEngineOn(missionVehicle, false, false, false)
    SetVehicleFuelLevel(missionVehicle, Config.Vehicle.fuel + 0.0)
    SetModelAsNoLongerNeeded(model)

    -- Ajouter un prop visuel de drogue dans le coffre
    if Config.UseVisualProps and currentMission and currentMission.missionType then
        local missionType = currentMission.missionType
        local propConfig = Config.DrugProps[missionType.name]

        if propConfig then
            Debug('Création du prop visuel: ' .. propConfig.model)
            SpawnDrugProp(missionVehicle, propConfig)
        end
    end

    -- Blip véhicule
    vehicleBlip = AddBlipForEntity(missionVehicle)
    SetBlipSprite(vehicleBlip, 225)
    SetBlipColour(vehicleBlip, 5)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipAsShortRange(vehicleBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Véhicule de livraison')
    EndTextCommandSetBlipName(vehicleBlip)

    Notify(T.gofast_title, T.vehicle_ready, 'info')

    Debug('Véhicule spawné: ' .. plate)

    -- Thread pour vérifier si le joueur monte
    CreateThread(function()
        while isOnMission and DoesEntityExist(missionVehicle) do
            Wait(1000)

            if IsPedInVehicle(PlayerPedId(), missionVehicle, false) then
                Debug('Joueur monté dans le véhicule')

                -- Supprimer le blip du véhicule
                if vehicleBlip then
                    RemoveBlip(vehicleBlip)
                    vehicleBlip = nil
                end

                -- Créer le point de livraison IMMÉDIATEMENT
                CreateDeliveryPoint()

                -- Puis lancer le timer pour l'alerte police
                StartGoFastTimer()
                break
            end
        end
    end)

    -- Thread surveillance véhicule
    CreateThread(function()
        while isOnMission do
            Wait(1000)

            if not DoesEntityExist(missionVehicle) or IsEntityDead(missionVehicle) then
                Notify(T.gofast_title, T.vehicle_destroyed, 'error')
                CancelMission()
                break
            end
        end
    end)
end

-- =====================================================
-- TIMER ET ALERTE POLICE
-- =====================================================

function StartGoFastTimer()
    Notify(T.gofast_title, T.move_quickly, 'info')

    local waitTime = math.random(Config.TimerBeforeAlert.min, Config.TimerBeforeAlert.max)
    Debug('Timer avant alerte: ' .. waitTime .. 's')

    CreateThread(function()
        Wait(waitTime * 1000)

        -- Alerter la police
        TriggerServerEvent('gofast:alertPolice')
        Notify(T.gofast_title, T.police_alerted, 'error')
        policeAlertActive = true

        local policeAlertDuration = math.random(Config.PoliceAlertDuration.min, Config.PoliceAlertDuration.max)
        Debug('Durée alerte police: ' .. policeAlertDuration .. 's')

        -- Thread pour mettre à jour la position
        local endTime = GetGameTimer() + (policeAlertDuration * 1000)
        while GetGameTimer() < endTime and isOnMission do
            Wait(Config.PoliceUpdateInterval * 1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('gofast:updatePoliceBlip', playerCoords)
        end

        if isOnMission then
            -- Signal perdu
            policeAlertActive = false
            TriggerServerEvent('gofast:signalLost')
            Notify(T.gofast_title, T.signal_jammed, 'success')
        end
    end)
end

-- =====================================================
-- POINT DE LIVRAISON
-- =====================================================

function CreateDeliveryPoint()
    local deliveryPoint = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]

    currentMission.deliveryLocation = deliveryPoint

    Debug('Point de livraison sélectionné: x=' .. deliveryPoint.x .. ', y=' .. deliveryPoint.y)

    -- Blip
    deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
    SetBlipSprite(deliveryBlip, Config.Delivery.blip.sprite)
    SetBlipColour(deliveryBlip, Config.Delivery.blip.color)
    SetBlipScale(deliveryBlip, Config.Delivery.blip.scale)
    SetBlipAsShortRange(deliveryBlip, false)

    if Config.Delivery.blip.route then
        SetBlipRoute(deliveryBlip, true)
        SetBlipRouteColour(deliveryBlip, Config.Delivery.blip.color)
    end

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Point de livraison')
    EndTextCommandSetBlipName(deliveryBlip)

    -- ACTIVER LE GPS AUTOMATIQUEMENT
    SetNewWaypoint(deliveryPoint.x, deliveryPoint.y)
    Debug('GPS activé vers le point de livraison')

    -- Notification
    Notify(T.gofast_title, '📍 GPS activé ! Livrez la marchandise.', 'info')
end

-- =====================================================
-- LIVRAISON
-- =====================================================

function CompleteDelivery()
    Debug('Livraison complétée')

    -- Envoyer au serveur (pas besoin de plaque sans système d'items)
    TriggerServerEvent('gofast:completeDelivery')

    -- Supprimer le prop de drogue
    DeleteDrugProp()

    -- Supprimer le véhicule
    if DoesEntityExist(missionVehicle) then
        ESX.Game.DeleteVehicle(missionVehicle)
    end

    CancelMission()
end

RegisterNetEvent('gofast:deliveryCompleted')
AddEventHandler('gofast:deliveryCompleted', function(reward)
    Notify(T.gofast_title, string.format(T.mission_success, ESX.Math.GroupDigits(reward)), 'success')
end)

-- =====================================================
-- ANNULATION
-- =====================================================

function CancelMission()
    Debug('Annulation de la mission')

    isOnMission = false
    currentMission = nil
    policeAlertActive = false

    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    if vehicleBlip then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end

    -- Supprimer le prop de drogue
    DeleteDrugProp()

    if DoesEntityExist(missionVehicle) then
        ESX.Game.DeleteVehicle(missionVehicle)
        missionVehicle = nil
    end
end

RegisterNetEvent('gofast:missionCancelled')
AddEventHandler('gofast:missionCancelled', function(msg)
    Notify(T.gofast_title, msg or T.come_back_later_player, 'error')
    CancelMission()
end)

-- =====================================================
-- BLIP POLICE
-- =====================================================

RegisterNetEvent('gofast:showPoliceBlip')
AddEventHandler('gofast:showPoliceBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(T.gofast_suspect)
    EndTextCommandSetBlipName(blip)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)

    Wait(Config.PoliceBlipDuration * 1000)
    RemoveBlip(blip)
end)

-- =====================================================
-- THREADS
-- =====================================================

-- Thread pour l'interaction avec le PNJ (si pas ox_target)
CreateThread(function()
    if Config.Ped.useOxTarget then
        return
    end

    while true do
        sleep = 1000

        if not isOnMission then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local pedCoords = vector3(Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z)
            local distance = #(playerCoords - pedCoords)

            if distance < Config.DrawDistance then
                sleep = 0

                if distance < Config.InteractDistance then
                    isNearPed = true
                    ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ' .. T.start_gofast)

                    if IsControlJustReleased(0, 38) then -- E
                        CheckPoliceAndShowMenu()
                    end
                else
                    isNearPed = false
                end
            else
                isNearPed = false
            end
        end

        Wait(sleep)
    end
end)

-- Thread pour afficher le marker de livraison
CreateThread(function()
    while true do
        local sleep = 1000

        if isOnMission and currentMission and currentMission.deliveryLocation then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local deliveryCoords = currentMission.deliveryLocation
            local distance = #(playerCoords - deliveryCoords)

            if distance < Config.DrawDistance then
                sleep = 0

                -- Dessiner le marker 3D au sol
                DrawMarker(
                    Config.Delivery.markerType,
                    deliveryCoords.x, deliveryCoords.y, deliveryCoords.z - 0.98,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Delivery.markerSize.x, Config.Delivery.markerSize.y, Config.Delivery.markerSize.z,
                    Config.Delivery.markerColor.r, Config.Delivery.markerColor.g, Config.Delivery.markerColor.b, Config.Delivery.markerColor.a,
                    false, true, 2, false, nil, nil, false
                )

                -- Vérifier si le joueur est dans la zone
                if distance < Config.Delivery.radius then
                    -- Vérifier si dans le véhicule de mission
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    if vehicle == missionVehicle then
                        ShowHelpNotification(T.press_to_deliver)

                        if IsControlJustReleased(0, 38) then -- Touche E
                            CompleteDelivery()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- =====================================================
-- INITIALISATION
-- =====================================================

CreateThread(function()
    SpawnPed()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if ped then
            DeletePed(ped)
        end
        if isOnMission then
            CancelMission()
        end
    end
end)

-- Commande debug
RegisterCommand('cancelgofast', function()
    if isOnMission then
        CancelMission()
        Notify(T.gofast_title, 'Mission annulée', 'info')
    end
end, false)
