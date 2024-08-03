import Foundation

// https://www.swiftbysundell.com/questions/array-with-mixed-types/
enum ScheduleItem: Codable {
    case fez(FezData)
    case event(EventData)
    case personalEvent(PersonalEventData)
}

extension ScheduleItem: Identifiable {
    var id: UUID {
        switch self {
            case .fez(let fez):
                return fez.fezID
            case .event(let event):
                return event.eventID
            case .personalEvent(let personalEvent):
                return personalEvent.personalEventID
        }
    }
    var startTime: Date {
        switch self {
            case .fez(let fez):
                return fez.startTime!
            case .event(let event):
                return event.startTime
            case .personalEvent(let personalEvent):
                return personalEvent.startTime
        }
    }
}