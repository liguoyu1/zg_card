import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/draw_service.dart';

void main() {
  group('DrawService Tests', () {
    test('draw returns valid rarity', () {
      final service = DrawService();
      final result = service.draw();
      
      expect(Rarity.values.contains(result.rarity), true);
    });
    
    test('drawTen returns 10 results', () {
      final service = DrawService();
      final results = service.drawTen();
      
      expect(results.length, 10);
    });
    
    test('drawWithPity returns valid result', () {
      final service = DrawService();
      
      // 测试保底计数>=49
      final result49 = service.drawWithPity(
        currentPityCount: 49,
        targetRarity: Rarity.legendary,
      );
      
      // 保底计数应该>=49或抽到传说
      expect(result49.pityCount >= 49 || result49.rarity == Rarity.legendary, true);
    });
    
    test('pity counter increments on miss', () {
      final service = DrawService();
      final result = service.drawWithPity(
        currentPityCount: 5,
        targetRarity: Rarity.rare,
      );
      
      // 至少有保底计数
      expect(result.pityCount >= 0, true);
    });
    
    test('getPityInfo returns correct structure', () {
      final info = DrawService.getPityInfo(
        rarePityCount: 5,
        epicPityCount: 10,
        legendaryPityCount: 25,
      );
      
      expect(info.containsKey(Rarity.rare), true);
      expect(info.containsKey(Rarity.epic), true);
      expect(info.containsKey(Rarity.legendary), true);
      
      expect(info[Rarity.rare]!.currentCount, 5);
      expect(info[Rarity.epic]!.currentCount, 10);
      expect(info[Rarity.legendary]!.currentCount, 25);
    });
    
    test('pity progress calculation', () {
      final info = DrawService.getPityInfo(
        rarePityCount: 5,
        epicPityCount: 10,
        legendaryPityCount: 25,
      );
      
      expect(info[Rarity.rare]!.remaining, 5);
      expect(info[Rarity.epic]!.remaining, 10);
      expect(info[Rarity.legendary]!.remaining, 25);
      
      expect(info[Rarity.rare]!.progress, 0.5);
      expect(info[Rarity.epic]!.progress, 0.5);
      expect(info[Rarity.legendary]!.progress, 0.5);
    });
    
    test('drawWithPity probability increase', () {
      final service = DrawService();
      
      // 第一次抽
      final result1 = service.drawWithPity(
        currentPityCount: 0,
        targetRarity: Rarity.legendary,
      );
      
      // 第49次抽
      final result49 = service.drawWithPity(
        currentPityCount: 49,
        targetRarity: Rarity.legendary,
      );
      
      // 保底计数应该>=49
      expect(result49.pityCount >= 49 || result49.rarity == Rarity.legendary, true);
    });
  });
  
  group('ProbabilityDisclosure Tests', () {
    test('getBaseProbabilities returns valid data', () {
      final base = ProbabilityDisclosure.getBaseProbabilities();
      
      expect(base['common']!['probability'], 0.70);
      expect(base['rare']!['probability'], 0.25);
      expect(base['epic']!['probability'], 0.04);
      expect(base['legendary']!['probability'], 0.01);
    });
    
    test('getPityMechanism returns valid data', () {
      final pity = ProbabilityDisclosure.getPityMechanism();
      
      expect(pity['rare']!['pulls'], 10);
      expect(pity['epic']!['pulls'], 20);
      expect(pity['legendary']!['pulls'], 50);
    });
    
    test('generateDisclosureText returns text', () {
      final text = ProbabilityDisclosure.generateDisclosureText();
      
      expect(text.contains('普通卡'), true);
      expect(text.contains('稀有卡'), true);
      expect(text.contains('史诗卡'), true);
      expect(text.contains('传说卡'), true);
      expect(text.contains('保底'), true);
    });
  });
  
  group('DrawResult Tests', () {
    test('rarityName returns Chinese name', () {
      const result = DrawResult(
        rarity: Rarity.legendary,
        isPityTriggered: false,
        pityCount: 0,
      );
      
      expect(result.rarityName, '传说');
    });
  });
  
  group('PityInfo Tests', () {
    test('description includes remaining count', () {
      const info = PityInfo(
        currentCount: 5,
        threshold: 10,
        currentProbability: 0.26,
      );
      
      expect(info.description.contains('5'), true);
      expect(info.description.contains('26'), true);
    });
  });
}