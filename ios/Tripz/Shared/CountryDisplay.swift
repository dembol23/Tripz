import Foundation

enum CountryDisplay {
    static func name(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    static func flag(for code: String) -> String {
        String(code.uppercased().unicodeScalars.compactMap { UnicodeScalar(127_397 + $0.value) }.map { Character($0) })
    }
}
