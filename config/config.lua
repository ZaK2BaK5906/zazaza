Config = {}

-- Configuration générale
Config.Debug = false -- Mode debug pour afficher les messages de debug (mettre false en production)
Config.Language = 'fr' -- Langue (fr ou en)

-- Cooldowns
Config.GlobalCooldown = 1800 -- 30 minutes - Cooldown global pour tous les joueurs (en secondes)
Config.PlayerCooldown = 3600 -- 1 heure - Cooldown par joueur (en secondes)

-- Police
Config.PoliceJobName = { 'police', 'sheriff' } -- Noms des jobs de police/sheriff
Config.MinPolice = 2 -- Nombre minimum de policiers en ligne
Config.TimerBeforeAlert = {min = 10, max = 30} -- Timer avant l'alerte police (en secondes)
Config.PoliceAlertDuration = {min = 90, max = 180} -- Durée de l'alerte police (en secondes)
Config.PoliceUpdateInterval = 7 -- Intervalle de mise à jour de la position (en secondes)
Config.PoliceBlipDuration = 5 -- Durée d'affichage du blip (en secondes)

-- Configuration du PNJ
Config.Ped = {
    model = 'g_m_m_chemwork_01', -- Modèle du PNJ
    coords = vector4(-1139.98, -2005.75, 13.18, 131.00), -- Position et rotation du PNJ
    scenario = 'WORLD_HUMAN_SMOKING', -- Animation du PNJ
    useOxTarget = true, -- Utiliser ox_target (true) ou markers classiques (false)
    blip = {
        enabled = false,
        sprite = 501,
        color = 1,
        scale = 0.8,
        label = 'Livraison Gofast'
    }
}

-- Configuration du véhicule
Config.Vehicle = {
    models = {'sultan', 'kuruma', 'buffalo', 'rumpo'}, -- Modèles possibles (aléatoire)
    spawnPoint = vector4(-1154.64, -2003.90, 13.18, 331.00), -- Point de spawn du véhicule
    platePrefix = 'GF', -- Préfixe de la plaque (ex: GF1234)
    fuel = 100 -- Essence du véhicule (si vous utilisez un script de carburant)
}

-- Configuration des missions (types de drogues)
Config.Missions = {
    {
        name = 'weed',
        label = 'Cannabis',
        description = 'Livraison de cannabis. Mission facile, récompense correcte.',
        rewardMin = 1000, -- Récompense minimum
        rewardMax = 3000, -- Récompense maximum
        item = 'weed_pooch', -- Nom de l'item dans la base de données
        itemLabel = 'Pochons de Weed',
        quantity = 50, -- Quantité dans le coffre
        icon = '🌿',
        color = '#2ecc71', -- Couleur pour l'UI
        difficulty = 'Facile'
    },
    {
        name = 'cocaine',
        label = 'Cocaïne',
        description = 'Livraison de cocaïne. Mission risquée, bonne récompense.',
        rewardMin = 3000, -- Récompense minimum
        rewardMax = 6000, -- Récompense maximum
        item = 'coke_pooch', -- Nom de l'item dans la base de données
        itemLabel = 'Pochons de Coke',
        quantity = 30, -- Quantité dans le coffre
        icon = '❄️',
        color = '#ecf0f1',
        difficulty = 'Moyen'
    },
    {
        name = 'meth',
        label = 'Méthamphétamine',
        description = 'Livraison de meth. Mission très risquée, haute récompense.',
        rewardMin = 6000, -- Récompense minimum
        rewardMax = 10000, -- Récompense maximum
        item = 'meth_pooch', -- Nom de l'item dans la base de données
        itemLabel = 'Pochons de Meth',
        quantity = 20, -- Quantité dans le coffre
        icon = '💎',
        color = '#3498db',
        difficulty = 'Difficile'
    }
}

-- Points de livraison (un sera choisi aléatoirement)
Config.DeliveryPoints = {
    vector3(809.005, 2180.060, 52.007),
    vector3(2465.861, 1588.717, 32.720),
    vector3(1380.85, 3594.11, 33.90),
    vector3(1382.87, 3604.67, 33.89),
    vector3(-1124.28, 4930.99, 217.96),
    vector3(1992.25, 3058.94, 46.06),
    vector3(-40.10, -1112.25, 25.44),
    vector3(-1523.74, 855.55, 180.62),
    vector3(1666.84, 4769.69, 40.94),
    vector3(-2188.02, 4258.90, 47.62),
    vector3(721.09, -980.04, 23.13)
}

-- Configuration de la livraison
Config.Delivery = {
    radius = 5, -- Rayon pour valider la livraison (en mètres)
    markerType = 27, -- Type de marker (1 = cylindre, 27 = cercle plat, 25 = checkpoint)
    markerSize = vector3(4.0, 4.0, 0.5), -- Taille du marker (x, y, z)
    markerColor = {r = 52, g = 152, b = 219, a = 120}, -- Couleur bleue douce et discrète (rgba)
    blip = {
        sprite = 478,
        color = 2,
        scale = 1.0,
        route = true -- Afficher la route GPS
    }
}

-- Système de récompense
Config.RewardType = 'black_money' -- Type de monnaie (money, black_money, etc.)

-- Notifications ox_lib
Config.NotifyPosition = 'top' -- Position des notifications (top, top-right, top-left, bottom, bottom-right, bottom-left)

-- Distance d'interaction (si ox_target désactivé)
Config.DrawDistance = 50.0 -- Distance pour afficher les markers
Config.InteractDistance = 2.0 -- Distance pour interagir avec le PNJ

-- Système de props visuels dans le coffre
Config.UseVisualProps = true -- Afficher des props de drogue dans le coffre (purement visuel)

-- Props pour chaque type de drogue
Config.DrugProps = {
    weed = {
        model = 'prop_weed_01', -- Modèle du prop de weed
        offset = vector3(0.0, -0.5, 0.3), -- Position dans le coffre
        rotation = vector3(0.0, 0.0, 90.0)
    },
    cocaine = {
        model = 'prop_cs_cocaine', -- Modèle du prop de cocaïne
        offset = vector3(0.0, -0.5, 0.3),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    meth = {
        model = 'prop_meth_bag_01', -- Modèle du prop de meth
        offset = vector3(0.0, -0.5, 0.3),
        rotation = vector3(0.0, 0.0, 45.0)
    }
}
