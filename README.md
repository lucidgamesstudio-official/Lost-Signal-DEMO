# 🧩 Fiche technique — _Lost Signal DEMO_

## 🎮 **Composantes de gameplay**


| Composante          | Description                                                      | Implémentation                                 |
| ------------------- | ---------------------------------------------------------------- | ---------------------------------------------- |
| Déplacement de base | Mouvement standard Roblox `Humanoid`                             | Par défaut                                     |
| Accroupissement     | Toggle ou maintient (`ctrl` ou `C`) pour passer en mode accroupi | Animation + vitesse réduite                    |
| Sprint              | Sprint temporaire avec barre de stamina                          | `Shift` + système de recharge et effets visuel |
| Stamina             | Barre qui diminue en sprint, se recharge lentement               | UI + logique de cooldown                       |
| Lampe torche        | Toggle avec `F`, portée limitée, effet de lumière dynamique      | `SpotLight` attaché au joueur                  |
| Interaction         | Appuie sur une touche `E` pour interagir avec des objets         | `ProximityPrompt`                              |
| Journal/Logs        | Objets à ramasser ou lire                                        | UI                                             |
| Effets visuels      | Brouillard, lumières dynamiques, distorsion visuelle             | `PostEffect`, `Tween`, `ParticleEmitter`       |
| Effets sonores      | Bruits de pas, radio, ambiance et jumpscare                      | `SoundService` + `Sound` localisés             |
| Evènements scriptés | Apparitions, blackout, portes qui s'ouvrent toutes seules        | `BindableEvent`, `Tween`, `Animation`          |
| Fin de partie       | Déclenchement d'une fin (sortie, piégeage, révélation)           | Trigger + UI narrative                         |


## 🧱 **Structure technique du projet**


| Module / Dossier              | Contenu                                           |
| ----------------------------- | ------------------------------------------------- |
| `src/Client/Player/`          | Scripts de mouvement, sprint, lampe, UI           |
| src/Client/Player/Inputs.luau | Module de mouvemevent                             |
| `src/Client/UI/`              | Barre de stamina, prompts, joural/logs            |
| `src/Shared/Config/`          | Paramètres (vitesse, stamina max, cooldowns, etc) |
| `src/Shared/Utils`            | Scripts utilitaires partagés                      |
| `src/Server/Events/`          | Apparitions, triggers, scripts de fin             |
| `tests/`                      | Tests unitaires                                   |


## 🧠 **À prévoir côté scripting**

- **Gestion des inputs** : `UserInputService` pour `Shift`, `Ctrl`, `F`, `E`
- **État du joueur** : `isCrouching`, `isSprinting`, `stamina`, `hasFlashlight`
- **Effets dynamiques** : `TweenService`, `Lighting`, `SoundService`
- **Interactions** : `ProximityPrompt`, `ClickDetector`, ou système custom
- **Narration** : `ModuleScript` pour stocker les logs, dialogues, événements
<div style="margin: auto; text-align: center">

### State Machine

```mermaid
stateDiagram-v2
	A : Idle
	B : Walk
	C : Sprint
	D : Action
	
    [*] --> A
    [*] --> D: MouseLeftButton
	
    A --> B: WASD
    B --> A
    B --> C: Shift
    C --> A
```
</div>

--- 
##### *Credits to:* 
<a href="https://obsidian.md/" style="text-decoration: none; color: gold; margin-left: 10px;"> Obsidian </a> \
<a href="https://obsidian.md/" style="text-decoration: none; color: gold; margin-left: 10px;"> Mermaid </a>

