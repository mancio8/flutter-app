import 'package:flutter/material.dart';
import 'x01_game.dart';

class DartsPlayer {
  const DartsPlayer({
    this.id,
    required this.name,
    this.avatar = '🎯',
    this.color = '#00d68f',
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.avgPpr = 0,
  });

  final String? id; // null = ospite
  final String name;
  final String avatar;
  final String color;
  final int gamesPlayed;
  final int gamesWon;
  final double avgPpr;

  bool get isRegistered => id != null;

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.teal;
    }
  }

  factory DartsPlayer.fromJson(Map<String, dynamic> j) => DartsPlayer(
        id: j['id'] as String?,
        name: j['name'] ?? '',
        avatar: j['avatar'] ?? '🎯',
        color: j['color'] ?? '#00d68f',
        gamesPlayed: j['games_played'] ?? 0,
        gamesWon: j['games_won'] ?? 0,
        avgPpr: (j['avg_ppr'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is DartsPlayer &&
      (isRegistered
          ? other.id == id
          : (!other.isRegistered && other.name == name));

  @override
  int get hashCode => isRegistered ? id.hashCode : name.hashCode;
}

enum DartsMode { x01, cricket }

class DartsGameConfig {
  const DartsGameConfig({
    required this.players,
    this.mode = DartsMode.x01,
    this.startScore = 501,
    this.outRule = OutRule.double,
  });

  final List<DartsPlayer> players;
  final DartsMode mode;
  final int startScore;
  final OutRule outRule;

  bool get isSolo => players.length == 1;
}