//
//  CalendarManager.swift
//
//  Created by Albert Montserrat on 16/02/17.
//  Copyright (c) 2015 Albert Montserrat. All rights reserved.
//

import EventKit

public class AMGCalendarManager{
    public var eventStore = EKEventStore()
    public let calendarName: String
    
    public var calendar: EKCalendar? {
        get {
            return eventStore.calendars(for: .event).filter { (element) in
                return element.title == calendarName
                }.first
        }
    }
    
    public static let shared = AMGCalendarManager()
    
    public init(calendarName: String = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String){
        self.calendarName = calendarName
    }
    
    //MARK: - Authorization
    
    public func requestAuthorization(completion: @escaping (_ allowed:Bool) -> ()){
        switch EKEventStore.authorizationStatus(for: EKEntityType.event) {
        case .authorized:
            if self.calendar == nil {
                _ = self.createCalendar()
            }
            completion(true)
        case .denied:
            completion(false)
        case .notDetermined:
            var userAllowed = false
            eventStore.requestAccess(to: .event, completion: { (allowed, error) -> Void in
                userAllowed = !allowed
                if userAllowed {
                    self.eventStore = EKEventStore()
                    if self.calendar == nil {
                        _ = self.createCalendar()
                    }
                    completion(userAllowed)
                } else {
                    completion(false)
                }
            })
        default:
            completion(false)
        }
    }
    
    //MARK: - Calendar
    
    public func addCalendar(commit: Bool = true, completion: ((_ error:NSError?) -> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            let error = weakSelf.createCalendar(commit: commit)
            completion?(error)
        }
    }
    
    public func removeCalendar(commit: Bool = true, completion: ((_ error:NSError?)-> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            if let cal = weakSelf.calendar, EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                do {
                    try weakSelf.eventStore.removeCalendar(cal, commit: true)
                    completion?(nil)
                } catch let error as NSError {
                    completion?(error)
                }
            }
        }
        
    }
    
    //MARK: - New and update events
    
    public func createEvent(completion: ((_ event:EKEvent?) -> Void)?) {
        
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(nil)
                return
            }
            
            if let c = weakSelf.calendar {
                let event = EKEvent(eventStore: weakSelf.eventStore)
                event.calendar = c
                completion?(event)
                return
            }
            completion?(nil)
        }
    }
    
    public func saveEvent(event: EKEvent, completion: ((_ error:NSError?) -> Void)? = nil) {
        
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            
            if !weakSelf.insertEvent(event: event) {
                completion?(weakSelf.getGeneralError())
            } else {
                completion?(nil)
            }
        }
    }
    
    //MARK: - Remove events
    
    public func removeEvent(eventId: String, completion: ((_ error:NSError?)-> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            weakSelf.getEvent(eventId: eventId, completion: { (error, event) in
                if let e = event {
                    if !weakSelf.deleteEvent(event: e) {
                        completion?(weakSelf.getGeneralError())
                    } else {
                        completion?(nil)
                    }
                } else {
                    completion?(weakSelf.getGeneralError())
                }
            })
        }
    }
    
    public func removeAllEvents(completion: ((_ error:NSError?) -> ())? = nil){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            weakSelf.getAllEvents(completion: { (error, events) in
                guard error == nil, let events = events else {
                    completion?(weakSelf.getGeneralError())
                    return
                }
                for event in events {
                    _ = weakSelf.deleteEvent(event: event)
                }
                completion?(nil)
            })
        }
    }
    
    //MARK: - Get events
    
    public func getAllEvents(completion: ((_ error:NSError?, _ events:[EKEvent]?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            guard let c = weakSelf.calendar else {
                completion?(weakSelf.getGeneralError(),nil)
                return
            }
            let range = 31536000 * 100 as TimeInterval /* 100 Years */
            var startDate = Date(timeIntervalSince1970: -range)
            let endDate = Date(timeIntervalSinceNow: range * 2) /* 200 Years */
            let four_years = 31536000 * 4 as TimeInterval /* 4 Years */
            
            var events = [EKEvent]()
            
            while startDate < endDate {
                var currentFinish = Date(timeInterval: four_years, since: startDate)
                if currentFinish > endDate {
                    currentFinish = Date(timeInterval: 0, since: endDate)
                }
                
                let pred = weakSelf.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [c])
                events.append(contentsOf: weakSelf.eventStore.events(matching: pred))
                
                startDate = Date(timeInterval: four_years + 1, since: startDate)
            }
            
            completion?(nil, events)
        }
    }
    
    public func getEvents(startDate: Date, endDate: Date, completion: ((_ error:NSError?, _ events:[EKEvent]?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            if let c = weakSelf.calendar {
                let pred = weakSelf.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [c])
                completion?(nil, weakSelf.eventStore.events(matching: pred))
            } else {
                
                completion?(weakSelf.getGeneralError(),nil)
                
            }
            
        }
    }
    
    public func getEvent(eventId: String, completion: ((_ error:NSError?, _ event:EKEvent?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            let event = weakSelf.eventStore.event(withIdentifier: eventId)
            completion?(nil,event)
        }
    }
    
    //MARK: - Privates
    
    private func createCalendar(commit: Bool = true) -> NSError? {
        let newCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
        newCalendar.title = self.calendarName
        
        // defaultCalendarForNewEvents will always return a writtable source, even when there is no iCloud support.
        newCalendar.source = self.eventStore.defaultCalendarForNewEvents.source
        do {
            try self.eventStore.saveCalendar(newCalendar, commit: commit)
            return nil
        } catch let error as NSError {
            return error
        }
    }
    
    private func insertEvent(event: EKEvent, commit: Bool = true) -> Bool {
        do {
            try eventStore.save(event, span: .thisEvent, commit: commit)
            return true
        } catch {
            return false
        }
    }
    
    private func deleteEvent(event: EKEvent, commit: Bool = true) -> Bool {
        do {
            try eventStore.remove(event, span: .futureEvents, commit: commit)
            return true
        } catch {
            return false
        }
    }
    
    //MARK: - Generic
    
    public func commit() -> Bool {
        do {
            try eventStore.commit()
            return true
        } catch {
            return false
        }
    }
    
    public func reset(){
        eventStore.reset()
    }
}

extension AMGCalendarManager {
    fileprivate func getErrorForDomain(domain: String, description: String, reason: String, code: Int = 999) -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: description,
            NSLocalizedFailureReasonErrorKey: reason
        ]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
    fileprivate func getGeneralError() -> NSError {
        return getErrorForDomain(domain: "CalendarError", description: "Unknown Error", reason: "An unknown error ocurred while trying to sync your calendar. Syncing will be turned off.", code: 999)
    }
    
    fileprivate func getDeniedAccessToCalendarError() -> NSError {
        return getErrorForDomain(domain: "CalendarAuthorization", description: "Calendar access was denied", reason: "To continue syncing your calendars re-enable Calendar access for Técnico Lisboa in Settings->Privacy->Calendars.", code: 987)
    }
    
}
