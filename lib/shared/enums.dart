/// 공유 열거형 (Presentation/Domain 모두 사용)
library;

enum CustomScreen {
  home(0, '홈'),
  recentViewed(1, '최근 본 작품'),
  favorites(2, '즐겨찾기'),
  settings(3, '설정'),
  reader(-1, '');

  final int tabIndex;
  final String title;
  const CustomScreen(this.tabIndex, this.title);

  int get stackIndex => tabIndex < 0 ? 0 : tabIndex;
}
