# AGENTS.md

## Project overview

`oxford` is a macOS CLI tool that looks up word definitions and synonyms using the DictionaryServices framework. It is a Swift package with an executable target and a library target.

## Architecture

- `Package.swift` — Swift package manifest. Executable target (`Oxford`) and library target (`OxfordKit`) with swift-argument-parser and Rainbow dependencies.
- `Sources/Oxford/OxfordCommand.swift` — Entry point. Contains the `OxfordCommand` (swift-argument-parser) which routes to dictionary or thesaurus output.
- `Sources/OxfordKit/Formatter.swift` — Output formatting with ANSI styling via Rainbow.
- `Sources/OxfordKit/DictionaryService.swift` — Low-level DictionaryServices API bindings. Looks up words in the Oxford dictionary and thesaurus.
- `Tests/OxfordTests/` — Tests for `OutputFormatter` (definition/thesaurus formatting, text wrapping, edge cases).

## Key technical details

- Uses DictionaryServices private APIs (`DCSCopyTextDefinition`, `DCSCopyRecordsForSearchString`, etc.) from CoreServices.
- macOS-only. DictionaryServices is not available on iOS/Linux.
- Swift 6.2 with strict concurrency. The dictionary lookup is synchronous and has no concurrency concerns.

## Building and testing

```
swift build
swift test
swift run oxford <word>
swift run oxford <word> --thesaurus
```

## Conventions

- Keep it simple. This is a small, focused tool.
- Use swift-argument-parser idioms: `@Argument`, `@Flag`, `ParsableCommand`, `ValidationError` for user-facing errors.
