//
//  GenericStructureViewController.swift
//  PeerGC
//
//  Created by Artemas Radik on 7/22/20.
//  Copyright © 2020 AJ Radik. All rights reserved.
//

// MARK: Imports
import Foundation
import UIKit
import Firebase

class GenericStructureViewController: UIViewController {
    
    static var sendToDatabaseData: [String: String] = [:]
    
    // MARK: Delegates
    weak var metaDataDelegate: GenericStructureViewControllerMetadataDelegate?
    weak var buttonsDelegate: ButtonsDelegate?
    weak var textFieldDelegate: TextFieldDelegate?
    weak var imagePickerDelegate: ImagePickerDelegate?
    weak var activityIndicatorDelegate: ActivityIndicatorDelegate?
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if metaDataDelegate == nil {
            print("ERROR: You must set the GenericStructureViewControllerMetadataDelegate.")
            return
        }
        
        let optionalDelegates: [Any?] = [buttonsDelegate, textFieldDelegate, imagePickerDelegate, activityIndicatorDelegate]
        
        var numberOfNonNilOptionalDelegates = 0
        
        for delegate in optionalDelegates {
            if delegate != nil {
                numberOfNonNilOptionalDelegates += 1
            }
        }
        
        if numberOfNonNilOptionalDelegates > 1 {
            print("ERROR: You cannot set more than one optional delegate.")
            return
        }
        
        layout()
    }
    
    // MARK: Layout
    var topBuffer: CGFloat = -10
    func layout() {
        
        view.backgroundColor = .secondarySystemGroupedBackground
            
        let headerStack = initializeCustomStack(spacing: 10, distribution: .fill)
        headerStack.addArrangedSubview(initializeCustomLabel(title: metaDataDelegate!.title(), size: Double(titleTextSize), color: .label))
        
        if metaDataDelegate!.subtitle() != nil {
            headerStack.addArrangedSubview(initializeCustomLabel(title: metaDataDelegate!.subtitle()!, size: Double(subtitleTextSize), color: .gray))
        }
        
        addAndConstraint(customView: headerStack, constraints: [
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: headerStack.trailingAnchor, constant: 20),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: headerStack.leadingAnchor, constant: -20),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: headerStack.topAnchor, constant: topBuffer)
        ])
            
        // MARK: Buttons Layout
        if buttonsDelegate != nil {
            
            let buttonStack = initializeCustomStack(spacing: 10, distribution: .fillEqually)
            
            for databaseValue in buttonsDelegate!.buttons() {
                buttonStack.addArrangedSubview(initializeCustomButton(title: databaseValue.rawValue, color: .systemPink, action:
                    #selector(selectionButtonHandler(sender:)), alpha: 1.0))
            }
            
            addAndConstraint(customView: buttonStack, constraints:
                [NSLayoutConstraint(item: buttonStack, attribute: .top, relatedBy: .equal,
                                    toItem: headerStack, attribute: .bottom, multiplier: 1, constant: 30),
                                    view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: buttonStack.trailingAnchor, constant: 20),
                                    view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: buttonStack.leadingAnchor, constant: -20)])
        }
        
        // MARK: Text Field Layout
        if textFieldDelegate != nil {
            
            textField = initializeCustomTextField()
            
            addAndConstraint(customView: textField!, constraints:
                [NSLayoutConstraint(item: textField!, attribute: .top, relatedBy: .equal,
                                    toItem: headerStack, attribute: .bottom, multiplier: 1, constant: 30),
                 view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textField!.trailingAnchor, constant: 30),
                 view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textField!.leadingAnchor, constant: -30)])

            errorLabel = initializeCustomLabel(title: "Error.", size: Double(subtitleTextSize), color: .systemPink)
            errorLabel!.isHidden = true
            
            addAndConstraint(customView: errorLabel!, constraints:
                [NSLayoutConstraint(item: errorLabel!, attribute: .top, relatedBy: .equal,
                                    toItem: textField, attribute: .bottom, multiplier: 1, constant: 30),
                 view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: errorLabel!.trailingAnchor, constant: 20),
                 view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: errorLabel!.leadingAnchor, constant: -20)])
            
            let textFieldContinueButton = initializeCustomButton(title: "Continue", color: .systemPink, action:
                #selector(textFieldContinueButtonHandler), alpha: 1.0)
            
            addAndConstraint(customView: textFieldContinueButton, constraints: [
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textFieldContinueButton.trailingAnchor, constant: 30),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textFieldContinueButton.leadingAnchor, constant: -30),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: textFieldContinueButton.bottomAnchor, constant: 16)
            ])
            
        }
        
        // MARK: Image Picker Layout
        if imagePickerDelegate != nil {
            
            let selectButton = initializeCustomButton(title: "Select",
                color: .systemIndigo, action: #selector(imagePickerSelectButtonHandler), alpha: 1.0)
            
            addAndConstraint(customView: selectButton, constraints:
                [NSLayoutConstraint(item: selectButton, attribute: .top, relatedBy: .equal,
                                    toItem: headerStack, attribute: .bottom, multiplier: 1, constant: 30),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: selectButton.trailingAnchor, constant: 30),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: selectButton.leadingAnchor, constant: -30)])
            
            imageView = initializeCustomImageView()
            
            addAndConstraint(customView: imageView!,
                constraints:
                    [NSLayoutConstraint(item: imageView!, attribute: .top, relatedBy: .equal,
                                        toItem: selectButton, attribute: .bottom, multiplier: 1, constant: 30),
                     view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 120),
                     view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: imageView!.leadingAnchor, constant: -120),
                     NSLayoutConstraint(item: imageView!, attribute: .width, relatedBy: .equal,
                                        toItem: imageView, attribute: .height, multiplier: 1, constant: 0)])
            
            imagePickerContinueButton = initializeCustomButton(title: "Continue", color: .systemPink, action:
                #selector(imagePickerContinueButtonHandler(sender:)), alpha: 0.6)
            
            addAndConstraint(customView: imagePickerContinueButton!, constraints: [
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: imagePickerContinueButton!.trailingAnchor, constant: 30),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: imagePickerContinueButton!.leadingAnchor, constant: -30),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: imagePickerContinueButton!.bottomAnchor, constant: 16)
            ])
            
            imagePickerDelegate!.setInitialImage(imageView: imageView!, continueButton: imagePickerContinueButton!)
        }
        
        // MARK: Activity Indicator Layout
        if activityIndicatorDelegate != nil {
            
            activityIndicator = initializeCustomActivityIndicator()
            
            addAndConstraint(customView: activityIndicator!, constraints: [
                view.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: activityIndicator!.centerXAnchor, constant: 0),
                view.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: activityIndicator!.centerYAnchor, constant: 0)
            ])
            
            activityIndicatorContinueButton = initializeCustomButton(title: "Finish", color: .systemIndigo, action:
                #selector(activityIndicatorContinueButtonHandler), alpha: 0.6)
            
            addAndConstraint(customView: activityIndicatorContinueButton!, constraints: [
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: activityIndicatorContinueButton!.trailingAnchor, constant: 30),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: activityIndicatorContinueButton!.leadingAnchor, constant: -30),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: activityIndicatorContinueButton!.bottomAnchor, constant: 16)
            ])
            
        }
    }
    
    // MARK: Custom UI Initializers
    let fontName = "LexendDeca-Regular"
    let titleTextSize = (3.0/71) * UIScreen.main.bounds.height
    let subtitleTextSize = (1.5/71) * UIScreen.main.bounds.height
    var buttonTextSize = (1.5/71) * UIScreen.main.bounds.height
    
    // MARK: Add And Constraint
    func addAndConstraint(customView: UIView, constraints: [NSLayoutConstraint]) {
        customView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customView)
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: Custom Button
    func initializeCustomButton(title: String, color: UIColor, action: Selector, alpha: Double) -> DesignableButton {
        let toReturn = DesignableButton()
        toReturn.setTitle(title, for: .normal)
        toReturn.setTitleColor(.white, for: .normal)
        toReturn.alpha = CGFloat(alpha)
        toReturn.titleLabel!.font = UIFont(name: fontName, size: buttonTextSize)
        toReturn.backgroundColor = color
        toReturn.cornerRadius = CGFloat(16)
        toReturn.addTarget(self, action: action, for: .touchUpInside)
        let buttonConstraints = [toReturn.heightAnchor.constraint(equalToConstant: 50)]
        NSLayoutConstraint.activate(buttonConstraints)
        return toReturn
    }
    
    // MARK: Custom Label
    func initializeCustomLabel(title: String, size: Double, color: UIColor) -> UILabel {
        let toReturn = UILabel()
        toReturn.textColor = color
        toReturn.numberOfLines = 0
        toReturn.textAlignment = .center
        toReturn.text = title
        toReturn.font = UIFont.init(name: fontName, size: CGFloat(size))
        return toReturn
    }
    
    // MARK: Custom Stack
    func initializeCustomStack(spacing: Int, distribution: UIStackView.Distribution) -> UIStackView {
        let toReturn = UIStackView()
        toReturn.axis = .vertical
        toReturn.alignment = .fill
        toReturn.distribution = distribution
        toReturn.spacing = CGFloat(spacing)
        toReturn.isUserInteractionEnabled = true
        return toReturn
    }
    
    // MARK: Custom Text Field
    func initializeCustomTextField() -> UITextField {
        let toReturn = UITextField()
        toReturn.delegate = self
        toReturn.borderStyle = .roundedRect
        toReturn.backgroundColor = .secondarySystemBackground
        toReturn.font = UIFont.init(name: fontName, size: toReturn.font!.pointSize)
        toReturn.textAlignment = .center
        toReturn.isUserInteractionEnabled = true
        toReturn.addDoneButtonOnKeyboard()
        let textFieldConstraints = [toReturn.heightAnchor.constraint(equalToConstant: 50)]
        NSLayoutConstraint.activate(textFieldConstraints)
        return toReturn
    }
    
    // MARK: Custom Image View
    func initializeCustomImageView() -> UIImageView {
        let toReturn = UIImageView()
        toReturn.cornerRadius = 20
        toReturn.clipsToBounds = true
        view.clipsToBounds = true
        toReturn.contentMode = .scaleAspectFill
        return toReturn
    }
    
    // MARK: Custom Activity Indicator
    func initializeCustomActivityIndicator() -> UIActivityIndicatorView {
        let toReturn = UIActivityIndicatorView()
        toReturn.startAnimating()
        toReturn.style = .large
        return toReturn
    }
    
    // MARK: Handlers
    // MARK: General Handlers
    func nextViewControllerHandler(viewController: UIViewController?) {
        if viewController != nil {
            navigationController?.pushViewController(viewController!, animated: true)
        }
    }
    
    // MARK: Button Handlers
    @objc func selectionButtonHandler(sender: UIButton) {
        selectionButtonTextHandler(text: sender.titleLabel!.text!)
    }
    
    func selectionButtonTextHandler(text: String) { //override this for custom button exceptions
        GenericStructureViewController.sendToDatabaseData[buttonsDelegate!.databaseIdentifier().name] = DatabaseValue.init(rawValue: text)!.name
        
        nextViewControllerHandler(viewController: metaDataDelegate!.nextViewController())
    }
    
    // MARK: Text Field Handlers
    var textField: UITextField?
    var errorLabel: UILabel?
    
    @objc func textFieldContinueButtonHandler() {
        if textFieldDelegate != nil {
            let error = textFieldDelegate?.continuePressed(textInput: textField!.text)
            
            if error == nil {
                nextViewControllerHandler(viewController: metaDataDelegate!.nextViewController())
                errorLabel!.isHidden = true
            } else {
                errorLabel!.text = error
                errorLabel!.isHidden = false
            }
        }
    }
    
    // MARK: Image Picker Handlers
    var imageView: UIImageView?
    var imagePickerContinueButton: UIButton?
    
    @objc func imagePickerSelectButtonHandler() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        let myActionSheet = UIAlertController(title: "Profile Picture", message: "Select", preferredStyle: UIAlertController.Style.actionSheet)
        
        let photoGallery = UIAlertAction(title: "Photos", style: UIAlertAction.Style.default) { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable( UIImagePickerController.SourceType.savedPhotosAlbum) {
                imagePickerController.sourceType = UIImagePickerController.SourceType.savedPhotosAlbum
                imagePickerController.allowsEditing = true
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        myActionSheet.addAction(photoGallery)
        myActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(myActionSheet, animated: true, completion: nil)
    }
    
    @objc func imagePickerContinueButtonHandler(sender: UIButton) {
        if imageView!.image != nil {
            nextViewControllerHandler(viewController: metaDataDelegate!.nextViewController())
        }
    }
    
    // MARK: Activity Indicator Handlers
    var activityIndicator: UIActivityIndicatorView?
    var activityIndicatorContinueButton: UIButton?
    
    @objc func activityIndicatorContinueButtonHandler() {
        if activityIndicatorContinueButton!.alpha == 1.0 {
            nextViewControllerHandler(viewController: metaDataDelegate!.nextViewController())
        }
    }
    
    func doneLoading() {
        activityIndicator?.isHidden = true
        activityIndicatorContinueButton!.alpha = 1.0
    }
    
}

// MARK: Extensions
extension GenericStructureViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return true
    }
}

extension GenericStructureViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        imagePickerDelegate?.imageWasSelected(imageView: imageView!, continueButton: imagePickerContinueButton!, image: image)
    
        self.dismiss(animated: true, completion: nil)
    }
}

extension GenericStructureViewController: UINavigationControllerDelegate {
    
}

// MARK: Delegate Protocols
protocol GenericStructureViewControllerMetadataDelegate: class {
    func title() -> String
    func subtitle() -> String?
    
    func nextViewController() -> UIViewController?
}

protocol ButtonsDelegate: class {
    func databaseIdentifier() -> DatabaseKey
    func buttons() -> [DatabaseValue]
}

protocol TextFieldDelegate: class {
    func continuePressed(textInput: String?) -> String?
}

protocol ImagePickerDelegate: class {
    func setInitialImage(imageView: UIImageView, continueButton: UIButton)
    func imageWasSelected(imageView: UIImageView, continueButton: UIButton, image: UIImage)
}

protocol ActivityIndicatorDelegate: class {

}
