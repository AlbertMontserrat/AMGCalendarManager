import UIKit
import EventKit
import AMGCalendarManager

class ViewController: UIViewController {
    
    @IBOutlet weak var createEvent: UIButton!
    @IBOutlet weak var clearEvents: UIButton!
    @IBOutlet weak var eventsTable: UITableView!
    
    var events = [EKEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createEvent.isHidden = false
        clearEvents.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshEvents()
    }
    
    @IBAction func deleteAllEvents(_ sender: AnyObject) {
        clearCalendarEvents()
    }
    
    @IBAction func createRandomEvent(_ sender: AnyObject) {
        insertEvent()
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell")!
        cell.textLabel?.text = event.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMMM-yyyy hh:mm"
        
        cell.detailTextLabel?.text = event.isAllDay ? "All day" : formatter.string(from: event.startDate) + " -> " + formatter.string(from: event.endDate)
        
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let event = self.events[indexPath.row]
            
            AMGCalendarManager.shared.removeEvent(eventId: event.eventIdentifier, completion: { (error) in
                self.refreshEvents()
            })
            
        }
    }
}

extension ViewController {
    
    fileprivate func refreshEvents() {
        
        AMGCalendarManager.shared.getAllEvents(completion: { (error, result) in
            if let events = result {
                self.events = events
                self.eventsTable.reloadData()
            }
        })
        
    }
    
    fileprivate func insertEvent() {
        AMGCalendarManager.shared.createEvent { (event) in
            guard let event = event else { return }
            
            event.title = "Meeting with Mr.\(Int(arc4random_uniform(2000)))"
            event.startDate = Date()
            event.endDate = event.startDate.addingTimeInterval(Double(arc4random_uniform(24)) * 60 * 60)
            
            //other options
            event.notes = "Don't forget to bring the meeting memos"
            event.location = "Room \(Int(arc4random_uniform(100)))"
            event.availability = .free
            
            AMGCalendarManager.shared.saveEvent(event: event, completion: { (error) in
                self.refreshEvents()
            })
        }
    }
    
    fileprivate func clearCalendarEvents(){
        AMGCalendarManager.shared.removeAllEvents { (error) in
            self.refreshEvents()
        }
    }
}
