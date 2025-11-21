// Variables globales
let missionsData = [];
let isVisible = false;

// Initialisation
window.addEventListener('DOMContentLoaded', () => {
    console.log('UI Gofast chargée');
    setupEventListeners();
});

// Configuration des event listeners
function setupEventListeners() {
    // Bouton de fermeture
    const closeBtn = document.getElementById('closeBtn');
    closeBtn.addEventListener('click', closeMenu);

    // Fermeture avec Échap
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && isVisible) {
            closeMenu();
        }
    });

    // Fermeture en cliquant sur l'overlay
    const overlay = document.getElementById('overlay');
    overlay.addEventListener('click', closeMenu);
}

// Écouter les messages de NUI
window.addEventListener('message', (event) => {
    const data = event.data;

    console.log('[NUI] Message reçu:', data);

    switch (data.type) {
        case 'openMenu':
            console.log('[NUI] openMenu appelé avec', data.missions ? data.missions.length : 0, 'missions');
            openMenu(data.missions);
            break;
        case 'closeMenu':
            console.log('[NUI] closeMenu appelé');
            closeMenu();
            break;
        default:
            console.log('[NUI] Type de message inconnu:', data.type);
    }
});

// Ouvrir le menu
function openMenu(missions) {
    console.log('[openMenu] Appelé avec:', missions);
    console.log('[openMenu] isVisible:', isVisible);

    if (isVisible) {
        console.log('[openMenu] Menu déjà visible, abandon');
        return;
    }

    if (!missions || missions.length === 0) {
        console.error('[openMenu] Aucune mission reçue!');
        return;
    }

    missionsData = missions;
    isVisible = true;

    console.log('[openMenu] Affichage du menu avec', missionsData.length, 'missions');

    const app = document.getElementById('app');
    if (!app) {
        console.error('[openMenu] Element #app introuvable!');
        return;
    }

    app.classList.remove('hidden');
    console.log('[openMenu] Menu affiché');

    // Générer les cartes de missions
    generateMissionCards();

    // Animation d'entrée simplifiée
    setTimeout(() => {
        const cards = document.querySelectorAll('.drug-card');
        console.log('[openMenu] Nombre de cartes:', cards.length);
        cards.forEach((card, index) => {
            card.style.animation = `fadeInUp 0.3s ease-out ${index * 0.05}s both`;
        });
    }, 50);
}

// Fermer le menu
function closeMenu() {
    if (!isVisible) return;

    const app = document.getElementById('app');
    const container = document.querySelector('.container');

    // Animation de sortie rapide
    container.style.animation = 'slideDown 0.2s ease-in';

    setTimeout(() => {
        app.classList.add('hidden');
        container.style.animation = '';
        isVisible = false;

        // Nettoyer
        missionsData = [];
        document.getElementById('drugsGrid').innerHTML = '';

        // Envoyer au client
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        }).catch(() => {});
    }, 200);
}

// Générer les cartes de missions
function generateMissionCards() {
    const grid = document.getElementById('drugsGrid');
    grid.innerHTML = '';

    missionsData.forEach((mission, index) => {
        const card = createMissionCard(mission, index);
        grid.appendChild(card);
    });
}

// Créer une carte de mission
function createMissionCard(mission, index) {
    const card = document.createElement('div');
    card.className = 'drug-card';
    card.setAttribute('data-color', mission.color);
    card.style.setProperty('--drug-color', mission.color);
    card.style.setProperty('--drug-color-alpha', hexToRgba(mission.color, 0.3));

    card.innerHTML = `
        <div class="drug-header">
            <div class="drug-icon">${mission.icon}</div>
            <div class="drug-title">
                <h3>${mission.label}</h3>
                <span class="drug-badge" style="background: ${mission.color}20; color: ${mission.color};">
                    ${mission.difficulty}
                </span>
            </div>
        </div>
        <div class="drug-description">
            ${mission.description}
        </div>
        <div class="drug-price">
            <span class="price-label">Récompense</span>
            <span class="price-value">${formatNumber(mission.reward)}</span>
        </div>
    `;

    // Event listener pour la sélection
    card.addEventListener('click', () => selectMission(index, card));

    // Effet hover sonore (optionnel)
    card.addEventListener('mouseenter', () => {
        playHoverSound();
    });

    return card;
}

// Sélectionner une mission
function selectMission(index, cardElement) {
    console.log('[selectMission] Mission cliquée, index:', index);
    console.log('[selectMission] isVisible:', isVisible);

    if (!isVisible) {
        console.log('[selectMission] Menu non visible, abandon');
        return;
    }

    console.log('[selectMission] Mission sélectionnée:', missionsData[index]);

    // Marquer comme non visible immédiatement pour éviter double clic
    isVisible = false;

    // Effet visuel de sélection
    cardElement.classList.add('selecting');

    // Son de sélection (optionnel)
    playSelectSound();

    // Fermer le menu IMMÉDIATEMENT
    const app = document.getElementById('app');
    app.classList.add('hidden');

    // Envoyer au serveur SANS attendre de réponse (fire and forget)
    console.log('[selectMission] Envoi au serveur...');
    fetch(`https://${GetParentResourceName()}/selectMission`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            mission: missionsData[index]
        })
    }).catch(() => {}); // Ignorer les erreurs

    // Nettoyer
    missionsData = [];
    document.getElementById('drugsGrid').innerHTML = '';
    console.log('[selectMission] Menu fermé');
}

// Fonctions utilitaires

function GetParentResourceName() {
    return window.location.hostname;
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

// Sons (optionnels - à activer si vous avez des fichiers audio)
function playHoverSound() {
    // Décommenter si vous ajoutez des sons
    /*
    const audio = new Audio('assets/hover.mp3');
    audio.volume = 0.2;
    audio.play().catch(() => {});
    */
}

function playSelectSound() {
    // Décommenter si vous ajoutez des sons
    /*
    const audio = new Audio('assets/select.mp3');
    audio.volume = 0.3;
    audio.play().catch(() => {});
    */
}

// Debug
console.log('Script Gofast initialisé');
