//
//  MailComposerView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation
import MessageUI
import Models
import SwiftUI

struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let emailData: EmailData
    var result: ((Result<MFMailComposeResult, Error>) -> Void)?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerView

        init(_ parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result?(.failure(error))
                return
            }

            parent.result?(.success(result))

            parent.dismiss()
        }
    }

    static func canSendEmail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let emailComposer = MFMailComposeViewController()
        emailComposer.mailComposeDelegate = context.coordinator

        emailComposer.setSubject(emailData.subject)
        emailComposer.setToRecipients(["luca@swift-mail.com"])
        switch emailData.body {
        case let .html(body):
            emailComposer.setMessageBody(body, isHTML: true)
        case let .raw(body):
            emailComposer.setMessageBody(body, isHTML: false)
        }
        for attachment in emailData.attachments {
            emailComposer.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }

        return emailComposer
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}
}
