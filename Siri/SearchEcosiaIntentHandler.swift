//
//  SearchEcosiaIntentHandler.swift
//  Siri
//
//  Created by Jörn Ehmann on 27.01.22.
//  Copyright © 2022 Mozilla. All rights reserved.
//

import Foundation
import Intents

class SearchEcosiaIntentHandler: NSObject, SearchEcosiaIntentHandling {
    func handle(intent: SearchEcosiaIntent, completion: @escaping (SearchEcosiaIntentResponse) -> Void) {
        let activity  = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        let encodedTerm = intent.term!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        activity.webpageURL = URL(string: "https://www.ecosia.org/search?q=\(encodedTerm)")!
        let response = SearchEcosiaIntentResponse(code: .continueInApp, userActivity: activity)
        completion(response)
    }

    func resolveTerm(for intent: SearchEcosiaIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if intent.term == "term" {
            completion(INStringResolutionResult.needsValue())
        }else{
            completion(INStringResolutionResult.success(with: intent.term ?? ""))
        }
    }

}
