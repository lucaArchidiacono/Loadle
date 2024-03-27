//
//  ShareViewController.swift
//  LoadleShareExtension
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import UIKit
import Generator
import SwiftUI

struct ShareView: View {
	var isLoading: Bool = true

	var body: some View {
		ZStack {
			Rectangle()
				.fill(.clear)
				.overlay {
					Rectangle()
						.fill(Color(red: 46/255, green: 46/255, blue: 46/255))
						.frame(width: 200, height: 200)
						.cornerRadius(8)
						.overlay {
							VStack {
								Assets.appIcon.swiftUIImage
									.resizable()
									.scaledToFit()
									.frame(width: 50, height: 50)
									.cornerRadius(8)

								if isLoading {
									ProgressView()
								} else {
									Text("\(L10n.done) ✅")
								}
							}
						}
				}
		}
	}
}

class ShareViewController: UIViewController {
	private let viewModel = ShareViewModel()
	private lazy var shareViewController: UIHostingController = {
		let viewController = UIHostingController(rootView: ShareView())
		return viewController
	}()

    override func viewDidLoad() {
		super.viewDidLoad()

		setupLayout()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if let extensionContext, let item = extensionContext.inputItems.first as? NSExtensionItem {
			Task { [unowned self] in
				self.shareViewController.rootView = ShareView(isLoading: true)
				
				await self.viewModel.handleExtension(item)

				self.shareViewController.rootView = ShareView(isLoading: false)

				try? await Task.sleep(for: .seconds(3))
				self.extensionContext?.completeRequest(returningItems: nil)
			}
		}
	}
}

extension ShareViewController {
	private func setupLayout() {
		let swiftuiView = shareViewController.view!
		swiftuiView.translatesAutoresizingMaskIntoConstraints = false
		swiftuiView.isOpaque = false
		swiftuiView.backgroundColor = UIColor.black.withAlphaComponent(0.75)

		addChild(shareViewController)
		view.addSubview(swiftuiView)

		NSLayoutConstraint.activate([
			swiftuiView.topAnchor.constraint(equalTo: view.topAnchor),
			swiftuiView.leftAnchor.constraint(equalTo: view.leftAnchor),
			swiftuiView.rightAnchor.constraint(equalTo: view.rightAnchor),
			swiftuiView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
		])

		shareViewController.didMove(toParent: self)
	}
}
