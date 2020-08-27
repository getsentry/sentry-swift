import XCTest

class SentryHubTests: XCTestCase {
    
    private class Fixture {
        let options: Options
        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Object does not exist"])
        let exception = NSException(name: NSExceptionName("My Custom exeption"), reason: "User wants to crash", userInfo: nil)
        var client: TestClient!
        let crumb = Breadcrumb(level: .error, category: "default")
        let scope = Scope()
        let message = "some message"
        let event: Event
        
        init() {
            options = Options()
            options.dsn = "https://username@sentry.io/1"
            
            scope.add(crumb)
            
            event = Event()
            event.message = message
        }
        
        func getSut(withMaxBreadcrumbs maxBreadcrumbs: UInt = 100) -> SentryHub {
            options.maxBreadcrumbs = maxBreadcrumbs
            return getSut(options)
        }
        
        func getSut(_ options: Options) -> SentryHub {
            client = TestClient(options: options)
            let hub = SentryHub(client: client, andScope: nil)
            hub.bindClient(client)
            return hub
        }
    }

    private let fixture = Fixture()
    
    func testBeforeBreadcrumbWithoutCallbackStoresBreadcrumb() {
        let hub = fixture.getSut()
        // TODO: Add a better API
        let crumb = Breadcrumb(
            level: .error,
            category: "default")
        hub.add(crumb)
        let scope = hub.getScope()
        let scopeBreadcrumbs = scope.serialize()["breadcrumbs"]
        XCTAssertNotNil(scopeBreadcrumbs)
    }
    
    func testBeforeBreadcrumbWithCallbackReturningNullDropsBreadcrumb() {
        let options = fixture.options
        options.beforeBreadcrumb = { crumb in return nil }
        
        let hub = fixture.getSut(options)
        
        let crumb = Breadcrumb(
            level: .error,
            category: "default")
        hub.add(crumb)
        let scope = hub.getScope()
        let scopeBreadcrumbs = scope.serialize()["breadcrumbs"]
        XCTAssertNil(scopeBreadcrumbs)
    }
    
    func testBreadcrumbLimitThroughOptionsUsingHubAddBreadcrumb() {
        let hub = fixture.getSut(withMaxBreadcrumbs: 10)

        for _ in 0...10 {
            let crumb = Breadcrumb(
                level: .error,
                category: "default")
            hub.add(crumb)
        }

        assert(withScopeBreadcrumbsCount: 10, with: hub)
    }
    
    func testBreadcrumbLimitThroughOptionsUsingConfigureScope() {
        let hub = fixture.getSut(withMaxBreadcrumbs: 10)

        for _ in 0...10 {
            addBreadcrumbThroughConfigureScope(hub)
        }

        assert(withScopeBreadcrumbsCount: 10, with: hub)
    }
    
    func testBreadcrumbCapLimit() {
        let hub = fixture.getSut()

        for _ in 0...100 {
            addBreadcrumbThroughConfigureScope(hub)
        }

        assert(withScopeBreadcrumbsCount: 100, with: hub)
    }
    
    func testBreadcrumbOverDefaultLimit() {
        let hub = fixture.getSut(withMaxBreadcrumbs: 200)

        for _ in 0...200 {
            addBreadcrumbThroughConfigureScope(hub)
        }

        assert(withScopeBreadcrumbsCount: 200, with: hub)
    }
    
    func testAddUserToTheScope() {
        let client = Client(options: fixture.options)
        let hub = SentryHub(client: client, andScope: Scope())

        let user = User()
        user.userId = "123"
        hub.setUser(user)
        
        let scope = hub.getScope()

        let scopeSerialized = scope.serialize()
        let scopeUser = scopeSerialized["user"] as? [String: Any?]
        let scopeUserId = scopeUser?["id"] as? String

        XCTAssertEqual(scopeUserId, "123")
    }
    
    func testCaptureEventWithScope() {
        fixture.getSut().capture(event: fixture.event, scope: fixture.scope)
        
        XCTAssertEqual(1, fixture.client.captureEventArguments.count)
        if let eventArguments = fixture.client.captureEventArguments.first {
            XCTAssertEqual(fixture.event.eventId, eventArguments.first.eventId)
            XCTAssertEqual(fixture.scope, eventArguments.second)
        }
    }
    
    func testCaptureEventWithoutScope() {
        fixture.getSut().capture(event: fixture.event, scope: nil)
        
        XCTAssertEqual(1, fixture.client.captureEventArguments.count)
        if let eventArguments = fixture.client.captureEventArguments.first {
            XCTAssertEqual(fixture.event.eventId, eventArguments.first.eventId)
            XCTAssertNil(eventArguments.second)
        }
    }
    
    func testCaptureMessageWithScope() {
        fixture.getSut().capture(message: fixture.message, scope: fixture.scope)
        
        XCTAssertEqual(1, fixture.client.captureMessageArguments.count)
        if let messageArguments = fixture.client.captureMessageArguments.first {
            XCTAssertEqual(fixture.message, messageArguments.first)
            XCTAssertEqual(fixture.scope, messageArguments.second)
        }
    }
    
    func testCaptureMessageWithoutScope() {
        fixture.getSut().capture(message: fixture.message, scope: nil)
        
        XCTAssertEqual(1, fixture.client.captureMessageArguments.count)
        if let messageArguments = fixture.client.captureMessageArguments.first {
            XCTAssertEqual(fixture.message, messageArguments.first)
            XCTAssertNil(messageArguments.second)
        }
    }
    
    func testCatpureErrorWithScope() {
        fixture.getSut().capture(error: fixture.error, scope: fixture.scope).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureErrorArguments.count)
        if let errorArguments = fixture.client.captureErrorArguments.first {
            XCTAssertEqual(fixture.error, errorArguments.first as NSError)
            XCTAssertEqual(fixture.scope, errorArguments.second)
        }
    }
    
    func testCatpureErrorWithSessionWithScope() {
        let sut = fixture.getSut()
        sut.startSession()
        sut.capture(error: fixture.error, scope: fixture.scope).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureErrorWithSessionArguments.count)
        if let errorArguments = fixture.client.captureErrorWithSessionArguments.first {
            let actualSession = errorArguments.second
            
            XCTAssertEqual(fixture.error, errorArguments.first as NSError)
            
            XCTAssertEqual(1, actualSession.errors)
            XCTAssertEqual(SentrySessionStatus.ok, actualSession.status)
            
            XCTAssertEqual(fixture.scope, errorArguments.third)
        }
        
        // only session init is sent
        XCTAssertEqual(1, fixture.client.sessions.count)
    }
    
    func testCatpureErrorWithoutScope() {
        fixture.getSut().capture(error: fixture.error, scope: nil).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureErrorArguments.count)
        if let errorArguments = fixture.client.captureErrorArguments.first {
            XCTAssertEqual(fixture.error, errorArguments.first as NSError)
            let actualScope = errorArguments.second
            XCTAssertNil(actualScope)
        }
    }
    
    func testCatpureExceptionWithScope() {
        fixture.getSut().capture(exception: fixture.exception, scope: fixture.scope).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureExceptionArguments.count)
        if let errorArguments = fixture.client.captureExceptionArguments.first {
            XCTAssertEqual(fixture.exception, errorArguments.first)
            XCTAssertEqual(fixture.scope, errorArguments.second)
        }
    }
    
    func testCatpureExceptionWithoutScope() {
        fixture.getSut().capture(exception: fixture.exception, scope: nil).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureExceptionArguments.count)
        if let errorArguments = fixture.client.captureExceptionArguments.first {
            XCTAssertEqual(fixture.exception, errorArguments.first)
            let actualScope = errorArguments.second
            XCTAssertNil(actualScope)
        }
    }
    
    func testCatpureExceptionWithSessionWithScope() {
        let sut = fixture.getSut()
        sut.startSession()
        sut.capture(exception: fixture.exception, scope: fixture.scope).assertIsNotEmpty()
        
        XCTAssertEqual(1, fixture.client.captureExceptionWithSessionArguments.count)
        if let exceptionArguments = fixture.client.captureExceptionWithSessionArguments.first {
            XCTAssertEqual(fixture.exception, exceptionArguments.first)
            
            let actualSession = exceptionArguments.second
            XCTAssertEqual(1, actualSession.errors)
            XCTAssertEqual(SentrySessionStatus.ok, actualSession.status)
            
            XCTAssertEqual(fixture.scope, exceptionArguments.third)
        }
        
        // only session init is sent
        XCTAssertEqual(1, fixture.client.sessions.count)
    }
    
    @available(OSX 10.12, *)
    func testCatpureMultipleExceptionWithSessionInParallel() {
        captureConcurrentWithSession(count: 10) { sut in
            sut.capture(exception: self.fixture.exception, scope: self.fixture.scope)
        }
        
        XCTAssertEqual(10, fixture.client.captureExceptionWithSessionArguments.count)
        for i in Array(0...9) {
            let arguments = fixture.client.captureExceptionWithSessionArguments[i]
            XCTAssertEqual(i + 1, Int(arguments.second.errors))
        }
    }
    
    @available(OSX 10.12, *)
    func testCatpureMultipleErrorsWithSessionInParallel() {
        captureConcurrentWithSession(count: 10) { sut in
            sut.capture(error: self.fixture.error, scope: self.fixture.scope)
        }
        
        XCTAssertEqual(10, fixture.client.captureErrorWithSessionArguments.count)
        for i in Array(0...9) {
            let arguments = fixture.client.captureErrorWithSessionArguments[i]
            XCTAssertEqual(i + 1, Int(arguments.second.errors))
        }
    }
    
    func testCaptureClientIsNil_ReturnsEmptySentryId() {
        let sut = fixture.getSut()
        sut.bindClient(nil)
        
        XCTAssertEqual(SentryId.empty, sut.capture(error: fixture.error, scope: nil))
        XCTAssertEqual(0, fixture.client.captureErrorArguments.count)
        
        XCTAssertEqual(SentryId.empty, sut.capture(message: fixture.message, scope: fixture.scope))
        XCTAssertEqual(0, fixture.client.captureMessageArguments.count)
        
        XCTAssertEqual(SentryId.empty, sut.capture(event: fixture.event, scope: nil))
        XCTAssertEqual(0, fixture.client.captureEventArguments.count)
        
        XCTAssertEqual(SentryId.empty, sut.capture(exception: fixture.exception, scope: nil))
        XCTAssertEqual(0, fixture.client.captureExceptionArguments.count)
    }
    
    private func addBreadcrumbThroughConfigureScope(_ hub: SentryHub) {
        hub.configureScope({ scope in
            scope.add(self.fixture.crumb)
        })
    }
    
    // Even if we don't run this test below OSX 10.12 we expect the actual
    // implementation to be thread safe.
    @available(OSX 10.12, *)
    private func captureConcurrentWithSession(count: Int, _ capture: @escaping (SentryHub) -> Void) {
        let sut = fixture.getSut()
        sut.startSession()
        
        let queue = DispatchQueue(label: "SentryHubTests", qos: .utility, attributes: [.concurrent, .initiallyInactive])
        
        let group = DispatchGroup()
        for _ in Array(0...count - 1) {
            group.enter()
            queue.async {
                capture(sut)
                group.leave()
            }
        }
        
        queue.activate()
        group.wait()
    }
    
    private func assert(withScopeBreadcrumbsCount count: Int, with hub: SentryHub) {
        let scope = hub.getScope()
        let scopeBreadcrumbs = scope.serialize()["breadcrumbs"] as? [AnyHashable]
        XCTAssertNotNil(scopeBreadcrumbs)
        XCTAssertEqual(scopeBreadcrumbs?.count, count)
    }
}
