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

-- Variables d'optimisation
local sleep = 1000
local isNearPed = false
local isNearDelivery = false

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
    ESX.TriggerServerCallback('gofast:getDrugList', function(availableDrugs)
        if #availableDrugs == 0 then
            Notify(T.gofast_title, T.no_drugs_available, 'error')
            return
        end

        OpenDrugMenu(availableDrugs)
    end)
end

-- =====================================================
-- UI PERSONNALISÉ
-- =====================================================

function OpenDrugMenu(availableDrugs)
    Debug('Ouverture du menu avec ' .. #availableDrugs .. ' drogues')

    -- Préparer les données pour l'UI
    local drugsData = {}
    for i, drug in ipairs(availableDrugs) do
        table.insert(drugsData, {
            name = drug.name,
            label = drug.label,
            description = string.format('%s | Min: %s | Max: %s | Dispo: %s',
                drug.description,
                drug.minAmount,
                math.min(drug.maxAmount, drug.playerAmount),
                drug.playerAmount
            ),
            rewardPerUnit = drug.rewardPerUnit,
            minAmount = drug.minAmount,
            maxAmount = drug.maxAmount,
            playerAmount = drug.playerAmount,
            icon = drug.icon,
            color = drug.color
        })
    end

    -- Ouvrir l'UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openMenu',
        drugs = drugsData
    })
end

-- Callback pour la sélection de drogue
RegisterNUICallback('selectDrug', function(data, cb)
    SetNuiFocus(false, false)

    local drugData = data.drug
    if not drugData then
        cb('error')
        return
    end

    Debug('Drogue sélectionnée: ' .. drugData.name)

    -- Demander la quantité
    local input = lib.inputDialog(string.format('%s %s', T.quantity_label, drugData.label), {
        {
            type = 'number',
            label = T.quantity_label,
            description = string.format(T.min_max_quantity_description, drugData.minAmount, math.min(drugData.maxAmount, drugData.playerAmount)),
            required = true,
            min = drugData.minAmount,
            max = math.min(drugData.maxAmount, drugData.playerAmount)
        }
    })

    if input and input[1] then
        local amount = math.floor(input[1])
        if amount >= drugData.minAmount and amount <= math.min(drugData.maxAmount, drugData.playerAmount) then
            TriggerServerEvent('gofast:startMission', drugData.name, amount)
        else
            Notify(T.gofast_title, string.format(T.invalid_quantity_range, drugData.minAmount, math.min(drugData.maxAmount, drugData.playerAmount)), 'error')
        end
    end

    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- =====================================================
-- DÉMARRAGE DE MISSION
-- =====================================================

RegisterNetEvent('gofast:startMission')
AddEventHandler('gofast:startMission', function(drugType, amount, plate)
    if isOnMission then
        return
    end

    Debug('Mission démarrée: ' .. drugType.name .. ' x' .. amount)

    isOnMission = true
    currentMission = {
        drugType = drugType,
        amount = amount,
        plate = plate
    }

    Notify(T.gofast_title, T.mission_started, 'success')

    -- Spawn véhicule
    SpawnVehicle(plate)
end)

-- =====================================================
-- SPAWN VÉHICULE
-- =====================================================

function SpawnVehicle(plate)
    local model = GetHashKey(Config.Vehicle.models[math.random(#Config.Vehicle.models)])
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    local spawnPoint = Config.Vehicle.spawnPoint

    -- Nettoyer la zone
    local vehicle = GetClosestVehicle(spawnPoint.x, spawnPoint.y, spawnPoint.z, 3.0, 0, 71)
    if DoesEntityExist(vehicle) then
        ESX.Game.DeleteVehicle(vehicle)
    end

    missionVehicle = CreateVehicle(model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    SetVehicleNumberPlateText(missionVehicle, plate)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleEngineOn(missionVehicle, false, false, false)
    SetVehicleFuelLevel(missionVehicle, Config.Vehicle.fuel + 0.0)

    -- Blip véhicule
    vehicleBlip = AddBlipForEntity(missionVehicle)
    SetBlipSprite(vehicleBlip, 225)
    SetBlipColour(vehicleBlip, 5)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipAsShortRange(vehicleBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Véhicule de livraison')
    EndTextCommandSetBlipName(vehicleBlip)

    SetNewWaypoint(spawnPoint.x, spawnPoint.y)
    Notify(T.gofast_title, T.vehicle_ready, 'info')

    Debug('Véhicule spawné: ' .. plate)

    -- Thread pour vérifier si le joueur monte
    CreateThread(function()
        while isOnMission and DoesEntityExist(missionVehicle) do
            Wait(1000)

            if IsPedInVehicle(PlayerPedId(), missionVehicle, false) then
                if vehicleBlip then
                    RemoveBlip(vehicleBlip)
                    vehicleBlip = nil
                end
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

            -- Créer point de livraison
            CreateDeliveryPoint()
        end
    end)
end

-- =====================================================
-- POINT DE LIVRAISON
-- =====================================================

function CreateDeliveryPoint()
    local deliveryPoint = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]

    currentMission.deliveryLocation = deliveryPoint

    Debug('Point de livraison: ' .. tostring(deliveryPoint))

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
end

-- =====================================================
-- LIVRAISON
-- =====================================================

function CompleteDelivery()
    Debug('Livraison complétée')

    TriggerServerEvent('gofast:completeDelivery', currentMission.drugType.name, currentMission.amount)

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
    isNearDelivery = false
    policeAlertActive = false

    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    if vehicleBlip then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end

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

-- Thread pour la zone de livraison
CreateThread(function()
    while true do
        sleep = 1000

        if isOnMission and currentMission and currentMission.deliveryLocation then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local deliveryCoords = currentMission.deliveryLocation
            local distance = #(playerCoords - deliveryCoords)

            if distance < Config.DrawDistance then
                sleep = 0

                -- Marker
                DrawMarker(
                    Config.Delivery.markerType,
                    deliveryCoords.x, deliveryCoords.y, deliveryCoords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Delivery.markerSize.x, Config.Delivery.markerSize.y, Config.Delivery.markerSize.z,
                    Config.Delivery.markerColor.r, Config.Delivery.markerColor.g, Config.Delivery.markerColor.b, Config.Delivery.markerColor.a,
                    false, true, 2, false, nil, nil, false
                )

                if distance < Config.Delivery.radius then
                    isNearDelivery = true

                    -- Vérifier si dans le véhicule
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    if vehicle == missionVehicle then
                        ShowHelpNotification(T.press_to_deliver)

                        if IsControlJustReleased(0, 38) then -- E
                            CompleteDelivery()
                        end
                    end
                else
                    isNearDelivery = false
                end
            else
                isNearDelivery = false
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
