---
title: ProjectName 개발환경 세팅
summary: 새 Mac에서 ProjectName을 클론, 빌드, 실행할 수 있게 만드는 실행형 가이드입니다.
version: 1.0
owner: Team Name
updated: 2026-07-09
estimated: 30-45분
---

<!--
MacSetup 앱 작성 규칙:
- H2(##)는 사이드바 섹션입니다.
- H3(###)는 체크 가능한 작업 카드입니다.
- ```bash 코드블록은 실행/복사 가능한 명령 카드입니다.
- > [!IMPORTANT], > [!WARNING], > [!DANGER]는 안내칸입니다.
- {{red:강조 문구}}는 빨간 굵은 글씨입니다.
-->

# ProjectName 개발환경 세팅

## 0. 시작 전 확인

### 준비물 확인

> [!IMPORTANT]
> GitHub 저장소 접근 권한과 로컬 설정 파일이 준비되어야 이후 단계가 막히지 않습니다.

- GitHub 계정
- 저장소 접근 권한
- 프로젝트별 로컬 설정 파일

## 1. 기본 도구 설치

### Homebrew 패키지 설치

필요한 패키지를 프로젝트에 맞게 수정합니다.

```bash
brew install git node
```

## 2. 프로젝트 준비

### 프로젝트 클론

```bash
mkdir -p ~/dev
cd ~/dev
git clone git@github.com:ORG/PROJECT.git
cd PROJECT
```

### 개인 Git 설정

> [!DANGER]
> `YOUR_EMAIL`은 {{red:본인 회사 이메일로 교체}}한 뒤 실행합니다.

```bash
git config user.email "YOUR_EMAIL"
```

## 3. 빌드와 실행

### 의존성 설치

```bash
# 프로젝트에 맞는 설치 명령으로 교체
echo "install dependencies"
```

### 빌드 확인

```bash
# 프로젝트에 맞는 빌드 명령으로 교체
echo "build project"
```

## 4. 트러블슈팅

### GitHub 접근 실패

```bash
ssh -T git@github.com
```
