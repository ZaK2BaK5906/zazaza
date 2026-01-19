Config = {}

-- =====================================================
-- CONFIGURATION GÉNÉRALE
-- =====================================================

Config.Debug = false -- Mode debug (true pour voir les logs)
Config.Language = 'fr' -- Langue (fr ou en)

-- =====================================================
-- COOLDOWNS
-- =====================================================

Config.GlobalCooldown = 1800 -- 30 minutes - Cooldown global pour tous les joueurs
Config.PlayerCooldown = 3600 -- 1 heure - Cooldown par joueur

-- =====================================================
-- POLICE & SHERIFF
-- =====================================================

Config.PoliceJobName = { 'police', 'sheriff' } -- Jobs qui reçoivent les alertes
Config.MinPolice = 2 -- Nombre minimum de policiers/sheriffs requis

-- Timers des alertes
Config.TimerBeforeAlert = {min = 10, max = 30} -- Délai avant l'alerte (secondes)
Config.PoliceAlertDuration = {min = 90, max = 180} -- Durée de l'alerte (secondes)
Config.PoliceUpdateInterval = 7 -- Intervalle de mise à jour de position (secondes)
Config.PoliceBlipDuration = 5 -- Durée d'affichage du blip (secondes)

-- =====================================================
-- PNJ DE DÉPART
-- =====================================================

Config.Ped = {
    model = 'g_m_m_chemwork_01', -- Modèle du PNJ
    coords = vector4(-1139.98, -2005.75, 13.18, 131.00), -- Position (x, y, z, heading)
    scenario = 'WORLD_HUMAN_SMOKING', -- Animation du PNJ
    useOxTarget = true, -- Utiliser ox_target pour l'interaction
    blip = {
        enabled = false, -- Afficher un blip sur la map
        sprite = 501,
        color = 1,
        scale = 0.8,
        label = 'Livraison Gofast'
    }
}

-- =====================================================
-- VÉHICULE
-- =====================================================

Config.Vehicle = {
    models = {'sultan', 'kuruma', 'buffalo', 'rumpo'}, -- Modèles possibles (aléatoire)
    spawnPoint = vector4(-1154.64, -2003.90, 13.18, 331.00), -- Point de spawn (x, y, z, heading)
    platePrefix = 'GF', -- Préfixe de la plaque (ex: GF1234)
    fuel = 100 -- Essence du véhicule (0-100)
}

-- =====================================================
-- MISSIONS (TYPES DE DROGUES)
-- =====================================================

Config.Missions = {
    {
        name = 'weed',
        label = 'Cannabis',
        description = 'Livraison de cannabis. Mission facile, récompense correcte.',
        rewardMin = 1000, -- Récompense minimum (argent sale)
        rewardMax = 3000, -- Récompense maximum (argent sale)
        icon = '🌿',
        color = '#2ecc71',
        difficulty = 'Facile'
    },
    {
        name = 'cocaine',
        label = 'Cocaïne',
        description = 'Livraison de cocaïne. Mission risquée, bonne récompense.',
        rewardMin = 3000, -- Récompense minimum (argent sale)
        rewardMax = 6000, -- Récompense maximum (argent sale)
        icon = '❄️',
        color = '#ecf0f1',
        difficulty = 'Moyen'
    },
    {
        name = 'meth',
        label = 'Méthamphétamine',
        description = 'Livraison de meth. Mission très risquée, haute récompense.',
        rewardMin = 6000, -- Récompense minimum (argent sale)
        rewardMax = 10000, -- Récompense maximum (argent sale)
        icon = '💎',
        color = '#3498db',
        difficulty = 'Difficile'
    }
}

-- =====================================================
-- POINTS DE LIVRAISON
-- =====================================================

Config.DeliveryPoints = {
    -- Sandy Shores
    vector3(809.005, 2180.060, 52.007),
    vector3(2465.861, 1588.717, 32.720),

    -- Grapeseed
    vector3(1380.85, 3594.11, 33.90),
    vector3(1382.87, 3604.67, 33.89),

    -- Paleto Bay
    vector3(-1124.28, 4930.99, 217.96),

    -- Grand Senora Desert
    vector3(1992.25, 3058.94, 46.06),

    -- Los Santos
    vector3(-40.10, -1112.25, 25.44),
    vector3(721.09, -980.04, 23.13),

    -- Chumash
    vector3(-1523.74, 855.55, 180.62),

    -- Lago Zancudo
    vector3(1666.84, 4769.69, 40.94),

    -- Mount Chiliad
    vector3(-2188.02, 4258.90, 47.62)
}

-- =====================================================
-- CONFIGURATION DE LIVRAISON
-- =====================================================

Config.Delivery = {
    radius = 5.0, -- Rayon pour valider la livraison (mètres)
    markerType = 27, -- Type de marker (1 = cylindre, 27 = cercle plat)
    markerSize = vector3(4.0, 4.0, 0.5), -- Taille du marker (x, y, z)
    markerColor = {r = 52, g = 152, b = 219, a = 120}, -- Couleur bleue discrète (rgba)
    blip = {
        sprite = 478, -- Icône du blip
        color = 2, -- Couleur du blip (vert)
        scale = 1.0, -- Taille du blip
        route = true -- Afficher la route GPS
    }
}

-- =====================================================
-- SYSTÈME DE RÉCOMPENSE
-- =====================================================

Config.RewardType = 'black_money' -- Type de monnaie (money = argent propre, black_money = argent sale)

-- =====================================================
-- PROPS VISUELS DE DROGUE
-- =====================================================

Config.UseVisualProps = true -- Afficher des props de drogue dans le coffre (purement visuel)

-- Props pour chaque type de drogue
Config.DrugProps = {
    weed = {
        model = 'prop_weed_01', -- Modèle du prop
        offset = vector3(0.0, -0.5, 0.3), -- Position dans le coffre
        rotation = vector3(0.0, 0.0, 90.0) -- Rotation
    },
    cocaine = {
        model = 'prop_cs_cocaine', -- Modèle du prop
        offset = vector3(0.0, -0.5, 0.3),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    meth = {
        model = 'prop_meth_bag_01', -- Modèle du prop
        offset = vector3(0.0, -0.5, 0.3),
        rotation = vector3(0.0, 0.0, 45.0)
    }
}

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

Config.NotifyPosition = 'top' -- Position des notifications (top, top-right, top-left, bottom, bottom-right, bottom-left)

-- =====================================================
-- DISTANCES D'INTERACTION
-- =====================================================

Config.DrawDistance = 50.0 -- Distance pour afficher les markers
Config.InteractDistance = 2.0 -- Distance pour interagir avec le PNJ (si ox_target désactivé)
