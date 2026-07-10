import 'package:equatable/equatable.dart';
import 'card.dart';

/// 卡组模型
class Deck extends Equatable {
  
  const Deck({
    required this.id,
    required this.name,
    required this.heroId,
    required this.cards,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String heroId;
  final List<Card> cards;
  final DateTime createdAt;
  
  /// 卡组是否有效
  bool get isValid => cards.length == 30;
  
  /// 复制卡组
  Deck copyWith({
    String? id,
    String? name,
    String? heroId,
    List<Card>? cards,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      heroId: heroId ?? this.heroId,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [id, name, heroId, cards.length, createdAt];
}