import XCTest

class SentryConcurrentRateLimitsDictionaryTests: XCTestCase {
    
    private var currentDateProvider: TestCurrentDateProvider!
    private var sut: SentryConcurrentRateLimitsDictionary!
    
    override func setUp() {
        currentDateProvider = TestCurrentDateProvider()
        sut = SentryConcurrentRateLimitsDictionary()
    }
    
    func testTwoRateLimit() {
        let dateA = self.currentDateProvider.date()
        let dateB = dateA.addingTimeInterval(TimeInterval(1))
        sut.addRateLimit(SentryRateLimitCategory.default, validUntil: dateA)
        sut.addRateLimit(SentryRateLimitCategory.error, validUntil: dateB)
        XCTAssertEqual(dateA, self.sut.getRateLimit(for: SentryRateLimitCategory.default))
        XCTAssertEqual(dateB, self.sut.getRateLimit(for: SentryRateLimitCategory.error))
    }
    
    func testOverridingRateLimit() {
        let dateA = self.currentDateProvider.date()
        let dateB = dateA.addingTimeInterval(TimeInterval(1))
        
        sut.addRateLimit(SentryRateLimitCategory.attachment, validUntil: dateA)
        XCTAssertEqual(dateA, self.sut.getRateLimit(for: SentryRateLimitCategory.attachment))

        sut.addRateLimit(SentryRateLimitCategory.attachment, validUntil: dateB)
        XCTAssertEqual(dateB, self.sut.getRateLimit(for: SentryRateLimitCategory.attachment))
    }

    func testConcurrentReadWrite()  {
        let queue1 = DispatchQueue(label: "SentryConcurrentRateLimitsStorageTests1", qos: .background, attributes: [.concurrent, .initiallyInactive])
        let queue2 = DispatchQueue(label: "SentryConcurrentRateLimitsStorageTests2", qos: .utility, attributes: [.concurrent, .initiallyInactive])
        
        let group = DispatchGroup()
        
        for i in Array(0...10) {
            
            let date = self.currentDateProvider.date().addingTimeInterval(TimeInterval(i))
            
            group.enter()
            queue1.async {
                let a = i as NSNumber
                let b = 100 + i as NSNumber
       
                self.sut.addRateLimit(self.getCategory(rawValue: a), validUntil: date)
                self.sut.addRateLimit(self.getCategory(rawValue: b), validUntil: date)
                XCTAssertEqual(date, self.sut.getRateLimit(for: self.getCategory(rawValue: a)))
                XCTAssertEqual(date, self.sut.getRateLimit(for: self.getCategory(rawValue: b)))
                group.leave()
            }
            
            group.enter()
            queue2.async {
                                
                let c = 200 + i as NSNumber
                let d = 300 + i as NSNumber

                self.sut.addRateLimit(self.getCategory(rawValue: c), validUntil: date)
                
                XCTAssertEqual(date, self.sut.getRateLimit(for: self.getCategory(rawValue: c)))
                self.sut.addRateLimit(self.getCategory(rawValue: d), validUntil: date)
                group.leave()
            }
        }
        
        queue1.activate()
        queue2.activate()
        group.wait()
        
        for i in Array(0...10) {
            let date = self.currentDateProvider.date().addingTimeInterval(TimeInterval(i))
            
            let a = i as NSNumber
            let b = 100 + i as NSNumber
            let c = 200 + i as NSNumber
            let d = 300 + i as NSNumber
            
            XCTAssertEqual(date, sut.getRateLimit(for: getCategory(rawValue: a)))
            XCTAssertEqual(date, sut.getRateLimit(for: getCategory(rawValue: b)))
            XCTAssertEqual(date, sut.getRateLimit(for: getCategory(rawValue: c)))
            XCTAssertEqual(date, sut.getRateLimit(for: getCategory(rawValue: d)))
        }
    }
    
    private func getCategory(rawValue:NSNumber) -> SentryRateLimitCategory {
        return SentryRateLimitCategory.init(rawValue: UInt(truncating: rawValue))!
    }
}
