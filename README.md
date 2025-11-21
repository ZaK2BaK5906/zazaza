# 🚚 Script Go-Fast FiveM

Script de livraison de drogue (Go-Fast) pour FiveM avec une UI moderne, système d'alerte police et ox_inventory.

## ✨ Fonctionnalités

### 🎯 Système de Mission
- **3 types de drogues** configurables (Cannabis, Cocaïne, Méthamphétamine)
- **Prix par unité** personnalisable pour chaque drogue
- **Quantité min/max** configurable
- **Points de livraison aléatoires** (11 emplacements par défaut)
- **Véhicules aléatoires** parmi une liste configurable

### 🚨 Système Police
- **Alerte automatique** après un délai aléatoire
- **Blips GPS** qui se mettent à jour régulièrement
- **Durée d'alerte configurable**
- **Signal perdu** après la période d'alerte
- **Nombre minimum de policiers** requis

### ⏱️ Cooldowns
- **Cooldown global** (30 min par défaut) - pour tous les joueurs
- **Cooldown par joueur** (1h par défaut) - par joueur

### 🎨 Interface Utilisateur
- **UI moderne** avec design glassmorphism
- **Animations fluides** et transitions élégantes
- **Responsive** - s'adapte à toutes les résolutions
- **Couleurs personnalisées** par drogue
- **Icons émoji** pour chaque drogue

### 🔐 Sécurité
- **Vérifications serveur** complètes
- **Système de sac Go-Fast** avec metadata
- **Validation des items** avant livraison
- **Anti-cheat** intégré
- **Cleanup automatique** des missions abandonnées

### 🛠️ Système
- **ox_target** OU markers classiques (configurable)
- **ox_inventory** avec système de metadata
- **ox_lib** pour les notifications et inputs
- **ESX** compatible
- **Multilingue** (FR/EN inclus)

## 📋 Prérequis

- **ESX Legacy** ou **ESX 1.9+**
- **ox_lib** (dernière version)
- **ox_inventory** (dernière version)
- **ox_target** (optionnel mais recommandé)
- **oxmysql** (si vous utilisez MySQL)

## 📦 Installation

### 1. Télécharger et installer
```bash
# Placer le dossier dans votre dossier resources
[zazaza]/
├── fxmanifest.lua
├── README.md
├── config/
│   └── config.lua
├── client/
│   └── client.lua
├── server/
│   └── server.lua
├── locales/
│   ├── fr.lua
│   └── en.lua
└── html/
    ├── index.html
    ├── style.css
    └── script.js
```

### 2. Ajouter l'item dans ox_inventory

Ouvrez votre fichier `ox_inventory/data/items.lua` et ajoutez :

```lua
['gofast_bag'] = {
    label = 'Sac Go-Fast',
    weight = 5000,
    stack = false,
    close = true,
    description = 'Un sac contenant de la marchandise illégale',
    client = {
        image = 'gofast_bag.png', -- Ajoutez votre image dans ox_inventory/web/images/
    }
},
```

### 3. Configurer le script

Éditez `config/config.lua` selon vos besoins :

```lua
-- Changer la langue
Config.Language = 'fr' -- ou 'en'

-- Ajuster les cooldowns
Config.GlobalCooldown = 1800 -- 30 minutes
Config.PlayerCooldown = 3600 -- 1 heure

-- Configurer le nombre de policiers requis
Config.MinPolice = 1

-- Position du PNJ
Config.Ped.coords = vector4(1086.514, -2400.004, 30.575, 265.33)

-- Activer/désactiver ox_target
Config.Ped.useOxTarget = true -- false pour markers classiques
```

### 4. Ajouter au server.cfg

```cfg
ensure zazaza
```

### 5. Redémarrer le serveur

```bash
restart zazaza
# ou
refresh
start zazaza
```

## ⚙️ Configuration

### Drogues

Modifiez les drogues dans `config/config.lua` :

```lua
Config.Drugs = {
    {
        name = 'weed',              -- Nom de l'item dans la base de données
        label = 'Cannabis',         -- Nom affiché
        description = '...',        -- Description
        rewardPerUnit = 30,         -- Prix par unité
        minAmount = 10,             -- Quantité minimum
        maxAmount = 500,            -- Quantité maximum
        icon = '🌿',                -- Icône (émoji)
        color = '#2ecc71'           -- Couleur de la carte
    },
    -- Ajoutez autant de drogues que vous voulez
}
```

### Points de livraison

Ajoutez vos propres points dans `config/config.lua` :

```lua
Config.DeliveryPoints = {
    vector3(x, y, z),
    vector3(x, y, z),
    -- etc...
}
```

### Véhicules

Modifiez la liste des véhicules possibles :

```lua
Config.Vehicle.models = {'sultan', 'kuruma', 'buffalo', 'rumpo'}
```

### Police

Ajustez les paramètres de la police :

```lua
Config.PoliceJobName = 'police'                    -- Nom du job
Config.MinPolice = 1                               -- Nombre minimum requis
Config.TimerBeforeAlert = {min = 60, max = 120}    -- Délai avant alerte (secondes)
Config.PoliceAlertDuration = {min = 120, max = 180} -- Durée de l'alerte (secondes)
Config.PoliceUpdateInterval = 10                   -- Intervalle de mise à jour (secondes)
Config.PoliceBlipDuration = 5                      -- Durée du blip (secondes)
```

## 🎮 Utilisation

### Pour les joueurs

1. **Se rendre au PNJ** (blip sur la carte)
2. **Interagir** avec le PNJ (ox_target ou E)
3. **Sélectionner une drogue** dans le menu
4. **Choisir la quantité** à livrer
5. **Récupérer le véhicule** au point marqué
6. **Monter dans le véhicule** pour démarrer
7. **Attendre l'alerte police** (aléatoire)
8. **Livrer au point GPS** après la perte du signal
9. **Recevoir la récompense**

### Commandes

#### Joueurs
- `/cancelgofast` - Annuler la mission en cours (debug)

#### Admins
- `/gofastmissions` - Voir toutes les missions actives

## 🔧 Personnalisation

### Modifier l'UI

Les fichiers HTML/CSS/JS se trouvent dans le dossier `html/` :

- `index.html` - Structure HTML
- `style.css` - Styles et animations
- `script.js` - Logique JavaScript

### Ajouter des traductions

Créez un nouveau fichier dans `locales/` (ex: `es.lua` pour l'espagnol) :

```lua
Locales = {
    ['gofast_title'] = 'Go-Fast',
    -- etc...
}

return Locales
```

Puis changez dans `config.lua` :
```lua
Config.Language = 'es'
```

## 📊 Système de récompense

Le système calcule automatiquement la récompense :

```
Récompense totale = Quantité × Prix par unité
```

Exemple :
- 100 unités de Cannabis à 30$ = 3,000$
- 50 unités de Cocaïne à 50$ = 2,500$

## 🐛 Debug

Activer le mode debug dans `config.lua` :

```lua
Config.Debug = true
```

Cela affichera des messages détaillés dans la console F8 et serveur.

## 🔒 Sécurité

Le script inclut plusieurs mesures de sécurité :

✅ Vérification serveur de la possession de drogue
✅ Système de sac avec metadata unique
✅ Validation du sac à la livraison
✅ Cooldowns anti-spam
✅ Vérifications anti-cheat
✅ Cleanup automatique des missions

## 🤝 Support

Pour toute question ou problème :

1. Vérifiez que toutes les dépendances sont installées
2. Vérifiez les logs serveur (F8)
3. Activez le mode debug
4. Vérifiez que l'item `gofast_bag` existe

## 📝 Notes importantes

- ⚠️ Assurez-vous que les items de drogue (`weed`, `cocaine`, `meth`) existent dans votre inventaire
- ⚠️ L'item `gofast_bag` doit être ajouté à ox_inventory
- ⚠️ Si vous n'utilisez pas ox_target, réglez `Config.Ped.useOxTarget = false`
- ⚠️ Les cooldowns sont partagés entre redémarrages (stockés en mémoire)

## 📜 Licence

Ce script est fourni tel quel. Vous êtes libre de le modifier selon vos besoins.

## 🎨 Crédits

- UI Design : Claude AI
- Système : Inspiré des meilleurs scripts Go-Fast
- Framework : ESX Legacy
- Inventaire : ox_inventory

---

**Version:** 1.0.0
**Auteur:** Claude
**Date:** 2024

Bon jeu! 🎮
