import SwiftUI

struct ActivityEvent: Identifiable {
    let id: String
    let type: EventType
    let description: String
    let timestamp: Date
    let dotColor: Color

    enum EventType {
        case elimination
        case joined
        case streakMilestone
        case survived
    }
}
