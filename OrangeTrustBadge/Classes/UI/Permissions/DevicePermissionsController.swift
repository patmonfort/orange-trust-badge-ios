/*
*
* OrangeTrustBadge
*
* File name:   PermissionsController.swift
* Created:     15/12/2015
* Created by:  Romain BIARD
*
* Copyright 2015 Orange
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit

class DevicePermissionsController: UITableViewController {
    
    
    @IBOutlet weak var header : Header!
    var permissions = [TrustBadgeElement]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = TrustBadge.shared.localizedString("permission-title")
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let splitViewController = self.splitViewController {
            navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationItem.leftItemsSupplementBackButton = true
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        }
        
        self.tableView.register(UINib(nibName: "ElementCell", bundle: Bundle(for: TrustBadgeConfig.self)), forCellReuseIdentifier: ElementCell.reuseIdentifier)
        tableView.estimatedRowHeight = 65
        
        NotificationCenter.default.addObserver(self, selector: #selector(DevicePermissionsController.refresh), name: UIApplication.willEnterForegroundNotification, object: nil)
                
        permissions = [TrustBadge.shared.devicePermissions.filter({ $0 is PreDefinedElement })
            .sorted(by: { ($0 as! PreDefinedElement).type.rawValue < ($1 as! PreDefinedElement).type.rawValue }),
                           TrustBadge.shared.devicePermissions.filter({ $0 is CustomElement })]
            .reduce([], { $0 + $1 })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: TrustBadge.TRUSTBADGE_PERMISSION_ENTER), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TrustBadge.shared.pageDidAppear("Permissions")
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return permissions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = permissions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ElementCell.reuseIdentifier, for: indexPath) as! ElementCell
        
        cell.nameLabel.text = TrustBadge.shared.localizedString(element.nameKey)
        let description = TrustBadge.shared.localizedString(element.descriptionKey)
        if description.contains("<html") {
            var attributeddDescription : NSAttributedString?
            do {
                attributeddDescription = try NSAttributedString(data: description.data(using: String.Encoding.unicode)!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                cell.descriptionLabel.attributedText = attributeddDescription
            } catch {
                cell.descriptionLabel.text = description
            }
        } else {
            cell.descriptionLabel.text = description
        }

                
        cell.descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        
        let statusKey :String = {
            if element.statusClosure() {
                return "status-enabled"
            } else {
                return "status-disabled"
            }
        }()
        
        cell.statusLabel.text = TrustBadge.shared.localizedString(statusKey)
        cell.statusLabel.textColor = element.statusClosure() ? TrustBadge.shared.config?.highlightColor : .defaultTextColor
        
        cell.icon.image = element.statusClosure() ? TrustBadge.shared.loadImage(element.statusEnabledIconName) : TrustBadge.shared.loadImage(element.statusDisabledIconName)
        
        let key = (element as! PreDefinedElement).type == .health ? "update-health-permission" : "update-permission"
        cell.actionButton.setTitle(TrustBadge.shared.localizedString(key), for: UIControl.State())
        
        if element.isExpanded{
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                cell.disclosureArrow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                cell.descriptionLabel.isHidden = false
                cell.descriptionLabelHiddingConstraint.priority = UILayoutPriority(rawValue: 250)
                cell.actionPanel.isHidden = !element.isConfigurable
                cell.actionButtonHiddingConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(element.isConfigurable ? 250 : 999))
            })
            
        } else{
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                cell.disclosureArrow.transform = CGAffineTransform(rotationAngle: CGFloat(-2 * Double.pi))
                cell.descriptionLabel.isHidden = true
                cell.descriptionLabelHiddingConstraint.priority = UILayoutPriority(rawValue: 999)
                cell.actionPanel.isHidden = true
                cell.actionButtonHiddingConstraint.priority = UILayoutPriority(rawValue: 999)
            })
        }
        
        cell.toggle.setOn(element.statusClosure(), animated: false)
        if element.isToggable{
            cell.toggle.isHidden = false
            cell.toggle.isAccessibilityElement = true
            cell.statusLabel.isHidden = true
            cell.switchHiddingConstraint.priority = UILayoutPriority(rawValue: 250)
        } else {
            cell.toggle.isHidden = true
            cell.toggle.isAccessibilityElement = false
            cell.statusLabel.isHidden = false
            cell.switchHiddingConstraint.priority = UILayoutPriority(rawValue: 999)
        }
        
        cell.toggleClosure = {(cell : ElementCell) in
            element.toggleClosure(cell.toggle)
            NotificationCenter.default.post(name: Notification.Name(rawValue: TrustBadge.TRUSTBADGE_ELEMENT_TOGGLED), object: element)
        }
        
        if (element as! PreDefinedElement).type == .health {
            cell.openPreferencesClosure = { () in
                UIApplication.shared.openURL(URL(string: "x-apple-health://sources")!)
                NotificationCenter.default.post(name: Notification.Name(rawValue: TrustBadge.TRUSTBADGE_GO_TO_SETTINGS), object: element)
            }
        } else {
            cell.openPreferencesClosure = { () in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                NotificationCenter.default.post(name: Notification.Name(rawValue: TrustBadge.TRUSTBADGE_GO_TO_SETTINGS), object: element)
            }
        }
        let status = element.statusClosure() ? TrustBadge.shared.localizedString("accessibility-enabled") : TrustBadge.shared.localizedString("accessibility-disabled")
        cell.accessibilityValue = "\(TrustBadge.shared.localizedString(element.nameKey)) : \(status)"
        cell.accessibilityHint = TrustBadge.shared.localizedString("accessibility-double-tap")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let element = permissions[indexPath.row]
        if element.isExpanded {
            return UITableView.automaticDimension
        } else {
            return 65
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = permissions[indexPath.row]
        element.isExpanded = !element.isExpanded
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        tableView.endUpdates()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: TrustBadge.TRUSTBADGE_ELEMENT_TAPPED), object: element)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = .defaultTextColor
    }
    
    // MARK: - Other Methods
    
    @objc func refresh() {
        self.tableView.reloadData()
    }
    
    @objc func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
}
