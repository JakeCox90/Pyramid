#if DEBUG
import Foundation
import Supabase

struct DevResetResponse: Decodable {
    let success: Bool
    let mode: String
    let clearOnboarding: Bool
}

enum DevResetService {
    static func reset(
        mode: String,
        client: SupabaseClient
    ) async throws -> DevResetResponse {
        Log.auth.info("DevReset: starting \(mode) reset")

        let response: DevResetResponse = try await client.functions.invoke(
            "reset-dev-data",
            options: FunctionInvokeOptions(body: ["mode": mode])
        )

        Log.auth.info(
            "DevReset: \(mode) complete, clearOnboarding=\(response.clearOnboarding)"
        )
        return response
    }
}
#endif
