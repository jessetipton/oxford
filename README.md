# 📖 Oxford

[![CI](https://github.com/jessetipton/oxford/actions/workflows/ci.yml/badge.svg)](https://github.com/jessetipton/oxford/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![macOS](https://img.shields.io/badge/macOS-only-blue)

A command-line tool for looking up word definitions, synonyms, and antonyms using the New Oxford American Dictionary and Oxford American Writer's Thesaurus that come with macOS.

## Installation

The easiest way to install is with [Mint](https://github.com/yonaskolb/Mint):

```
mint install jessetipton/oxford
```

## Usage

```
oxford <word>
oxford <word> --thesaurus
```

### Example

```
$ oxford superlative

  superlative  | səˈpərlədiv |
  su·per·la·tive

  adjective
  1 of the highest quality or degree: a superlative piece of skill.
  2 Grammar (of an adjective or adverb) expressing the highest or a very high
    degree of a quality (e.g. bravest, most fiercely). Contrasted with positive,
    and comparative noun 1 Grammar a superlative adjective or adverb.
    · (the superlative) the highest degree of comparison.
  2 (usually superlatives) an exaggerated or hyperbolical expression of praise:
    the critics ran out of superlatives to describe him.
  3 something or someone embodying excellence: chili has become the superlative
    among spices.

  DERIVATIVES
  superlativeness | səˈpərlədivnəs | noun

  ORIGIN
  late Middle English: from Old French superlatif, -ive, from late Latin
  superlativus, from Latin superlatus 'carried beyond', past participle of
  superferre.
```

Multi-word lookups require quoting:

```
$ oxford "ice cream"
```
