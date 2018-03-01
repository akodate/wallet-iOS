//
//  SettingsTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts
import LocalAuthentication

class SettingsCell : UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView  = UIImageView(image: #imageLiteral(resourceName: "icon_disclosure"))
        textLabel?.font = Style.Font.T3S
        textLabel?.textColor = Style.Color.C6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SettingsTableViewController: UITableViewController {
    private var oldBarStyle : UIBarStyle?

    private let cellReuseIdentifier = "UITableViewCell"
    
    #if DEBUG
        private let isDebugBuild = true
    #else
        private let isDebugBuild = false
    #endif

    convenience init() {
        self.init(style: .grouped)
    }
    
    override init(style: UITableViewStyle) {
        // ignore input. This view is always the grouped style
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    // Mark: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        clearsSelectionOnViewWillAppear = true
        title = NSLocalizedString("Settings", comment: "Title of the Settings screen.")

        navigationController?.navigationBar.barTintColor = Style.Color.C3
        navigationController?.navigationBar.isTranslucent = false
        
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(dismissSettings))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.backgroundColor = Style.Color.C2
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.instance.styleApplicationDefault()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedPath, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        var barStyle = UIBarStyle.default
        if let oldBarStyle = oldBarStyle {
            barStyle = oldBarStyle
        }
        
        navigationController?.navigationBar.barStyle = barStyle
    }

    @objc func dismissSettings() {
        Logger.main.info("Dismissing the settings screen.")
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isDebugBuild ? 10 : 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        let text : String?
        switch indexPath.row {
        case 0:
            text = NSLocalizedString("Add an Issuer", comment: "Action item in settings screen to add an Issuer manually.")
        case 1:
            text = NSLocalizedString("Add a Credential", comment: "Action item in settings screen to add an Issuer manually.")
        case 2:
            text = NSLocalizedString("My Passphrase", comment: "Action item in settings screen.")
        case 3:
            text = NSLocalizedString("About Passphrases", comment: "Menu action item for sharing device logs.")
        case 4:
            text = NSLocalizedString("Privacy Policy", comment: "Menu item in the settings screen that links to our privacy policy.")
        case 5:
            text = NSLocalizedString("Email Logs", comment: "Action item in settings screen.")
        // The following are only visible in DEBUG builds
        case 6:
            text = "Destroy passphrase & crash"
        case 7:
            text = "Delete all issuers & certificates"
        case 8:
            text = "Destroy all data & crash"
        case 9:
            text = "Show onboarding"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text

        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller : UIViewController?
        var configuration : AppConfiguration?
        
        switch indexPath.row {
        case 0:
            Logger.main.info("Add Issuer tapped in settings")
            showAddIssuerFlow()
        case 1:
            Logger.main.info("Add Credential tapped in settings")
            let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
            controller = storyboard.instantiateViewController(withIdentifier: "addIssuer") as! SettingsAddCredentialViewController
        case 2:
            Logger.main.info("My passphrase tapped in settings")
            authenticate()
            controller = nil
        case 3:
            Logger.main.info("About passphrase tapped in settings")
            controller = AboutPassphraseViewController()
        case 4:
            Logger.main.info("Privacy statement tapped in settings")
            controller = PrivacyViewController()
        case 5:
            Logger.main.info("Share device logs")
            controller = nil
            shareLogs()
            
        // The following are only visible in DEBUG builds
        case 6:
            Logger.main.info("Destroy passphrase & crash...")
            configuration = AppConfiguration(shouldDeletePassphrase: true, shouldResetAfterConfiguring: true)
        case 7:
            Logger.main.info("Delete all issuers & certificates...")
            configuration = AppConfiguration(shouldDeleteIssuersAndCertificates: true)
            tableView.deselectRow(at: indexPath, animated: true)
        case 8:
            Logger.main.info("Delete all data & crash...")
            configuration = AppConfiguration.resetEverything
        case 9:
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            present(storyboard.instantiateInitialViewController()!, animated: false, completion: nil)
        default:
            controller = nil
        }
        
        if let newAppConfig = configuration {
            try! ConfigurationManager().configure(with: newAppConfig)
        }
        
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func deleteIssuersAndCertificates() {
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: Paths.certificatesDirectory.path)
            for filePath in filePaths {
                try FileManager.default.removeItem(at: Paths.certificatesDirectory.appendingPathComponent(filePath))
            }
        } catch {
            Logger.main.warning("Could not clear temp folder: \(error)")
        }
        
        do {
            try FileManager.default.removeItem(at: Paths.issuersNSCodingArchiveURL)
        } catch {
            Logger.main.warning("Could not delete NSCoding-based issuer list: \(error)")
        }
        
        do {
            try FileManager.default.removeItem(at: Paths.managedIssuersListURL)
        } catch {
            Logger.main.warning("Could not delete managed issuers list: \(error)")
        }
    }
    
    func shareLogs() {
        guard let shareURL = try? Logger.main.shareLogs() else {
            Logger.main.error("Sharing the logs failed. Not sure how we'll ever get this information back to you. ¯\\_(ツ)_/¯")
            let alert = UIAlertController(title: NSLocalizedString("File not found", comment: "Title for the failed-to-share-your-logs alert"),
                                          message: NSLocalizedString("We couldn't find the logs on the device.", comment: "Explanation for failing to share the log file"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "ok action"), style: .default, handler: {[weak self] _ in
                self?.deselectRow()
            }))
            
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        let items : [Any] = [ shareURL ]
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        present(shareController, animated: true, completion: { [weak self] in
            self?.deselectRow()
        })
    }
    
    func clearLogs() {
        Logger.main.clearLogs()
        
        let controller = UIAlertController(title: NSLocalizedString("Success!", comment: "action completed successfully"), message: NSLocalizedString("Logs have been deleted from this device.", comment: "A message displayed after clearing the logs successfully."), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "action confirmed"), style: .default, handler: { [weak self] _ in
            self?.deselectRow()
        }))
        
        present(controller, animated: true, completion: nil)
    }
    
    func deselectRow() {
        if let indexPath = tableView.indexPathForSelectedRow {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - Add Issuer
    
    func showAddIssuerFlow(identificationURL: URL? = nil, nonce: String? = nil) {
        let controller = AddIssuerViewController(identificationURL: identificationURL, nonce: nonce)
        controller.delegate = self
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - User Authentication (TouchID/FaceID)
    
    func authenticate() {
        defer {
            if let selectionIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectionIndexPath, animated: true)
            }
        }
        
        authenticateUser { [weak self] (success, error) in
            
            guard success else {
                guard let error = error else {
                    return
                }
                
                switch error {
                case AuthErrors.noAuthMethodAllowed:
                    DispatchQueue.main.async { [weak self] in
                        let title = NSLocalizedString("Authentication Error", comment: "Alert view title shown when unable to authenticate for My Passphrase")
                        let message = NSLocalizedString("It looks like local authentication is disabled for this app. Without it, showing your passphrase is insecure. Please enable local authentication for this app in Settings.", comment: "Specific authentication error: The user's phone has local authentication disabled, so we can't show the passphrase.")
                        let buttonText = NSLocalizedString("Okay", comment: "Button copy")
                        let alert = AlertViewController.create(title: title, message: message, icon: .warning, buttonText: buttonText)
                        self?.present(alert, animated: false, completion: nil)
                    }
                default:
                    //                    self.specificAuthenticationError = nil
                    break
                }
                
                dump(error)
                return
            }
            
            // Successful authentication - show the users's passphrase
            DispatchQueue.main.async { [weak self] in
                let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
                let controller = storyboard.instantiateViewController(withIdentifier: "MyPassphrase")
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
    }
    
    func authenticateUser(completionHandler: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error : NSError? = nil
        let reason = NSLocalizedString("Authenticate to see your secure passphrase.", comment: "Prompt to authenticate in order to reveal their passphrase.")
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason,
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
    
}

extension SettingsTableViewController: AddIssuerViewControllerDelegate {
    func added(managedIssuer: ManagedIssuer) {
        if managedIssuer.issuer != nil {
            let manager = ManagedIssuerManager()
            let managedIssuers = manager.load()
            let updatedIssuers = managedIssuers.filter{ $0.issuer?.id != managedIssuer.issuer?.id } + [managedIssuer]
            _ = manager.save(updatedIssuers)
        } else {
            Logger.main.warning("Something weird -- delegate called with nil issuer. \(#function)")
        }
    }
}

class SettingsMyPassphraseViewController : ScrollingOnboardingControllerBase, UIActivityItemSource {
    @IBOutlet var manualButton : SecondaryButton!
    @IBOutlet var copyButton : SecondaryButton!
    @IBOutlet var passphraseLabel : UILabel!

    var passphrase: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passphraseLabel.text = Keychain.loadSeedPhrase()
    }

    override var defaultScrollViewInset : UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    @IBAction func backupCopy() {
        let alert = AlertViewController.create(title: NSLocalizedString("Are you sure?", comment: "Confirmation before copying for backup"),
                                               message: NSLocalizedString("Email is a low-security backup method. Do you want to continue?", comment: "Scare tactic to warn user about insecurity of email"),
                                               icon: .warning)
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button to confirm user action"), for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            alert.dismiss(animated: false, completion: nil)
            self?.presentCopySheet()
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Button to cancel user action"), for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        
        alert.set(buttons: [okayButton, cancelButton])
        
        present(alert, animated: false, completion: nil)
    }

    func presentCopySheet() {
        guard let passphrase = Keychain.loadSeedPhrase() else {
            // TODO: present alert? how to help user in this case?
            return
        }
        
        self.passphrase = passphrase
        let activity = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        
        present(activity, animated: true) {}
    }
    
    // MARK: - Activity Item Source
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return passphrase!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        return passphrase! as NSString
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivityType?) -> String {
        return NSLocalizedString("BlockCerts Backup", comment: "Email subject line when backing up passphrase")
    }
    
}



class SettingsAddCredentialViewController: UIViewController, UIDocumentPickerDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.instance.styleApplicationDefault()
    }
    
    // MARK: - Add Credential
    
    @IBAction func importFromURL() {
        Logger.main.info("Add Credential from URL tapped in settings")
        let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "addCredentialFromURL") as! SettingsAddCredentialURLViewController

        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func importFromFile() {
        Logger.main.info("User has chosen to add a certificate from file")
        
        let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet
        
        present(controller, animated: true, completion: { AppDelegate.instance.styleApplicationAlternate() })
    }
    
    func importCertificate(from data: Data?) {
        showActivityIndicator()
        defer {
            hideActivityIndicator()
        }
        guard let data = data else {
            Logger.main.error("Failed to load a certificate from file. Data is nil.")
            
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
        
        do {
            let certificate = try CertificateParser.parse(data: data)
            saveCertificateIfOwned(certificate: certificate)

            alertSuccess(callback: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })

        } catch {
            Logger.main.error("Importing failed with error: \(error)")
            
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
    }
    
    func saveCertificateIfOwned(certificate: Certificate) {
        let manager = CertificateManager()
        manager.save(certificate: certificate)
    }
    
    
    var activityIndicator: UIActivityIndicatorView?
    
    func showActivityIndicator() {
        guard self.activityIndicator == nil else { return }
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.startAnimating()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.backgroundColor = .gray
        activityIndicator.alpha = 0.8
        
        let center: CGPoint
        if let keyView: UIView = UIApplication.shared.keyWindow?.rootViewController?.view {
            center = keyView.convert(keyView.center, to: view)
        } else {
            center = CGPoint(x: view.center.x, y: view.center.y - 32)
        }
        activityIndicator.center = center
        
        view.addSubview(activityIndicator)
        self.activityIndicator = activityIndicator
    }
    
    func hideActivityIndicator() {
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.removeFromSuperview()
        self.activityIndicator = nil
    }
    
    func alertError(localizedTitle: String, localizedMessage: String) {
        let okay = NSLocalizedString("Okay", comment: "OK dismiss action")
        let alert = AlertViewController.createWarning(title: localizedTitle, message: localizedMessage, buttonText: okay)
        present(alert, animated: false, completion: nil)
    }

    func alertSuccess(callback: (() -> Void)?) {
        let title = NSLocalizedString("Success!", comment: "Alert title")
        let message = NSLocalizedString("A credential was imported. Please check your credentials screen.", comment: "Successful credential import from URL in settings alert message")
        let okay = NSLocalizedString("Okay", comment: "OK dismiss action")
        let alert = AlertViewController.create(title: title, message: message, icon: .success, buttonText: okay)
        if let callback = callback {
            alert.buttons.first?.onTouchUpInside {
                callback()
            }
        }
        present(alert, animated: false, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        importCertificate(from: data)
    }
    
}

class SettingsAddCredentialURLViewController: SettingsAddCredentialViewController, UITextViewDelegate {
    
    @IBOutlet weak var urlTextView: UITextView!
    
    // closure called when presented modally and credential successfully added
    var successCallback: ((Certificate) -> ())?
    var presentedModally = false
    
    @IBAction func importURL() {
        guard let urlString = urlTextView.text,
            let url = URL(string: urlString.trimmingCharacters(in: CharacterSet.whitespaces)) else {
                return
        }
        Logger.main.info("User attempting to add a certificate from \(url).")
        
        addCertificate(from: url)
    }
    
    func addCertificate(from url: URL) {
        urlTextView.resignFirstResponder()
        showActivityIndicator()
        defer {
            hideActivityIndicator()
        }
        guard let certificate = CertificateManager().load(certificateAt: url) else {
            Logger.main.error("Failed to load certificate from \(url)")
            
            let title = NSLocalizedString("Invalid Credential", comment: "Title for an alert when importing an invalid certificate")
            let message = NSLocalizedString("That file doesn't appear to be a valid credential.", comment: "Message in an alert when importing an invalid certificate")
            alertError(localizedTitle: title, localizedMessage: message)
            
            return
        }
        
        saveCertificateIfOwned(certificate: certificate)
        
        alertSuccess(callback: { [weak self] in
            if self?.presentedModally ?? true {
                self?.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                    self?.successCallback?(certificate)
                })
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        })
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextView.backgroundColor = Style.Color.C10
        urlTextView.text = ""
        urlTextView.delegate = self
    }
    
    @objc func dismissModally() {
        presentingViewController?.dismiss(animated: true, completion: nil)
   }
    
    // Mark: - UITextViewDelegate

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}

