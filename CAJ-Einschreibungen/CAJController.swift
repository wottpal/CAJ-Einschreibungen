//
//  CAJController.swift
//  CAJ-Einschreibungen
//


// Webkit includes the invisible 'WKWebView' which we use
// to load the CAJ, inject out JavaScript and fetch the results.
// Informations: https://goo.gl/O4M2Q3
// Great Tutorial: http://goo.gl/EgrTD1
import WebKit
import UIKit


// A protocol what our 'TableViewController' implements to
// get notified when this controller has finished fetching.
protocol CAJControllerDelegate: class {
    func didLoadCAJCourses(fetchedCourses: [CAJCourse]?)
}


// Our class which does the actual fetching-work. It get's a username/password,
// loads the CAJ into a WKWebView, injects the credentials, fires the login-event,
// waits for the course-page to be displayed and crawls any course-informations
// from the DOM. (See: Injection.js and try the functions in the chrome-/safari-console)
class CAJController: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    
    // MARK: - VARIABLES
    
    private var username: String
    private var password: String
    
    // Our reference to our 'TableViewController' which implements the delegate-protocol
    weak var delegate: CAJControllerDelegate? = nil
    
    // Once again a lazy property which contains our a 'WKWebView' which will be 
    // configured with the JavaScript-file 'Insertion.js'. Also we set ourself
    // the 'WKScriptMessageHandler' (which is also a delegate) to handle data
    // sent by our javascript function 'getAllCourses()' in 'Injection.js'.
    lazy var webView: WKWebView = { [unowned self] in
        
        // A WKUserContentController object provides a way for JavaScript to post messages to a web view.
        let webViewConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Load JS-Script
        let jsPath = NSBundle.mainBundle().pathForResource("Injection", ofType: "js")
        let js = String(contentsOfFile: jsPath!, encoding: NSUTF8StringEncoding, error: nil)
        
        // Create a WKUserscript and add it to the contentController
        let userScript = WKUserScript(source: js!, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        userContentController.addScriptMessageHandler(self, name: "courses")
        
        webViewConfiguration.userContentController = userContentController
        
        // Create WKWebView
        let webView = WKWebView(frame: CGRectZero, configuration: webViewConfiguration)
        return webView
        
        }()

    
    
    // MARK: - INITIALIZER

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    

    
    // MARK: - Login- and Fetch-Method
    
    func loginAndGetCourses() {
        // Load initial request with WebView
        let url = NSURL(string: "https://caj.informatik.uni-jena.de/caj/login")
        let urlRequest = NSURLRequest(URL: url!)
        webView.navigationDelegate = self
        webView.loadRequest(urlRequest)
    }

    
    
    // MARK: - WKScriptMessageHandler
    
    // This function is called because of line 30 in 'Injection.js' where data
    // is returned to the webview-object. We parse the array of course-dictionaries
    // into our custom 'CAJCourse'-struct (see in 'TableViewController.swift').
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        if (message.name == "courses") {
            // Convert Message into Array of Dictionaries
            let jsCourses = message.body as! [AnyObject]
            var cajCourses = [CAJCourse]()
            
            // Convert JS-Objects into CAJCourse-Structs
            for course in jsCourses {
                if let course = course as? NSDictionary,
                    let typ = course["typ"] as? String,
                    let name = course["name"] as? String,
                    let dozent = course["dozent"] as? String,
                    let ort = course["ort"] as? String,
                    let zeit = course["zeit"] as? String {
                        
                        // Construct CAJCourse with fetched data
                        cajCourses.append(CAJCourse(typ: typ, name: name, dozent: dozent, ort: ort, zeit: zeit))
                }
            }
            
            // Inform Delegate about
            self.delegate?.didLoadCAJCourses(cajCourses)
        }
    }
    
    

    // MARK: - WKNavigationDelegate
    
    // This function is called when a site (i.e. CAJ-Login and CAJ-Details) is loaded
    // successfully by our 'webView'. At this point our JavaScript-functions have been
    // inserted and we can call them via 'self.webView.evaluateJavaScript(...)'.
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        // Call functions depending on the current state
        if let url = webView.URL {

            var javascriptCode = ""
            
            // Login-Case: Fill in credentials and execute Login-Button
            if url.description.hasSuffix("login") {
                javascriptCode = "login('\(self.username)', '\(self.password)');"
                
                // Logged-in-Case: Crawl all Veranstaltungen
            } else if url.description.hasSuffix("details") {
                javascriptCode = "getAllCourses();"
            }
            
            self.webView.evaluateJavaScript(javascriptCode, completionHandler: nil)
        }
    }
    
}
