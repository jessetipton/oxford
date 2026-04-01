import Testing
import OxfordKit

/// Creates a formatter with Rainbow disabled (non-TTY) for predictable output.
private func makeFormatter(width: Int = 80) -> OutputFormatter {
    OutputFormatter(isTTY: false, terminalWidth: width)
}

// MARK: - Definition formatting

@Test func formatDefinitionExtractsHeadword() {
    let formatter = makeFormatter()
    let input = "happy hap·py |ˈhapē| adjective 1 feeling pleasure."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("happy"))
    #expect(output.contains("|ˈhapē|"))
}

@Test func formatDefinitionShowsSyllablesWhenDifferent() {
    let formatter = makeFormatter()
    let input = "happy hap·py |ˈhapē| adjective 1 feeling pleasure."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("hap·py"))
}

@Test func formatDefinitionOmitsSyllablesWhenSame() {
    let formatter = makeFormatter()
    // When syllables match the headword, they should not appear separately
    let input = "set set |set| verb 1 put in a position."
    let output = formatter.formatDefinition(input)
    let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
    // "set" should only appear once as the headword line, not as a separate syllable line
    let setLines = lines.filter { $0.trimmingCharacters(in: .whitespaces) == "set" }
    #expect(setLines.isEmpty, "Syllables matching headword should not appear as a separate line")
}

@Test func formatDefinitionNumberedSenses() {
    let formatter = makeFormatter()
    let input = "test |test| noun 1 a procedure to establish quality. 2 a short exam."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("1"))
    #expect(output.contains("a procedure to establish quality"))
    #expect(output.contains("2"))
    #expect(output.contains("a short exam"))
}

@Test func formatDefinitionBulletPoints() {
    let formatter = makeFormatter()
    let input = "test |test| noun 1 a procedure. • a secondary meaning."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("·"))
    #expect(output.contains("a secondary meaning"))
}

@Test func formatDefinitionPartOfSpeech() {
    let formatter = makeFormatter()
    let input = "run |rən| verb 1 move quickly. noun 1 an act of running."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("verb"))
    #expect(output.contains("noun"))
}

@Test func formatDefinitionSectionHeaders() {
    let formatter = makeFormatter()
    let input = "test |test| noun 1 a procedure. ORIGIN late Middle English."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("ORIGIN"))
    #expect(output.contains("late Middle English"))
}

@Test func formatDefinitionDerivatives() {
    let formatter = makeFormatter()
    let input = "happy |ˈhapē| adjective 1 feeling pleasure. DERIVATIVES happily adverb."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("DERIVATIVES"))
    #expect(output.contains("happily"))
}

@Test func formatDefinitionPhrases() {
    let formatter = makeFormatter()
    let input = "test |test| noun 1 a procedure. PHRASES put to the test challenge."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("PHRASES"))
}

// MARK: - Thesaurus formatting

@Test func formatThesaurusExtractsHeadword() {
    let formatter = makeFormatter()
    let input = "happy adjective 1 cheerful, content, joyful."
    let output = formatter.formatThesaurus(input)
    #expect(output.contains("happy"))
}

@Test func formatThesaurusNumberedSenses() {
    let formatter = makeFormatter()
    let input = "happy adjective 1 feeling glad. cheerful, content. 2 willing. glad, pleased."
    let output = formatter.formatThesaurus(input)
    #expect(output.contains("1"))
    #expect(output.contains("2"))
}

@Test func formatThesaurusAntonyms() {
    let formatter = makeFormatter()
    let input = "happy adjective 1 feeling glad. cheerful. ANTONYMS sad, miserable."
    let output = formatter.formatThesaurus(input)
    #expect(output.contains("Antonyms:"))
    #expect(output.contains("sad, miserable"))
}

@Test func formatThesaurusPartOfSpeech() {
    let formatter = makeFormatter()
    let input = "run verb 1 sprint, jog. noun 1 a sprint, a jog."
    let output = formatter.formatThesaurus(input)
    #expect(output.contains("verb"))
    #expect(output.contains("noun"))
}

// MARK: - Text wrapping

@Test func textWrapsAtTerminalWidth() {
    let formatter = makeFormatter(width: 40)
    let longInput = "test |test| noun 1 " + String(repeating: "word ", count: 20) + "end."
    let output = formatter.formatDefinition(longInput)
    let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
    for line in lines {
        // Allow a small margin for indentation and ANSI codes
        #expect(line.count <= 45, "Line should wrap near terminal width: \(line)")
    }
}

@Test func narrowTerminalDoesNotCrash() {
    let formatter = makeFormatter(width: 10)
    let input = "test |test| noun 1 a procedure to establish quality."
    let output = formatter.formatDefinition(input)
    #expect(!output.isEmpty)
}

@Test func wideTerminalFormatsCorrectly() {
    let formatter = makeFormatter(width: 200)
    let input = "test |test| noun 1 a procedure to establish quality."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("a procedure to establish quality"))
}

// MARK: - Edge cases

@Test func emptyInputProducesMinimalOutput() {
    let formatter = makeFormatter()
    let output = formatter.formatDefinition("")
    // Should not crash; output is just whitespace/newlines
    // Should not crash; output is just whitespace/newlines
    _ = output
}

@Test func inputWithoutPronunciationPipes() {
    let formatter = makeFormatter()
    // No pipe characters — head extraction should fail gracefully
    let input = "hello world noun 1 a greeting."
    let output = formatter.formatDefinition(input)
    #expect(!output.isEmpty)
}

@Test func multiDigitNumberedSenses() {
    let formatter = makeFormatter()
    let input = "test |test| noun 1 first. 2 second. 10 tenth meaning."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("10"))
    #expect(output.contains("tenth meaning"))
}

@Test func bracketAnnotationsInDefinition() {
    let formatter = makeFormatter()
    let input = "test |test| verb 1 [no object] perform a test."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("[no object]"))
    #expect(output.contains("perform a test"))
}

@Test func verbWithConjugationForms() {
    let formatter = makeFormatter()
    let input = "run |rən| verb (runs, running, ran, run) 1 move quickly."
    let output = formatter.formatDefinition(input)
    #expect(output.contains("verb"))
    #expect(output.contains("runs, running"))
    #expect(output.contains("move quickly"))
}

@Test func thesaurusExampleSplitFromSynonyms() {
    let formatter = makeFormatter()
    // The numbered sense should split "example sentence." from the synonym list
    let input = "happy adjective 1 she looked happy and relaxed. cheerful, content, merry."
    let output = formatter.formatThesaurus(input)
    #expect(output.contains("cheerful"))
}
