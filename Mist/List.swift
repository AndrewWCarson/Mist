//
//  List.swift
//  Mist
//
//  Created by Nindi Gill on 10/3/21.
//

import Foundation
import Yams

struct List {

    static func run(format: ExportFormat?, exportPath: String?) throws {
        PrettyPrint.print(.info, string: "Checking for macOS versions...")
        let products: [Product] = HTTP.retrieveProducts()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        list(products, using: dateFormatter)

        if let path: String = exportPath {

            guard !path.isEmpty else {
                throw MistError.missingExportPath
            }

            guard let format: ExportFormat = format else {
                throw MistError.missingExportFormat
            }

            switch format {
            case .csv:
                try saveCSV(path, using: products)
            case .json:
                try saveJSON(path, using: products)
            case .propertyList:
                try savePropertyList(path, using: products)
            case .yaml:
                try saveYAML(path, using: products)
            }
        }
    }

    private static func list(_ products: [Product], using dateFormatter: DateFormatter) {

        guard let maxIdentifierLength: Int = products.map({ $0.identifier }).max(by: { $0.count < $1.count })?.count,
            let maxNameLength: Int = products.map({ $0.name }).max(by: { $0.count < $1.count })?.count,
            let maxVersionLength: Int = products.map({ $0.version }).max(by: { $0.count < $1.count })?.count,
            let maxBuildLength: Int = products.map({ $0.build }).max(by: { $0.count < $1.count })?.count else {
            return
        }

        let identifierHeading: String = "Identifier"
        let nameHeading: String = "Name"
        let versionHeading: String = "Version"
        let buildHeading: String = "Build"
        let dateHeading: String = "Date"
        let identifierPadding: Int = max(maxIdentifierLength - identifierHeading.count, 0)
        let namePadding: Int = max(maxNameLength - nameHeading.count, 0)
        let versionPadding: Int = max(maxVersionLength - versionHeading.count, 0)
        let buildPadding: Int = max(maxBuildLength - buildHeading.count, 0)
        let datePadding: Int = max(dateFormatter.dateFormat.count - dateHeading.count, 0)

        var string: String = "\nThere are \(products.count) macOS Installers available for download:\n\n"
        string += identifierHeading + [String](repeating: " ", count: identifierPadding).joined()
        string += " │ " + nameHeading + [String](repeating: " ", count: namePadding).joined()
        string += " │ " + versionHeading + [String](repeating: " ", count: versionPadding).joined()
        string += " │ " + buildHeading + [String](repeating: " ", count: buildPadding).joined()
        string += " │ " + dateHeading + [String](repeating: " ", count: datePadding).joined()
        string += "\n" + [String](repeating: "─", count: identifierHeading.count + identifierPadding).joined()
        string += "─┼─" + [String](repeating: "─", count: nameHeading.count + namePadding).joined()
        string += "─┼─" + [String](repeating: "─", count: versionHeading.count + versionPadding).joined()
        string += "─┼─" + [String](repeating: "─", count: buildHeading.count + buildPadding).joined()
        string += "─┼─" + [String](repeating: "─", count: dateHeading.count + datePadding).joined()
        string += "\n"

        for product in products {
            let identifierPadding: Int = max(identifierHeading.count - product.identifier.count, 0)
            let namePadding: Int = max(maxNameLength - product.name.count, 0)
            let versionPadding: Int = max(maxVersionLength - product.version.count, 0)
            let buildPadding: Int = max(maxBuildLength - product.build.count, 0)
            let datePadding: Int = max(dateFormatter.dateFormat.count - product.date.count, 0)

            var line: String = product.identifier + [String](repeating: " ", count: identifierPadding).joined()
            line += " │ " + product.name + [String](repeating: " ", count: namePadding).joined()
            line += " │ " + product.version + [String](repeating: " ", count: versionPadding).joined()
            line += " │ " + product.build + [String](repeating: " ", count: buildPadding).joined()
            line += " │ " + product.date + [String](repeating: " ", count: datePadding).joined()
            string += line + "\n"
        }

        print(string)
    }

    private static func saveCSV(_ path: String, using products: [Product]) throws {
        let header: String = "Identifier,Name,Version,Build,Date\n"
        let string: String = header + products.map { $0.csvLine }.joined()
        try string.write(toFile: path, atomically: true, encoding: .utf8)
        PrettyPrint.print(.info, string: "Saved list as CSV: '\(path)'")
    }

    private static func saveJSON(_ path: String, using products: [Product]) throws {
        let dictionaries: [[String: Any]] = products.map { $0.dictionary }
        let data: Data = try JSONSerialization.data(withJSONObject: dictionaries, options: .prettyPrinted)

        guard let string: String = String(data: data, encoding: .utf8) else {
            throw MistError.invalidData
        }

        try string.write(toFile: path, atomically: true, encoding: .utf8)
        PrettyPrint.print(.info, string: "Saved list as JSON: '\(path)'")
    }

    private static func savePropertyList(_ path: String, using products: [Product]) throws {
        let dictionaries: [[String: Any]] = products.map { $0.dictionary }
        let data: Data = try PropertyListSerialization.data(fromPropertyList: dictionaries, format: .xml, options: .bitWidth)

        guard let string: String = String(data: data, encoding: .utf8) else {
            throw MistError.invalidData
        }

        try string.write(toFile: path, atomically: true, encoding: .utf8)
        PrettyPrint.print(.info, string: "Saved list as Property List: '\(path)'")
    }

    private static func saveYAML(_ path: String, using products: [Product]) throws {
        let dictionaries: [[String: Any]] = products.map { $0.dictionary }
        let string: String = try Yams.dump(object: dictionaries)
        try string.write(toFile: path, atomically: true, encoding: .utf8)
        PrettyPrint.print(.info, string: "Saved list as YAML: '\(path)'")
    }
}
