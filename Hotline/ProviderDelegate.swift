//
//  ProviderDelegate.swift
//  Hotline
//
//  Created by Fernando on 4/13/18.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import CallKit

class ProviderDelegate: NSObject {
    
    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
    
    init(callManager: CallManager) {
        self.callManager = callManager
        
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        
        super.init()
        
        provider.setDelegate(self , queue: nil)
    }

    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Hotline")
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        
        return providerConfiguration
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        // 1. You prepare a call update for the system, which will contain all the relevant call metadata.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo
        
        // 2. Invoking reportIncomingCall(with:update:completion) on the provider will notify the system of the incoming call.
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                // 3. The completion handler will be called once the system processes the call. If there were no errors, you create a Call instance, and add it to the list of calls via the CallManager.
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            
            // 4. Invoke the completion handler, if it’s not nil.
            completion?(error as NSError?)
        }
    }
}


extension ProviderDelegate: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        
        for call in callManager.calls {
            call.end()
        }
        
        callManager.removeAllCalls()
    }
}
