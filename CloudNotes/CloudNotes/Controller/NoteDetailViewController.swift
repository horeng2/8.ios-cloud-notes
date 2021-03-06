//
//  NoteDetailViewController.swift
//  CloudNotes
//
//  Created by 황제하 on 2022/02/08.
//

import UIKit

protocol NoteDetailViewDelegate: AnyObject {
    func textViewDidChange(noteInformation: NoteInformation)
    func sharedNoteAction(_ sender: UIBarButtonItem)
    func deleteNoteAction()
}

final class NoteDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let noteDetailScrollView = NoteDetailScrollView()
    weak var delegate: NoteDetailViewDelegate?
    var persistentManager: PersistentManager?
    
    let titleAttirbuteText = [
        NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title1),
        NSAttributedString.Key.foregroundColor: UIColor.label
    ]
    let bodyAttributeText = [
        NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
        NSAttributedString.Key.foregroundColor: UIColor.label
    ]
    
    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupNoteDetailScrollView()
        addObserverKeyboardNotification()
        noteDetailScrollView.noteDetailTextView.delegate = self
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - internal Methods
    
    func setupDetailView(index: Int) {
        if let note = persistentManager?.notes[index] {
            noteDetailScrollView.configure(with: note)
            scrollTextViewToVisible()
            view.endEditing(true)
        }
    }
    
    func setupEmptyDetailView() {
        DispatchQueue.main.async {
            self.noteDetailScrollView.isHidden = true
        }
    }
    
    func setupNotEmptyDetailView() {
        DispatchQueue.main.async {
            self.noteDetailScrollView.isHidden = false
        }
    }
    
    // MARK: - private Methods
    
    private func setupNavigation() {
        let seeMoreMenuButtonImage = UIImage(systemName: ImageNames.ellipsisCircleImageName)
        let rightButton = UIBarButtonItem(
            image: seeMoreMenuButtonImage,
            style: .done,
            target: self,
            action: #selector(showPopover(_:))
        )
        self.navigationController?.navigationBar.shadowImage = UIImage()
        rightButton.tintColor = .systemYellow
        navigationItem.setRightBarButton(rightButton, animated: false)
        
    }
    
    private func setupNoteDetailScrollView() {

        noteDetailScrollView.backgroundColor = UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0)
        noteDetailScrollView.delegate = self
        view.addSubview(noteDetailScrollView)
        noteDetailScrollView.setupConstraint(view: view)
    }
    
    @objc private func showPopover(_ sender: UIBarButtonItem) {
        self.showActionSheet(
            sharedTitle: "Shared".localized,
            deleteTitle: "Delete".localized,
            targetBarButton: sender
        ) { _ in
            self.delegate?.sharedNoteAction(sender)
        } deleteHandler: { _ in
            self.delegate?.deleteNoteAction()
        }
    }
    
    private func scrollTextViewToVisible() {
        DispatchQueue.main.async { [weak self] in
            if let dateLabelHeight = self?.noteDetailScrollView.lastModifiedDateLabel.frame.height {
                let offset = CGPoint(x: 0, y: dateLabelHeight)
                self?.noteDetailScrollView.setContentOffset(offset, animated: true)
            }
        }
    }
}

// MARK: - ScrollView Delegate

extension NoteDetailViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let dateLabelHeight = noteDetailScrollView.lastModifiedDateLabel.frame.height
        
        if scrollView.contentOffset.y < dateLabelHeight {
            targetContentOffset.pointee = CGPoint.zero
        }
    }
}

// MARK: - TextView Delegate

extension NoteDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let textViewText = textView.text else {
            return
        }
        let information = splitText(text: textViewText)
        delegate?.textViewDidChange(noteInformation: information)
    }
    
    func splitText(text: String) -> NoteInformation {
        var title = ""
        var body = ""
        
        if text.contains("\n") == false && text.count <= 100 {
            title = text
        } else if text.contains("\n") == false && text.count > 100 {
            title = text.substring(from: 0, to: 99)
            body = "\n" + text.substring(from: 100, to: text.count - 1)
        } else {
            let splitedText = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            title = String(splitedText.first ?? "")
            body = String(splitedText.last ?? "")
        }
        let information = NoteInformation(title: title, content: body, lastModifiedDate: Date().timeIntervalSince1970)
        return information
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textAsNSString = textView.text as NSString
        let replacedString = textAsNSString.replacingCharacters(in: range, with: text) as NSString
        let titleRange = replacedString.range(of: "\n")

        if titleRange.location > range.location {
            textView.typingAttributes = titleAttirbuteText
        } else {
            textView.typingAttributes = bodyAttributeText
        }
        return true
    }
}

// MARK: - Keyboard

extension NoteDetailViewController {
    private func addObserverKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        guard let info = sender.userInfo else {
            return
        }
        
        let userInfo = info as NSDictionary
        guard let keyboardFrame = userInfo.value(
            forKey: UIResponder.keyboardFrameEndUserInfoKey
        ) as? NSValue else {
            return
        }
        
        let keyboardRect = keyboardFrame.cgRectValue
        noteDetailScrollView.contentInset.bottom = keyboardRect.height
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        noteDetailScrollView.contentInset.bottom = .zero
    }
}
