import 'dart:ui';

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
      final sysCode = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      for (final lang in AppLanguage.values) {
        if (lang.code == sysCode) return lang;
      }
      return AppLanguage.it;
    }
    final clean = code.toLowerCase();
    for (final lang in AppLanguage.values) {
      if (lang.code == clean) return lang;
    }
    return AppLanguage.it;
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
        it: 'SCALATA LIVELLI (1, 2, 3...)',
        en: 'LEVEL CLIMB (1, 2, 3...)',
        es: 'NIVELES (1, 2, 3...)',
        fr: 'NIVEAUX (1, 2, 3...)',
        de: 'LEVEL-AUFSTIEG (1, 2, 3...)',
        pt: 'NÍVEIS (1, 2, 3...)',
      );

  String modeDailyTab(int issue) => _t(
        it: 'TORRE DI OGGI (#$issue)',
        en: 'TODAY\'S TOWER (#$issue)',
        es: 'TORRE DE HOY (#$issue)',
        fr: 'TOUR DU JOUR (#$issue)',
        de: 'TAGESTURM (#$issue)',
        pt: 'TORRE DE HOJE (#$issue)',
      );

  String topRankBadgeLevels(int rank, int level) => _t(
        it: '🏆 CLASSIFICA #$rank • LIV. $level',
        en: '🏆 RANK #$rank • LVL $level',
        es: '🏆 RANKING #$rank • NIV. $level',
        fr: '🏆 CLASSEMENT #$rank • NIV. $level',
        de: '🏆 RANG #$rank • LVL $level',
        pt: '🏆 RANKING #$rank • NÍV. $level',
      );

  String topRankBadgeDaily(int rank, int issue) => _t(
        it: '🏆 OGGI #$rank • TORRE #$issue',
        en: '🏆 TODAY #$rank • TOWER #$issue',
        es: '🏆 HOY #$rank • TORRE #$issue',
        fr: '🏆 JOUR #$rank • TOUR #$issue',
        de: '🏆 HEUTE #$rank • TURM #$issue',
        pt: '🏆 HOJE #$rank • TORRE #$issue',
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

  String leaderboardDailyTitle(int issue) => _t(
        it: 'CLASSIFICA TORRE DI OGGI (#$issue)',
        en: 'TODAY\'S TOWER LEADERBOARD (#$issue)',
        es: 'CLASIFICACIÓN TORRE DE HOY (#$issue)',
        fr: 'CLASSEMENT TOUR DU JOUR (#$issue)',
        de: 'TAGESTURM-RANGLISTE (#$issue)',
        pt: 'RANKING TORRE DE HOJE (#$issue)',
      );

  String get leaderboardLevelsSub => _t(
        it: 'I livelli sono identici per tutti: chi raggiunge il livello più alto domina la torre!',
        en: 'Levels are identical for everyone: reach the highest level to rule the tower!',
        es: 'Los niveles son idénticos para todos: ¡llega al nivel más alto de la torre!',
        fr: 'Les niveaux sont identiques pour tous : atteignez le plus haut niveau !',
        de: 'Alle Level sind für jeden gleich: Erreiche das höchste Level im Turm!',
        pt: 'Os níveis são idênticos para todos: alcance o nível mais alto da torre!',
      );

  String get leaderboardDailySub => _t(
        it: 'Classifica sulla Torre di Oggi (100m): confronta il tuo record quotidiano!',
        en: 'Today\'s 100m Tower ranking: compare your daily best climb!',
        es: 'Clasificación en la Torre de Hoy (100m): ¡compara tu récord diario!',
        fr: 'Classement sur la Tour du Jour (100m) : comparez votre record quotidien !',
        de: 'Rangliste für den heutigen 100m-Turm: Vergleiche deinen Tagesrekord!',
        pt: 'Ranking na Torre de Hoje (100m): compare seu recorde diário!',
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
}
