//
//  ViewController.swift
//  AppAuthSampleSwift
//
//  Created by Kamal Dandamudi on 5/25/16.
//  Copyright © 2016 SillyApps. All rights reserved.
//

import UIKit
import AppAuth

class ViewController: UIViewController, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    @IBOutlet var authAutoButton: UIButton!
    @IBOutlet var authManual: UIButton!
    @IBOutlet var codeExchangeButton: UIButton!
    @IBOutlet var userinfoButton: UIButton!
    @IBOutlet var clearAuthStateButton: UIButton!
    @IBOutlet var logTextView: UITextView!
    
    /*! @var kIssuer
     @brief The OIDC issuer from which the configuration will be discovered.
     */
    let kIssuer = "https://accounts.google.com"
    
    /*! @var kClientID
     @brief The OAuth client ID.
     @discussion For Google, register your client at
     https://console.developers.google.com/apis/credentials?project=_
     The client should be registered with the "iOS" type.
     */
    let kClientID =
    "120786619086-sr3hag35r805o1ic06q4ch8rb41reg6p.apps.googleusercontent.com"
    
    /*! @var kRedirectURI
     @brief The OAuth redirect URI for the client @c kClientID.
     @discussion With Google, the scheme of the redirect URI is the reverse DNS notation of the
     client id. This scheme must be registered as a scheme in the project's Info
     property list ("CFBundleURLTypes" plist key). Any path component will work, we use
     'oauthredirect' here to help disambiguate from any other use of this scheme.
     */
    let kRedirectURI =
    "com.googleusercontent.apps.120786619086-sr3hag35r805o1ic06q4ch8rb41reg6p:/oauthredirect"
    
    /*! @var kAppAuthExampleAuthStateKey
     @brief NSCoding key for the authState property.
     */
    let kAppAuthExampleAuthStateKey = "authState";
    
    /*! @property authState
     @brief The authorization state. This is the AppAuth object that you should keep around and
     serialize to disk.
     */
    var authState:OIDAuthState?
   
    // MARK:Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NOTE:
        //
        // To run this sample, you need to register your own iOS client at
        // https://console.developers.google.com/apis/credentials?project=_ and update three configuration
        // points in the sample: kClientID and kRedirectURI constants in AppAuthExampleViewController.m
        // and the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0).
        // Full instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md
        
        assert(kClientID != "YOUR_CLIENT.apps.googleusercontent.com","Update kClientID with your own client id. Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md")
        
        assert(kRedirectURI != "com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect","Update kRedirectURI with your own redirect URI. Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md")
        
        // verifies that the custom URI scheme has been updated in the Info.plist
        let urlTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as? NSArray
        assert(urlTypes != nil && urlTypes?.count > 0, "No custom URI scheme has been configured for the project.")
        let urlSchemes = (urlTypes!.objectAtIndex(0) as! NSDictionary).objectForKey("CFBundleURLSchemes") as? NSArray
        assert(urlSchemes != nil && urlSchemes?.count > 0,"No custom URI scheme has been configured for the project.")
        let urlScheme = urlSchemes!.objectAtIndex(0) as? NSString
        
        assert(urlScheme != "com.googleusercontent.apps.YOUR_CLIENT","Configure the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0) with the scheme of your redirect URI. Full instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md")
        
        logTextView.layer.borderColor = UIColor(white: 0.8, alpha: 1.0).CGColor
        logTextView.layer.borderWidth = 1.0
        logTextView.alwaysBounceVertical = true
        logTextView.textContainer.lineBreakMode = .ByCharWrapping
        logTextView.text = ""
        
        self.loadState()
        self.updateUI()
    }
    
    /*! @fn saveState
     @brief Saves the @c OIDAuthState to @c NSUSerDefaults.
     */
    func saveState(){
        // for production usage consider using the OS Keychain instead
        if authState != nil{
            let archivedAuthState = NSKeyedArchiver.archivedDataWithRootObject(authState!)
            NSUserDefaults.standardUserDefaults().setObject(archivedAuthState, forKey: kAppAuthExampleAuthStateKey)
        }
        else{
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: kAppAuthExampleAuthStateKey)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /*! @fn loadState
     @brief Loads the @c OIDAuthState from @c NSUSerDefaults.
     */
    func loadState(){
        // loads OIDAuthState from NSUSerDefaults
        guard let archivedAuthState = NSUserDefaults.standardUserDefaults().objectForKey(kAppAuthExampleAuthStateKey) as? NSData else{
            return
        }
        guard let authState = NSKeyedUnarchiver.unarchiveObjectWithData(archivedAuthState) as? OIDAuthState else{
            return
        }
        assignAuthState(authState)
    }
    
    func assignAuthState(authState:OIDAuthState?){
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        self.stateChanged()
    }
    
    /*! @fn updateUI
     @brief Refreshes UI, typically called after the auth state changed.
     */
    func updateUI(){
        // dynamically changes authorize button text depending on authorized state
        if authState != nil {
            userinfoButton.enabled = authState!.isAuthorized
            clearAuthStateButton.enabled = true
            codeExchangeButton.enabled = (authState!.lastAuthorizationResponse.authorizationCode != nil) && (authState!.lastTokenResponse == nil)
            authAutoButton.setTitle("Re-authorize", forState: .Normal)
            authAutoButton.setTitle("Re-authorize", forState:.Highlighted)
            authManual.setTitle("Re-authorize (Manual)", forState: .Normal)
            authManual.setTitle("Re-authorize (Manual)", forState:.Highlighted)
        }
        else{
            userinfoButton.enabled = false
            clearAuthStateButton.enabled = false
            codeExchangeButton.enabled = false
            authAutoButton.setTitle("Authorize", forState: .Normal)
            authAutoButton.setTitle("Authorize", forState:.Highlighted)
            authManual.setTitle("Authorize (Manual)", forState: .Normal)
            authManual.setTitle("Authorize (Manual)", forState:.Highlighted)
        }
    }
    
    func stateChanged(){
        self.saveState()
        self.updateUI()
    }
    
    
    func didChangeState(state: OIDAuthState) {
        authState = state
        authState?.stateChangeDelegate = self
        self.stateChanged()
    }
    
    func authState(state: OIDAuthState, didEncounterAuthorizationError error: NSError) {
        self.logMessage("Received authorization error: \(error)")
    }
    
    /*! @fn authWithAutoCodeExchange:
     @brief Authorization code flow using @c OIDAuthState automatic code exchanges.
     @param sender IBAction sender.
     */
    @IBAction func autoWithAutoCodeExchange(sender: AnyObject) {
        let issuer = NSURL(string: kIssuer)
        let redirectURI = NSURL(string: kRedirectURI)
        
        self.logMessage("Fetching configuration for issuer: \(issuer!)")
        
        // discovers endpoints
        OIDAuthorizationService.discoverServiceConfigurationForIssuer(issuer!){
            configuration,error in
            
            if configuration == nil {
                self.logMessage("Error retrieving discovery document: \(error?.localizedDescription)")
                self.assignAuthState(nil)
                return
            }
            
            self.logMessage("Got configuration: \(configuration!)")
            
            // builds authentication request
            let request = OIDAuthorizationRequest(configuration: configuration!, clientId: self.kClientID, scopes: [OIDScopeOpenID, OIDScopeProfile], redirectURL: redirectURI!, responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            // performs authentication request
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.logMessage("Initiating authorization request with scope: \(request!.scope!)")
            
            appDelegate.currentAuthorizationFlow = OIDAuthState.authStateByPresentingAuthorizationRequest(request!, presentingViewController: self){
                authState,error in
                if authState != nil{
                    self.assignAuthState(authState)
                    self.logMessage("Got authorization tokens. Access token: \(authState!.lastTokenResponse!.accessToken!)")
                }
                else{
                    self.logMessage("Authorization error: \(error!.localizedDescription)")
                    self.assignAuthState(nil)
                }
            }
        }
    }
    
    /*! @fn authNoCodeExchange:
     @brief Authorization code flow without a the code exchange (need to call @c codeExchange:
     manually)
     @param sender IBAction sender.
     */
    @IBAction func authNoCodeExchange(sender: AnyObject) {
        let issuer = NSURL(string: kIssuer)
        let redirectURI = NSURL(string: kRedirectURI)
        
        self.logMessage("Fetching configuration for issuer: \(issuer!)")
        
        // discovers endpoints
        OIDAuthorizationService.discoverServiceConfigurationForIssuer(issuer!){
            configuration,error in
            
            if configuration == nil {
                self.logMessage("Error retrieving discovery document: \(error?.localizedDescription)")
                return
            }
            
            self.logMessage("Got configuration: \(configuration!)")
            
            // builds authentication request
            let request = OIDAuthorizationRequest(configuration: configuration!, clientId: self.kClientID, scopes: [OIDScopeOpenID, OIDScopeProfile], redirectURL: redirectURI!, responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            // performs authentication request
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.logMessage("Initiating authorization request: \(request!)")
            
            appDelegate.currentAuthorizationFlow = OIDAuthorizationService.presentAuthorizationRequest(request!, presentingViewController: self){
                authorizationResponse, error in
                if authorizationResponse != nil{
                    self.assignAuthState(OIDAuthState(authorizationResponse: authorizationResponse!))
                    self.logMessage("Authorization response with code: \(authorizationResponse!.authorizationCode!)")
                    // could just call [self tokenExchange:nil] directly, but will let the user initiate it.
                }
                else{
                    self.logMessage("Authorization error: \(error!.localizedDescription)")
                }
            }
        }
    }
    
    
    /*! @fn codeExchange:
     @brief Performs the authorization code exchange at the token endpoint.
     @param sender IBAction sender.
     */
    @IBAction func codeExchange(sender: AnyObject) {
        // performs code exchange request
        let tokenExchangeRequest = authState?.lastAuthorizationResponse.tokenExchangeRequest()
        self.logMessage("Performing authorization code exchange with request [\(tokenExchangeRequest!)]")
        
        OIDAuthorizationService.performTokenRequest(tokenExchangeRequest!){
          tokenResponse,error in
            if tokenResponse == nil{
                self.logMessage("Token exchange error: \(error!.localizedDescription)")
            }
            else{
                self.logMessage("Received token response with accessToken: \(tokenResponse!.accessToken!)")
            }
            self.authState?.updateWithTokenResponse(tokenResponse, error: error)
        }
    }
    
    /*! @fn clearAuthState:
     @brief Nils the @c OIDAuthState object.
     @param sender IBAction sender.
     */
    @IBAction func clearAuthState(sender: AnyObject) {
        self.assignAuthState(nil)
    }
    
    /*! @fn clearLog:
     @brief Clears the UI log.
     @param sender IBAction sender.
     */
    @IBAction func clearLog(sender: AnyObject) {
        logTextView.text = ""
    }
    
    /*! @fn userinfo:
     @brief Performs a Userinfo API call using @c OIDAuthState.withFreshTokensPerformAction.
     @param sender IBAction sender.
     */
    @IBAction func userinfo(sender: AnyObject) {
        let userInfoEndpoint = authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint
        if userInfoEndpoint == nil{
            self.logMessage("Userinfo endpoint not declared in discovery document")
            return
        }
        let currentAccessToken = authState?.lastTokenResponse?.accessToken
        
        self.logMessage("Performing userinfo request")
        
        authState?.withFreshTokensPerformAction(){
            accessToken,idToken,error in
            if error != nil{
                self.logMessage("Error fetching fresh tokens: \(error!.localizedDescription)")
                return
            }
            
            // log whether a token refresh occurred
            if currentAccessToken != accessToken{
                self.logMessage("Access token was refreshed automatically (\(currentAccessToken!) to \(accessToken!)")
            }
            else{
                self.logMessage("Access token was fresh and not updated [\(accessToken!)]")
            }
            
            // creates request to the userinfo endpoint, with access token in the Authorization header
            let request = NSMutableURLRequest(URL: userInfoEndpoint!)
            let authorizationHeaderValue = "Bearer \(accessToken!)"
            request.addValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
            
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            
            // performs HTTP request
            let postDataTask = session.dataTaskWithRequest(request){
                data,response,error in
                dispatch_async(dispatch_get_main_queue()){
                    guard let httpResponse = response as? NSHTTPURLResponse else{
                        self.logMessage("Non-HTTP response \(error)")
                        return
                    }
                    do{
                       let jsonDictionaryOrArray = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                        if httpResponse.statusCode != 200{
                            let responseText = NSString(data: data!, encoding: NSUTF8StringEncoding)
                            if httpResponse.statusCode == 401{
                                // "401 Unauthorized" generally indicates there is an issue with the authorization
                                // grant. Puts OIDAuthState into an error state.
                                let oauthError = OIDErrorUtilities.resourceServerAuthorizationErrorWithCode(0, errorResponse: jsonDictionaryOrArray as? [NSObject : AnyObject], underlyingError: error)
                                self.authState?.updateWithAuthorizationError(oauthError!)
                                //log error
                                self.logMessage("Authorization Error (\(oauthError)). Response: \(responseText)")
                            }
                            else{
                                self.logMessage("HTTP: \(httpResponse.statusCode). Response: \(responseText)")
                            }
                            return
                        }
                        self.logMessage("Success: \(jsonDictionaryOrArray)")
                    }
                    catch{
                        self.logMessage("Error while serializing data to JSON")
                    }
                }
            }
            postDataTask.resume()
        }
    }
    
    /*! @fn logMessage
     @brief Logs a message to stdout and the textfield.
     @param format The format string
     */
    func logMessage(message:String){
        // outputs to stdout
        print(message)
        
        // appends to output log
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let dateString = dateFormatter.stringFromDate(NSDate())
        logTextView.text = logTextView.text +  ((logTextView.text.isEmpty) ? "" : "\n") + dateString + ":" + message
        
    }
}

