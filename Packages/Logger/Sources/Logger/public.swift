//
//  public.swift
//
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Foundation

public func log(
	_ level: LogLevel,
	_ message: Any...,
	file: String = #file,
	line: Int = #line,
	function: String = #function
) {
	Logging.shared.log(level, message, file: file, line: line, function: function)
}
