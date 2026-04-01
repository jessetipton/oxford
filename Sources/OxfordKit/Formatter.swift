import Foundation
@preconcurrency import Rainbow

private func configureRainbow(enabled: Bool) {
    Rainbow.enabled = enabled
}

package struct OutputFormatter {
    package let isTTY: Bool
    package let terminalWidth: Int

    package init() {
        self.isTTY = isatty(STDOUT_FILENO) != 0
        if let cols = ProcessInfo.processInfo.environment["COLUMNS"],
           let width = Int(cols) {
            self.terminalWidth = width
        } else {
            var ws = winsize()
            if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0, ws.ws_col > 0 {
                self.terminalWidth = Int(ws.ws_col)
            } else {
                self.terminalWidth = 80
            }
        }
        configureRainbow(enabled: self.isTTY)
    }

    package init(isTTY: Bool, terminalWidth: Int) {
        self.isTTY = isTTY
        self.terminalWidth = terminalWidth
        configureRainbow(enabled: isTTY)
    }

    // MARK: - Definition formatting

    package func formatDefinition(_ text: String) -> String {
        var lines: [String] = [""]
        var remaining = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract headword and pronunciation
        if let head = extractHead(from: remaining) {
            lines.append("  " + head.word.bold + "  " + head.pronunciation.dim.italic)
            if !head.syllables.isEmpty && head.syllables != head.word {
                lines.append("  " + head.syllables.dim)
            }
            remaining = head.rest
        }

        lines.append("")
        lines.append(contentsOf: formatBody(remaining, source: .definition))
        lines.append("")
        return lines.joined(separator: "\n")
    }

    // MARK: - Thesaurus formatting

    package func formatThesaurus(_ text: String) -> String {
        var lines: [String] = [""]
        var remaining = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract headword (first word)
        if let spaceIdx = remaining.firstIndex(of: " ") {
            let word = String(remaining[..<spaceIdx])
            lines.append("  " + word.bold)
            remaining = String(remaining[remaining.index(after: spaceIdx)...])
                .trimmingCharacters(in: .whitespaces)
        }

        lines.append("")
        lines.append(contentsOf: formatBody(remaining, source: .thesaurus))
        lines.append("")
        return lines.joined(separator: "\n")
    }

    // MARK: - Head extraction

    private struct HeadInfo {
        let word: String
        let syllables: String
        let pronunciation: String
        let rest: String
    }

    private func extractHead(from text: String) -> HeadInfo? {
        guard let firstPipe = text.firstIndex(of: "|") else { return nil }
        let beforePipe = String(text[..<firstPipe]).trimmingCharacters(in: .whitespaces)
        let afterFirstPipe = text.index(after: firstPipe)
        guard afterFirstPipe < text.endIndex,
              let secondPipe = text[afterFirstPipe...].firstIndex(of: "|") else { return nil }

        let pronunciation = String(text[firstPipe...secondPipe])
        let rest = String(text[text.index(after: secondPipe)...]).trimmingCharacters(in: .whitespaces)

        let parts = beforePipe.split(separator: " ", maxSplits: 1)
        let word = parts.first.map(String.init) ?? beforePipe
        let syllables = parts.count > 1 ? String(parts[1]) : ""

        return HeadInfo(word: word, syllables: syllables, pronunciation: pronunciation, rest: rest)
    }

    // MARK: - Unified body formatting

    private enum Source {
        case definition
        case thesaurus
    }

    private func formatBody(_ text: String, source: Source) -> [String] {
        let segments = splitIntoSegments(text, source: source)
        var lines: [String] = []

        for segment in segments {
            switch segment.kind {
            case .partOfSpeech:
                lines.append("  " + segment.text.bold.cyan)
            case .numberedSense(let n):
                switch source {
                case .definition:
                    let content = highlightExamples(segment.text)
                    let label = "  " + "\(n)".bold.yellow + " "
                    lines.append(contentsOf: wrapText(content, indent: "    ", firstLineIndent: label))
                case .thesaurus:
                    let parts = splitExampleFromSynonyms(segment.text)
                    lines.append("")
                    lines.append("  " + "\(n)".bold.yellow + " " + parts.example.dim.italic)
                    if !parts.synonyms.isEmpty {
                        lines.append(contentsOf: wrapText(parts.synonyms, indent: "    "))
                    }
                }
            case .bullet:
                let content = highlightExamples(segment.text)
                let label = "    " + "·".dim + " "
                lines.append(contentsOf: wrapText(content, indent: "      ", firstLineIndent: label))
            case .sectionHeader(let header):
                lines.append("")
                lines.append("  " + header.bold.underline)
            case .antonyms:
                lines.append("    " + "Antonyms: ".bold + segment.text.italic)
            case .plain:
                let indent = source == .definition ? "  " : "    "
                lines.append(contentsOf: wrapText(segment.text, indent: indent))
            }
        }

        return lines
    }

    // MARK: - Segment splitting

    private enum SegmentKind {
        case partOfSpeech
        case numberedSense(Int)
        case bullet
        case sectionHeader(String)
        case antonyms
        case plain
    }

    private struct Segment {
        let kind: SegmentKind
        let text: String
    }

    private static let partsOfSpeech = Set([
        "noun", "verb", "adjective", "adverb", "exclamation", "preposition",
        "pronoun", "conjunction", "determiner", "prefix", "suffix",
    ])

    private func sectionHeaders(for source: Source) -> [String] {
        switch source {
        case .definition:
            return ["DERIVATIVES", "ORIGIN", "PHRASES", "USAGE"]
        case .thesaurus:
            return ["ANTONYMS", "WORD LINKS", "CHOOSE THE RIGHT WORD"]
        }
    }

    private func splitIntoSegments(_ text: String, source: Source) -> [Segment] {
        let headers = sectionHeaders(for: source)

        // Insert markers before known boundaries so we can split
        var marked = text

        for header in headers {
            marked = marked.replacingOccurrences(of: " \(header) ", with: "\n\(header) ")
            marked = marked.replacingOccurrences(of: ". \(header) ", with: ".\n\(header) ")
        }

        // Insert newlines before POS that follow ". " (end of previous section)
        for pos in Self.partsOfSpeech {
            marked = marked.replacingOccurrences(of: ". \(pos) ", with: ".\n\(pos) ")
        }

        // Insert newlines before numbered senses that follow ". "
        for n in 1...20 {
            marked = marked.replacingOccurrences(of: ". \(n) ", with: ".\n\(n) ")
        }

        // Insert newlines before bullets (definition only)
        if source == .definition {
            marked = marked.replacingOccurrences(of: " • ", with: "\n• ")
        }

        let rawLines = marked.split(separator: "\n", omittingEmptySubsequences: true).map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        var segments: [Segment] = []
        for line in rawLines {
            if line.isEmpty { continue }

            // Check ANTONYMS (thesaurus only)
            if source == .thesaurus && line.hasPrefix("ANTONYMS") {
                let content = String(line.dropFirst("ANTONYMS".count)).trimmingCharacters(in: .whitespaces)
                let cleaned = content.hasSuffix(".") ? String(content.dropLast()) : content
                segments.append(Segment(kind: .antonyms, text: cleaned))
                continue
            }

            // Check section headers
            var isHeader = false
            for header in headers where header != "ANTONYMS" {
                if line.hasPrefix(header) {
                    segments.append(Segment(kind: .sectionHeader(header), text: ""))
                    let content = String(line.dropFirst(header.count)).trimmingCharacters(in: .whitespaces)
                    if !content.isEmpty {
                        segments.append(Segment(kind: .plain, text: content))
                    }
                    isHeader = true
                    break
                }
            }
            if isHeader { continue }

            // Check POS
            var isPOS = false
            for pos in Self.partsOfSpeech {
                if line.hasPrefix(pos + " ") || line == pos {
                    let posContent = extractPOSContent(line, pos: pos)
                    segments.append(Segment(kind: .partOfSpeech, text: posContent.posText))
                    if !posContent.rest.isEmpty {
                        segments.append(contentsOf: splitIntoSegments(posContent.rest, source: source))
                    }
                    isPOS = true
                    break
                }
            }
            if isPOS { continue }

            // Check numbered sense
            if let (number, content) = extractNumberPrefix(line) {
                segments.append(Segment(kind: .numberedSense(number), text: content))
                continue
            }

            // Check bullet (definition only)
            if source == .definition && line.hasPrefix("•") {
                let content = String(line.dropFirst(line.hasPrefix("• ") ? 2 : 1))
                    .trimmingCharacters(in: .whitespaces)
                segments.append(Segment(kind: .bullet, text: content))
                continue
            }

            // Plain text
            segments.append(Segment(kind: .plain, text: line))
        }

        return segments
    }

    // MARK: - Helpers

    private func extractPOSContent(_ line: String, pos: String) -> (posText: String, rest: String) {
        // POS might be followed by parenthetical forms: "verb (runs, running, ...)"
        let afterPOS = String(line.dropFirst(pos.count)).trimmingCharacters(in: .whitespaces)

        if afterPOS.hasPrefix("(") {
            // Find matching close paren
            var depth = 0
            for (i, ch) in afterPOS.enumerated() {
                if ch == "(" { depth += 1 }
                if ch == ")" {
                    depth -= 1
                    if depth == 0 {
                        let endIdx = afterPOS.index(afterPOS.startIndex, offsetBy: i + 1)
                        let posText = pos + " " + String(afterPOS[..<endIdx])
                        let rest = String(afterPOS[endIdx...]).trimmingCharacters(in: .whitespaces)
                        return (posText, rest)
                    }
                }
            }
        }

        // Check if there's a numbered sense or section following
        if let (_, _) = extractNumberPrefix(afterPOS) {
            return (pos, afterPOS)
        }

        return (pos, afterPOS)
    }

    private func extractNumberPrefix(_ text: String) -> (Int, String)? {
        guard let first = text.first, first.isNumber else { return nil }
        // Allow multi-digit: "10 content..."
        var numEnd = text.startIndex
        while numEnd < text.endIndex && text[numEnd].isNumber {
            numEnd = text.index(after: numEnd)
        }
        guard numEnd < text.endIndex && text[numEnd] == " " else { return nil }
        guard let number = Int(text[text.startIndex..<numEnd]) else { return nil }
        let content = String(text[text.index(after: numEnd)...]).trimmingCharacters(in: .whitespaces)
        return (number, content)
    }

    private func highlightExamples(_ text: String) -> String {
        // Highlight bracket annotations like [no object], [with clause]
        var result = text
        let bracketPattern = try? NSRegularExpression(pattern: "\\[[^\\]]+\\]")
        if let matches = bracketPattern?.matches(in: result, range: NSRange(result.startIndex..., in: result)) {
            // Apply in reverse to preserve indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: result) {
                    let original = String(result[range])
                    result = result.replacingCharacters(in: range, with: original.dim)
                }
            }
        }

        return result
    }

    private func splitExampleFromSynonyms(_ text: String) -> (example: String, synonyms: String) {
        // Example ends at first ". " followed by a lowercase word
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "." {
                let nextIdx = text.index(after: i)
                if nextIdx < text.endIndex && text[nextIdx] == " " {
                    let afterDot = text.index(after: nextIdx)
                    if afterDot < text.endIndex && text[afterDot].isLowercase {
                        return (String(text[...i]), String(text[afterDot...]))
                    }
                }
            }
            i = text.index(after: i)
        }
        return (text, "")
    }

    // MARK: - Text wrapping

    private func wrapText(_ text: String, indent: String, firstLineIndent: String? = nil) -> [String] {
        let effectiveWidth = terminalWidth - indent.count
        guard effectiveWidth > 20 else { return [indent + text] }

        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else { return [] }

        var lines: [String] = []
        var currentLine = ""
        let firstIndent = firstLineIndent ?? indent
        let firstWidth = terminalWidth - stripANSI(firstIndent).count

        for word in words {
            let plainWord = stripANSI(word)
            if currentLine.isEmpty {
                currentLine = word
            } else {
                let maxWidth = lines.isEmpty ? firstWidth : effectiveWidth
                if stripANSI(currentLine).count + 1 + plainWord.count > maxWidth {
                    lines.append((lines.isEmpty ? firstIndent : indent) + currentLine)
                    currentLine = word
                } else {
                    currentLine += " " + word
                }
            }
        }
        if !currentLine.isEmpty {
            lines.append((lines.isEmpty ? firstIndent : indent) + currentLine)
        }

        return lines
    }

    private func stripANSI(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{001B}\\[[0-9;]*m", with: "", options: .regularExpression)
    }
}
