//
//  AppDelegate.swift
//  AppAuthSampleSwift
//
//  Created by Kamal Dandamudi on 5/25/16.
//  Copyright © 2016 SillyApps. All rights reserved.
//

import UIKit
import CoreData
import AppAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var currentAuthorizationFlow:OIDAuthorizationFlowSession?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    /*! @fn application:openURL:options:
     @brief Handles inbound URLs. Checks if the URL matches the redirect URI for a pending
     AppAuth authorization request.
     */
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        // Sends the URL to the current authorization flow (if any) which will process it if it relates to
        // an authorization response.
        if currentAuthorizationFlow!.resumeAuthorizationFlowWithURL(url){
            currentAuthorizationFlow = nil
            return true
        }
        
        // Your additional URL handling (if any) goes here.
        
        return false;
    }
    
    /*! @fn application:openURL:sourceApplication:annotation:
     @brief Forwards inbound URLs for iOS 8.x and below to @c application:openURL:options:.
     @discussion When you drop support for versions of iOS earlier than 9.0, you can delete this
     method. NB. this implementation doesn't forward the sourceApplication or annotations. If you
     need these, then you may want @c application:openURL:options to call this method instead.
     */
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return self.application(application, openURL: url, options:[:])
    }
}

