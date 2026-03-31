import Foundation

struct TensionMoment: Identifiable, Equatable {
    let teamId: Int
    let teamName: String
    let pickCount: Int

    var id: Int { teamId }

    var flavorText: String {
        switch pickCount {
        case 2:
            return "shared fate"
        case 3:
            return "all watching nervously"
        default:
            return "biggest group at risk"
        }
    }
}
