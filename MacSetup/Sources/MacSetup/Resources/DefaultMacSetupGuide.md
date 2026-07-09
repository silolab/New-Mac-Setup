---
title: Sample Project Mac Setup
summary: 새 Mac에서 예시 프로젝트를 클론, 의존성 설치, 빌드, 실행 확인까지 진행하는 공개용 샘플 가이드입니다.
version: 1.1
owner: Example Team
updated: 2026-07-09
estimated: 40-60분
---

<!--
작성 규칙:
- H2(##)는 사이드바 섹션이 됩니다.
- H3(###)는 체크 가능한 앱 카드가 됩니다.
- ```bash 코드블록은 실행/복사 가능한 명령 카드가 됩니다.
- > [!IMPORTANT], > [!WARNING], > [!DANGER]는 색상 안내칸으로 표시됩니다.
- {{red:중요 문구}}는 빨간색 굵은 글씨로 표시됩니다.
-->

# Sample Project Mac Setup Guide

새 Mac을 받은 구성원이 개발 환경을 빠르게 맞추고, 예시 프로젝트를 클론/빌드/실행할 수 있도록 정리한 실행형 가이드입니다.

## 0. 시작 전 확인

### 준비물 확인

> [!IMPORTANT]
> 이 단계에서 GitHub 권한과 로컬 설정 파일이 준비되지 않으면 뒤쪽 빌드 단계에서 멈춥니다.

- Apple ID로 App Store 로그인
- GitHub 계정과 저장소 접근 권한
- Claude Code 사용 권한
- 프로젝트별 로컬 설정 파일

### 작업 폴더 만들기

```bash
mkdir -p ~/dev
```

## 1. Xcode 준비

### Xcode 설치 후 Command Line Tools 지정

App Store에서 Xcode 설치를 마치고 첫 실행까지 완료한 뒤 실행합니다.

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

### Xcode 라이선스 동의

처음 설치한 Mac에서는 빌드 전에 라이선스 동의가 필요할 수 있습니다.

```bash
sudo xcodebuild -license accept
```

## 2. Homebrew 준비

### Homebrew 설치

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Apple Silicon PATH 등록

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/.zprofile
```

### 기본 도구 설치

```bash
brew install git node pandoc
brew install --cask warp
```

## 3. GitHub 접근 설정

### Git 사용자 정보 설정

`YOUR_NAME`, `YOUR_EMAIL`을 본인 정보로 바꾼 뒤 실행합니다.

> [!DANGER]
> `YOUR_NAME`, `YOUR_EMAIL`을 그대로 실행하지 마세요. {{red:반드시 본인 이름과 이메일로 바꾼 뒤}} 실행합니다.

```bash
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_EMAIL"
git config --global init.defaultBranch main
```

### SSH 키 생성

기존 키가 있으면 새로 만들지 않고 그대로 사용합니다.

> [!NOTE]
> 아래 명령은 기존 공개키가 없을 때만 새 키를 만듭니다.

```bash
mkdir -p ~/.ssh
test -f ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### 공개키 확인

출력된 키를 GitHub의 `Settings > SSH and GPG keys > New SSH key`에 등록합니다.

```bash
cat ~/.ssh/id_ed25519.pub
```

### GitHub 연결 확인

```bash
ssh -T git@github.com
```

## 4. Claude Code 준비

### Claude Code 설치

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### Claude Code 로그인

브라우저가 열리면 계정으로 로그인합니다.

> [!WARNING]
> 로그인처럼 브라우저 인증이 필요한 명령은 앱 내 실행보다 Terminal 버튼으로 여는 것을 권장합니다.

```bash
claude login
```

### 기본 작업 규칙 만들기

자동 커밋을 막고, 빌드 확인을 우선하도록 전역 규칙을 만듭니다.

```bash
mkdir -p ~/.claude
printf '%s\n' '# 기본 규칙' '- 사용자가 명시하지 않으면 자동 커밋하지 않는다.' '- 코드 수정 후 가능한 경우 빌드나 테스트로 확인한다.' > ~/.claude/CLAUDE.md
```

## 5. 예시 프로젝트 준비

### 프로젝트 클론

```bash
cd ~/dev
git clone git@github.com:ORG/PROJECT.git
cd PROJECT
```

### Swift Package 의존성 받기

```bash
cd ~/dev/PROJECT
xcodebuild -resolvePackageDependencies -project PROJECT.xcodeproj -scheme PROJECT
```

### 로컬 설정 파일 배치

프로젝트별 로컬 설정 파일은 Git에 들어가지 않게 관리합니다. 샘플을 복사한 뒤 실제 값으로 수정합니다.

> [!IMPORTANT]
> 로컬 설정 값이 비어 있으면 앱이 빌드되더라도 런타임 연결에서 실패할 수 있습니다.

```bash
cp ~/dev/PROJECT/Config.local.sample.json ~/dev/PROJECT/Config.local.json
open ~/dev/PROJECT/Config.local.json
```

## 6. 빌드와 실행

### 터미널 Debug 빌드

```bash
cd ~/dev/PROJECT
xcodebuild -project PROJECT.xcodeproj -scheme PROJECT -configuration Debug -sdk macosx build
```

### Xcode에서 열기

```bash
open ~/dev/PROJECT/PROJECT.xcodeproj
```

## 7. macOS 권한 확인

### 앱 권한 초기화

권한 팝업이 꼬였거나 다시 허용해야 할 때만 실행합니다.

> [!WARNING]
> 아래 명령은 기존 권한 허용 상태를 초기화합니다. 권한 팝업이 다시 떠야 하는 상황에서만 사용하세요.

```bash
tccutil reset AppleEvents com.example.PROJECT
tccutil reset MediaLibrary com.example.PROJECT
```

### 권한 위치

- 시스템 설정 > 개인정보 보호 및 보안 > 자동화 > 앱 제어 허용
- 시스템 설정 > 개인정보 보호 및 보안 > 미디어 및 Apple Music > 앱 허용

## 8. 배포 빌드

### 릴리즈 아카이브 만들기

```bash
cd ~/dev/PROJECT
xcodebuild -project PROJECT.xcodeproj -scheme PROJECT -configuration Release -sdk macosx archive -archivePath /tmp/PROJECT_latest.xcarchive
```

### zip 패키징

```bash
TIMESTAMP=$(date +"%Y%m%d_%H%M")
APP_PATH="/tmp/PROJECT_latest.xcarchive/Products/Applications/PROJECT.app"
DIST_DIR="$HOME/dev/PROJECT/dist"
mkdir -p "$DIST_DIR"
ditto -c -k --keepParent "$APP_PATH" "$DIST_DIR/PROJECT_${TIMESTAMP}.zip"
echo "릴리즈 완료: $DIST_DIR/PROJECT_${TIMESTAMP}.zip"
```

## 9. 자주 막히는 지점

### GitHub Push 또는 Clone 실패

```bash
ssh -T git@github.com
```

### Xcode 인덱싱 오류 확인

SourceKit 오류처럼 보여도 실제 빌드가 성공하면 인덱싱 문제일 수 있습니다.

```bash
cd ~/dev/PROJECT
xcodebuild -project PROJECT.xcodeproj -scheme PROJECT -configuration Debug -sdk macosx build
```

### Claude Code 재설치

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```
