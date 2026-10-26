enum AppLanguage {
  it('it', 'IT', 'Italiano'),
  en('en', 'EN', 'English'),
  es('es', 'ES', 'Español'),
  fr('fr', 'FR', 'Français'),
  de('de', 'DE', 'Deutsch'),
  pt('pt', 'PT', 'Português');

  final String code;
  final String shortLabel;
  final String displayName;
  const AppLanguage(this.code, this.shortLabel, this.displayName);

  static AppLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return AppLanguage.en;
    }
    final clean = code.toLowerCase();
    for (final lang in AppLanguage.values) {
      if (lang.code == clean) return lang;
    }
    return AppLanguage.en;
  }
}

/// Gestisce tutte le traduzioni del gioco nelle 6 lingue più popolari:
/// Italiano, Inglese, Spagnolo, Francese, Tedesco e Portoghese.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  String _t({
    required String it,
    required String en,
    required String es,
    required String fr,
    required String de,
    required String pt,
  }) {
    switch (lang) {
      case AppLanguage.it:
        return it;
      case AppLanguage.en:
        return en;
      case AppLanguage.es:
        return es;
      case AppLanguage.fr:
        return fr;
      case AppLanguage.de:
        return de;
      case AppLanguage.pt:
        return pt;
    }
  }

  String paletteName(String paletteId) {
    switch (paletteId) {
      case 'sumi_charcoal':
        return _t(
          it: 'Notte',
          en: 'Night',
          es: 'Noche',
          fr: 'Nuit',
          de: 'Nacht',
          pt: 'Noite',
        );
      case 'kyoto_matcha':
        return _t(
          it: 'Salvia',
          en: 'Sage',
          es: 'Salvia',
          fr: 'Sauge',
          de: 'Salbei',
          pt: 'Sálvia',
        );
      default:
        return _t(
          it: 'Sabbia',
          en: 'Sand',
          es: 'Arena',
          fr: 'Sable',
          de: 'Sand',
          pt: 'Areia',
        );
    }
  }

  String get subtitleClimbStick => _t(
        it: 'CLIMB & STICK • SCALA LA TORRE',
        en: 'CLIMB & STICK • SCALE THE TOWER',
        es: 'CLIMB & STICK • ESCALA LA TORRE',
        fr: 'CLIMB & STICK • GRIMPE LA TOUR',
        de: 'CLIMB & STICK • ERKLIMME DEN TURM',
        pt: 'CLIMB & STICK • ESCALE A TORRE',
      );

  String get metersUnit => _t(
        it: 'METRI',
        en: 'METERS',
        es: 'METROS',
        fr: 'MÈTRES',
        de: 'METER',
        pt: 'METROS',
      );

  String get levelShort => _t(
        it: 'LIV.',
        en: 'LVL',
        es: 'NIV.',
        fr: 'NIV.',
        de: 'LVL',
        pt: 'NÍV.',
      );

  String get modeLevelsTab => _t(
        it: 'SCALATA LIVELLI',
        en: 'LEVEL CLIMB',
        es: 'ESCALADA NIVELES',
        fr: 'ESCALADE NIVEAUX',
        de: 'LEVEL-AUFSTIEG',
        pt: 'ESCALADA NÍVEIS',
      );

  String modeDailyTab([int? issue]) => _t(
        it: 'TORRE DI OGGI',
        en: 'TODAY\'S TOWER',
        es: 'TORRE DE HOY',
        fr: 'TOUR DU JOUR',
        de: 'TAGESTURM',
        pt: 'TORRE DE HOJE',
      );

  String topRankBadgeLevels(int rank, int level) => _t(
        it: '🏆 CLASSIFICA #$rank • LIV. $level',
        en: '🏆 RANK #$rank • LVL $level',
        es: '🏆 RANKING #$rank • NIV. $level',
        fr: '🏆 CLASSEMENT #$rank • NIV. $level',
        de: '🏆 RANG #$rank • LVL $level',
        pt: '🏆 RANKING #$rank • NÍV. $level',
      );

  String topRankBadgeDaily(int rank, [int? issue]) => _t(
        it: '🏆 OGGI #$rank • TORRE DI OGGI',
        en: '🏆 TODAY #$rank • TODAY\'S TOWER',
        es: '🏆 HOY #$rank • TORRE DE HOY',
        fr: '🏆 JOUR #$rank • TOUR DU JOUR',
        de: '🏆 HEUTE #$rank • TAGESTURM',
        pt: '🏆 HOJE #$rank • TORRE DE HOJE',
      );

  String get maxLevelLabel => _t(
        it: 'LIVELLO MAX',
        en: 'MAX LEVEL',
        es: 'NIVEL MÁX',
        fr: 'NIVEAU MAX',
        de: 'MAX LEVEL',
        pt: 'NÍVEL MÁX',
      );

  String get goalHeightLabel => _t(
        it: 'ALTEZZA TORRE',
        en: 'TOWER HEIGHT',
        es: 'ALTURA TORRE',
        fr: 'HAUTEUR TOUR',
        de: 'TURMHÖHE',
        pt: 'ALTURA TORRE',
      );

  String get rankLabel => _t(
        it: 'CLASSIFICA',
        en: 'RANK',
        es: 'RANKING',
        fr: ' RANG',
        de: 'RANG',
        pt: 'RANKING',
      );

  String selectLevelLabel(int selected, int maxLvl) => _t(
        it: 'LIVELLO $selected / $maxLvl (+10m ogni 10 liv.)',
        en: 'LEVEL $selected / $maxLvl (+10m every 10 lvls)',
        es: 'NIVEL $selected / $maxLvl (+10m cada 10 niv.)',
        fr: 'NIVEAU $selected / $maxLvl (+10m tous les 10 niv.)',
        de: 'LEVEL $selected / $maxLvl (+10m alle 10 Lvl)',
        pt: 'NÍVEL $selected / $maxLvl (+10m a cada 10 nív.)',
      );

  String get heightGrowthHint => _t(
        it: '📏 Nuovi ostacoli a ogni livello • +10m ogni 10 livelli!',
        en: '📏 New obstacles each level • +10m every 10 levels!',
        es: '📏 Nuevos obstáculos cada nivel • ¡+10m cada 10 niveles!',
        fr: '📏 Nouveaux obstacles par niveau • +10m tous les 10 niveaux !',
        de: '📏 Neue Hindernisse pro Level • +10m alle 10 Level!',
        pt: '📏 Novos obstáculos a cada nível • +10m a cada 10 níveis!',
      );

  String recordTodayLabel(String dateStr) => _t(
        it: 'RECORD OGGI ($dateStr)',
        en: 'BEST TODAY ($dateStr)',
        es: 'RÉCORD HOY ($dateStr)',
        fr: 'RECORD JOUR ($dateStr)',
        de: 'REKORD HEUTE ($dateStr)',
        pt: 'RECORDE HOJE ($dateStr)',
      );

  String get streakLabel => _t(
        it: 'SERIE',
        en: 'STREAK',
        es: 'RACHA',
        fr: 'SÉRIE',
        de: 'SERIE',
        pt: 'SEQUÊNCIA',
      );

  String streakDays(int days) => _t(
        it: '$days GG',
        en: '$days D',
        es: '$days D',
        fr: '$days J',
        de: '$days T',
        pt: '$days D',
      );

  String get livesTodayLabel => _t(
        it: 'VITE OGGI',
        en: 'LIVES TODAY',
        es: 'VIDAS HOY',
        fr: 'VIES JOUR',
        de: 'LEBEN HEUTE',
        pt: 'VIDAS HOJE',
      );

  String get rule1Sticky => _t(
        it: 'Le piattaforme verdi INCOLLANO su tutti i lati e angoli: fermati e mira!',
        en: 'Green pads STICK on all sides & corners: stop and aim calmly!',
        es: 'Las plataformas verdes PEGAN en lados y esquinas: ¡apunta con calma!',
        fr: 'Les blocs verts COLLENT sur tous les côtés et coins : visez au calme !',
        de: 'Grüne Blöcke KLEBEN an allen Seiten & Ecken: Anhalten und zielen!',
        pt: 'Plataformas verdes COLAM em todos os lados e cantos: mire com calma!',
      );

  String get rule2Hazards => _t(
        it: 'Attento a piattaforme a tempo, laser a impulsi, respingenti e inchiostro!',
        en: 'Watch out for crumbling pads, pulse lasers, bumpers & rising ink!',
        es: '¡Cuidado con bloques frágiles, láseres, rebotadores y la tinta que sube!',
        fr: 'Attention aux blocs fragiles, lasers, bumpers et à l\'encre qui monte !',
        de: 'Achtung vor brüchigen Blöcken, Lasern, Bumpern & steigender Tinte!',
        pt: 'Cuidado com blocos frágeis, lasers, bumpers e a tinta subindo!',
      );

  String get rule3Charges => _t(
        it: 'Hai 3 lanci per salto (si ricaricano sempre sulle piattaforme).',
        en: 'You have 3 launches per jump (recharged on every sticky pad).',
        es: 'Tienes 3 lanzamientos por salto (se recargan en cada plataforma).',
        fr: '3 lancers par saut (rechargés sur chaque plateforme collante).',
        de: '3 Würfe pro Sprung (werden auf jeder Plattform aufgeladen).',
        pt: '3 lançamentos por salto (recarregam em cada plataforma).',
      );

  String playLevelBtn(int level, int meters) => _t(
        it: 'GIOCA LIVELLO $level (${meters}m)',
        en: 'PLAY LEVEL $level (${meters}m)',
        es: 'JUGAR NIVEL $level (${meters}m)',
        fr: 'JOUER NIVEAU $level (${meters}m)',
        de: 'SPIELE LEVEL $level (${meters}m)',
        pt: 'JOGAR NÍVEL $level (${meters}m)',
      );

  String playDailyBtn(int lives) {
    if (lives > 0) {
      return _t(
        it: 'GIOCA LA TORRE DI OGGI ($lives VITE)',
        en: 'PLAY TODAY\'S TOWER ($lives LIVES)',
        es: 'JUGAR TORRE DE HOY ($lives VIDAS)',
        fr: 'JOUER LA TOUR DU JOUR ($lives VIES)',
        de: 'SPIELE TAGESTURM ($lives LEBEN)',
        pt: 'JOGAR TORRE DE HOJE ($lives VIDAS)',
      );
    }
    return _t(
      it: 'ALLENAMENTO LIBERO SULLA TORRE DI OGGI',
      en: 'FREE PRACTICE ON TODAY\'S TOWER',
      es: 'PRÁCTICA LIBRE EN LA TORRE DE HOY',
      fr: 'ENTRAÎNEMENT LIBRE SUR LA TOUR DU JOUR',
      de: 'FREIES TRAINING AUF DEM TAGESTURM',
      pt: 'TREINO LIVRE NA TORRE DE HOJE',
    );
  }

  String playDailyImproveBtn(int lives) => _t(
        it: 'MIGLIORA RECORD GIORNALIERO ($lives VITE)',
        en: 'IMPROVE DAILY RECORD ($lives LIVES)',
        es: 'MEJORAR RÉCORD DIARIO ($lives VIDAS)',
        fr: 'AMÉLIORER LE RECORD DU JOUR ($lives VIES)',
        de: 'TAGESTURM-REKORD VERBESSERN ($lives LEBEN)',
        pt: 'MELHORAR RECORDE DIÁRIO ($lives VIDAS)',
      );

  String improveDailyRecordBtn(int lives) => _t(
        it: 'MIGLIORA RECORD ($lives VITE RIMASTE)',
        en: 'IMPROVE RECORD ($lives LIVES LEFT)',
        es: 'MEJORAR RÉCORD ($lives VIDAS RESTANTES)',
        fr: 'AMÉLIORER LE RECORD ($lives VIES RESTANTES)',
        de: 'REKORD VERBESSERN ($lives LEBEN ÜBRIG)',
        pt: 'MELHORAR RECORDE ($lives VIDAS RESTANTES)',
      );

  String leaderboardLevelsBtn(int rank) => _t(
        it: 'CLASSIFICA LIVELLI (SEI #$rank)',
        en: 'LEVELS LEADERBOARD (YOU ARE #$rank)',
        es: 'CLASIFICACIÓN NIVELES (ERES #$rank)',
        fr: 'CLASSEMENT NIVEAUX (TU ES #$rank)',
        de: 'LEVEL-RANGLISTE (DU BIST #$rank)',
        pt: 'RANKING DE NÍVEIS (VOCÊ É #$rank)',
      );

  String leaderboardDailyBtn(int rank) => _t(
        it: 'CLASSIFICA TORRE DI OGGI (SEI #$rank)',
        en: 'TODAY\'S TOWER LEADERBOARD (YOU ARE #$rank)',
        es: 'CLASIFICACIÓN TORRE DE HOY (ERES #$rank)',
        fr: 'CLASSEMENT TOUR DU JOUR (TU ES #$rank)',
        de: 'TAGESTURM-RANGLISTE (DU BIST #$rank)',
        pt: 'RANKING TORRE DE HOJE (VOCÊ É #$rank)',
      );

  String get unlockExtraLifeBtn => _t(
        it: 'SBLOCCA +1 VITA (VIDEO)',
        en: 'UNLOCK +1 LIFE (VIDEO)',
        es: 'DESBLOQUEAR +1 VIDA (VÍDEO)',
        fr: 'DÉBLOQUER +1 VIE (VIDÉO)',
        de: '+1 LEBEN FREISCHALTEN (VIDEO)',
        pt: 'DESBLOQUEAR +1 VIDA (VÍDEO)',
      );

  String get unlockExtraLifeRewardTitle => _t(
        it: 'Ottieni +1 Vita Oggi',
        en: 'Get +1 Extra Life Today',
        es: 'Consigue +1 Vida Hoy',
        fr: 'Obtenir +1 Vie Aujourd\'hui',
        de: 'Hol dir heute +1 Leben',
        pt: 'Ganhe +1 Vida Hoje',
      );

  String get leaderboardLevelsTitle => _t(
        it: 'CLASSIFICA SCALATORI (LIVELLI)',
        en: 'CLIMBERS LEADERBOARD (LEVELS)',
        es: 'CLASIFICACIÓN ESCALADORES (NIVELES)',
        fr: 'CLASSEMENT GRIMPEURS (NIVEAUX)',
        de: 'KLETTERER-RANGLISTE (LEVEL)',
        pt: 'RANKING ESCALADORES (NÍVEIS)',
      );

  String leaderboardDailyTitle([int? issue]) => _t(
        it: 'CLASSIFICA TORRE DI OGGI',
        en: 'TODAY\'S TOWER LEADERBOARD',
        es: 'CLASIFICACIÓN TORRE DE HOY',
        fr: 'CLASSEMENT TOUR DU JOUR',
        de: 'TAGESTURM-RANGLISTE',
        pt: 'RANKING TORRE DE HOJE',
      );

  String get leaderboardLevelsSub => _t(
        it: 'Ordine: Livello • % Completamento • Minor numero di rimbalzi',
        en: 'Ranked by: Level • % Completion • Fewest bounces',
        es: 'Orden: Nivel • % Completado • Menos rebotes',
        fr: 'Ordre : Niveau • % Progression • Moins de rebonds',
        de: 'Wertung: Level • % Fortschritt • Wenigste Abpraller',
        pt: 'Ordem: Nível • % Conclusão • Menos rebotes',
      );

  String get leaderboardDailySub => _t(
        it: 'Classifica 24h sulla Torre di Oggi (100m) • A parità di metri vince chi fa meno rimbalzi!',
        en: '24h Today\'s Tower (100m) ranking • Fewest bounces wins on tied height!',
        es: 'Ranking 24h en la Torre de Hoy (100m) • ¡A igual altura gana quien haga menos rebotes!',
        fr: 'Classement 24h Tour du Jour (100m) • À hauteur égale, moins de rebonds l\'emporte !',
        de: '24h-Rangliste Tagesturm (100m) • Bei gleicher Höhe gewinnen weniger Abpraller!',
        pt: 'Ranking 24h na Torre de Hoje (100m) • Na mesma altura, vence quem tiver menos rebotes!',
      );

  String get bouncesShort => _t(
        it: 'rimb.',
        en: 'bnc',
        es: 'reb.',
        fr: 'reb.',
        de: 'Abpr.',
        pt: 'reb.',
      );

  String get nicknameHint => _t(
        it: 'Il tuo nome in classifica...',
        en: 'Your leaderboard name...',
        es: 'Tu nombre en el ranking...',
        fr: 'Votre pseudo au classement...',
        de: 'Dein Name in der Rangliste...',
        pt: 'Seu nome no ranking...',
      );

  String get saveBtn => _t(
        it: 'SALVA',
        en: 'SAVE',
        es: 'GUARDAR',
        fr: 'SAUVER',
        de: 'SPEICHERN',
        pt: 'SALVAR',
      );

  String get youTag => _t(
        it: 'TU',
        en: 'YOU',
        es: 'TÚ',
        fr: 'TOI',
        de: 'DU',
        pt: 'VOCÊ',
      );

  // HUD & In-Game Canvas
  String get hudDailyBadge => _t(
        it: 'TORRE OGGI',
        en: 'TODAY',
        es: 'HOY',
        fr: 'JOUR',
        de: 'HEUTE',
        pt: 'HOJE',
      );

  String get hudLaunchesLabel => _t(
        it: 'LANCI',
        en: 'SLINGS',
        es: 'TIROS',
        fr: 'TIRS',
        de: 'WÜRFE',
        pt: 'LANÇOS',
      );

  String goalLineMarker(int m) => _t(
        it: '🏁 VETTA TORRE ${m}m',
        en: '🏁 TOWER TOP ${m}m',
        es: '🏁 CIMA TORRE ${m}m',
        fr: '🏁 SOMMET ${m}m',
        de: '🏁 TURMSPITZE ${m}m',
        pt: '🏁 TOPO ${m}m',
      );

  String dangerZoneMarker(int m) => _t(
        it: '⚠️ ZONA CRITICA (${m}m)',
        en: '⚠️ DANGER ZONE (${m}m)',
        es: '⚠️ ZONA CRÍTICA (${m}m)',
        fr: '⚠️ ZONE CRITIQUE (${m}m)',
        de: '⚠️ GEFAHRENZONE (${m}m)',
        pt: '⚠️ ZONA CRÍTICA (${m}m)',
      );

  String get floatingBoost => _t(
        it: '+SLANCIO!',
        en: '+BOOST!',
        es: '¡+IMPULSO!',
        fr: '+BOOST !',
        de: '+SCHUB!',
        pt: '+IMPULSO!',
      );

  String get floatingShield => _t(
        it: 'SCUDO!',
        en: 'SHIELD!',
        es: '¡ESCUDO!',
        fr: 'BOUCLIER !',
        de: 'SCHILD!',
        pt: 'ESCUDO!',
      );

  String get floatingBumper => _t(
        it: 'RIMBALZO!',
        en: 'BOUNCE!',
        es: '¡REBOTE!',
        fr: 'REBOND !',
        de: 'ABPRALL!',
        pt: 'REBOTE!',
      );

  // Game Over / Victory Overlay
  String get newLevelUnlockedBadge => _t(
        it: '★ NUOVO LIVELLO SBLOCCATO!',
        en: '★ NEW LEVEL UNLOCKED!',
        es: '★ ¡NUEVO NIVEL DESBLOQUEADO!',
        fr: '★ NOUVEAU NIVEAU DÉBLOQUÉ !',
        de: '★ NEUES LEVEL FREIGESCHALTET!',
        pt: '★ NOVO NÍVEL DESBLOQUEADO!',
      );

  String get newPersonalRecordBadge => _t(
        it: '★ NUOVO RECORD PERSONALE!',
        en: '★ NEW PERSONAL RECORD!',
        es: '★ ¡NUEVO RÉCORD PERSONAL!',
        fr: '★ NOUVEAU RECORD PERSONNEL !',
        de: '★ NEUER PERSÖNLICHER REKORD!',
        pt: '★ NOVO RECORDE PESSOAL!',
      );

  String levelWonTitle(int level) => _t(
        it: 'LIVELLO $level VINTO!',
        en: 'LEVEL $level CLEARED!',
        es: '¡NIVEL $level SUPERADO!',
        fr: 'NIVEAU $level RÉUSSI !',
        de: 'LEVEL $level GESCHAFFT!',
        pt: 'NÍVEL $level VENCIDO!',
      );

  String get dailyTowerCompletedTitle => _t(
        it: 'TORRE COMPLETATA!',
        en: 'TOWER COMPLETED!',
        es: '¡TORRE COMPLETADA!',
        fr: 'TOUR TERMINÉE !',
        de: 'TURM GESCHAFFT!',
        pt: 'TORRE CONCLUÍDA!',
      );

  String fellAtTitle(String meters) => _t(
        it: 'CADUTO A ${meters}m',
        en: 'FELL AT ${meters}m',
        es: 'CAÍSTE A ${meters}m',
        fr: 'TOMBÉ À ${meters}m',
        de: 'GEFALLEN BEI ${meters}m',
        pt: 'CAIU EM ${meters}m',
      );

  String get gradeLabel => _t(
        it: 'GRADO',
        en: 'GRADE',
        es: 'GRADO',
        fr: 'RANG',
        de: 'NOTE',
        pt: 'NOTA',
      );

  String motivatingSubtitle({
    required double meters,
    required double targetMeters,
    required bool isVictory,
    required bool isLevelMode,
    required int nextLevel,
  }) {
    if (isVictory) {
      if (isLevelMode) {
        return _t(
          it: '🎉 Livello $nextLevel sbloccato! Scalata impeccabile!',
          en: '🎉 Level $nextLevel unlocked! Flawless climb!',
          es: '🎉 ¡Nivel $nextLevel desbloqueado! ¡Escalada impecable!',
          fr: '🎉 Niveau $nextLevel débloqué ! Ascension parfaite !',
          de: '🎉 Level $nextLevel freigeschaltet! Perfekter Aufstieg!',
          pt: '🎉 Nível $nextLevel desbloqueado! Escalada perfeita!',
        );
      }
      return _t(
        it: '🏆 Hai conquistato la vetta della Torre di Oggi!',
        en: '🏆 You conquered the top of Today\'s Tower!',
        es: '🏆 ¡Conquistaste la cima de la Torre de Hoy!',
        fr: '🏆 Vous avez conquis le sommet de la Tour du Jour !',
        de: '🏆 Du hast die Spitze des Tagesturms erobert!',
        pt: '🏆 Você conquistou o topo da Torre de Hoje!',
      );
    }
    final remaining = (targetMeters - meters).clamp(0.0, targetMeters).toStringAsFixed(1);
    final ratio = meters / targetMeters;
    if (ratio >= 0.80) {
      return _t(
        it: '🔥 A un soffio dalla vetta! Mancavano solo ${remaining}m!',
        en: '🔥 So close to the top! Only ${remaining}m left!',
        es: '🔥 ¡A un paso de la cima! ¡Solo faltaban ${remaining}m!',
        fr: '🔥 Si près du sommet ! Il ne manquait que ${remaining}m !',
        de: '🔥 So nah an der Spitze! Nur noch ${remaining}m!',
        pt: '🔥 Tão perto do topo! Faltavam apenas ${remaining}m!',
      );
    }
    if (ratio >= 0.50) {
      return _t(
        it: '⚡ Oltre metà torre superata! Ancora ${remaining}m alla vetta!',
        en: '⚡ Past halfway up the tower! ${remaining}m to the top!',
        es: '⚡ ¡Más de media torre superada! ¡A ${remaining}m de la cima!',
        fr: '⚡ Plus de la moitié franchie ! Encore ${remaining}m !',
        de: '⚡ Über die Hälfte geschafft! Noch ${remaining}m bis oben!',
        pt: '⚡ Mais da metade superada! Faltam ${remaining}m!',
      );
    }
    return _t(
      it: '🎯 Attaccati anche ai lati o agli angoli delle piattaforme verdi!',
      en: '🎯 Stick to any side or corner of the green platforms to aim!',
      es: '🎯 ¡Pégate a cualquier lado o esquina de las plataformas verdes!',
      fr: '🎯 Collez-vous sur n\'importe quel côté ou coin des blocs verts !',
      de: '🎯 Klebe dich an jede Seite oder Ecke der grünen Plattformen!',
      pt: '🎯 Cole em qualquer lado ou canto das plataformas verdes!',
    );
  }

  String get towerProgressLabel => _t(
        it: 'AVANZAMENTO TORRE',
        en: 'TOWER PROGRESS',
        es: 'PROGRESO TORRE',
        fr: 'PROGRESSION TOUR',
        de: 'TURM-FORTSCHRITT',
        pt: 'PROGRESSO TORRE',
      );

  String get timeLabel => _t(
        it: 'TEMPO',
        en: 'TIME',
        es: 'TIEMPO',
        fr: 'TEMPS',
        de: 'ZEIT',
        pt: 'TEMPO',
      );

  String get bouncesLabel => _t(
        it: 'SPONDE',
        en: 'BOUNCES',
        es: 'REBOTES',
        fr: 'REBONDS',
        de: 'ABPRALLER',
        pt: 'REBOTES',
      );

  String globalRankSummary(int rank, bool isLevelMode, int levelOrIssue) {
    if (isLevelMode) {
      return _t(
        it: '🏆 Classifica Livelli: #$rank (Max Liv. $levelOrIssue)',
        en: '🏆 Levels Rank: #$rank (Max Lvl $levelOrIssue)',
        es: '🏆 Ranking Niveles: #$rank (Niv. Máx $levelOrIssue)',
        fr: '🏆 Classement Niveaux : #$rank (Niv. Max $levelOrIssue)',
        de: '🏆 Level-Rang: #$rank (Max Lvl $levelOrIssue)',
        pt: '🏆 Ranking Níveis: #$rank (Nív. Máx $levelOrIssue)',
      );
    }
    return _t(
      it: '🏆 Classifica Torre di Oggi: #$rank',
      en: '🏆 Today\'s Tower Rank: #$rank',
      es: '🏆 Ranking Torre de Hoy: #$rank',
      fr: '🏆 Classement Tour du Jour : #$rank',
      de: '🏆 Tagesturm-Rang: #$rank',
      pt: '🏆 Ranking Torre de Hoje: #$rank',
    );
  }

  String reviveWithShieldBtn(String meters) => _t(
        it: 'CONTINUA DA ${meters}m CON SCUDO (VIDEO)',
        en: 'CONTINUE FROM ${meters}m WITH SHIELD (VIDEO)',
        es: 'CONTINUAR DESDE ${meters}m CON ESCUDO (VÍDEO)',
        fr: 'CONTINUER DE ${meters}m AVEC BOUCLIER (VIDÉO)',
        de: 'WEITER AB ${meters}m MIT SCHILD (VIDEO)',
        pt: 'CONTINUAR DE ${meters}m COM ESCUDO (VÍDEO)',
      );

  String get shareBtn => _t(
        it: 'CONDIVIDI',
        en: 'SHARE',
        es: 'COMPARTIR',
        fr: 'PARTAGER',
        de: 'TEILEN',
        pt: 'COMPARTILHAR',
      );

  String get shareCopiedSnack => _t(
        it: 'Sfida copiata! Incollala e mandala a un amico!',
        en: 'Challenge copied! Paste and send it to a friend!',
        es: '¡Reto copiado! ¡Pégalo y envíalo a un amigo!',
        fr: 'Défi copié ! Collez-le et envoyez-le à un ami !',
        de: 'Herausforderung kopiert! Teile sie mit Freunden!',
        pt: 'Desafio copiado! Cole e envie para um amigo!',
      );

  String nextLevelBtn(int nextLvl) => _t(
        it: 'LIVELLO $nextLvl ▶',
        en: 'LEVEL $nextLvl ▶',
        es: 'NIVEL $nextLvl ▶',
        fr: 'NIVEAU $nextLvl ▶',
        de: 'LEVEL $nextLvl ▶',
        pt: 'NÍVEL $nextLvl ▶',
      );

  String get retryNowBtn => _t(
        it: 'RIPROVA SUBITO',
        en: 'RETRY NOW',
        es: 'REINTENTAR',
        fr: 'RÉESSAYER',
        de: 'NOCHMAL',
        pt: 'TENTAR DE NOVO',
      );

  String get backToMenuBtn => _t(
        it: 'Torna al Menu Principale',
        en: 'Back to Main Menu',
        es: 'Volver al Menú Principal',
        fr: 'Retour au Menu Principal',
        de: 'Zurück zum Hauptmenü',
        pt: 'Voltar ao Menu Principal',
      );

  String get shareChallengeFooter => _t(
        it: 'Riesci a scalare la torre di oggi?',
        en: 'Can you climb today\'s tower?',
        es: '¿Puedes escalar la torre de hoy?',
        fr: 'Peux-tu grimper la tour du jour ?',
        de: 'Schaffst du den heutigen Turm?',
        pt: 'Consegue escalar a torre de hoje?',
      );

  // --- PROFILO GIOCATORE & ICONE SBLOCCABILI ---
  String get profileTitle => _t(
        it: 'PROFILO GIOCATORE',
        en: 'PLAYER PROFILE',
        es: 'PERFIL DEL JUGADOR',
        fr: 'PROFIL DU JOUEUR',
        de: 'SPIELERPROFIL',
        pt: 'PERFIL DO JOGADOR',
      );

  String get editNameTooltip => _t(
        it: 'Modifica Nome',
        en: 'Edit Name',
        es: 'Editar Nombre',
        fr: 'Modifier le Nom',
        de: 'Name bearbeiten',
        pt: 'Editar Nome',
      );

  String get saveNameBtn => _t(
        it: 'SALVA',
        en: 'SAVE',
        es: 'GUARDAR',
        fr: 'ENREGISTRER',
        de: 'SPEICHERN',
        pt: 'SALVAR',
      );

  String get statsHeader => _t(
        it: 'STATISTICHE DELLA SCALATA',
        en: 'CLIMBING STATISTICS',
        es: 'ESTADÍSTICAS DE ESCALADA',
        fr: 'STATISTIQUES DE GRIMPE',
        de: 'KLETTER-STATISTIKEN',
        pt: 'ESTATÍSTICAS DA ESCALADA',
      );

  String get iconsHeader => _t(
        it: 'ICONE PROFILO & AVATAR',
        en: 'PROFILE ICONS & AVATARS',
        es: 'ICONOS DE PERFIL Y AVATARES',
        fr: 'ICÔNES DE PROFIL & AVATARS',
        de: 'PROFILSYMBOLE & AVATARE',
        pt: 'ÍCONES DE PERFIL E AVATARES',
      );

  String get tabStats => _t(
        it: 'STATISTICHE',
        en: 'STATS',
        es: 'ESTADÍSTICAS',
        fr: 'STATS',
        de: 'STATISTIK',
        pt: 'ESTATÍSTICAS',
      );

  String get tabIcons => _t(
        it: 'ICONE',
        en: 'ICONS',
        es: 'ICONOS',
        fr: 'ICÔNES',
        de: 'SYMBOLE',
        pt: 'ÍCONES',
      );

  String get tabSkins => _t(
        it: 'SKIN SFERA',
        en: 'BALL SKINS',
        es: 'SKINS BOLA',
        fr: 'SKINS BALLE',
        de: 'BALL-SKINS',
        pt: 'SKINS BOLA',
      );

  String get equippedBadge => _t(
        it: 'IN USO',
        en: 'EQUIPPED',
        es: 'EN USO',
        fr: 'ÉQUIPÉ',
        de: 'AKTIV',
        pt: 'EM USO',
      );

  String get equipBtn => _t(
        it: 'USA',
        en: 'EQUIP',
        es: 'USAR',
        fr: 'UTILISER',
        de: 'WÄHLEN',
        pt: 'USAR',
      );

  String get unlockedLabel => _t(
        it: 'SBLOCCATO',
        en: 'UNLOCKED',
        es: 'DESBLOQUEADO',
        fr: 'DÉBLOQUÉ',
        de: 'FREIGESCHALTET',
        pt: 'DESBLOQUEADO',
      );

  String get totalBouncesStat => _t(
        it: 'Rimbalzi Totali',
        en: 'Total Bounces',
        es: 'Rebotes Totales',
        fr: 'Rebonds Totaux',
        de: 'Gesamtsprünge',
        pt: 'Pulos Totais',
      );

  String get dayStreakStat => _t(
        it: 'Streak Giorni',
        en: 'Day Streak',
        es: 'Racha de Días',
        fr: 'Série de Jours',
        de: 'Tage-Streak',
        pt: 'Sequência de Dias',
      );

  String get levelFirstPlaceStat => _t(
        it: '#1 Scalata Livelli',
        en: '#1 Levels Leaderboard',
        es: '#1 Clasif. Niveles',
        fr: '#1 Classement Niveaux',
        de: '#1 Level-Rangliste',
        pt: '#1 Ranking Níveis',
      );

  String get dailyFirstPlaceStat => _t(
        it: '#1 Torre del Giorno',
        en: '#1 Daily Tower',
        es: '#1 Torre del Día',
        fr: '#1 Tour du Jour',
        de: '#1 Tagesturm',
        pt: '#1 Torre do Dia',
      );

  String get dailyTop3Stat => _t(
        it: 'Podi Top 3 Giornalieri',
        en: 'Daily Top 3 Podiums',
        es: 'Podios Top 3 Diarios',
        fr: 'Podiums Top 3 du Jour',
        de: 'Tägliche Top-3-Podestplätze',
        pt: 'Pódios Top 3 Diários',
      );

  String get totalDailyWonStat => _t(
        it: 'Torri Giornaliere Vinte',
        en: 'Daily Towers Completed',
        es: 'Torres Diarias Ganadas',
        fr: 'Tours du Jour Réussies',
        de: 'Tagestürme Bezwingt',
        pt: 'Torres Diárias Concluídas',
      );

  String get highestLevelStat => _t(
        it: 'Livello Più Alto',
        en: 'Highest Level',
        es: 'Nivel Más Alto',
        fr: 'Plus Haut Niveau',
        de: 'Höchstes Level',
        pt: 'Nível Mais Alto',
      );

  String get totalMetersStat => _t(
        it: 'Metri Totali Scalati',
        en: 'Total Meters Climbed',
        es: 'Metros Totales Escalados',
        fr: 'Mètres Totaux Grimpés',
        de: 'Gekletterte Meter Gesamt',
        pt: 'Metros Totais Escalados',
      );

  String get totalRunsStat => _t(
        it: 'Partite Totali',
        en: 'Total Runs',
        es: 'Partidas Totales',
        fr: 'Parties Totales',
        de: 'Gesamte Runden',
        pt: 'Partidas Totais',
      );

  // Nomi Icone Profilo
  String get iconInkDropName => _t(
        it: 'Goccia Zen',
        en: 'Zen Drop',
        es: 'Gota Zen',
        fr: 'Goutte Zen',
        de: 'Zen-Tropfen',
        pt: 'Gota Zen',
      );

  String get iconSpiritOrbName => _t(
        it: 'Sfera Celeste',
        en: 'Spirit Orb',
        es: 'Orbe Celestial',
        fr: 'Orbe Céleste',
        de: 'Himmelskugel',
        pt: 'Esfera Celestial',
      );

  String get iconZenBrushName => _t(
        it: 'Pennello Maestro',
        en: 'Master Brush',
        es: 'Pincel Maestro',
        fr: 'Pinceau Maître',
        de: 'Meisterpinsel',
        pt: 'Pincel Mestre',
      );

  String get iconMatchaLeafName => _t(
        it: 'Foglia Matcha',
        en: 'Matcha Leaf',
        es: 'Hoja Matcha',
        fr: 'Feuille Matcha',
        de: 'Matchablatt',
        pt: 'Folha Matcha',
      );

  String get iconShinobiSealName => _t(
        it: 'Sigillo Shinobi',
        en: 'Shinobi Seal',
        es: 'Sello Shinobi',
        fr: 'Sceau Shinobi',
        de: 'Shinobi-Siegel',
        pt: 'Selo Shinobi',
      );

  String get iconBambooGuardName => _t(
        it: 'Guardiano Bambù',
        en: 'Bamboo Guard',
        es: 'Guardián Bambú',
        fr: 'Gardien Bambou',
        de: 'Bambuswächter',
        pt: 'Guardião Bambu',
      );

  String get iconPaperCraneName => _t(
        it: 'Gru Origami',
        en: 'Paper Crane',
        es: 'Grulla Origami',
        fr: 'Grue Origami',
        de: 'Origami-Kranich',
        pt: 'Tsuru Origami',
      );

  String get iconDragonSpiritName => _t(
        it: 'Spirito Dragone',
        en: 'Dragon Spirit',
        es: 'Espíritu Dragón',
        fr: 'Esprit Dragon',
        de: 'Drachengeist',
        pt: 'Espírito Dragão',
      );

  String get iconDailyPodiumName => _t(
        it: 'Podio del Giorno',
        en: 'Daily Podium',
        es: 'Podio del Día',
        fr: 'Podium du Jour',
        de: 'Tages-Podest',
        pt: 'Pódio do Dia',
      );

  String get iconEliteSilverName => _t(
        it: 'Argento d\'Élite',
        en: 'Elite Silver',
        es: 'Plata Élite',
        fr: 'Argent d\'Élite',
        de: 'Elite-Silber',
        pt: 'Prata de Elite',
      );

  String get iconGoldCrownName => _t(
        it: 'Corona Campione',
        en: 'Champion Crown',
        es: 'Corona Campeón',
        fr: 'Couronne Champion',
        de: 'Meisterkrone',
        pt: 'Coroa Campeão',
      );

  String get iconBounceMasterName => _t(
        it: 'Maestro Rimbalzi',
        en: 'Bounce Master',
        es: 'Maestro Rebote',
        fr: 'Maître Rebonds',
        de: 'Sprungmeister',
        pt: 'Mestre dos Pulos',
      );

  // Requisiti di Sblocco Icone
  String get iconDefaultReq => _t(
        it: 'Disponibile dall\'inizio',
        en: 'Available from the start',
        es: 'Disponible desde el inicio',
        fr: 'Disponible dès le début',
        de: 'Von Beginn an verfügbar',
        pt: 'Disponível desde o início',
      );

  String iconReachLevelReq(int lvl) => _t(
        it: 'Raggiungi il Livello $lvl',
        en: 'Reach Level $lvl',
        es: 'Alcanza el Nivel $lvl',
        fr: 'Atteins le Niveau $lvl',
        de: 'Erreiche Level $lvl',
        pt: 'Alcance o Nível $lvl',
      );

  String iconTop3Req(int times) => _t(
        it: times == 1
            ? 'Entra nella Top 3 Giornaliera'
            : 'Entra $times volte nella Top 3 Giornaliera',
        en: times == 1
            ? 'Finish in Daily Top 3'
            : 'Finish in Daily Top 3 ($times times)',
        es: times == 1
            ? 'Llega al Top 3 Diario'
            : 'Llega al Top 3 Diario ($times veces)',
        fr: times == 1
            ? 'Termine dans le Top 3 du Jour'
            : 'Termine dans le Top 3 du Jour ($times fois)',
        de: times == 1
            ? 'Erreiche die tägliche Top 3'
            : 'Erreiche $times Mal die tägliche Top 3',
        pt: times == 1
            ? 'Chegue ao Top 3 Diário'
            : 'Chegue ao Top 3 Diário ($times vezes)',
      );

  String iconDailyFirstReq(int times) => _t(
        it: times == 1
            ? 'Conquista il 1° Posto Giornaliero'
            : 'Conquista il 1° Posto Giornaliero ($times volte)',
        en: times == 1
            ? 'Win 1st Place in Daily Tower'
            : 'Win 1st Place in Daily Tower ($times times)',
        es: times == 1
            ? 'Gana el 1.º Lugar en la Torre Diaria'
            : 'Gana el 1.º Lugar en la Torre Diaria ($times veces)',
        fr: times == 1
            ? 'Décroche la 1ère Place du Jour'
            : 'Décroche la 1ère Place du Jour ($times fois)',
        de: times == 1
            ? 'Erobere Platz 1 im Tagesturm'
            : 'Erobere Platz 1 im Tagesturm ($times Mal)',
        pt: times == 1
            ? 'Conquiste o 1º Lugar na Torre Diária'
            : 'Conquiste o 1º Lugar na Torre Diária ($times vezes)',
      );

  String iconBouncesReq(int count) => _t(
        it: 'Esegui $count rimbalzi totali',
        en: 'Perform $count total bounces',
        es: 'Realiza $count rebotes totales',
        fr: 'Effectue $count rebonds au total',
        de: 'Mache insgesamt $count Sprünge',
        pt: 'Faça $count pulos no total',
      );

  // Titoli Onorifici
  String get titleDailyChampion => _t(
        it: 'Campione del Giorno 👑',
        en: 'Daily Champion 👑',
        es: 'Campeón del Día 👑',
        fr: 'Champion du Jour 👑',
        de: 'Tages-Champion 👑',
        pt: 'Campeão do Dia 👑',
      );

  String get titleLegend => _t(
        it: 'Leggenda Risograph 🐉',
        en: 'Risograph Legend 🐉',
        es: 'Leyenda Risograph 🐉',
        fr: 'Légende Risograph 🐉',
        de: 'Risograph-Legende 🐉',
        pt: 'Lenda Risograph 🐉',
      );

  String get titleBounceMaster => _t(
        it: 'Maestro del Rimbalzo ⚡',
        en: 'Bounce Master ⚡',
        es: 'Maestro del Salto ⚡',
        fr: 'Maître du Rebond ⚡',
        de: 'Meisterspringer ⚡',
        pt: 'Mestre do Pulo ⚡',
      );

  String get titleRisographSentinel => _t(
        it: 'Sentinella della Torre 🛡️',
        en: 'Tower Sentinel 🛡️',
        es: 'Centinela de la Torre 🛡️',
        fr: 'Sentinelle de la Tour 🛡️',
        de: 'Turmwächter 🛡️',
        pt: 'Sentinela da Torre 🛡️',
      );

  String get titleRisingClimber => _t(
        it: 'Scalatore Promettente 🍃',
        en: 'Rising Climber 🍃',
        es: 'Escalador Prometedor 🍃',
        fr: 'Grimpeur Prometteur 🍃',
        de: 'Aufstrebender Kletterer 🍃',
        pt: 'Escalador Promissor 🍃',
      );

  String get titleInkNovice => _t(
        it: 'Scalatore d\'Inchiostro 💧',
        en: 'Ink Climber 💧',
        es: 'Escalador de Tinta 💧',
        fr: 'Grimpeur d\'Encre 💧',
        de: 'Tuschekletterer 💧',
        pt: 'Escalador de Tinta 💧',
      );

  // --- SKIN DELLA SFERA ---
  String get skinsTitle => _t(
        it: 'SKIN DELLA SFERA',
        en: 'BALL SKINS',
        es: 'SKINS DE LA BOLA',
        fr: 'SKINS DE LA BALLE',
        de: 'BALL-SKINS',
        pt: 'SKINS DA BOLA',
      );

  String get skinsHeader => _t(
        it: 'PERSONALIZZA LA TUA SFERA',
        en: 'CUSTOMIZE YOUR BALL',
        es: 'PERSONALIZA TU BOLA',
        fr: 'PERSONNALISE TA BALLE',
        de: 'PASSE DEINEN BALL AN',
        pt: 'PERSONALIZE SUA BOLA',
      );

  String get openStudioBtn => _t(
        it: 'Studio Animato 🎨',
        en: 'Animated Studio 🎨',
        es: 'Estudio Animado 🎨',
        fr: 'Studio Animé 🎨',
        de: 'Animationsstudio 🎨',
        pt: 'Estúdio Animado 🎨',
      );

  String skinReachLevelReq(int lvl) => _t(
        it: 'Raggiungi il Livello $lvl',
        en: 'Reach Level $lvl',
        es: 'Alcanza el Nivel $lvl',
        fr: 'Atteins le Niveau $lvl',
        de: 'Erreiche Level $lvl',
        pt: 'Alcance o Nível $lvl',
      );

  String skinTop3Req(int times) => _t(
        it: times == 1
            ? 'Entra nella Top 3 Giornaliera'
            : 'Entra $times volte nella Top 3 Giornaliera',
        en: times == 1
            ? 'Finish in Daily Top 3'
            : 'Finish in Daily Top 3 ($times times)',
        es: times == 1
            ? 'Llega al Top 3 Diario'
            : 'Llega al Top 3 Diario ($times veces)',
        fr: times == 1
            ? 'Termine dans le Top 3 du Jour'
            : 'Termine dans le Top 3 du Jour ($times fois)',
        de: times == 1
            ? 'Erreiche die tägliche Top 3'
            : 'Erreiche $times Mal die tägliche Top 3',
        pt: times == 1
            ? 'Chegue ao Top 3 Diário'
            : 'Chegue ao Top 3 Diário ($times vezes)',
      );

  String skinDailyFirstReq(int times) => _t(
        it: times == 1
            ? 'Conquista il 1° Posto Giornaliero'
            : 'Conquista il 1° Posto Giornaliero ($times volte)',
        en: times == 1
            ? 'Win 1st Place in Daily Tower'
            : 'Win 1st Place in Daily Tower ($times times)',
        es: times == 1
            ? 'Gana el 1.º Lugar en la Torre Diaria'
            : 'Gana el 1.º Lugar en la Torre Diaria ($times veces)',
        fr: times == 1
            ? 'Décroche la 1ère Place du Jour'
            : 'Décroche la 1ère Place du Jour ($times fois)',
        de: times == 1
            ? 'Erobere Platz 1 im Tagesturm'
            : 'Erobere Platz 1 im Tagesturm ($times Mal)',
        pt: times == 1
            ? 'Conquiste o 1º Lugar na Torre Diária'
            : 'Conquiste o 1º Lugar na Torre Diária ($times vezes)',
      );

  String skinBouncesReq(int count) => _t(
        it: 'Esegui $count rimbalzi totali',
        en: 'Perform $count total bounces',
        es: 'Realiza $count rebotes totales',
        fr: 'Effectue $count rebonds au total',
        de: 'Mache insgesamt $count Sprünge',
        pt: 'Faça $count pulos no total',
      );

  // Nomi e Descrizioni Skin Sfera
  String get skinClassicInkName => _t(
        it: 'Inchiostro Tradizionale',
        en: 'Traditional Ink',
        es: 'Tinta Tradicional',
        fr: 'Encre Traditionnelle',
        de: 'Traditionelle Tusche',
        pt: 'Tinta Tradicional',
      );
  String get skinClassicInkDesc => _t(
        it: 'L\'essenza pura dell\'inchiostro Risograph.',
        en: 'The pure essence of Risograph ink.',
        es: 'La esencia pura de la tinta Risograph.',
        fr: 'L\'essence pure de l\'encre Risograph.',
        de: 'Die reine Essenz der Risograph-Tusche.',
        pt: 'A essência pura da tinta Risograph.',
      );

  String get skinMatchaZenName => _t(
        it: 'Foglia Matcha',
        en: 'Matcha Leaf',
        es: 'Hoja Matcha',
        fr: 'Feuille Matcha',
        de: 'Matchablatt',
        pt: 'Folha Matcha',
      );
  String get skinMatchaZenDesc => _t(
        it: 'Concentrazione e armonia con la natura.',
        en: 'Focus and harmony with nature.',
        es: 'Concentración y armonía con la naturaleza.',
        fr: 'Concentration et harmonie avec la nature.',
        de: 'Fokus und Harmonie mit der Natur.',
        pt: 'Foco e harmonia com a natureza.',
      );

  String get skinShinobiStarName => _t(
        it: 'Stella Shinobi',
        en: 'Shinobi Star',
        es: 'Estrella Shinobi',
        fr: 'Étoile Shinobi',
        de: 'Shinobi-Stern',
        pt: 'Estrela Shinobi',
      );
  String get skinShinobiStarDesc => _t(
        it: 'Taglia l\'aria come uno shuriken letale.',
        en: 'Cuts the air like a lethal shuriken.',
        es: 'Corta el aire como un shuriken letal.',
        fr: 'Fend l\'air comme un shuriken mortel.',
        de: 'Schneidet die Luft wie ein tödliches Shuriken.',
        pt: 'Corta o ar como uma shuriken letal.',
      );

  String get skinPaperOrigamiName => _t(
        it: 'Papiro Origami',
        en: 'Origami Scroll',
        es: 'Papiro Origami',
        fr: 'Papyrus Origami',
        de: 'Origami-Papyrus',
        pt: 'Papiro Origami',
      );
  String get skinPaperOrigamiDesc => _t(
        it: 'Pieghature geometriche d\'arte millenaria.',
        en: 'Geometric folds of thousand-year art.',
        es: 'Pliegues geométricos de arte milenario.',
        fr: 'Plis géométriques d\'un art millénaire.',
        de: 'Geometrische Falten jahrtausendealter Kunst.',
        pt: 'Dobras geométricas de arte milenar.',
      );

  String get skinDragonEmberName => _t(
        it: 'Braci del Dragone',
        en: 'Dragon Ember',
        es: 'Brasas del Dragón',
        fr: 'Braises du Dragon',
        de: 'Drachenglut',
        pt: 'Brasas do Dragão',
      );
  String get skinDragonEmberDesc => _t(
        it: 'Fiamme cremisi ardenti ad ogni salto.',
        en: 'Blazing crimson flames with every bounce.',
        es: 'Llamas carmesí ardientes en cada salto.',
        fr: 'Flammes cramoisies ardentes à chaque saut.',
        de: 'Lodernde karmesinrote Flammen bei jedem Sprung.',
        pt: 'Chamas carmesim ardentes a cada pulo.',
      );

  String get skinCelestialVoidName => _t(
        it: 'Cosmo Celeste',
        en: 'Celestial Void',
        es: 'Cosmos Celestial',
        fr: 'Cosmos Céleste',
        de: 'Himmlischer Kosmos',
        pt: 'Cosmo Celestial',
      );
  String get skinCelestialVoidDesc => _t(
        it: 'Mistero della mezzaluna e stelle lontane.',
        en: 'Mystery of the crescent moon and distant stars.',
        es: 'Misterio de la media luna y estrellas lejanas.',
        fr: 'Mystère du croissant de lune et étoiles lointaines.',
        de: 'Geheimnis des Halbmonds und ferner Sterne.',
        pt: 'Mistério da meia-lua e estrelas distantes.',
      );

  String get skinDailyBronzeName => _t(
        it: 'Risonanza Bronzea',
        en: 'Bronze Resonance',
        es: 'Resonancia Broncínea',
        fr: 'Résonance de Bronze',
        de: 'Bronze-Resonanz',
        pt: 'Ressonância de Bronze',
      );
  String get skinDailyBronzeDesc => _t(
        it: 'Simbolo di chi ha calcato il podio giornaliero.',
        en: 'Symbol of those who stepped on the daily podium.',
        es: 'Símbolo de quienes subieron al podio diario.',
        fr: 'Symbole de ceux qui ont foulé le podium du jour.',
        de: 'Symbol für diejenigen, die das tägliche Podest betreten haben.',
        pt: 'Símbolo de quem pisou no pódio diário.',
      );

  String get skinDailySilverName => _t(
        it: 'Prisma d\'Argento',
        en: 'Silver Prism',
        es: 'Prisma de Plata',
        fr: 'Prisme d\'Argent',
        de: 'Silber-Prisma',
        pt: 'Prisma de Prata',
      );
  String get skinDailySilverDesc => _t(
        it: 'Armatura metallica forgiata nelle sfide di vertice.',
        en: 'Metallic armor forged in top-tier challenges.',
        es: 'Armadura metálica forjada en desafíos de élite.',
        fr: 'Armure métallique forgée dans les défis d\'élite.',
        de: 'Metallische Rüstung, geschmiedet in Spitzenherausforderungen.',
        pt: 'Armadura metálica forjada em desafios de elite.',
      );

  String get skinDailyGoldName => _t(
        it: 'Aureo del Campione',
        en: 'Champion Gold',
        es: 'Oro del Campeón',
        fr: 'Or du Champion',
        de: 'Meistergold',
        pt: 'Ouro do Campeão',
      );
  String get skinDailyGoldDesc => _t(
        it: 'Corona e splendore del dominatore della Torre.',
        en: 'Crown and glory of the ruler of the Tower.',
        es: 'Corona y gloria del conquistador de la Torre.',
        fr: 'Couronne et gloire du conquérant de la Tour.',
        de: 'Krone und Glanz des Turmbeherrschers.',
        pt: 'Coroa e glória do conquistador da Torre.',
      );

  String get skinThunderSparkName => _t(
        it: 'Fulmine del Tuono',
        en: 'Thunder Spark',
        es: 'Chispa del Trueno',
        fr: 'Éclair du Tonnerre',
        de: 'Donnerfunke',
        pt: 'Faísca do Trovão',
      );
  String get skinThunderSparkDesc => _t(
        it: 'Carica elettrificante per i maestri del rimbalzo.',
        en: 'Electrifying charge for masters of the bounce.',
        es: 'Carga electrizante para los maestros del rebote.',
        fr: 'Charge électrisante pour les maîtres du rebond.',
        de: 'Elektrisierende Ladung für Meister des Sprungs.',
        pt: 'Carga eletrizante para os mestres do pulo.',
      );

  // --- Norme sulla Privacy (Privacy Policy) ---
  String get privacyTitle => _t(
        it: 'Norme sulla Privacy',
        en: 'Privacy Policy',
        es: 'Política de Privacidad',
        fr: 'Politique de Confidentialité',
        de: 'Datenschutzerklärung',
        pt: 'Política de Privacidade',
      );

  String get privacyBtn => _t(
        it: 'Privacy',
        en: 'Privacy',
        es: 'Privacidad',
        fr: 'Confidentialité',
        de: 'Datenschutz',
        pt: 'Privacidade',
      );

  String get privacyOpenWeb => _t(
        it: 'Apri Norme Complete (Web)',
        en: 'Open Full Policy (Web)',
        es: 'Abrir Política Completa (Web)',
        fr: 'Ouvrir la Politique Complète (Web)',
        de: 'Vollständige Erklärung (Web)',
        pt: 'Abrir Política Completa (Web)',
      );

  String get privacySummaryLine1 => _t(
        it: 'Nessun dato personale o sensibile raccolto (nessun account o tracciamento).',
        en: 'No personal or sensitive user data is collected (no accounts or tracking).',
        es: 'No se recopilan datos personales ni sensibles (sin cuentas ni rastreo).',
        fr: 'Aucune donnée personnelle ou sensible collectée (aucun compte ni suivi).',
        de: 'Keine Erfassung persönlicher oder sensibler Daten (keine Konten oder Tracking).',
        pt: 'Nenhum dado pessoal ou confidencial é coletado (sem contas ou rastreamento).',
      );

  String get privacySummaryLine2 => _t(
        it: 'Salvataggio 100% in locale sul dispositivo (livelli, record, skin e impostazioni).',
        en: '100% local storage on your device (levels, records, skins, and settings).',
        es: 'Almacenamiento 100% local en tu dispositivo (niveles, récords, skins y ajustes).',
        fr: 'Stockage 100% local sur votre appareil (niveaux, scores, skins et paramètres).',
        de: '100% lokale Speicherung auf dem Gerät (Level, Rekorde, Skins und Einstellungen).',
        pt: 'Armazenamento 100% local no dispositivo (níveis, recordes, skins e opções).',
      );

  String get privacySummaryLine3 => _t(
        it: 'Gioco offline con classifiche simulate proceduralmente senza terze parti profilanti.',
        en: 'Offline gameplay with procedural simulated rivals and zero profiling third parties.',
        es: 'Juego sin conexión con rivales simulados proceduralmente sin terceros de perfilado.',
        fr: 'Jeu hors ligne avec rivaux simulés de manière procédurale sans tiers profilants.',
        de: 'Offline-Gameplay mit prozedural simulierten Rivalen ohne Profiling-Drittanbieter.',
        pt: 'Jogo offline com rivais simulados proceduralmente sem terceiros de rastreamento.',
      );

  String get privacyContactDeveloper => _t(
        it: 'Contatto sviluppatore: alemacciodev@gmail.com',
        en: 'Developer contact: alemacciodev@gmail.com',
        es: 'Contacto del desarrollador: alemacciodev@gmail.com',
        fr: 'Contact développeur: alemacciodev@gmail.com',
        de: 'Entwicklerkontakt: alemacciodev@gmail.com',
        pt: 'Contato do desenvolvedor: alemacciodev@gmail.com',
      );

  String get privacyPoint1Title => _t(
        it: 'Zero Dati Personali',
        en: 'Zero Personal Data',
        es: 'Cero Datos Personales',
        fr: 'Zéro Donnée Personnelle',
        de: 'Keine persönlichen Daten',
        pt: 'Zero Dados Pessoais',
      );

  String get privacyPoint2Title => _t(
        it: 'Salvataggio Locale',
        en: 'Local Storage',
        es: 'Almacenamiento Local',
        fr: 'Stockage Local',
        de: 'Lokale Speicherung',
        pt: 'Armazenamento Local',
      );

  String get privacyPoint3Title => _t(
        it: 'Offline & Bot Simulati',
        en: 'Offline & Simulated Bots',
        es: 'Sin Conexión y Bots',
        fr: 'Hors Ligne & Bots',
        de: 'Offline & Simulierte Bots',
        pt: 'Offline e Bots Simulados',
      );

  String get privacyErrorOpenUrl => _t(
        it: 'Impossibile aprire il link',
        en: 'Could not open link',
        es: 'No se pudo abrir el enlace',
        fr: 'Impossible d\'ouvrir le lien',
        de: 'Link konnte nicht geöffnet werden',
        pt: 'Não foi possibile abrir o link',
      );

  String get closeBtn => _t(
        it: 'Chiudi',
        en: 'Close',
        es: 'Cerrar',
        fr: 'Fermer',
        de: 'Schließen',
        pt: 'Fechar',
      );
}
