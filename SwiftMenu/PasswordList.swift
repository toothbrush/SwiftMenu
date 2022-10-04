//
//  PasswordList.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Foundation
import PathKit

let PATH = NSString("~/.password-store/").expandingTildeInPath

func contentsOfPasswordDirectory() throws -> [String] {
    //guard let paths = try? FileManager.default.contentsOfDirectory(atPath: PATH, ) else { return nil }

    var items : [String] = []

    var path = Path(PATH)
    print("Password store: \(path)")
    if path.isSymlink {
        if let pathDest = try? path.symlinkDestination() {
            path = pathDest
        }
    }

    let generator = path.iterateChildren(options: .skipsHiddenFiles).makeIterator()
    while let child = generator.next() {
        if child.isSymlink {
            if let dest = try? child.symlinkDestination() {
                items.append(dest.string)
            }
        }

        if child.isFile {
            items.append(child.string)
        }
    }
    print("Found \(items.count) password entries")
    return items.sorted()
}

func prettyPasswordsList() throws -> [String] {
    let raw_files : [String] = try contentsOfPasswordDirectory()

    let regex = ".*/\\.password-store/(.+)\\.gpg"
    let repl = "$1"

    return raw_files.map { path in
        return path.replacingOccurrences(of: regex, with: repl, options: [.regularExpression])
    }
}

extension ViewController {
    func refreshPasswordListAndTableView() throws {
        self.actualPasswordList = try prettyPasswordsList()
        self.filteredPasswordList = self.actualPasswordList
        DispatchQueue.main.async {
            self.inputField.stringValue = ""
            self.updateTableWithFilter()
        }
    }
}
