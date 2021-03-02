@testable import Sentry
import XCTest

class SentryTransportInitializerTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "SentryTransportInitializerTests")
    private static let dsn = TestConstants.dsn(username: "SentryTransportInitializerTests")
    
    private var fileManager: SentryFileManager!
    
    override func setUp() {
        do {
            fileManager = try SentryFileManager(dsn: SentryTransportInitializerTests.dsn, andCurrentDateProvider: TestCurrentDateProvider())
        } catch {
            XCTFail("SentryDsn could not be created")
        }
    }

    func testDefault() throws {
        let options = try Options(dict: ["dsn": SentryTransportInitializerTests.dsnAsString])
        
        let result = TransportInitializer.initTransport(options, sentryFileManager: fileManager)
        
        XCTAssertTrue(result.isKind(of: SentryHttpTransport.self))
    }
}
