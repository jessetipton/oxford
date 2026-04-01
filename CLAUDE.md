# CLAUDE.md

## Project overview

`oxford` is a macOS CLI tool that looks up word definitions and synonyms using the DictionaryServices framework. Swift package with an executable target (`Oxford`) and a library target (`DictionaryKit`).

## Building and testing

```
swift build
swift test
swift run oxford <word>
swift run oxford <word> --thesaurus
```

## Architecture

- `Sources/DictionaryKit/DictionaryService.swift` — Low-level DictionaryServices private API bindings. Public functions: `lookUp(_:in:)` and `lookUpWord(_:)`.
- `Sources/Oxford/OxfordCommand.swift` — CLI entry point using swift-argument-parser.
- `Sources/Oxford/Formatter.swift` — Parses raw dictionary text and formats with ANSI styling via Rainbow.
- `Tests/DictionaryKitTests/` — Tests for dictionary lookup functions.
- `Tests/OxfordTests/` — Tests for `OutputFormatter` (definition/thesaurus formatting, text wrapping, edge cases).

## Conventions

- Keep it simple. This is a small, focused tool.
- Use swift-argument-parser idioms: `@Argument`, `@Flag`, `ParsableCommand`, `ValidationError` for user-facing errors.
- macOS-only. DictionaryServices is not available on other platforms.
- Swift 6.2 with strict concurrency.
- `OutputFormatter` has an `init(isTTY:terminalWidth:)` for testing with deterministic settings. Use `isTTY: false` in tests to disable ANSI codes.
