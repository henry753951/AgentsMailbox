# Agents Mailbox

A small native macOS reader for the
[`cloudflare-catchall-mailbox`](https://github.com/henry753951/cloudflare-catchall-mailbox)
API. It offers server-side search, attachment filtering, message details, and
raw EML export.

The app is intentionally read-only. API credentials are stored in macOS
Keychain and are never written to project files or UserDefaults.

## Requirements

- macOS 15 or later; Liquid Glass is used on macOS 26 or later
- Xcode 26 or later
- A mailbox API Bearer token

## Build

```sh
make check
```

Open `AgentsMailbox.xcodeproj` in Xcode to run the app. In Settings, enter the
API URL and save the Bearer token to Keychain. The defaults match the Codex
`agents-mailbox` skill:

- API URL: `https://api.agents.hongyu.dev`
- Keychain service: `agents.hongyu.dev-mailbox-api`
- Keychain account: `codex-agent`

## Updates and releases

The app uses Sparkle for signed in-app updates. Pushing a `v*` tag starts the
release workflow, which builds the app, creates a DMG, generates a signed
`appcast.xml`, and publishes both files to GitHub Releases. The repository must
have a `SPARKLE_PRIVATE_KEY` Actions secret.

## License

MIT
