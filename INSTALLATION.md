# 🚀 Guide d'installation rapide

## Étape 1 : Ajouter l'item gofast_bag

### Méthode 1 : ox_inventory (RECOMMANDÉ)

Ouvrez `ox_inventory/data/items.lua` et ajoutez :

```lua
['gofast_bag'] = {
    label = 'Sac Go-Fast',
    weight = 5000,
    stack = false,
    close = true,
    description = 'Un sac contenant de la marchandise illégale',
    client = {
        image = 'gofast_bag.png',
    }
},
```

### Image de l'item (optionnel)

1. Créez ou trouvez une image `gofast_bag.png` (150x150px)
2. Placez-la dans `ox_inventory/web/images/gofast_bag.png`

## Étape 2 : Vérifier les items de drogue

Assurez-vous que ces items existent dans votre serveur :

- `weed` (Cannabis)
- `cocaine` (Cocaïne)
- `meth` (Méthamphétamine)

Si vous utilisez d'autres noms, modifiez `config/config.lua` :

```lua
Config.Drugs = {
    {
        name = 'votre_item_weed', -- Changez ici
        -- ...
    }
}
```

## Étape 3 : Configuration serveur

Ajoutez à votre `server.cfg` :

```cfg
ensure zazaza
```

OU si vous avez des catégories :

```cfg
# === ILLEGAL ===
ensure zazaza
```

## Étape 4 : Configuration du script

Modifiez `config/config.lua` selon vos besoins :

### Configuration minimale requise :

```lua
-- 1. Langue
Config.Language = 'fr' -- ou 'en'

-- 2. Position du PNJ (IMPORTANT - Changez si besoin)
Config.Ped.coords = vector4(1086.514, -2400.004, 30.575, 265.33)

-- 3. Point de spawn du véhicule (IMPORTANT - Changez si besoin)
Config.Vehicle.spawnPoint = vector4(1079.645, -2385.448, 29.997, 359.73)

-- 4. Job de police (Vérifiez le nom dans votre serveur)
Config.PoliceJobName = 'police'

-- 5. Ox_target (true si vous l'avez, false sinon)
Config.Ped.useOxTarget = true
```

### Configuration optionnelle :

```lua
-- Cooldowns
Config.GlobalCooldown = 1800 -- 30 minutes (en secondes)
Config.PlayerCooldown = 3600 -- 1 heure (en secondes)

-- Police
Config.MinPolice = 1 -- Nombre minimum de policiers requis

-- Récompense
Config.RewardType = 'money' -- ou 'black_money', 'dirty_money', etc.
```

## Étape 5 : Redémarrer le serveur

```bash
# Dans la console serveur
restart zazaza

# OU si première installation
refresh
ensure zazaza
```

## ✅ Vérification de l'installation

### Checklist :

- [ ] Le script démarre sans erreur dans la console
- [ ] Le message de bienvenue s'affiche : `[GOFAST] Script chargé avec succès!`
- [ ] Un blip apparaît sur la carte
- [ ] Le PNJ est présent à la position configurée
- [ ] L'item `gofast_bag` existe dans ox_inventory
- [ ] Les items de drogue existent (`weed`, `cocaine`, `meth`)

### En cas de problème :

1. **Le script ne démarre pas**
   - Vérifiez que toutes les dépendances sont installées (ox_lib, ox_inventory, ox_target)
   - Vérifiez la syntaxe dans config.lua

2. **Le PNJ n'apparaît pas**
   - Vérifiez les coordonnées dans Config.Ped.coords
   - Essayez de vous téléporter à ces coordonnées

3. **L'UI ne s'ouvre pas**
   - Si vous utilisez ox_target, vérifiez qu'il est bien démarré
   - Si pas ox_target, mettez `Config.Ped.useOxTarget = false`

4. **"Vous n'avez aucune drogue disponible"**
   - Donnez-vous des items de drogue pour tester : `/giveitem [id] weed 100`
   - Vérifiez que le nom de l'item correspond à celui dans config.lua

5. **Le véhicule ne spawn pas**
   - Vérifiez Config.Vehicle.spawnPoint
   - Assurez-vous que les modèles de véhicules existent

## 🧪 Test rapide

1. Donnez-vous de la drogue :
```
/giveitem [votre_id] weed 100
```

2. Téléportez-vous au PNJ :
```
/tp 1086.514 -2400.004 30.575
```

3. Interagissez avec le PNJ

4. Sélectionnez Cannabis et une quantité

5. Vérifiez que :
   - Le véhicule spawn
   - Vous recevez un sac go-fast dans l'inventaire
   - La drogue est retirée

## 📞 Support

En cas de problème, activez le mode debug :

```lua
Config.Debug = true
```

Puis regardez les logs dans :
- Console serveur
- Console F8 (client)

## 🎉 C'est tout !

Votre script Go-Fast est maintenant installé et prêt à l'emploi !

Bon jeu! 🚗💨
