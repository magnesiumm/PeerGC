//
//  PostGradAspirationsVC.swift
//  PeerGC
//
//  Created by Artemas Radik on 7/24/20.
//  Copyright © 2020 AJ Radik. All rights reserved.
//

import Foundation
import UIKit

class PostGradAspirationsVC: GenericStructureViewController {
    override func viewDidLoad() {
        buttonTextSize = (1.3/71) * UIScreen.main.bounds.height
        metaDataDelegate = self
        buttonsDelegate = self
        super.viewDidLoad()
    }
}

extension PostGradAspirationsVC: GenericStructureViewControllerMetadataDelegate {
    func title() -> String {
        return "What are your post-grad aspirations?"
    }
    
    func subtitle() -> String? {
        return "This information will be displayed on your public profile and is used by our matching algorithm."
    }
    
    func nextViewController() -> UIViewController? {
        return WhyYouBeCounselorVC()
    }
}

extension PostGradAspirationsVC: ButtonsDelegate {
    func databaseIdentifier() -> DatabaseKey {
        return .What_Are_Your_Post_Grad_Aspirations
    }
    
    func buttons() -> [DatabaseValue] {
        return [.continued_study, .atheltics, .work_in_an_industry_related_to_your_major, .earn_money_with_your_degree, .something_else]
    }
}
