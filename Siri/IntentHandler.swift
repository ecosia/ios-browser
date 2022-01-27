//
//  IntentHandler.swift
//  Siri
//
//  Created by Jörn Ehmann on 27.01.22.
//  Copyright © 2022 Mozilla. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        guard intent is SearchEcosiaIntent else {
            fatalError("Unhandled Intent error : \(intent)")
        }
        return SearchEcosiaIntentHandler()
    }
    
}
