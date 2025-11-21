Config = {}

-- Configuration générale
Config.Debug = true -- Mode debug pour afficher les messages de debug (mettre false en production)
Config.Language = 'fr' -- Langue (fr ou en)

-- Cooldowns
Config.GlobalCooldown = 1800 -- 30 minutes - Cooldown global pour tous les joueurs (en secondes)
Config.PlayerCooldown = 3600 -- 1 heure - Cooldown par joueur (en secondes)

-- Police
Config.PoliceJobName = 'police' -- Nom du job de police
Config.MinPolice = 0 -- Nombre minimum de policiers en ligne
Config.TimerBeforeAlert = {min = 60, max = 120} -- Timer avant l'alerte police (en secondes)
Config.PoliceAlertDuration = {min = 120, max = 180} -- Durée de l'alerte police (en secondes)
Config.PoliceUpdateInterval = 10 -- Intervalle de mise à jour de la position (en secondes)
Config.PoliceBlipDuration = 5 -- Durée d'affichage du blip (en secondes)

-- Configuration du PNJ
Config.Ped = {
    model = 'g_m_m_chemwork_01', -- Modèle du PNJ
    coords = vector4(1072.0420, -2382.7825, 30.5901, 62.1716), -- Position et rotation du PNJ
    scenario = 'WORLD_HUMAN_SMOKING', -- Animation du PNJ
    useOxTarget = true, -- Utiliser ox_target (true) ou markers classiques (false)
    blip = {
        enabled = true,
        sprite = 501,
        color = 1,
        scale = 0.8,
        label = 'Livraison Gofast'
    }
}

-- Configuration du véhicule
Config.Vehicle = {
    models = {'sultan', 'kuruma', 'buffalo', 'rumpo'}, -- Modèles possibles (aléatoire)
    spawnPoint = vector4(1072.0420, -2382.7825, 30.5901, 62.1716), -- Point de spawn du véhicule
    platePrefix = 'GF', -- Préfixe de la plaque (ex: GF1234)
    fuel = 100 -- Essence du véhicule (si vous utilisez un script de carburant)
}

-- Configuration des missions (types de drogues)
Config.Missions = {
    {
        name = 'weed',
        label = 'Cannabis',
        description = 'Livraison de cannabis. Mission facile, récompense correcte.',
        reward = 5000, -- Récompense fixe pour cette mission
        icon = '🌿',
        color = '#2ecc71', -- Couleur pour l'UI
        difficulty = 'Facile'
    },
    {
        name = 'cocaine',
        label = 'Cocaïne',
        description = 'Livraison de cocaïne. Mission risquée, bonne récompense.',
        reward = 10000, -- Récompense fixe
        icon = '❄️',
        color = '#ecf0f1',
        difficulty = 'Moyen'
    },
    {
        name = 'meth',
        label = 'Méthamphétamine',
        description = 'Livraison de meth. Mission très risquée, haute récompense.',
        reward = 15000, -- Récompense fixe
        icon = '💎',
        color = '#3498db',
        difficulty = 'Difficile'
    }
}

-- Points de livraison (un sera choisi aléatoirement)
Config.DeliveryPoints = {
    vector3(809.005, 2180.060, 52.007),
    vector3(2465.861, 1588.717, 32.720),
    vector3(1393.35, 3608.43, 38.94),
    vector3(2434.78, 4969.18, 46.81),
    vector3(-1108.32, 4937.66, 218.65),
    vector3(1983.36, 3053.08, 47.22),
    vector3(-38.31, -1109.85, 26.44),
    vector3(-1520.14, 851.82, 181.59),
    vector3(1662.04, 4776.55, 42.01),
    vector3(-2186.67, 4250.81, 48.17),
    vector3(715.98, -962.73, 30.40)
}

-- Configuration de la livraison
Config.Delivery = {
    radius = 5.0, -- Rayon pour valider la livraison (en mètres)
    markerType = 1, -- Type de marker (1 = cylinder)
    markerSize = vector3(3.0, 3.0, 1.0), -- Taille du marker
    markerColor = {r = 46, g = 204, b = 113, a = 100}, -- Couleur du marker (rgba)
    blip = {
        sprite = 478,
        color = 2,
        scale = 1.0,
        route = true -- Afficher la route GPS
    }
}

-- Système de récompense
Config.RewardType = 'money' -- Type de monnaie (money, black_money, etc.)

-- Notifications ox_lib
Config.NotifyPosition = 'top' -- Position des notifications (top, top-right, top-left, bottom, bottom-right, bottom-left)

-- Distance d'interaction (si ox_target désactivé)
Config.DrawDistance = 50.0 -- Distance pour afficher les markers
Config.InteractDistance = 2.0 -- Distance pour interagir avec le PNJ
