# New Mac Setup

Markdown files become guided setup cards for macOS onboarding.

This app is useful when a team wants repeatable setup guides for new Macs, new projects, or onboarding sessions. Write one Markdown guide, drag it into the app or add it with the `+` button, and teammates can follow sections, check off steps, copy commands, run safe commands, and see warnings in context.

## What It Does

- Loads Markdown setup guides as sidebar sections and step cards.
- Starts empty; no sample guide is bundled into the app.
- Turns fenced `bash` code blocks into copy/run command cards.
- Tracks completed steps locally.
- Supports guide metadata, comments, callouts, and red bold emphasis.
- Includes a reusable guide format and template for future projects.

## Usage

Launch the app, then drag a `.md` guide file into the window or click the `+` button in the sidebar. Removing a guide only removes it from the app list; the original Markdown file stays where it is.

## Guide Format

Start with front matter:

```md
---
title: ProjectName 개발환경 세팅
summary: 새 Mac에서 ProjectName을 실행할 수 있게 만드는 가이드입니다.
version: 1.0
owner: Team Name
updated: 2026-07-09
estimated: 30분
---
```

Use headings and code blocks:

- `##` becomes a sidebar section.
- `###` becomes a checkable card.
- Fenced `bash` code blocks become command cards.
- `<!-- comments -->` are hidden in the app.
- `> [!IMPORTANT]`, `> [!WARNING]`, and `> [!DANGER]` become colored callouts.
- `{{red:important text}}` becomes red bold text in the app.

See [MacSetup/GUIDE_FORMAT.md](MacSetup/GUIDE_FORMAT.md) and [MacSetup/Templates/MacSetupGuideTemplate.md](MacSetup/Templates/MacSetupGuideTemplate.md).

## Build

Requirements:

- macOS 14+
- Xcode
- XcodeGen

```bash
cd MacSetup
xcodegen generate
xcodebuild -project MacSetup.xcodeproj -scheme MacSetup -configuration Debug -sdk macosx build
```

## Public Repo Safety

The repository intentionally ignores local build outputs, Xcode user state, local agent settings, and common secret files such as `GoogleService-Info.plist`, `*.pem`, `*.key`, and `*.p8`.

Project-specific internal setup guides should be kept as `*.private.md`, `*.local.md`, or outside the repository.
