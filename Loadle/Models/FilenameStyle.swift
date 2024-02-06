//
//  FilenameStyle.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

enum FilenameStyle: String, Encodable {
	/// Default loadle file name pattern
	case classic
	/// Title and Basic info in brackets
	case basic
	/// Tiltle and info in brackets
	case pretty
	/// Title and all info in brackets
	case nerdy
}
