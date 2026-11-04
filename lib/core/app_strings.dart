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
    bool isInfiniteMode = false,
    bool isNewRecord = false,
    double bestInfiniteMeters = 0.0,
  }) {
    if (isInfiniteMode) {
      final mStr = meters.toStringAsFixed(1);
      final bestStr = (bestInfiniteMeters > meters ? bestInfiniteMeters : meters)
          .toStringAsFixed(1);
      if (isNewRecord && meters > 0) {
        return _t(
          it: 'Nuovo record nella Torre Infinita! Hai raggiunto ${mStr}m!',
          en: 'New Infinite Tower record! You climbed ${mStr}m!',
          es: '¡Nuevo récord en la Torre Infinita! ¡Subiste ${mStr}m!',
          fr: 'Nouveau record Tour Infinie ! Vous avez atteint ${mStr}m !',
          de: 'Neuer Endlos-Turm-Rekord! Du hast ${mStr}m erreicht!',
          pt: 'Novo recorde na Torre Infinita! Você alcançou ${mStr}m!',
        );
      }
      return _t(
        it: 'Scalata infinita fino a ${mStr}m • Record personale: ${bestStr}m',
        en: 'Infinite climb up to ${mStr}m • Personal best: ${bestStr}m',
        es: 'Escalada infinita hasta ${mStr}m • Récord personal: ${bestStr}m',
        fr: 'Ascension infinie jusqu\'à ${mStr}m • Record : ${bestStr}m',
        de: 'Endloser Aufstieg bis ${mStr}m • Rekord: ${bestStr}m',
        pt: 'Escalada infinita até ${mStr}m • Recorde pessoal: ${bestStr}m',
      );
    }
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

  String globalRankSummary(
    int rank,
    bool isLevelMode,
    int levelOrIssue, {
    bool isInfiniteMode = false,
    String bestInfiniteMeters = '0.0',
  }) {
    if (isInfiniteMode) {
      return _t(
        it: 'Classifica Torre Infinita: #$rank (Record ${bestInfiniteMeters}m)',
        en: 'Infinite Tower Rank: #$rank (Best ${bestInfiniteMeters}m)',
        es: 'Ranking Torre Infinita: #$rank (Récord ${bestInfiniteMeters}m)',
        fr: 'Classement Tour Infinie : #$rank (Record ${bestInfiniteMeters}m)',
        de: 'Endlos-Turm-Rang: #$rank (Rekord ${bestInfiniteMeters}m)',
        pt: 'Ranking Torre Infinita: #$rank (Recorde ${bestInfiniteMeters}m)',
      );
    }
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

  // --- MENU PAUSA, IMPOSTAZIONI & ANTI-CHEAT ORARIO ---
  String get pauseTitle => _t(
        it: 'GIOCO IN PAUSA',
        en: 'GAME PAUSED',
        es: 'JUEGO EN PAUSA',
        fr: 'JEU EN PAUSE',
        de: 'SPIEL PAUSIERT',
        pt: 'JOGO PAUSADO',
      );

  String get pauseSubtitle => _t(
        it: 'Fisica e timer sospesi in sicurezza',
        en: 'Physics and timer safely paused',
        es: 'Física y temporizador en pausa',
        fr: 'Physique et chrono en pause',
        de: 'Physik und Timer pausiert',
        pt: 'Física e cronômetro em pausa',
      );

  String get resumeBtn => _t(
        it: 'RIPRENDI SCALATA',
        en: 'RESUME CLIMB',
        es: 'REANUDAR ESCALADA',
        fr: 'REPRENDRE',
        de: 'WEITERSPIELEN',
        pt: 'RETOMAR ESCALADA',
      );

  String get themeSelectLabel => _t(
        it: 'TEMA VISIVO RISOGRAPH',
        en: 'RISOGRAPH VISUAL THEME',
        es: 'TEMA VISUAL RISOGRAPH',
        fr: 'THÈME VISUEL RISOGRAPH',
        de: 'RISOGRAPH-FARBSCHEMA',
        pt: 'TEMA VISUAL RISOGRAPH',
      );
  String get themeSectionLabel => themeSelectLabel;

  String get audioSettingsLabel => _t(
        it: 'CONTROLLI AUDIO',
        en: 'AUDIO CONTROLS',
        es: 'CONTROLES DE AUDIO',
        fr: 'CONTRÔLES AUDIO',
        de: 'AUDIO-EINSTELLUNGEN',
        pt: 'CONTROLES DE ÁUDIO',
      );
  String get audioSectionLabel => audioSettingsLabel;

  String get masterAudioLabel => _t(
        it: 'Audio Generale (Master)',
        en: 'Master Audio',
        es: 'Audio General (Master)',
        fr: 'Audio Principal (Master)',
        de: 'Haupt-Audio (Master)',
        pt: 'Áudio Geral (Master)',
      );

  String get sfxAudioLabel => _t(
        it: 'Effetti Sonori (SFX)',
        en: 'Sound Effects (SFX)',
        es: 'Efectos de Sonido (SFX)',
        fr: 'Effets Sonores (SFX)',
        de: 'Soundeffekte (SFX)',
        pt: 'Efeitos Sonoros (SFX)',
      );

  String get musicAudioLabel => _t(
        it: 'Musica Ambientale',
        en: 'Ambient Music',
        es: 'Música Ambiental',
        fr: 'Musique d\'Ambiance',
        de: 'Hintergrundmusik',
        pt: 'Música Ambiente',
      );

  String get exitToMenuBtn => _t(
        it: 'ESCI AL MENÙ PRINCIPALE',
        en: 'EXIT TO MAIN MENU',
        es: 'SALIR AL MENÚ PRINCIPAL',
        fr: 'QUITTER VERS LE MENU',
        de: 'ZUM HAUPTMENÜ',
        pt: 'SAIR PARA O MENU',
      );

  String get exitConfirmTitle => _t(
        it: 'Uscire dalla partita?',
        en: 'Exit current climb?',
        es: '¿Salir de la partida?',
        fr: 'Quitter la partie ?',
        de: 'Runde wirklich beenden?',
        pt: 'Sair da partida atual?',
      );

  String get exitConfirmSub => _t(
        it: 'Il progresso della scalata attuale andrà perso.',
        en: 'Your current climb progress will be lost.',
        es: 'Se perderá el progreso de la escalada actual.',
        fr: 'La progression de l\'ascension actuelle sera perdue.',
        de: 'Dein aktueller Fortschritt geht verloren.',
        pt: 'O progresso da escalada atual será perdido.',
      );

  String get cancelBtn => _t(
        it: 'ANNULLA',
        en: 'CANCEL',
        es: 'CANCELAR',
        fr: 'ANNULER',
        de: 'ABBRECHEN',
        pt: 'CANCELAR',
      );

  String get confirmExitBtn => _t(
        it: 'ESCI ORA',
        en: 'EXIT NOW',
        es: 'SALIR AHORA',
        fr: 'QUITTER',
        de: 'BEENDEN',
        pt: 'SAIR AGORA',
      );

  String get settingsBtn => _t(
        it: 'Impostazioni',
        en: 'Settings',
        es: 'Ajustes',
        fr: 'Options',
        de: 'Optionen',
        pt: 'Ajustes',
      );
  String get settingsTitle => settingsBtn.toUpperCase();
  String get settingsNavBtn => settingsBtn;

  String get levelsNavBtn => _t(
        it: 'Classifica',
        en: 'Rankings',
        es: 'Ranking',
        fr: 'Classement',
        de: 'Rangliste',
        pt: 'Ranking',
      );

  String get shopSkinsNavBtn => _t(
        it: 'Skin Sfera',
        en: 'Ball Skins',
        es: 'Skins Bola',
        fr: 'Skins Balle',
        de: 'Ball-Skins',
        pt: 'Skins Bola',
      );
  String get shopNavBtn => shopSkinsNavBtn;

  String get profileNavBtn => _t(
        it: 'Profilo',
        en: 'Profile',
        es: 'Perfil',
        fr: 'Profil',
        de: 'Profil',
        pt: 'Perfil',
      );

  String get languageLabel => _t(
        it: 'Lingua / Language',
        en: 'Language',
        es: 'Idioma',
        fr: 'Langue',
        de: 'Sprache',
        pt: 'Idioma',
      );

  String nextDailyInLabel(String timeStr) => _t(
        it: 'Nuova Torre tra $timeStr',
        en: 'Next Tower in $timeStr',
        es: 'Nueva Torre en $timeStr',
        fr: 'Prochaine Tour dans $timeStr',
        de: 'Nächster Turm in $timeStr',
        pt: 'Nova Torre em $timeStr',
      );

  String get clockTamperTitle => _t(
        it: 'ORARIO DI SISTEMA ALTERATO',
        en: 'SYSTEM CLOCK TAMPERED',
        es: 'RELOJ DEL SISTEMA ALTERADO',
        fr: 'HORLOGE SYSTÈME MODIFIÉE',
        de: 'SYSTEMUHR MANIPULIERT',
        pt: 'RELÓGIO DO SISTEMA ALTERADO',
      );

  String get clockTamperWarning => _t(
        it: 'Rilevata modifica manuale della data/ora. Ripristina l\'ora automatica o connettiti a Internet per accedere alla Torre di Oggi.',
        en: 'Manual date/time change detected. Restore automatic time or connect to the Internet to access Today\'s Tower.',
        es: 'Cambio manual de hora detectado. Restaura la hora automática o conéctate a Internet para jugar la Torre de Hoy.',
        fr: 'Modification manuelle de l\'heure détectée. Rétablissez l\'heure automatique ou connectez-vous à Internet.',
        de: 'Manuelle Zeitänderung erkannt. Stelle die automatische Uhrzeit wieder her oder verbinde dich mit dem Internet.',
        pt: 'Alteração manual de data/hora detectada. Restaure a hora automática ou conecte-se à Internet.',
      );
  String get clockTamperBody => clockTamperWarning;

  String get clockTamperVerifyBtn => _t(
        it: 'VERIFICA ORARIO ORA',
        en: 'VERIFY TIME NOW',
        es: 'VERIFICAR HORA AHORA',
        fr: 'VÉRIFIER L\'HEURE',
        de: 'ZEIT JETZT PRÜFEN',
        pt: 'VERIFICAR HORA AGORA',
      );
  String get clockTamperRetryBtn => clockTamperVerifyBtn;

  // --- VOLUME SINGOLO, TORRE INFINITA & MATRICE LIVELLI ---
  String get volumeAudioLabel => _t(
        it: 'Volume di Gioco',
        en: 'Game Volume',
        es: 'Volumen del Juego',
        fr: 'Volume du Jeu',
        de: 'Spiellautstärke',
        pt: 'Volume do Jogo',
      );

  String get modeDailyCardTitle => _t(
        it: 'LIVELLO GIORNALIERO',
        en: 'DAILY LEVEL',
        es: 'NIVEL DIARIO',
        fr: 'NIVEAU DU JOUR',
        de: 'TAGES-LEVEL',
        pt: 'NÍVEL DIÁRIO',
      );

  String get modeDailyCardSub => _t(
        it: 'Torre da 100m condivisa (24h)',
        en: 'Shared 100m daily tower (24h)',
        es: 'Torre de 100m compartida (24h)',
        fr: 'Tour de 100m partagée (24h)',
        de: 'Geteilter 100m-Tagesturm (24h)',
        pt: 'Torre de 100m compartilhada (24h)',
      );

  String get modeProgressiveCardTitle => _t(
        it: 'LIVELLI PROGRESSIVI',
        en: 'PROGRESSIVE LEVELS',
        es: 'NIVELES PROGRESIVOS',
        fr: 'NIVEAUX PROGRESSIFS',
        de: 'PROGRESSIVE LEVEL',
        pt: 'NÍVEIS PROGRESSIVOS',
      );

  String get modeProgressiveCardSub => _t(
        it: 'Livelli infiniti • +10m ogni 10 liv.',
        en: 'Endless levels • +10m every 10 lvls',
        es: 'Niveles infinitos • +10m cada 10 niv.',
        fr: 'Niveaux infinis • +10m / 10 niv.',
        de: 'Endlose Level • +10m alle 10 Lvl',
        pt: 'Níveis infinitos • +10m a cada 10 nív.',
      );

  String get modeInfiniteCardTitle => _t(
        it: 'TORRE INFINITA',
        en: 'INFINITE TOWER',
        es: 'TORRE INFINITA',
        fr: 'TOUR INFINIE',
        de: 'ENDLOSER TURM',
        pt: 'TORRE INFINITA',
      );

  String get modeInfiniteCardSub => _t(
        it: 'Senza fine • +1 ostacolo ogni 50m (fino al Cap MAX)',
        en: 'No summit • +1 obstacle every 50m (up to MAX Cap)',
        es: 'Sin cima • +1 obstáculo cada 50m (hasta el Cap MÁX)',
        fr: 'Sans sommet • +1 obstacle / 50m (jusqu\'au Cap MAX)',
        de: 'Ohne Gipfel • +1 Hindernis / 50m (bis zum MAX-Cap)',
        pt: 'Sem topo • +1 obstáculo a cada 50m (até o Cap MÁX)',
      );

  String get hudInfiniteBadge => _t(
        it: 'INFINITA',
        en: 'INFINITE',
        es: 'INFINITA',
        fr: 'INFINIE',
        de: 'ENDLOS',
        pt: 'INFINITA',
      );

  String get infiniteRecordLabel => _t(
        it: 'RECORD INFINITO',
        en: 'INFINITE BEST',
        es: 'RÉCORD INFINITO',
        fr: 'RECORD INFINI',
        de: 'ENDLOS-REKORD',
        pt: 'RECORDE INFINITO',
      );

  String get nextObstacleLabel => _t(
        it: 'NUOVO OSTACOLO',
        en: 'NEW OBSTACLE',
        es: 'NUEVO OBSTÁCULO',
        fr: 'NOUVEL OBSTACLE',
        de: 'NEUES HINDERNIS',
        pt: 'NOVO OBSTÁCULO',
      );

  String get every50mValue => _t(
        it: 'OGNI 50m',
        en: 'EVERY 50m',
        es: 'CADA 50m',
        fr: 'TOUS LES 50m',
        de: 'ALLE 50m',
        pt: 'A CADA 50m',
      );

  String get infiniteSummaryHeader => _t(
        it: 'RIEPILOGO SCALATA INFINITA',
        en: 'INFINITE CLIMB SUMMARY',
        es: 'RESUMEN ESCALADA INFINITA',
        fr: 'BILAN ASCENSION INFINIE',
        de: 'ENDLOS-AUFSTIEG BILANZ',
        pt: 'RESUMO ESCALADA INFINITA',
      );

  String get infiniteReachedHeightLabel => _t(
        it: 'ALTEZZA RAGGIUNTA',
        en: 'HEIGHT REACHED',
        es: 'ALTURA ALCANZADA',
        fr: 'HAUTEUR ATTEINTE',
        de: 'ERREICHTE HÖHE',
        pt: 'ALTURA ALCANÇADA',
      );

  String infiniteObstacleTierInfo(int tier, int nextMeters) => _t(
        it: 'Fascia Ostacoli $tier • Prossimo ostacolo a ${nextMeters}m',
        en: 'Obstacle Tier $tier • Next obstacle at ${nextMeters}m',
        es: 'Fase Obstáculos $tier • Próximo obstáculo a ${nextMeters}m',
        fr: 'Palier Obstacles $tier • Prochain obstacle à ${nextMeters}m',
        de: 'Hindernis-Stufe $tier • Nächstes Hindernis bei ${nextMeters}m',
        pt: 'Fase Obstáculos $tier • Próximo obstáculo em ${nextMeters}m',
      );

  String infiniteObstacleTierMaxInfo(int tier) => _t(
        it: 'Fascia Ostacoli $tier (Cap MAX) • Tutti gli ostacoli sbloccati!',
        en: 'Obstacle Tier $tier (MAX Cap) • All obstacles unlocked!',
        es: 'Fase Obstáculos $tier (Cap MÁX) • ¡Todos los obstáculos desbloqueados!',
        fr: 'Palier Obstacles $tier (Cap MAX) • Tous les obstacles débloqués !',
        de: 'Hindernis-Stufe $tier (MAX-Cap) • Alle Hindernisse freigeschaltet!',
        pt: 'Fase Obstáculos $tier (Cap MÁX) • Todos os obstáculos desbloqueados!',
      );

  String leaderboardInfiniteOpenBtn(int rank, int tier) => _t(
        it: 'CLASSIFICA INFINITA (#$rank) • FASCIA OSTACOLI $tier',
        en: 'INFINITE RANKING (#$rank) • OBSTACLE TIER $tier',
        es: 'RANKING INFINITO (#$rank) • FASE OBSTÁCULOS $tier',
        fr: 'CLASSEMENT INFINI (#$rank) • PALIER $tier',
        de: 'ENDLOS-RANG (#$rank) • HINDERNIS-STUFE $tier',
        pt: 'RANKING INFINITO (#$rank) • FASE OBSTÁCULOS $tier',
      );

  String playInfiniteBtn(String bestMeters) => _t(
        it: 'GIOCA TORRE INFINITA (RECORD ${bestMeters}m)',
        en: 'PLAY INFINITE TOWER (BEST ${bestMeters}m)',
        es: 'JUGAR TORRE INFINITA (RÉCORD ${bestMeters}m)',
        fr: 'JOUER TOUR INFINIE (RECORD ${bestMeters}m)',
        de: 'SPIELE ENDLOS-TURM (REKORD ${bestMeters}m)',
        pt: 'JOGAR TORRE INFINITA (RECORDE ${bestMeters}m)',
      );

  String infiniteNewObstacleStamp(int meters, {bool isMaxTier = false}) {
    if (isMaxTier) {
      return _t(
        it: '${meters}m! VELOCITÀ & DENSITÀ +',
        en: '${meters}m! SPEED & DENSITY +',
        es: '¡${meters}m! ¡VELOCIDAD Y DENSIDAD +!',
        fr: '${meters}m ! VITESSE & DENSITÉ +',
        de: '${meters}m! TEMPO & DICHTE +',
        pt: '${meters}m! VELOCIDADE & DENSIDADE +',
      );
    }
    return _t(
      it: '${meters}m! +NUOVO OSTACOLO!',
      en: '${meters}m! +NEW OBSTACLE!',
      es: '¡${meters}m! ¡+NUEVO OBSTÁCULO!',
      fr: '${meters}m ! +NOUVEL OBSTACLE !',
      de: '${meters}m! +NEUES HINDERNIS!',
      pt: '${meters}m! +NOVO OBSTÁCULO!',
    );
  }

  String infiniteMilestoneMarker(int meters, {bool isMaxTier = false}) {
    if (isMaxTier) {
      return _t(
        it: '— ${meters}m • VELOCITÀ & DENSITÀ + —',
        en: '— ${meters}m • SPEED & DENSITY + —',
        es: '— ${meters}m • VELOCIDAD Y DENSIDAD + —',
        fr: '— ${meters}m • VITESSE & DENSITÉ + —',
        de: '— ${meters}m • TEMPO & DICHTE + —',
        pt: '— ${meters}m • VELOCIDADE & DENSIDADE + —',
      );
    }
    return _t(
      it: '— ${meters}m • +NUOVO OSTACOLO —',
      en: '— ${meters}m • +NEW OBSTACLE —',
      es: '— ${meters}m • +NUEVO OBSTÁCULO —',
      fr: '— ${meters}m • +NOUVEL OBSTACLE —',
      de: '— ${meters}m • +NEUES HINDERNIS —',
      pt: '— ${meters}m • +NOVO OBSTÁCULO —',
    );
  }

  String get leaderboardInfiniteTitle => _t(
        it: 'CLASSIFICA TORRE INFINITA',
        en: 'INFINITE TOWER LEADERBOARD',
        es: 'CLASIFICACIÓN TORRE INFINITA',
        fr: 'CLASSEMENT TOUR INFINIE',
        de: 'ENDLOS-TURM RANGLISTE',
        pt: 'RANKING TORRE INFINITA',
      );

  String get leaderboardInfiniteSub => _t(
        it: 'Chi scala più in alto nella Torre Infinita (+1 ostacolo ogni 50m)',
        en: 'Highest climbers in the Infinite Tower (+1 obstacle every 50m)',
        es: 'Los más altos en la Torre Infinita (+1 obstáculo cada 50m)',
        fr: 'Les plus hauts sur la Tour Infinie (+1 obstacle tous les 50m)',
        de: 'Höchste Kletterer im Endlos-Turm (+1 Hindernis alle 50m)',
        pt: 'Os mais altos na Torre Infinita (+1 obstáculo a cada 50m)',
      );

  String get levelMatrixTitle => _t(
        it: 'MATRICE SELEZIONE LIVELLI',
        en: 'LEVEL SELECTION MATRIX',
        es: 'MATRIZ DE NIVELES',
        fr: 'MATRICE DES NIVEAUX',
        de: 'LEVEL-MATRIX',
        pt: 'MATRIZ DE NÍVEIS',
      );

  String levelMatrixPageLabel(int start, int end) => _t(
        it: 'LIVELLI $start – $end',
        en: 'LEVELS $start – $end',
        es: 'NIVELES $start – $end',
        fr: 'NIVEAUX $start – $end',
        de: 'LEVEL $start – $end',
        pt: 'NÍVEIS $start – $end',
      );

  String levelMatrixOpenBtn(int selected, int maxUnlocked) => _t(
        it: 'SCEGLI LIVELLO DALLA MATRICE (LIV. $selected / $maxUnlocked)',
        en: 'SELECT LEVEL FROM MATRIX (LVL $selected / $maxUnlocked)',
        es: 'ELEGIR NIVEL EN MATRIZ (NIV. $selected / $maxUnlocked)',
        fr: 'CHOISIR NIVEAU DANS LA MATRICE (NIV. $selected / $maxUnlocked)',
        de: 'LEVEL AUS MATRIX WÄHLEN (LVL $selected / $maxUnlocked)',
        pt: 'ESCOLHER NÍVEL NA MATRIZ (NÍV. $selected / $maxUnlocked)',
      );

  String levelMatrixLockedHint(int frontierLevel) => _t(
        it: 'Supera il Livello $frontierLevel per sbloccare i successivi • Usa le frecce per sfogliare all\'infinito!',
        en: 'Beat Level $frontierLevel to unlock next levels • Use arrows to browse infinitely!',
        es: '¡Supera el Nivel $frontierLevel para desbloquear • Usa las flechas para explorar sin fin!',
        fr: 'Battez le Niveau $frontierLevel pour débloquer • Utilisez les flèches à l\'infini !',
        de: 'Schlage Level $frontierLevel zum Freischalten • Pfeile zum endlosen Blättern!',
        pt: 'Vença o Nível $frontierLevel para desbloquear • Use as setas para navegar sem fim!',
      );

  // ===========================================================================
  // NUOVE SKIN SFERA HARDCORE & ICONE PROFILO AVANZATE
  // ===========================================================================
  String get skinCrimsonOniName => _t(
        it: 'Oni Cremisi',
        en: 'Crimson Oni',
        es: 'Oni Carmesí',
        fr: 'Oni Cramoisi',
        de: 'Purpur-Oni',
        pt: 'Oni Carmesim',
      );
  String get skinCrimsonOniDesc => _t(
        it: 'Maschera demoniaca incisa a fuoco con corna d\'avorio e nucleo cremisi.',
        en: 'Fire-etched demon mask with ivory horns and crimson core.',
        es: 'Máscara demoníaca grabada con cuernos de marfil y núcleo carmesí.',
        fr: 'Masque de démon gravé avec cornes d\'ivoire et cœur cramoisi.',
        de: 'Feuergeätzte Dämonenmaske mit Elfenbeinhörnern und Purpurkern.',
        pt: 'Máscara demoníaca gravada com chifres de marfim e núcleo carmesim.',
      );

  String get skinKitsuneSpiritName => _t(
        it: 'Vortice Kitsune',
        en: 'Kitsune Vortex',
        es: 'Vórtice Kitsune',
        fr: 'Vortex Kitsune',
        de: 'Kitsune-Wirbel',
        pt: 'Vórtice Kitsune',
      );
  String get skinKitsuneSpiritDesc => _t(
        it: 'Spirito volpe a nove code con fiamme volpine ciano e oro.',
        en: 'Nine-tailed fox spirit with cyan and gold foxfire.',
        es: 'Espíritu zorro de nueve colas con fuego fatuo cian y oro.',
        fr: 'Esprit renard à neuf queues avec feu follet cyan et or.',
        de: 'Neunschwänziger Fuchsgeist mit Cyan- und Gold-Fuchsfeuer.',
        pt: 'Espírito raposa de nove caudas com fogo-fátuo ciano e ouro.',
      );

  String get skinShogunObsidianName => _t(
        it: 'Ossidiana Shogun',
        en: 'Shogun Obsidian',
        es: 'Obsidiana Shogun',
        fr: 'Obsidienne Shogun',
        de: 'Shogun-Obsidian',
        pt: 'Obsidiana Shogun',
      );
  String get skinShogunObsidianDesc => _t(
        it: 'Armatura poligonale in ossidiana nera e lame di giada imperiale.',
        en: 'Black obsidian polygonal armor with imperial jade blades.',
        es: 'Armadura poligonal de obsidiana negra y hojas de jade imperial.',
        fr: 'Armure polygonale en obsidienne noire et lames de jade impérial.',
        de: 'Schwarze Obsidian-Rüstung mit kaiserlichen Jade-Klingen.',
        pt: 'Armadura poligonal de obsidiana negra e lâminas de jade imperial.',
      );

  String get skinSunEmperorName => _t(
        it: 'Imperatore del Sole',
        en: 'Sun Emperor',
        es: 'Emperador del Sol',
        fr: 'Empereur du Soleil',
        de: 'Sonnenkaiser',
        pt: 'Imperador do Sol',
      );
  String get skinSunEmperorDesc => _t(
        it: 'Aureola solare a 12 raggi forgiata per i dominatori della Torre di Oggi.',
        en: '12-ray solar halo forged for masters of Today\'s Tower.',
        es: 'Halo solar de 12 rayos forjado para maestros de la Torre de Hoy.',
        fr: 'Halo solaire à 12 rayons forgé pour les maîtres de la Tour du Jour.',
        de: '12-strahliger Sonnenkranz für Meister des Tagesturms.',
        pt: 'Halo solar de 12 raios forjado para mestres da Torre de Hoje.',
      );

  String get skinPhantomDuelistName => _t(
        it: 'Spettro Duellante',
        en: 'Phantom Duelist',
        es: 'Espectro Duelista',
        fr: 'Spectre Duelliste',
        de: 'Phantom-Duellant',
        pt: 'Espectro Duelista',
      );
  String get skinPhantomDuelistDesc => _t(
        it: 'Sfera ectoplasmatica bicolore riservata ai campioni delle sfide P2P.',
        en: 'Dual-tone ectoplasmic orb reserved for P2P duel champions.',
        es: 'Orbe ectoplásmico bicolor reservado a campeones de duelos P2P.',
        fr: 'Orbe ectoplasmique bicolore réservé aux champions de duels P2P.',
        de: 'Zweifarbige Ektoplasma-Kugel für P2P-Duell-Champions.',
        pt: 'Orbe ectoplasmático bicolor reservado a campeões de duelos P2P.',
      );

  String get skinVoidSingularityName => _t(
        it: 'Singolarità Zen',
        en: 'Zen Singularity',
        es: 'Singularidad Zen',
        fr: 'Singularité Zen',
        de: 'Zen-Singularität',
        pt: 'Singularidade Zen',
      );
  String get skinVoidSingularityDesc => _t(
        it: 'Orizzonte degli eventi d\'inchiostro puro con anello gravitazionale.',
        en: 'Pure ink event horizon with rotating gravitational accretion ring.',
        es: 'Horizonte de sucesos de tinta pura con anillo gravitacional.',
        fr: 'Horizon des événements d\'encre pure avec anneau gravitationnel.',
        de: 'Ereignishorizont aus reiner Tinte mit Gravitationsring.',
        pt: 'Horizonte de eventos de tinta pura com anel gravitacional.',
      );

  String skinInfiniteMetersReq(int meters) => _t(
        it: 'Raggiungi ${meters}m nella Torre Infinita',
        en: 'Reach ${meters}m in Infinite Tower',
        es: 'Alcanza ${meters}m en Torre Infinita',
        fr: 'Atteindre ${meters}m en Tour Infinie',
        de: 'Erreiche ${meters}m im Endlos-Turm',
        pt: 'Alcance ${meters}m na Torre Infinita',
      );

  String skinP2PWinsReq(int wins) => _t(
        it: 'Vinci $wins sfide Multiplayer P2P',
        en: 'Win $wins P2P Multiplayer duels',
        es: 'Gana $wins duelos Multijugador P2P',
        fr: 'Gagner $wins duels Multijoueur P2P',
        de: 'Gewinne $wins P2P-Multiplayer-Duelle',
        pt: 'Vença $wins duelos Multiplayer P2P',
      );

  String get iconOniMaskName => _t(
        it: 'Maschera Oni',
        en: 'Oni Mask',
        es: 'Máscara Oni',
        fr: 'Masque Oni',
        de: 'Oni-Maske',
        pt: 'Máscara Oni',
      );
  String get iconKitsuneFoxName => _t(
        it: 'Spirito Kitsune',
        en: 'Kitsune Spirit',
        es: 'Espíritu Kitsune',
        fr: 'Esprit Kitsune',
        de: 'Kitsune-Geist',
        pt: 'Espírito Kitsune',
      );
  String get iconDuelChampionName => _t(
        it: 'Campione Duelli',
        en: 'Duel Champion',
        es: 'Campeón de Duelos',
        fr: 'Champion de Duels',
        de: 'Duell-Champion',
        pt: 'Campeão de Duelos',
      );
  String get iconSunSovereignName => _t(
        it: 'Sovrano del Sole',
        en: 'Sun Sovereign',
        es: 'Soberano del Sol',
        fr: 'Souverain Solaire',
        de: 'Sonnenherrscher',
        pt: 'Soberano do Sol',
      );
  String get iconInkCometName => _t(
        it: 'Cometa d\'Inchiostro',
        en: 'Ink Comet',
        es: 'Cometa de Tinta',
        fr: 'Comète d\'Encre',
        de: 'Tintenkomet',
        pt: 'Cometa de Tinta',
      );
  String get iconPeakDeityName => _t(
        it: 'Divinità della Vetta',
        en: 'Peak Deity',
        es: 'Deidad de la Cima',
        fr: 'Divinité du Sommet',
        de: 'Gipfelgottheit',
        pt: 'Divindade do Topo',
      );

  String get titleGrandShogun => _t(
        it: '⚔️ Grande Shogun della Torre',
        en: '⚔️ Grand Tower Shogun',
        es: '⚔️ Gran Shogun de la Torre',
        fr: '⚔️ Grand Shogun de la Tour',
        de: '⚔️ Großer Turm-Shogun',
        pt: '⚔️ Grande Shogun da Torre',
      );
  String get titleDuelMaster => _t(
        it: '👻 Maestro dei Duelli P2P',
        en: '👻 P2P Duel Master',
        es: '👻 Maestro de Duelos P2P',
        fr: '👻 Maître des Duels P2P',
        de: '👻 P2P-Duellmeister',
        pt: '👻 Mestre dos Duelos P2P',
      );

  // ===========================================================================
  // ABILITÀ DI SCALATA SBLOCCABILI (COOLDOWN)
  // ===========================================================================
  String get abilitiesTitle => _t(
        it: 'ABILITÀ DI SCALATA',
        en: 'CLIMB ABILITIES',
        es: 'HABILIDADES DE ESCALADA',
        fr: 'COMPÉTENCES D\'ASCENSION',
        de: 'KLETTER-FÄHIGKEITEN',
        pt: 'HABILIDADES DE ESCALADA',
      );
  String get abilitiesSubtitle => _t(
        it: 'Equipaggia 1 abilità attiva con tempo di ricarica da usare durante la scalata',
        en: 'Equip 1 active cooldown ability to trigger during your climb',
        es: 'Equipa 1 habilidad activa con enfriamiento para usar al escalar',
        fr: 'Équipez 1 compétence active avec recharge à utiliser en grimpant',
        de: 'Rüste 1 aktive Fähigkeit mit Abklingzeit für den Aufstieg aus',
        pt: 'Equipe 1 habilidade ativa com recarga para usar na escalada',
      );
  String abilityCooldownLabel(int sec) => _t(
        it: 'RICARICA: ${sec}s',
        en: 'COOLDOWN: ${sec}s',
        es: 'RECARGA: ${sec}s',
        fr: 'RECHARGE: ${sec}s',
        de: 'ABKLINGZEIT: ${sec}s',
        pt: 'RECARGA: ${sec}s',
      );
  String get abilityReadyLabel => _t(
        it: 'PRONTA',
        en: 'READY',
        es: 'LISTA',
        fr: 'PRÊTE',
        de: 'BEREIT',
        pt: 'PRONTA',
      );

  String get abilityZenAnchorName => _t(
        it: 'Presa Zen',
        en: 'Zen Anchor',
        es: 'Ancla Zen',
        fr: 'Ancre Zen',
        de: 'Zen-Anker',
        pt: 'Âncora Zen',
      );
  String get abilityZenAnchorDesc => _t(
        it: 'Ferma istantaneamente la sfera a mezz\'aria per 2.5s e ricarica tutti i 3 lanci.',
        en: 'Freezes the orb in mid-air for 2.5s and recharges all 3 slings.',
        es: 'Detiene la esfera en el aire por 2.5s y recarga los 3 tiros.',
        fr: 'Figer la sphère en plein vol (2.5s) et recharge les 3 tirs.',
        de: 'Stoppt die Kugel für 2.5s in der Luft und lädt alle 3 Würfe auf.',
        pt: 'Trava a esfera no ar por 2.5s e recarrega todos os 3 lanços.',
      );

  String get abilityInkAegisName => _t(
        it: 'Egida d\'Inchiostro',
        en: 'Ink Aegis',
        es: 'Égida de Tinta',
        fr: 'Égide d\'Encre',
        de: 'Tinten-Ägide',
        pt: 'Égide de Tinta',
      );
  String get abilityInkAegisDesc => _t(
        it: 'Evoca uno scudo protettivo che si rompe solo quando colpisci un ostacolo.',
        en: 'Summons a protective shield that only breaks when hitting an obstacle.',
        es: 'Invoca un escudo protector que solo se rompe al chocar un obstáculo.',
        fr: 'Invoque un bouclier qui ne se brise qu\'en touchant un obstacle.',
        de: 'Beschwört einen Schild, der erst beim Aufprall auf ein Hindernis bricht.',
        pt: 'Invoca um escudo protetor que só quebra ao atingir um obstáculo.',
      );

  String get abilityInkSabotageName => _t(
        it: 'Spruzzo d\'Inchiostro',
        en: 'Ink Splatter',
        es: 'Salpicadura de Tinta',
        fr: 'Jet d\'Encre',
        de: 'Tintenklecks',
        pt: 'Jato de Tinta',
      );
  String get abilityInkSabotageDesc => _t(
        it: 'In P2P acceca lo schermo e la mira avversaria per 4.8s (+1 lancio). In solo distrugge la trappola vicina.',
        en: 'In P2P blinds opponent screen & aim for 4.8s (+1 sling). In solo destroys nearby hazard.',
        es: 'En P2P ciega pantalla y puntería rival por 4.8s (+1 tiro). En solo destruye trampa cercana.',
        fr: 'En P2P aveugle l\'écran et la visée adverse 4.8s (+1 tir). En solo détruit le piège proche.',
        de: 'Blendet im P2P Gegner-Screen & Ziel für 4.8s (+1 Wurf). Zerstört solo nahe Falle.',
        pt: 'No P2P cega a tela e mira rival por 4.8s (+1 lanço). No solo destrói armadilha próxima.',
      );

  String get abilityHankoSurgeName => _t(
        it: 'Slancio Hanko',
        en: 'Hanko Surge',
        es: 'Impulso Hanko',
        fr: 'Élan Hanko',
        de: 'Hanko-Schub',
        pt: 'Impulso Hanko',
      );
  String get abilityHankoSurgeDesc => _t(
        it: 'Forte spinta verticale verso l\'alto e ricarica immediata di tutti e 3 i lanci.',
        en: 'Powerful upward boost and instant recharge of all 3 air slings.',
        es: 'Potente impulso vertical hacia arriba y recarga de los 3 tiros.',
        fr: 'Puissant boost vertical et recharge immédiate des 3 tirs.',
        de: 'Starker Aufwärtsschub und sofortiges Aufladen aller 3 Würfe.',
        pt: 'Forte impulso vertical para cima e recarga imediata dos 3 lanços.',
      );

  String get abilityShadowPhaseName => _t(
        it: 'Passo d\'Ombra',
        en: 'Shadow Phase',
        es: 'Paso Sombrío',
        fr: 'Phase d\'Ombre',
        de: 'Schattenphase',
        pt: 'Passo das Sombras',
      );
  String get abilityShadowPhaseDesc => _t(
        it: 'Per 3.5s attraversi indenne tutte le barriere rosse e i laser attivi.',
        en: 'For 3.5s phase harmlessly through all red hazards and active lasers.',
        es: 'Por 3.5s atraviesas sin daño todas las barreras rojas y láseres.',
        fr: 'Pendant 3.5s traversez sans dommage les pièges rouges et lasers.',
        de: '3.5s lang unbeschadet durch alle roten Fallen und Laser gleiten.',
        pt: 'Por 3.5s atravesse ileso todas as barreiras vermelhas e lasers.',
      );

  String get abilityChronoSealName => _t(
        it: 'Sigillo del Tempo',
        en: 'Chrono Seal',
        es: 'Sello del Tiempo',
        fr: 'Sceau Temporel',
        de: 'Zeitsiegel',
        pt: 'Selo do Tempo',
      );
  String get abilityChronoSealDesc => _t(
        it: 'Per 5s congela la Marea d\'Inchiostro e rallenta del 65% tutti gli ostacoli.',
        en: 'For 5s freezes the Ink Tide and slows all moving hazards by 65%.',
        es: 'Por 5s congela la Marea de Tinta y frena un 65% los obstáculos.',
        fr: 'Pendant 5s gèle la Marée d\'Encre et ralentit les pièges de 65%.',
        de: 'Friert 5s lang die Tintenflut ein und verlangsamt Fallen um 65%.',
        pt: 'Por 5s congela a Maré de Tinta e desacelera obstáculos em 65%.',
      );

  // ===========================================================================
  // SEZIONE AMICI & MULTIPLAYER P2P (FANTASMA + SPETTATORE)
  // ===========================================================================
  String get friendsAndP2PBtn => _t(
        it: 'AMICI & DUELLO P2P',
        en: 'FRIENDS & P2P DUEL',
        es: 'AMIGOS Y DUELO P2P',
        fr: 'AMIS & DUEL P2P',
        de: 'FREUNDE & P2P-DUELL',
        pt: 'AMIGOS E DUELO P2P',
      );
  String get friendsSectionTitle => _t(
        it: 'AMICI & SFIDE P2P 1-TAP',
        en: 'FRIENDS & 1-TAP P2P DUELS',
        es: 'AMIGOS Y DUELOS P2P 1-TAP',
        fr: 'AMIS & DUELS P2P 1-TAP',
        de: 'FREUNDE & 1-TAP P2P-DUELLE',
        pt: 'AMIGOS E DUELOS P2P 1-TAP',
      );
  String get yourFriendCodeLabel => _t(
        it: 'IL TUO CODICE AMICO',
        en: 'YOUR FRIEND CODE',
        es: 'TU CÓDIGO DE AMIGO',
        fr: 'VOTRE CODE AMI',
        de: 'DEIN FREUNDESCODE',
        pt: 'SEU CÓDIGO DE AMIGO',
      );
  String get addFriendTitle => _t(
        it: 'AGGIUNGI AMICO (UNA SOLA VOLTA)',
        en: 'ADD FRIEND (ONE-TIME SETUP)',
        es: 'AÑADIR AMIGO (UNA SOLA VEZ)',
        fr: 'AJOUTER UN AMI (UNE SEULE FOIS)',
        de: 'FREUND HINZUFÜGEN (EINMALIG)',
        pt: 'ADICIONAR AMIGO (UMA SÓ VEZ)',
      );
  String get friendCodeHint => _t(
        it: 'Codice Amico a 8 cifre (es. INK-84729103)',
        en: '8-digit Friend Code (e.g. INK-84729103)',
        es: 'Código de 8 dígitos (ej. INK-84729103)',
        fr: 'Code Ami à 8 chiffres (ex. INK-84729103)',
        de: '8-stelliger Freundescode (z.B. INK-84729103)',
        pt: 'Código de 8 dígitos (ex. INK-84729103)',
      );
  String removeFriendTitle(String name) => _t(
        it: 'Rimuovere $name?',
        en: 'Remove $name?',
        es: '¿Eliminar a $name?',
        fr: 'Retirer $name ?',
        de: '$name entfernen?',
        pt: 'Remover $name?',
      );
  String get removeFriendMessage => _t(
        it: 'Sei sicuro di voler eliminare questo amico dalla tua lista?',
        en: 'Are you sure you want to remove this friend from your list?',
        es: '¿Estás seguro de que quieres eliminar a este amigo de tu lista?',
        fr: 'Voulez-vous vraiment supprimer cet ami de votre liste ?',
        de: 'Möchtest du diesen Freund wirklich aus deiner Liste entfernen?',
        pt: 'Tem certeza de que deseja remover este amigo da sua lista?',
      );
  String get removeFriendConfirmBtn => _t(
        it: 'RIMUOVI',
        en: 'REMOVE',
        es: 'ELIMINAR',
        fr: 'SUPPRIMER',
        de: 'ENTFERNEN',
        pt: 'REMOVER',
      );
  String p2pPausedByLabel(String playerName) => _t(
        it: 'PARTITA SOSPESA DA ${playerName.toUpperCase()}',
        en: 'MATCH PAUSED BY ${playerName.toUpperCase()}',
        es: 'PARTIDA PAUSADA POR ${playerName.toUpperCase()}',
        fr: 'PARTIE SUSPENDUE PAR ${playerName.toUpperCase()}',
        de: 'SPIEL PAUSIERT VON ${playerName.toUpperCase()}',
        pt: 'PARTIDA PAUSADA POR ${playerName.toUpperCase()}',
      );
  String waitingForFriendAccept(String name) => _t(
        it: 'Invito inviato a $name (4G/5G/Wi-Fi)... In attesa di risposta',
        en: 'Invite sent to $name (4G/5G/Wi-Fi)... Waiting for response',
        es: 'Invitación enviada a $name (4G/5G/Wi-Fi)... Esperando respuesta',
        fr: 'Invitation envoyée à $name (4G/5G/Wi-Fi)... En attente',
        de: 'Einladung an $name gesendet (4G/5G/Wi-Fi)... Warte auf Antwort',
        pt: 'Convite enviado para $name (4G/5G/Wi-Fi)... Aguardando resposta',
      );
  String get playVsBotFallbackBtn => _t(
        it: 'Gioca contro il Bot (Allenamento)',
        en: 'Play vs Bot (Training)',
        es: 'Jugar contra el Bot (Entrenamiento)',
        fr: 'Jouer contre le Bot (Entraînement)',
        de: 'Gegen Bot spielen (Training)',
        pt: 'Jogar contra o Bot (Treino)',
      );
  String get p2pYourTrailLabel => _t(
        it: 'Tuo tracciato',
        en: 'Your trail',
        es: 'Tu ruta',
        fr: 'Votre tracé',
        de: 'Deine Spur',
        pt: 'Seu trajeto',
      );
  String p2pRivalTrailLabel(String rivalName) => _t(
        it: 'Tracciato $rivalName',
        en: '$rivalName trail',
        es: 'Ruta de $rivalName',
        fr: 'Tracé $rivalName',
        de: '$rivalName Spur',
        pt: 'Trajeto $rivalName',
      );
  String get friendNameHint => _t(
        it: 'Nome amico',
        en: 'Friend name',
        es: 'Nombre del amigo',
        fr: 'Nom de l\'ami',
        de: 'Name des Freundes',
        pt: 'Nome do amigo',
      );
  String get addFriendBtn => _t(
        it: 'AGGIUNGI',
        en: 'ADD',
        es: 'AÑADIR',
        fr: 'AJOUTER',
        de: 'HINZUFÜGEN',
        pt: 'ADICIONAR',
      );
  String get duelFormatLabel => _t(
        it: 'MODALITÀ SFIDA P2P',
        en: 'P2P DUEL FORMAT',
        es: 'FORMATO DUELO P2P',
        fr: 'FORMAT DUEL P2P',
        de: 'P2P-DUELLFORMAT',
        pt: 'FORMATO DUELO P2P',
      );
  String get duelFormatRace100m => _t(
        it: '🏁 Traguardo 100m',
        en: '🏁 100m Race',
        es: '🏁 Meta 100m',
        fr: '🏁 Course 100m',
        de: '🏁 100m-Rennen',
        pt: '🏁 Corrida 100m',
      );
  String get duelFormatInfinite => _t(
        it: '♾️ Sopravvivenza Infinita',
        en: '♾️ Infinite Survival',
        es: '♾️ Supervivencia Infinita',
        fr: '♾️ Survie Infinie',
        de: '♾️ Endlos-Überleben',
        pt: '♾️ Sobrevivência Infinita',
      );
  String get challengeNowBtn => _t(
        it: '⚔️ SFIDA',
        en: '⚔️ DUEL',
        es: '⚔️ RETAR',
        fr: '⚔️ DÉFIER',
        de: '⚔️ DUELL',
        pt: '⚔️ DESAFIAR',
      );
  String get onlineStatusLabel => _t(
        it: 'ONLINE',
        en: 'ONLINE',
        es: 'EN LÍNEA',
        fr: 'EN LIGNE',
        de: 'ONLINE',
        pt: 'ONLINE',
      );
  String incomingChallengeBanner(String name, String mode) => _t(
        it: '⚔️ $name ti sfida in $mode!',
        en: '⚔️ $name challenges you to $mode!',
        es: '⚔️ ¡$name te reta en $mode!',
        fr: '⚔️ $name vous défie en $mode !',
        de: '⚔️ $name fordert dich heraus ($mode)!',
        pt: '⚔️ $name desafia você em $mode!',
      );
  String get acceptChallengeBtn => _t(
        it: 'ACCETTA',
        en: 'ACCEPT',
        es: 'ACEPTAR',
        fr: 'ACCEPTER',
        de: 'ANNEHMEN',
        pt: 'ACEITAR',
      );
  String get declineChallengeBtn => _t(
        it: 'RIFIUTA',
        en: 'DECLINE',
        es: 'RECHAZAR',
        fr: 'REFUSER',
        de: 'ABLEHNEN',
        pt: 'RECUSAR',
      );
  String spectatingBannerTitle(String opponentName) => _t(
        it: '👁️ MODALITÀ SPETTATORE • Stai seguendo $opponentName',
        en: '👁️ SPECTATOR MODE • Watching $opponentName',
        es: '👁️ MODO ESPECTADOR • Siguiendo a $opponentName',
        fr: '👁️ MODE SPECTATEUR • Vous suivez $opponentName',
        de: '👁️ ZUSCHAUERMODUS • Du folgst $opponentName',
        pt: '👁️ MODO ESPECTADOR • Seguindo $opponentName',
      );
  String opponentSpectatingYouBadge(String opponentName, String meters) => _t(
        it: '👁️ $opponentName caduto a ${meters}m • Ti osserva!',
        en: '👁️ $opponentName fell at ${meters}m • Watching you!',
        es: '👁️ $opponentName cayó a ${meters}m • ¡Te observa!',
        fr: '👁️ $opponentName tombé à ${meters}m • Vous regarde !',
        de: '👁️ $opponentName fiel bei ${meters}m • Schaut dir zu!',
        pt: '👁️ $opponentName caiu em ${meters}m • Observando você!',
      );
  String get finishSpectatingBtn => _t(
        it: 'TERMINA E VEDI RISULTATO',
        en: 'FINISH & VIEW RESULT',
        es: 'TERMINAR Y VER RESULTADO',
        fr: 'TERMINER & VOIR RÉSULTAT',
        de: 'BEENDEN & ERGEBNIS SEHEN',
        pt: 'ENCERRAR E VER RESULTADO',
      );
  String p2pVictoryTitle(String opponentName) => _t(
        it: 'HAI BATTUTO $opponentName!',
        en: 'YOU DEFEATED $opponentName!',
        es: '¡VENCISTE A $opponentName!',
        fr: 'VOUS AVEZ BATTU $opponentName !',
        de: 'DU HAST $opponentName BESIEGT!',
        pt: 'VOCÊ VENCEU $opponentName!',
      );
  String p2pDefeatTitle(String opponentName) => _t(
        it: '$opponentName HA VINTO IL DUELLO',
        en: '$opponentName WON THE DUEL',
        es: '$opponentName GANÓ EL DUELO',
        fr: '$opponentName A GAGNÉ LE DUEL',
        de: '$opponentName HAT DAS DUELL GEWONNEN',
        pt: '$opponentName VENCEU O DUELO',
      );
  String get rematchFriendBtn => _t(
        it: '⚔️ RIVINCITA IMMEDIATA',
        en: '⚔️ INSTANT REMATCH',
        es: '⚔️ REVANCHA INMEDIATA',
        fr: '⚔️ REVANCHE IMMÉDIATE',
        de: '⚔️ SOFORT-REVANCHE',
        pt: '⚔️ REVANCHE IMEDIATA',
      );
  String get simulateInviteBtn => _t(
        it: '🔔 Ricevi Invito Test da Amico',
        en: '🔔 Simulate Incoming Friend Invite',
        es: '🔔 Simular Invitación de Amigo',
        fr: '🔔 Simuler Invitation d\'un Ami',
        de: '🔔 Freundeseinladung simulieren',
        pt: '🔔 Simular Convite de Amigo',
      );
  String get friendCodeCopied => _t(
        it: 'Codice Amico copiato negli appunti!',
        en: 'Friend Code copied to clipboard!',
        es: '¡Código de Amigo copiado!',
        fr: 'Code Ami copié !',
        de: 'Freundescode kopiert!',
        pt: 'Código de Amigo copiado!',
      );
  String get friendsEmptyHint => _t(
        it: 'Invia una richiesta col Codice Amico a 8 cifre: appena accettata potrete sfidarvi con 1 tocco!',
        en: 'Send a request with an 8-digit Friend Code: once accepted, challenge each other with 1 tap!',
        es: '¡Envía una solicitud con el Código de 8 dígitos: al aceptarla podrán retarse con 1 toque!',
        fr: 'Envoyez une demande avec le Code à 8 chiffres : une fois acceptée, défiez-vous en 1 geste !',
        de: 'Sende eine Anfrage per 8-stelligem Code: Nach Annahme starten 1-Tap-Duelle!',
        pt: 'Envie um pedido com o Código de 8 dígitos: após aceito, desafiem-se com 1 toque!',
      );
  String get sendFriendRequestBtn => _t(
        it: 'INVIA RICHIESTA',
        en: 'SEND REQUEST',
        es: 'ENVIAR SOLICITUD',
        fr: 'ENVOYER DEMANDE',
        de: 'ANFRAGE SENDEN',
        pt: 'ENVIAR PEDIDO',
      );
  String friendRequestSentSnack(String code) => _t(
        it: 'Richiesta di amicizia inviata a $code!',
        en: 'Friend request sent to $code!',
        es: '¡Solicitud de amistad enviada a $code!',
        fr: 'Demande d\'ami envoyée à $code !',
        de: 'Freundschaftsanfrage an $code gesendet!',
        pt: 'Pedido de amizade enviado para $code!',
      );
  String get friendRequestSelfErrorSnack => _t(
        it: 'Non puoi inviare una richiesta al tuo stesso codice!',
        en: 'You cannot send a friend request to your own code!',
        es: '¡No puedes enviarte una solicitud a tu propio código!',
        fr: 'Vous ne pouvez pas envoyer une demande à votre propre code !',
        de: 'Du kannst keine Anfrage an deinen eigenen Code senden!',
        pt: 'Você não pode enviar um pedido para o seu próprio código!',
      );
  String get friendRequestAlreadyFriendsSnack => _t(
        it: 'Questo giocatore è già nella tua lista amici!',
        en: 'This player is already in your friends list!',
        es: '¡Este jugador ya está en tu lista de amigos!',
        fr: 'Ce joueur est déjà dans votre liste d\'amis !',
        de: 'Dieser Spieler ist bereits in deiner Freundesliste!',
        pt: 'Este jogador já está na sua lista de amigos!',
      );
  String get incomingFriendRequestsTitle => _t(
        it: 'RICHIESTE DI AMICIZIA RICEVUTE',
        en: 'INCOMING FRIEND REQUESTS',
        es: 'SOLICITUDES DE AMISTAD RECIBIDAS',
        fr: 'DEMANDES D\'AMI REÇUES',
        de: 'EMPFANGENE FREUNDSCHAFTSANFRAGEN',
        pt: 'PEDIDOS DE AMIZADE RECEBIDOS',
      );
  String get outgoingFriendRequestsTitle => _t(
        it: 'RICHIESTE INVIATE (IN ATTESA)',
        en: 'SENT REQUESTS (PENDING)',
        es: 'SOLICITUDES ENVIADAS (PENDIENTES)',
        fr: 'DEMANDES ENVOYÉES (EN ATTENTE)',
        de: 'GESENDETE ANFRAGEN (AUSSTEHEND)',
        pt: 'PEDIDOS ENVIADOS (PENDENTES)',
      );
  String get confirmedFriendsListTitle => _t(
        it: 'I TUOI AMICI',
        en: 'YOUR FRIENDS',
        es: 'TUS AMIGOS',
        fr: 'VOS AMIS',
        de: 'DEINE FREUNDE',
        pt: 'SEUS AMIGOS',
      );
  String get friendRequestPendingLabel => _t(
        it: '⏳ IN ATTESA DI ACCETTAZIONE',
        en: '⏳ WAITING FOR ACCEPTANCE',
        es: '⏳ ESPERANDO ACEPTACIÓN',
        fr: '⏳ EN ATTENTE D\'ACCEPTATION',
        de: '⏳ WARTE AUF ANNAHME',
        pt: '⏳ AGUARDANDO ACEITAÇÃO',
      );
  String incomingFriendRequestBannerTitle(String name) => _t(
        it: '🤝 Richiesta di amicizia da $name',
        en: '🤝 Friend request from $name',
        es: '🤝 Solicitud de amistad de $name',
        fr: '🤝 Demande d\'ami de $name',
        de: '🤝 Freundschaftsanfrage von $name',
        pt: '🤝 Pedido de amizade de $name',
      );
  String get removeAllFriendsBtn => _t(
        it: 'RIMUOVI TUTTI',
        en: 'REMOVE ALL',
        es: 'ELIMINAR TODOS',
        fr: 'TOUT SUPPRIMER',
        de: 'ALLE ENTFERNEN',
        pt: 'REMOVER TODOS',
      );
  String get removeAllFriendsTitle => _t(
        it: 'Rimuovere tutti gli amici?',
        en: 'Remove all friends?',
        es: '¿Eliminar todos los amigos?',
        fr: 'Supprimer tous les amis ?',
        de: 'Alle Freunde entfernen?',
        pt: 'Remover todos os amigos?',
      );
  String get removeAllFriendsMessage => _t(
        it: 'Tutti gli amici salvati verranno rimossi dalla tua lista.',
        en: 'All saved friends will be removed from your list.',
        es: 'Todos los amigos guardados se eliminarán de tu lista.',
        fr: 'Tous les amis enregistrés seront supprimés de votre liste.',
        de: 'Alle gespeicherten Freunde werden aus deiner Liste entfernt.',
        pt: 'Todos os amigos salvos serão removidos da sua lista.',
      );
  String get abilityEquipAction => _t(
        it: 'TOCCA PER EQUIPAGGIARE',
        en: 'TAP TO EQUIP',
        es: 'TOCA PARA EQUIPAR',
        fr: 'TOUCHER POUR ÉQUIPER',
        de: 'ZUM AUSRÜSTEN TIPPEN',
        pt: 'TOQUE PARA EQUIPAR',
      );
  String get spectatorBannerTitle => _t(
        it: '👁 MODALITÀ SPETTATORE',
        en: '👁 SPECTATOR MODE',
        es: '👁 MODO ESPECTADOR',
        fr: '👁 MODE SPECTATEUR',
        de: '👁 ZUSCHAUERMODUS',
        pt: '👁 MODO ESPECTADOR',
      );
  String get friendsAndP2PTitle => friendsSectionTitle;
  String get p2pFormatLabel => duelFormatLabel;
  String get p2pFormat100m => duelFormatRace100m;
  String get p2pFormatInfinite => duelFormatInfinite;
  String get addFriendNameHint => friendNameHint;
  String get addFriendCodeHint => friendCodeHint;
  String get friendOnlineReady => '🟢 $onlineStatusLabel';
  String get offlineStatusLabel => _t(
        it: 'OFFLINE',
        en: 'OFFLINE',
        es: 'DESCONECTADO',
        fr: 'HORS LIGNE',
        de: 'OFFLINE',
        pt: 'OFFLINE',
      );
  String get friendOfflineStatus => '⚪ $offlineStatusLabel';
  String get cancelInviteBtn => _t(
        it: 'ANNULLA INVITO',
        en: 'CANCEL INVITE',
        es: 'CANCELAR INVITACIÓN',
        fr: 'ANNULER INVITATION',
        de: 'EINLADUNG ABBRECHEN',
        pt: 'CANCELAR CONVITE',
      );
  String inviteDeclinedBySnack(String name) => _t(
        it: '$name ha rifiutato l\'invito alla sfida.',
        en: '$name declined the duel invite.',
        es: '$name rechazó la invitación al duelo.',
        fr: '$name a refusé l\'invitation au duel.',
        de: '$name hat die Duelleinladung abgelehnt.',
        pt: '$name recusou o convite para o duelo.',
      );
  String get trainingVsBotStandaloneBtn => _t(
        it: '🤖 ALLENAMENTO CONTRO IL BOT',
        en: '🤖 PRACTICE VS BOT (TRAINING)',
        es: '🤖 ENTRENAMIENTO CONTRA BOT',
        fr: '🤖 ENTRAÎNEMENT CONTRE BOT',
        de: '🤖 TRAINING GEGEN BOT',
        pt: '🤖 TREINO CONTRA BOT',
      );
  String get trainingBotName => _t(
        it: 'Bot Allenamento',
        en: 'Training Bot',
        es: 'Bot Entrenamiento',
        fr: 'Bot Entraînement',
        de: 'Trainings-Bot',
        pt: 'Bot de Treino',
      );
  String opponentLeftMatchStamp(String name) => _t(
        it: '👋 $name HA LASCIATO LA PARTITA',
        en: '👋 $name LEFT THE MATCH',
        es: '👋 $name SALIÓ DE LA PARTIDA',
        fr: '👋 $name A QUITTÉ LA PARTIE',
        de: '👋 $name HAT DAS SPIEL VERLASSEN',
        pt: '👋 $name SAIU DA PARTIDA',
      );
  String get opponentLeftMatchShort => _t(
        it: 'USCITO',
        en: 'LEFT',
        es: 'SALIÓ',
        fr: 'PARTI',
        de: 'VERLASSEN',
        pt: 'SAIU',
      );
  String get proposeRematchBtn => _t(
        it: '⚔️ PROPONI RIVINCITA',
        en: '⚔️ PROPOSE REMATCH',
        es: '⚔️ PROPONER REVANCHA',
        fr: '⚔️ PROPOSER REVANCHE',
        de: '⚔️ REVANCHE ANFRAGEN',
        pt: '⚔️ PROPOR REVANCHE',
      );
  String rematchWaitingVoteLabel(String name) => _t(
        it: '⏳ VOTO 1/2 • In attesa che $name accetti...',
        en: '⏳ VOTE 1/2 • Waiting for $name to accept...',
        es: '⏳ VOTO 1/2 • Esperando que $name acepte...',
        fr: '⏳ VOTE 1/2 • En attente de $name...',
        de: '⏳ STIMME 1/2 • Warte auf $name...',
        pt: '⏳ VOTO 1/2 • Aguardando $name aceitar...',
      );
  String rematchIncomingVoteTitle(String name) => _t(
        it: '⚔️ $name CHIEDE LA RIVINCITA! (1/2)',
        en: '⚔️ $name WANTS A REMATCH! (1/2)',
        es: '⚔️ ¡$name PIDE LA REVANCHA! (1/2)',
        fr: '⚔️ $name DEMANDE UNE REVANCHE ! (1/2)',
        de: '⚔️ $name WILL EINE REVANCHE! (1/2)',
        pt: '⚔️ $name QUER REVANCHE! (1/2)',
      );
  String get acceptRematchVoteBtn => _t(
        it: '✓ ACCETTA RIVINCITA (2/2)',
        en: '✓ ACCEPT REMATCH (2/2)',
        es: '✓ ACEPTAR REVANCHA (2/2)',
        fr: '✓ ACCEPTER REVANCHE (2/2)',
        de: '✓ REVANCHE ANNEHMEN (2/2)',
        pt: '✓ ACEITAR REVANCHE (2/2)',
      );
  String get declineRematchVoteBtn => _t(
        it: '✕ RIFIUTA',
        en: '✕ DECLINE',
        es: '✕ RECHAZAR',
        fr: '✕ REFUSER',
        de: '✕ ABLEHNEN',
        pt: '✕ RECUSAR',
      );
  String rematchDeclinedLabel(String name) => _t(
        it: '✕ $name ha rifiutato la rivincita.',
        en: '✕ $name declined the rematch.',
        es: '✕ $name rechazó la revancha.',
        fr: '✕ $name a refusé la revanche.',
        de: '✕ $name hat die Revanche abgelehnt.',
        pt: '✕ $name recusou a revanche.',
      );
  String rematchOpponentLeftLabel(String name) => _t(
        it: '👋 $name è uscito dalla partita.',
        en: '👋 $name left the match.',
        es: '👋 $name salió de la partida.',
        fr: '👋 $name a quitté la partie.',
        de: '👋 $name hat das Spiel verlassen.',
        pt: '👋 $name saiu da partida.',
      );
  String get challengeOneTapBtn => challengeNowBtn;
  String get abilitiesSectionTitle => abilitiesTitle;
  String get abilitiesSectionSubtitle => abilitiesSubtitle;
  String abilityCooldownBadge(int sec) => '⏱ ${sec}s';
  String abilityUnlockLevelLabel(int lvl) => skinReachLevelReq(lvl);
  String get abilityEquippedBadge => _t(
        it: 'EQUIPAGGIATA',
        en: 'EQUIPPED',
        es: 'EQUIPADA',
        fr: 'ÉQUIPÉE',
        de: 'AUSGERÜSTET',
        pt: 'EQUIPADA',
      );
  String spectatorBannerSub(String opponentName) =>
      spectatingBannerTitle(opponentName);
  String get spectatorLeaveBtn => finishSpectatingBtn;
  String incomingInviteTitle(String name) => '⚔️ $name';
  String incomingInviteSub(String mode) => mode;
  String get friendsP2PBtn => friendsAndP2PBtn;
  String get abilitiesNavBtn => abilitiesTitle;
  String get ignoredTrailing => _t(
        it: '',
        en: '',
        es: '',
        fr: '',
        de: '',
        pt: '',
      );
}
