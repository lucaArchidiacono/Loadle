//
//  MediaAssetItemsArchiveList.swift
//  Loadle
//
//  Created by Luca Archidiacono on 26.04.2024.
//

import Foundation
import SwiftUI
import Zip
import Generator
import Models

public struct MediaAssetItemsArchiveList: View {
	@State private var selectedMediaAssetItems: [MediaAssetItem]
	@State private var selectedFileURLs: Set<URL>
	@State private var fileNameRegistry: [URL: (String, String)]
	@State private var createZip: Bool = false
	@State private var isExtracting = false

	let onExtract: ([URL]) -> Void

	init(selectedMediaAssetItems: Set<MediaAssetItem>, onExtract: @escaping ([URL]) -> Void) {
		let selectedMediaAssetItems = Array(selectedMediaAssetItems)
		self._selectedMediaAssetItems = State(wrappedValue: selectedMediaAssetItems)

		let fileURLs = selectedMediaAssetItems
			.enumerated()
			.map { ($0.offset, $0.element.fileURLs) }
		
		let selectedFileURLs = Set<URL>(fileURLs.flatMap { $0.1 })
		self._selectedFileURLs = State(wrappedValue: selectedFileURLs)

		let fileNameRegistry = fileURLs
			.map { ($0.0, $0.1.enumerated().map { ($0.offset, $0.element) }) }
			.reduce(into: [URL: (String, String)](), { partialResult, tuple in
				let (objectIndex, urls) = tuple

				for (urlIndex, url) in urls {
					let pathExtension = url.pathExtension
					let dirName = selectedMediaAssetItems[objectIndex].title

					if url.containsImage {
						partialResult[url] = (dirName, "IMG_\(objectIndex)_\(urlIndex)_\(!pathExtension.isEmpty ? ".\(pathExtension)" : "")")
					} else if url.containsMovie {
						partialResult[url] = (dirName, "MOV_\(objectIndex)_\(urlIndex)_\(!pathExtension.isEmpty ? ".\(pathExtension)" : "")")
					} else if url.containsAudio {
						partialResult[url] = (dirName, "MOV_\(objectIndex)_\(urlIndex)_\(!pathExtension.isEmpty ? ".\(pathExtension)" : "")")
					} else {
						partialResult[url] = (dirName, "\(objectIndex)_\(urlIndex)_\(!pathExtension.isEmpty ? ".\(pathExtension)" : "")")
					}
				}
			})
		self._fileNameRegistry = State(wrappedValue: fileNameRegistry)

		self.onExtract = onExtract
	}

	public var body: some View {
		List {
			ForEach(selectedMediaAssetItems) { item in
				Section(item.title) {
					ForEach(item.fileURLs, id: \.self) { fileURL in
						let tuple = fileNameRegistry[fileURL]

						SelectionCell(
							title: tuple?.1 ?? fileURL.absoluteString,
							fileURL: fileURL,
							isSelected: selectedFileURLs.contains(fileURL)) {
								if selectedFileURLs.contains(fileURL) {
									selectedFileURLs.remove(fileURL)
								} else {
									selectedFileURLs.insert(fileURL)
								}
							}
					}
				}
			}

			Section {
				Toggle(
					isOn: $createZip,
					label: { Text(L10n.createZip) }
				)
			}

			Section {
				Button(
					action: {
						isExtracting = true

						Task {
							let temp = FileManager.default.temporaryDirectory
							let exports = temp.appendingPathComponent("Exports", conformingTo: .directory)

							try? FileManager.default.removeItem(at: exports)

							do {
								try FileManager.default.createDirectory(at: exports, withIntermediateDirectories: true)

								for selectedFileURL in selectedFileURLs {
									guard let (dirName, fileName) = fileNameRegistry[selectedFileURL] else { return }
									
									let exportsInnerDir = exports.appendingPathComponent(dirName, conformingTo: .directory)

									if !FileManager.default.fileExists(atPath: exportsInnerDir.path) {
										try FileManager.default.createDirectory(at: exportsInnerDir, withIntermediateDirectories: true)
									}

									try FileManager.default.copyItem(at: selectedFileURL, to: exportsInnerDir.appendingPathComponent(fileName, conformingTo: .fileURL))
								}

								let tempContents = try FileManager.default.contentsOfDirectory(at: exports, includingPropertiesForKeys: nil)

								if createZip {
									let zipFilePath = temp.appendingPathComponent("archive.zip", conformingTo: .zip)
									try Zip.zipFiles(paths: tempContents, zipFilePath: zipFilePath, password: nil, progress: nil)
									onExtract([zipFilePath])
								} else {
									onExtract(tempContents)
								}
							} catch {
								log(.error, error)
							}

							isExtracting = false
						}
					},
					label: {
						ZStack {
							Text(L10n.export).opacity(isExtracting ? 0 : 1)

							if isExtracting {
								ProgressView()
							}
						}
						.frame(height: 30)
						.frame(maxWidth: .infinity)
					}
				)
				.buttonStyle(.borderedProminent)
				.disabled(isExtracting)
			}
			.listRowInsets(EdgeInsets())
			.listRowBackground(Color.clear)
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Text(L10n.archiving)
					.font(.title)
					.bold()
					.padding(.horizontal, 10)
			}
		}
	}
}

import AVFoundation
import Logger

private struct SelectionCell: View {
	let title: String
	let fileURL: URL
	let isSelected: Bool
	let onTap: () -> Void

	@State private var artwork: UIImage?

	var body: some View {
		HStack {
			if isSelected {
				Image(systemName: "checkmark.circle.fill")
					.foregroundColor(.accentColor)
			} else {
				Image(systemName: "circle")
			}

			Text(title)
			Spacer()
			
			ZStack {
				if let artwork {
					Image(uiImage: artwork)
						.resizable()
						.scaledToFill()
				} else {
					if fileURL.containsMovie {
						Image(systemName: "movieclapper.fill")
							.resizable()
							.padding()
							.scaledToFill()
							.background(.fill)
					} else if fileURL.containsAudio {
						Image(systemName: "music.note")
							.resizable()
							.padding()
							.scaledToFill()
							.background(.fill)
					} else if fileURL.containsImage {
						Image(systemName: "photo.fill")
							.resizable()
							.padding()
							.scaledToFill()
							.background(.fill)
					}
				}
			}
			.aspectRatio(1.0, contentMode: .fit)
			.frame(width: 60, height: 60)
			.clipShape(RoundedRectangle(cornerRadius: 8))
			.clipped()
		}
		.contentShape(.interaction, Rectangle())
		.onTapGesture {
			onTap()
		}
		.task {
			if fileURL.containsMovie {
				let asset = AVURLAsset(url: fileURL)

				do {
					let generator = AVAssetImageGenerator(asset: asset)
					generator.appliesPreferredTrackTransform = true
					generator.requestedTimeToleranceBefore = .zero
					generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)

					artwork = try await withCheckedThrowingContinuation { continuation in
						generator.generateCGImageAsynchronously(for: .zero) { cgImage, _, error in
							if let error {
								continuation.resume(throwing: error)
								return
							}

							continuation.resume(returning: UIImage(cgImage: cgImage!))
							return
						}
					}
				} catch {
					log(.error, error)
				}
			} else {
				if fileURL.containsImage {
					guard let data = try? Data(contentsOf: fileURL) else { return }
					artwork = UIImage(data: data)
				}
			}
		}
	}
}

