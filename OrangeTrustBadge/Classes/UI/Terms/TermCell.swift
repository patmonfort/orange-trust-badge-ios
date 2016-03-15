/*
*
* OrangeTrustBadge
*
* File name:   TermCell.swift
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

class TermCell: UITableViewCell {
    
    static let reuseIdentifier = "TermText"
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var content: UITextView!
    
    override func awakeFromNib() {
        content.text = ""
        title.text = ""
    }
    
    override func prepareForReuse() {
        content.text = ""
        title.text = ""
    }
}