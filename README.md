# PsyGuard AI

[English](./README.md) | [繁體中文](./README.zh-TW.md)

## Project Overview

PsyGuard AI is a Flutter-based mental health companion app MVP. It provides AI companion chat, daily self-awareness check-ins, sleep tracking, risk observation, and trend analysis. The main app currently lives in `psyguard_ai_app`, stores user data in a local database, and calls an OpenAI-compatible API for AI chat.

## Features

- `AI companion`: Responds in a counselor-like style and uses previous conversation context.
- `Context memory`: Reads chat history and compresses older messages into summaries when needed.
- `High-risk protection`: Prioritizes safety guidance and human support resources when high-risk language is detected.
- `Daily check-ins`: Records mood, stress, energy, and notes.
- `Sleep tracking`: Records sleep duration, bedtime, and sleep difficulty.
- `Trend analysis`: Presents recent mental and physical changes through charts and AI reports.
- `Local storage`: Stores chats, records, and risk snapshots in local SQLite.
- `Language settings`: Supports English and Traditional Chinese in settings, defaults to English, and applies the preference to AI replies.
- `Voice settings`: Allows users to adjust AI response speech playback speed.

## Tech Stack

- `Frontend`: Flutter
- `State management`: Riverpod
- `Routing`: GoRouter
- `Database`: Drift + SQLite
- `Networking`: Dio
- `Voice features`: `speech_to_text`, `flutter_tts`
- `AI integration`: OpenAI-compatible `chat/completions` API

## Project Structure

```text
.
├── README.md
├── README.zh-TW.md
├── LICENSE
└── psyguard_ai_app
    ├── README.md
    ├── lib
    ├── test
    ├── integration_test
    └── pubspec.yaml
```

## Local Testing Guide

1. Enter the app directory:
   ```bash
   cd psyguard_ai_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Regenerate Drift and test-related generated code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run static analysis:
   ```bash
   flutter analyze
   ```
5. Run tests:
   ```bash
   flutter test
   ```
6. If the app icon is updated, regenerate platform icons:
   ```bash
   cd psyguard_ai_app
   dart run flutter_launcher_icons
   ```
7. To verify the Web build:
   ```bash
   cd psyguard_ai_app
   flutter build web
   ```

## Environment Variables

Set the following variables in `psyguard_ai_app/.env`:

```env
API_BASE_URL=https://api.openai.com
API_KEY=your_api_key
AI_MODEL=gpt-4o-mini
APP_ENV=dev
```

Descriptions:

- `API_BASE_URL`: Base URL for the OpenAI-compatible API.
- `API_KEY`: API key for the model service.
- `AI_MODEL`: Model name shared by chat and analysis features.
- `APP_ENV`: Runtime environment label, such as `dev`, `staging`, or `prod`.

## Coolify Deployment Guide

This repository currently contains only the Flutter client. It does not include a backend service or container configuration that can be deployed directly to Coolify, so there is no verified Coolify deployment flow yet.

If a standalone API or Web service is added later, document the following:

- `Dockerfile` or deployable image configuration
- Coolify service setup steps
- Required environment variables
- Health checks and startup commands

## Frontend / Backend Documentation

- Frontend app documentation: [psyguard_ai_app/README.md](./psyguard_ai_app/README.md)
- Backend documentation: No standalone backend directory currently exists.
