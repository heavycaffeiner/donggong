# 동공 (Donggong)

**Donggong**은 세련된 Material Design 3 (MD3) 기반의 현대적인 히토미(Hitomi) 리더 앱입니다. 사용자 경험을 최우선으로 고려하여 설계되었으며, 빠르고 직관적인 인터페이스를 제공합니다.

## ✨ 주요 특징 (Key Features)

### 1. 현대적인 UI/UX (Material Design 3)
- 최신 **Material Design 3** 가이드라인을 준수한 깔끔하고 미려한 디자인을 제공합니다.
- **다크 모드(Dark Mode)** 및 **OLED 다크 모드**를 완벽하게 지원하여 눈의 피로를 줄이고 배터리를 절약합니다.
- 부드러운 애니메이션과 직관적인 제스처로 쾌적한 사용성을 보장합니다.

### 2. 강력한 갤러리 탐색 및 리더
- **빠른 이미지 로딩**: 최적화된 캐싱 시스템으로 끊김 없는 감상을 지원합니다.
- **몰입형 리더**: 불필요한 요소를 최소화하여 콘텐츠에 집중할 수 있는 뷰어 환경을 제공합니다.
- **태그 및 검색**: 태그 시스템을 통해 원하는 콘텐츠를 쉽고 빠르게 찾을 수 있습니다.

### 3. 스마트한 즐겨찾기 관리 (Favorites Management)
- **간편한 백업 및 복구**: JSON 파일 형식으로 즐겨찾기 목록을 내보내거나 가져올 수 있어, 기기 변경 시에도 데이터를 안전하게 보존할 수 있습니다.
- **데이터 유효성 검사**: 삭제되거나 유효하지 않은 갤러리를 자동으로 감지하고 정리하는 'Clean Up' 기능을 제공합니다.
- **로컬 저장소**: 모든 데이터는 기기 내부에 안전하게 저장되며, 외부 서버로 전송되지 않습니다.

### 4. 사용자 편의 기능
- **최근 본 목록 (Recent)**: 감상했던 갤러리를 자동으로 기록하여 언제든 다시 찾아볼 수 있습니다.
- **다국어 지원**: 한국어, 영어, 일본어 등 다양한 언어 환경을 지원합니다.
- **설정 최적화**: 사용자의 취향에 맞춰 앱의 동작과 테마를 세밀하게 설정할 수 있습니다.

## 🛠 기술 스택 (Tech Stack)
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Riverpod (riverpod_annotation)
- **Local Database**: SQLite (sqflite)
- **Metadata Handling**: metadata_god
- **Network**: http, cached_network_image

## 🚀 설치 및 실행
이 프로젝트는 Flutter로 개발되었습니다.

```bash
# 의존성 패키지 설치
flutter pub get

# 코드 생성 (build_runner)
dart run build_runner build -d

# 앱 실행
flutter run
```
