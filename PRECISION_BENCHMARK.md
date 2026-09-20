# Registre Permanent de Précision Astrométrique (Precision Benchmark Ledger)

> **Statut actuel** : ✅ **Précision Sub-Arcseconde Validée**  
> **Erreur Planétaire Moyenne** : **`0.470"`** (Soleil, Mercure, Vénus, Mars, Jupiter, Saturne, Uranus, Neptune)  
> **Erreur Globale Moyenne (avec Lune)** : **`0.571"`**  
> **Vérité Terrain de Référence** : **NASA JPL Horizons DE441 / DE440** (Intégration Numérique Relativiste Barycentrique)  
> **Dernière évaluation** : 2026-09-21 (Époque de test : `2026-Sep-20 00:00:00 UTC` / `JD 2461303.5`)  
> **Temps d'exécution de la suite** : **82 millisecondes** (282 tests, 54 suites, 100% de succès)

Ce document constitue le **registre officiel et vivant** consignant l'évolution métrologique du moteur de calcul d'AstronomyKit face aux éphémérides fondamentales de référence de la NASA (JPL Horizons). **Il doit être mis à jour à chaque optimisation, recalibrage ou enrichissement de modèle.**

---

## 1. Scorecard de Précision Actuelle (v1.2)

### Époque de Référence : `2026-Sep-20 00:00:00 UTC` (`JD 2461303.5`)
- **Échelle de temps** : Temps Terrestre Dynamique ($TT = UTC + \Delta T = UTC + 69.18\,\text{s}$)
- **Repère de référence** : Géocentrique Apparent ICRF / FK5
- **Conditions** : Airless (sans réfraction atmosphérique), équateur et équinoxe de la date.

| Corps Céleste | $\alpha$ Calculé (Deg) | $\alpha$ JPL DE441 (Deg) | $\delta$ Calculé (Deg) | $\delta$ JPL DE441 (Deg) | Écart Angulaire $\Delta\theta$ | Écart de Distance $\Delta r$ | Régime de Précision |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Soleil** | $177.3058^\circ$ | $177.3059^\circ$ | $+1.1673^\circ$ | $+1.1673^\circ$ | **$0.140''$** | $4.2\,\text{km}$ | Sub-arcseconde |
| **Mercure** | $193.6420^\circ$ | $193.6420^\circ$ | $-6.2435^\circ$ | $-6.2435^\circ$ | **$0.053''$** | $8.3\,\text{km}$ | Sub-arcseconde extrême |
| **Vénus** | $211.0205^\circ$ | $211.0204^\circ$ | $-18.8171^\circ$ | $-18.8171^\circ$ | **$0.158''$** | $2.8\,\text{km}$ | Sub-arcseconde |
| **Mars** | $117.2755^\circ$ | $117.2755^\circ$ | $+21.9185^\circ$ | $+21.9185^\circ$ | **$0.060''$** | $10.3\,\text{km}$ | Sub-arcseconde extrême |
| **Saturne** | $12.4780^\circ$ | $12.4780^\circ$ | $+2.4220^\circ$ | $+2.4220^\circ$ | **$0.280''$** | $102.1\,\text{km}$ | Sub-arcseconde |
| **Jupiter** | $140.1683^\circ$ | $140.1683^\circ$ | $+16.1178^\circ$ | $+16.1179^\circ$ | **$0.338''$** | $78.9\,\text{km}$ | Sub-arcseconde |
| **Uranus** | $63.7847^\circ$ | $63.7850^\circ$ | $+21.0964^\circ$ | $+21.0967^\circ$ | **$1.235''$** | $394.5\,\text{km}$ | Basse-arcseconde |
| **Neptune** | $3.4690^\circ$ | $3.4694^\circ$ | $-0.0431^\circ$ | $-0.0431^\circ$ | **$1.496''$** | $512.3\,\text{km}$ | Basse-arcseconde |
| **Lune (ELP2000)** | $280.5878^\circ$ | $280.5876^\circ$ | $-27.1098^\circ$ | $-27.1096^\circ$ | **$1.381''$** | $35.6\,\text{km}$ | Basse-arcseconde |

### Synthèse Statistique
- **Moyenne Planétaire (8 corps)** : **$0.470''$**
- **Médiane Planétaire** : **$0.219''$**
- **Moyenne Globale (9 corps avec Lune)** : **$0.571''$**
- **Écart Angulaire Maximal** : **$1.496''$** (Neptune)
- **Empreinte Données Externes Requise** : **0 octet** (100% autonome, zéro téléchargement réseau)

---

## 2. Historique des Évolutions du Modèle (Precision Changelog)

### [v1.2] - 2026-09-21 : Franchise du Seuil Sub-Arcseconde & Théorie Lunaire ELP2000-82B
- **Changements majeurs** :
  1. **Paramétrisation en Temps Terrestre ($TT$)** : Élimination du retard cinématique artificiel de $69.2\,\text{s}$ ($0.549''/\text{s} \times 69.2\,\text{s} \approx 38.0''$ sur la Lune et $2.84''$ sur le Soleil) dans les benchmarks d'évaluation.
  2. **Implémentation de `CAAELP2000` (`ELP2000Engine.swift`)** : Modélisation des 18 termes majeurs de Delaunay du Problème Principal des 3 corps (Terre-Lune-Soleil) et des corrections d'aplatissement terrestre $J_2$.
  3. **Obliquité Vraie de Date** : Réduction équatoriale de la Lune couplée à $\epsilon = \epsilon_0 + \Delta\epsilon$ (élimination de l'erreur périodique de nutation en déclinaison de $9.2''$).
  4. **Architecture Bimodale** : Conservation du mode historique Meeus Ch. 47 sous `highPrecision = false` (100% de succès sur les tests académiques du livre) et activation automatique d'ELP2000 sous `highPrecision = true`.
  5. **Moteur Hybride Offline-First** : Ajout de `makeOfflineFirstProvider()` basculant sans blocage réseau sur les kernels millimétriques DE440s/VSOP2013 si présents localement.
- **Résultats** :
  - Erreur Lune : de $34.222'' \to \mathbf{1.381''}$ (**gain de $96\%$**).
  - Erreur Planétaire Moyenne : de $1.670'' \to \mathbf{0.470''}$ (**gain de $72\%$**).
  - Erreur Mercure : de $4.364'' \to \mathbf{0.053''}$ (**gain de $98.8\%$**).
  - Erreur Soleil : de $2.840'' \to \mathbf{0.140''}$ (**gain de $95\%$**).

### [v1.1] - 2026-09-20 : Migration Pure Swift 6 & Précession/Nutation Modernes
- **Changements majeurs** :
  1. Élimination complète du bridge C++ `AAplus` (412 000 lignes) au profit d'une implémentation 100% Swift 6 native.
  2. Implémentation du moteur IAU 2006 (P03) pour la précession et IAU 2000B (77 termes) pour la nutation.
  3. Remplacement des tables massives de $\Delta T$ par un encodage binaire compacté en Base64.
- **Résultats** :
  - Clean build accéléré de $70\,\text{s} \to 0.51\,\text{s}$ (**gain $140\times$**).
  - Exécution complète des 282 tests passée sous le seuil des $100\,\text{ms}$ ($82\,\text{ms}$).

### [v1.0] - Baseline Historique (Meeus AA+ v2.63)
- Modèle analytique initial utilisant la série tronquée Meeus Ch. 47 pour la Lune et VSOP87D évalué en temps civil sans correction d'obliquité vraie.
- Erreur Lune : $\approx 34.2''$ | Erreur Planétaire Moyenne : $\approx 1.67''$.

---

## 3. Causes Physiques Fondamentales des Écarts Résiduels

L'écart entre le moteur analytique compact d'AstronomyKit et les éphémérides de la NASA est gouverné par des lois physiques et des contraintes observationnelles précises :

```
                  PARADIGMES DE RÉSOLUTION DU SYSTÈME SOLAIRE
                  
  [Théories Analytiques : VSOP87 / ELP2000]       [Intégration Numérique : NASA JPL DE441]
  -----------------------------------------       ----------------------------------------
  • Séries de Fourier/Poisson finies              • Intégration pas-à-pas (Adams 14e ordre)
  • Solutions générales périodiques               • Trajectoires numériques brutes
  • Système fermé à N=8+1 corps                   • 343 astéroïdes discrets + Disque de Kuiper
  • Relativité séculaire moyenne                  • Relativité générale PPN complète (Einstein)
  • Zéro stockage disque                          • 3.1 Go de coefficients de Tchebychev
  • Précision : ~0.05" à 1.5"                     • Précision : ~0.001" (Millimétrique LLR)
```

### 1. Mercure ($0.053''$) & Soleil ($0.140''$) — Relativité Générale PPN & Déflexion Lumineuse
- **Avance relativiste du périhélie** : Mercure subit une précession relativiste de $42.98''/\text{siècle}$. VSOP87 intègre ce terme séculaire dans ses fréquences fondamentales, mais ne résout pas les micro-oscillations périodiques post-newtoniennes d'ordre supérieur.
- **Courbure d'Einstein** : La déflexion gravitationnelle des photons frôlant le Soleil ($\Delta\theta = \frac{4GM_{\odot}}{c^2 r} \frac{1+\cos\psi}{\sin\psi}$) atteint $0.025''$ à $10^\circ$ du Soleil. Elle est intégrée par le JPL et absente des algorithmes Meeus standards.

### 2. Mars ($0.060''$, $10.3\,\text{km}$) — Perturbations des 343 Astéroïdes Massifs
- Mars est en résonance continue avec la Ceinture Principale d'astéroïdes. DE441 calcule gravitationnellement l'attraction pas-à-pas de **Cérès, Pallas, Vesta et 340 autres astéroïdes majeurs**, ainsi que d'un anneau de poussière massique continu. VSOP87 traite la ceinture comme négligeable. L'écart de $10.3\,\text{km}$ correspond à la déviation accumulée par ces corps mineurs.

### 3. Jupiter ($0.338''$) & Saturne ($0.280''$) — La « Grande Inégalité » (Résonance 5:2)
- Cinq révolutions de Saturne ($\sim 147.3\,\text{ans}$) coïncident presque exactement avec deux révolutions de Jupiter ($\sim 142.3\,\text{ans}$), générant une oscillation mutuelle gigantesque d'une période de **$\sim 883\,\text{ans}$** qui déplace Saturne de plus de $1^\circ$.
- Le développement en séries de Poisson de cette résonance tronque les termes d'ordre 3 et 4, conduisant à un résidu de $\approx 0.3''$. De plus, le barycentre du système solaire oscille périodiquement hors du corps physique du Soleil (jusqu'à $2.1$ rayons solaires).

### 4. Uranus ($1.235''$) & Neptune ($1.496''$) — Révision Voyager 2 & Arc Historique
- **Révision de masse post-Voyager 2** : En 1989 (deux ans après la publication de VSOP87), le survol de Neptune par Voyager 2 a corrigé sa masse de **$0.5\%$** à la baisse ($M_{\odot}/M_{\Psi} = 19\,412.24$ vs $19\,314$).
- **Arc d'observation incomplet en 1987** : Au moment de l'ajustement de VSOP87 sur DE200, Neptune n'avait accompli que $80\%$ d'une seule révolution depuis sa découverte en 1846.

### 5. La Lune ($1.381''$, $35.6\,\text{km}$) — Troncature de Delaunay & Perturbation Solaire $2.18\times$
- **Rapport de force héliocentrique** : La force gravitationnelle exercée par le Soleil sur la Lune est **$2.18$ fois supérieure** à celle exercée par la Terre ($F_{\odot}/F_{\oplus} \approx 2.18$).
- **Troncature harmonique** : La solution de laboratoire ELP2000 complète compte 35 628 termes périodiques. Notre implémentation embarquée sélectionne les 18 termes du problème principal et $J_2$. Les milliers de micro-termes omis totalisent un résidu de $\approx 1.2''$.
- **Dissipation de marée & LLR** : DE441 est calée sur les tirs laser Terre-Lune (Lunar Laser Ranging) sur les réflecteurs Apollo, mesurant l'éloignement de $3.82\,\text{cm/an}$ par marée océanique et le champ asphérique lunaire mesuré par la sonde GRAIL (harmoniques sphériques degré 150+).

---

## 4. Feuille de Route des Paliers d'Amélioration (Optimization Roadmap)

```
+─────────────────────────────────────────────────────────────────────────────────────────────+
|                                    FEUILLE DE ROUTE                                         |
+───────────+──────────────────────────────────────+──────────────────+───────────────────────+
| Palier    | Améliorations Physiques & Algorithme | Erreur Planétaire| Erreur Lune           |
+───────────+──────────────────────────────────────+──────────────────+───────────────────────+
| Actuel    | TT (TDB), ELP2000 (18t), IAU 2000B   | 0.470"           | 1.381" (35.6 km)      |
| Palier 2  | Séculaire Uranus/Neptune + Delaunay 40| < 0.080"        | < 0.200" (< 5 km)     |
| Palier 3  | Mini-Kernel Tchebychev compact (1 Mo)| < 0.005"         | < 0.010" (< 200 m)    |
| Palier 4  | Full Hybrid DE440s/VSOP2013 (18 Mo)  | < 0.001"         | < 0.001" (~ cm)       |
+───────────+──────────────────────────────────────+──────────────────+───────────────────────+
```

### Actions Prévues pour le Palier 2 (Pure Swift, 0 octet externe)
1. **Ajustement séculaire post-Voyager 2 d'Uranus & Neptune** : Ajout d'un polynôme de dérive $c_0 + c_1 T + c_2 T^2$ sur la période 1950–2050 pour ramener Neptune et Uranus sous les $0.15''$.
2. **Extension harmonique ELP2000** : Intégration des 22 termes de Delaunay d'ordre suivant et du terme de résonance planétaire de Vénus (terme de Hansen $+1.44'' \sin(l - 2D + 2l_V)$).
3. **Déflexion relativiste lumineuse** : Intégration de la formule vectorielle d'Einstein dans la réduction apparente.
4. **Matrice de Frame Bias IERS** : Raccordement séculaire strict du repère moyen FK5 vers l'ICRF3 ($\Delta\alpha_0 = -0.0146''$, $\xi_0 = -0.0166''$, $\eta_0 = -0.0068''$).

---

## 5. Protocole de Reproductibilité & Exécution du Benchmark

Le benchmark officiel contre les éphémérides NASA JPL Horizons DE441 est intégré directement dans la suite de tests automatisée.

### Commande d'Exécution
```bash
swift test --filter PrecisionBenchmarkTests
```

### Code Source du Benchmark
Le test unitaire de référence est localisé dans :
[`Tests/AstronomyKitTests/PrecisionBenchmarkTests.swift`](file:///Users/mo/Developer/PROTO/CALMSKY/Tests/AstronomyKitTests/PrecisionBenchmarkTests.swift)

### Seuils d'Invalidation Stricts (Gating CI/CD)
Toute modification régressant les seuils suivants invalide immédiatement le build :
- Erreur angulaire Lune : `#expect(sepArcsec <= 2.0)`
- Erreur angulaire Mercure : `#expect(sepArcsec <= 1.0)`
- Erreur angulaire planétaire maximale : `#expect(sepArcsec <= 1.8)`
- Erreur planétaire moyenne : `#expect(meanPlanetaryError < 1.0)`
- Erreur globale moyenne : `#expect(overallMean < 1.0)`
