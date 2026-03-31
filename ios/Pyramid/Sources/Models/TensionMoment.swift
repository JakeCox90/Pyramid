import Foundation

struct TensionMoment: Identifiable, Equatable {
    let id: Int
    let teamName: String
    let teamId: Int
    let pickCount: Int

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
