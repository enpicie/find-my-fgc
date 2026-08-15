
import XCTest
import Vapor
@testable import App

/// Covers the query classifier that decides whether to pin a geocode lookup to a
/// country. Getting this wrong is not a visible crash — it is a search silently
/// centred on the wrong continent — so the boundaries are pinned explicitly.
final class NLPServiceTests: XCTestCase {

    // MARK: - US ZIP codes

    func testFiveDigitZIPSelectsUS() {
        for zip in ["90210", "44444", "01841", "00501", "99950"] {
            XCTAssertEqual(NLPService.countryComponent(for: zip), "US", "expected US for \(zip)")
        }
    }

    func testZIPPlusFourSelectsUS() {
        XCTAssertEqual(NLPService.countryComponent(for: "12345-6789"), "US")
    }

    func testSurroundingWhitespaceIsIgnored() {
        XCTAssertEqual(NLPService.countryComponent(for: "  90210  "), "US")
    }

    /// A well-formed ZIP that is not assigned still classifies as US. That is
    /// deliberate: the classifier only reads shape, and geocode() rejects the
    /// country-level fallback Google returns for these.
    func testUnassignedButWellFormedZIPStillSelectsUS() {
        XCTAssertEqual(NLPService.countryComponent(for: "01828"), "US")
        XCTAssertEqual(NLPService.countryComponent(for: "55555"), "US")
    }

    func testMalformedDigitStringsAreNotZIPs() {
        for value in ["1234", "123456", "9021a", "12345-678", "12345-67890", "12345-", "-1234"] {
            XCTAssertNil(NLPService.countryComponent(for: value), "expected nil for \(value)")
        }
    }

    // MARK: - Canadian postal codes

    func testCanadianPostalCodeSelectsCA() {
        for code in ["J4H 2P3", "J4H2P3", "M5V 3L9", "K1A0B1"] {
            XCTAssertEqual(NLPService.countryComponent(for: code), "CA", "expected CA for \(code)")
        }
    }

    func testCanadianPostalCodeIsCaseInsensitive() {
        XCTAssertEqual(NLPService.countryComponent(for: "j4h 2p3"), "CA")
    }

    func testMalformedPostalCodesAreNotCanadian() {
        for value in ["J4H 2P", "1AB 2C3", "J4HH2P3", "J4H 2P33"] {
            XCTAssertNil(NLPService.countryComponent(for: value), "expected nil for \(value)")
        }
    }

    // MARK: - Free text stays unrestricted

    /// The regression that matters most: constraining free text would send
    /// "london" to Ontario instead of the UK. These must stay unpinned.
    func testFreeTextIsUnrestricted() {
        for query in ["london", "Boston", "Portland, ME", "Tucson", "Paris", "Tokyo", ""] {
            XCTAssertNil(NLPService.countryComponent(for: query), "expected nil for \"\(query)\"")
        }
    }
}
