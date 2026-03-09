import SwiftUI
import UIKit

let isRunningTests = NSClassFromString("XCTestCase") != nil

if isRunningTests {
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
    PyramidApp.main()
}
