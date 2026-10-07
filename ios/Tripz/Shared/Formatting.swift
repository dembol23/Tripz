import Foundation

enum Formatting {
    static func distance(meters: Double) -> String {
        Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .road,
                numberFormatStyle: .number.precision(.fractionLength(0...2))
            ))
    }

    static func elevation(meters: Double) -> String {
        Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            ))
    }
}
