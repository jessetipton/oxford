import CoreServices
import Foundation

// MARK: - Private DictionaryServices API bindings

@_silgen_name("DCSGetActiveDictionaries")
private func DCSGetActiveDictionaries() -> Unmanaged<CFArray>?

@_silgen_name("DCSDictionaryGetName")
private func DCSDictionaryGetName(_ dictionary: OpaquePointer) -> Unmanaged<CFString>?

@_silgen_name("DCSCopyTextDefinition")
private func DCSCopyTextDefinitionFromDictionary(
    _ dictionary: OpaquePointer?,
    _ word: CFString,
    _ range: CFRange
) -> Unmanaged<CFString>?

@_silgen_name("DCSCopyRecordsForSearchString")
private func DCSCopyRecordsForSearchString(
    _ dictionary: OpaquePointer?,
    _ searchString: CFString,
    _ method: Int,
    _ maxResults: Int
) -> Unmanaged<CFArray>?

@_silgen_name("DCSRecordGetHeadword")
private func DCSRecordGetHeadword(
    _ record: OpaquePointer?
) -> Unmanaged<CFString>?

// MARK: - API

package enum DictionarySource: String, CaseIterable, Sendable {
    case dictionary = "New Oxford American Dictionary"
    case thesaurus = "Oxford American Writer\u{2019}s Thesaurus"
}

package struct WordResult: Sendable {
    package let word: String
    package let definition: String?
    package let thesaurus: String?

    package var hasAnyResult: Bool {
        definition != nil || thesaurus != nil
    }
}

/// Find the dictionary reference matching the given source.
private func findDictionary(for source: DictionarySource) -> OpaquePointer? {
    guard let unmanaged = DCSGetActiveDictionaries() else { return nil }
    let cfArray = unmanaged.takeUnretainedValue()
    let count = CFArrayGetCount(cfArray)
    for i in 0..<count {
        guard let ptr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
        let dict = OpaquePointer(ptr)
        if let nameRef = DCSDictionaryGetName(dict) {
            let name = nameRef.takeUnretainedValue() as String
            if name.contains(source.rawValue) {
                return dict
            }
        }
    }
    return nil
}

/// Look up a word's plain text definition in a specific dictionary source.
package func lookUp(_ word: String, in source: DictionarySource) -> String? {
    guard let dict = findDictionary(for: source) else { return nil }

    // DCSCopyTextDefinition works for the Oxford dictionary but not the thesaurus.
    // Use DCSCopyRecordsForSearchString as a fallback, which extracts plain text
    // via DCSCopyTextDefinition scoped to individual record headwords.
    let nsWord = word as NSString
    let range = CFRangeMake(0, nsWord.length)
    if let result = DCSCopyTextDefinitionFromDictionary(dict, nsWord, range) {
        return result.takeRetainedValue() as String
    }

    // Fallback: use records API (needed for thesaurus)
    guard let recordsRef = DCSCopyRecordsForSearchString(dict, word as CFString, 0, 1) else {
        return nil
    }
    let records = recordsRef.takeUnretainedValue()
    guard CFArrayGetCount(records) > 0,
          let ptr = CFArrayGetValueAtIndex(records, 0) else {
        return nil
    }
    let record = OpaquePointer(ptr)

    // Get the headword from the record and try DCSCopyTextDefinition with it
    if let hwRef = DCSRecordGetHeadword(record) {
        let headword = hwRef.takeUnretainedValue()
        let hwRange = CFRangeMake(0, CFStringGetLength(headword))
        if let text = DCSCopyTextDefinitionFromDictionary(dict, headword, hwRange) {
            return text.takeRetainedValue() as String
        }
    }

    return nil
}

/// Look up a word in both the dictionary and thesaurus.
package func lookUpWord(_ word: String) -> WordResult {
    WordResult(
        word: word,
        definition: lookUp(word, in: .dictionary),
        thesaurus: lookUp(word, in: .thesaurus)
    )
}
