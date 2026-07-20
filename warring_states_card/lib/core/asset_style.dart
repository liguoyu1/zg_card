/// 卡面风格
enum AssetStyle {
  chibiCute('chibi_cute'),
  fantasyRpg('fantasy_rpg');

  final String dirName;
  const AssetStyle(this.dirName);

  static AssetStyle current = AssetStyle.fantasyRpg;
}
