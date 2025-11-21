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

    switch (data.type) {
        case 'openMenu':
            openMenu(data.missions);
            break;
        case 'closeMenu':
            closeMenu();
            break;
    }
});

// Ouvrir le menu
function openMenu(missions) {
    if (isVisible) return;

    missionsData = missions;
    isVisible = true;

    const app = document.getElementById('app');
    app.classList.remove('hidden');

    // Générer les cartes de missions
    generateMissionCards();

    // Animation d'entrée simplifiée
    setTimeout(() => {
        const cards = document.querySelectorAll('.drug-card');
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
    if (!isVisible) return;

    // Marquer comme non visible immédiatement pour éviter double clic
    isVisible = false;

    // Effet visuel de sélection
    cardElement.classList.add('selecting');

    // Son de sélection (optionnel)
    playSelectSound();

    // Envoyer au serveur IMMÉDIATEMENT
    fetch(`https://${GetParentResourceName()}/selectMission`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            mission: missionsData[index]
        })
    }).catch(err => console.error('Erreur selectMission:', err));

    // Fermer visuellement le menu SANS callback (NUI focus déjà désactivé)
    const app = document.getElementById('app');
    setTimeout(() => {
        app.classList.add('hidden');
        missionsData = [];
        document.getElementById('drugsGrid').innerHTML = '';
    }, 100);
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
