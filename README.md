# PromptDock

PromptDock is a small native macOS menu bar app for rewriting rough ideas, bug notes, refactor requests, and clipboard text into clearer prompts for AI coding agents such as Codex, Claude Code, Cursor, ChatGPT, and generic OpenAI-compatible tools.

## Features

- Menu bar app with no Dock icon by default. Left-click the menu bar icon to open the popover; right-click or Control-click for the app menu.
- Global hotkey: Command + Option + P.
- Prompt modes for Codex development tasks, bug fixes, refactors, code reviews, requirement breakdowns, and general prompt optimization.
- Target tool guidance for Codex, Claude Code, Cursor, ChatGPT, and generic agents.
- OpenAI-compatible Chat Completions API client using async/await.
- API key storage in macOS Keychain.
- Local JSON history store in Application Support.
- Clipboard optimization flow that only sends clipboard text after the user selects Optimize Clipboard.

## Run Locally

1. Open `PromptDock.xcodeproj` in Xcode 26 or newer.
2. Select the `PromptDock` scheme.
3. Build and run on macOS 14 or newer.

You can also build from Terminal:

```sh
xcodebuild -scheme PromptDock -configuration Debug build
```

## API Configuration

Open Settings from the menu bar menu or the gear button in the popover, then set:

- API Provider Name
- Base URL, for example `https://api.openai.com/v1`
- API Key
- Model Name
- Temperature
- Max Tokens
- Optional extra headers

PromptDock sends requests to:

```text
POST {baseURL}/chat/completions
```

The API key is sent as a Bearer token and is stored in Keychain, not in UserDefaults or JSON files. When editing settings later, leave the API Key field blank to keep the existing Keychain value.

## Privacy

- PromptDock does not include a fixed backend.
- User input is sent only to the API provider configured by the user.
- Clipboard text is not uploaded automatically; it is sent only after Optimize Clipboard is selected.
- API keys are stored in macOS Keychain.
- History is stored locally as JSON under Application Support.
- Authorization headers are not logged.

## Tests

Run:

```sh
xcodebuild -scheme PromptDock -configuration Debug test
```

Current unit coverage includes:

- Prompt template generation by mode and target tool.
- API configuration defaults and URL validation.
- OpenAI-compatible request body, response parsing, and API error handling.
- Local history save, load, and clear behavior.

## Known Limits

- The global hotkey is fixed to Command + Option + P.
- The first API implementation targets OpenAI-compatible Chat Completions only.
- Extra headers are configured as simple `Name: Value` lines.
- History uses a local JSON file; SQLite or CoreData can be added later.
- The app is an MVP and does not implement sync, accounts, login, or plugin systems.
