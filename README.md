# mv

Telegram-like chat UI mock in Flutter.

## Run

```
npm run start:dev
```

## Message types

- Text
- Audio: JSON mocks support `type: "audio"` with `audio` object fields:
  - `durationSec` (int)
  - `sizeBytes` (int)
  - `url` (string, asset path or network URL)
  - `waveform` (list[int], optional)

UI renders audio via `AudioMessage` widget inside `MessageBubble`.
