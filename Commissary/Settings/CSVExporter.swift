import Foundation

/// History export of tin identity, dates, and marks. No energy columns and no meal slots.
enum CSVExporter {
    static func history(_ record: LarderRecord) -> String {
        var lines = ["tin,barcode,packageDaykey,mark,cookDaykey,recordedAt"]
        let lookup = Dictionary(uniqueKeysWithValues: (record.tins + record.archivedTins).map { ($0.id, $0) })
        struct Row {
            var sequence: Int
            var line: String
        }
        var rows: [Row] = []
        for mark in record.assignMarks {
            rows.append(Row(sequence: mark.sequence, line: line(lookup[mark.tinID], mark: "assign", cook: mark.cookDaykey, at: mark.recordedAt)))
        }
        for mark in record.finishMarks {
            rows.append(Row(sequence: mark.sequence, line: line(lookup[mark.tinID], mark: "finish", cook: nil, at: mark.recordedAt)))
        }
        for mark in record.wasteMarks {
            rows.append(Row(sequence: mark.sequence, line: line(lookup[mark.tinID], mark: "waste", cook: nil, at: mark.recordedAt)))
        }
        for mark in record.earlyMarks {
            rows.append(Row(sequence: mark.sequence, line: line(lookup[mark.tinID], mark: "early", cook: nil, at: mark.recordedAt)))
        }
        for mark in record.duplicateMarks {
            rows.append(Row(sequence: mark.sequence, line: line(lookup[mark.tinID], mark: "duplicate", cook: mark.cookDaykey, at: mark.recordedAt)))
        }
        lines.append(contentsOf: rows.sorted { $0.sequence < $1.sequence }.map(\.line))
        return lines.joined(separator: "\n")
    }

    private static func line(_ tin: Tin?, mark: String, cook: Int?, at: Date) -> String {
        let title = csv(tin?.title ?? "")
        let barcode = csv(tin?.barcode ?? "")
        let package = tin.map { String($0.packageDaykey) } ?? ""
        let day = cook.map(String.init) ?? ""
        let stamp = at.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash).timeSeparator(.colon))
        return "\(title),\(barcode),\(package),\(mark),\(day),\(stamp)"
    }

    private static func csv(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
