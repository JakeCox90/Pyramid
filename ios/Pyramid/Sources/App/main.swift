import SwiftUI
import UIKit

// When running under XCTest, launch a minimal app that skips Supabase
// initialization. This prevents the test runner from crashing due to
// missing environment variables.
let isRunningTests = NSClassFromString("XCTestCase") != nil

if isRunningTests {
    // Minimal UIApplication that does nothing — tests use mocks
    final class TestAppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
        ) -> Bool {
            return true
        }
    }

    UIApplicationMain(
        CommandLine.argc,
        CommandLine.unsafeArgv,
        nil,
        NSStringFromClass(TestAppDelegate.self)
    )
} else {
    // Normal app launch
    struct MainApp: App {
        @UIApplicationDelegateAdaptor(AppDelegate.self)
        var appDelegate
        @StateObject private var appState = AppState()

        var body: some Scene {
            WindowGroup {
                RootView()
                    .environmentObject(appState)
            }
        }
    }

    MainApp.main()
}
