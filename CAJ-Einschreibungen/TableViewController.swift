//
//  ViewController.swift
//  CAJ-Einschreibungen
//


// Contains Cocoa-Touch and Foundation 
// Informations: https://goo.gl/g0H9Q1
import UIKit


// The ViewController of our Course-Table which is asked for the contents
// of the table by the table itself, because we have marked this class as
// 'UITableViewDataSource' in the Interface-Builder ('.storyboard'-file).
// It also cares about instantiating a 'CAJController'-instance, asking it 
// to fetch 'CAJCourses' and handles the results as a 'CAJControllerDelegate'.
class TableViewController: UITableViewController, UITableViewDataSource, CAJControllerDelegate {
    
    // MARK: - VARIABLES
    
    // An array of all Courses which is empty by default
    var courses: [CAJCourse] = []
    
    // Our instance of 'CAJController' which fetches the data from the CAJ
    var cajController: CAJController? = nil
    
    // A "lazily" computed property which represents the modal-view which
    // pops up and asks for username&password. Lazy means the closure will
    // execute first just after the property is used it's first time.
    // Informations: https://goo.gl/QNiQxr
    lazy var loginAlertController: UIAlertController = { [unowned self] in
        // Create Alert Controller with title and subtitle
        let alertController = UIAlertController(title: "CAJ-Anmeldung", message: "Gib dein Nutzerkürzel mit entsprechendem Passwort ein, um fortzufahren.", preferredStyle: .Alert)
        
        alertController.addTextFieldWithConfigurationHandler { $0.placeholder = "Benutzerkürzel" }
        alertController.addTextFieldWithConfigurationHandler { $0.placeholder = "Passwort"; $0.secureTextEntry = true }
        
        // Add "Anmelden"-Action
        alertController.addAction(UIAlertAction(title: "Anmelden", style: .Default) { _ in
            // Get Textfields
            let nameField = alertController.textFields?[0] as! UITextField
            let pwField = alertController.textFields?[1] as! UITextField
            
            // Instantiate CAJController with username & password
            self.cajController = CAJController(username: nameField.text, password: pwField.text)
            self.cajController?.delegate = self
            self.cajController?.loginAndGetCourses()
            })
        
        // Add "Abbrechen"-Action
        alertController.addAction(UIAlertAction(title: "Abbrechen", style: .Destructive) { _ in })
        
        return alertController
        }()

    
    
    // MARK: - VIEW-CONTROLLER-LIFECYCLE
    
    // This function is called after the view-hierachy did
    // loaded successfully from the memory
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start Loading
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: Selector("loadCAJCourses"), forControlEvents: .ValueChanged)
        self.refreshControl?.beginRefreshing()
        self.loadCAJCourses()
    }
    
    
    
    // MARK: - FETCH/GET CAJ-COURSES
    
    // If we already passed in our password/username this method
    // asks the 'cajController' to fetch again, otherwise the 'loginAlertController'
    // is prompted, and it's completion-handler intantiates our
    // 'cajController' and asks it to fetch the data from CAJ.
    func loadCAJCourses() {
        // Ask for Login and Passwort if nil, otherwise fetch again
        if self.cajController == nil {
            self.parentViewController?.presentViewController(self.loginAlertController, animated: true, completion: nil)
        } else {
            self.cajController!.loginAndGetCourses()
        }
    }

    // Becourse web-requests should not be handled synchronously, we don't
    // get any results from the 'loginAndGetCourses' function. Has the
    // 'cajController' fetched everything successfully it's calling this
    // method. The compiler knows that we implement this method because we
    // conform to the 'CAJControllerDelegate'.
    func didLoadCAJCourses(fetchedCourses: [CAJCourse]?) {
        if fetchedCourses != nil {
            self.courses = fetchedCourses!
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            
        }
    }

    
    
    // MARK: - UITableViewDataSource
    
    // We return the number of rows which is equivalent to the number of courses
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }
    
    // We create a new cell (actually we 'dequeue a reusable' one but don't care about that)
    // and customize it to display the Course-Name, -Dozent, ... in it's labels.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CourseCell", forIndexPath: indexPath) as! UITableViewCell
        
        let course = self.courses[indexPath.row]
        let courseShortType = "[" + (course.typ as NSString).substringToIndex(1) + "]"
        
        cell.textLabel?.text = "\(courseShortType) \(course.name) von \(course.dozent)"
        cell.detailTextLabel?.text = "Ort: \(course.ort), Zeit: \(course.zeit)"
        
        return cell
    }
}

