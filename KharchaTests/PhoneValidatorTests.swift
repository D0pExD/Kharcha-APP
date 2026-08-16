import XCTest
@testable import Kharcha

final class PhoneValidatorTests: XCTestCase {
    
    func testValidIndianMobileNumbers() {
        XCTAssertTrue(PhoneValidator.isValid("9876543210"))
        XCTAssertTrue(PhoneValidator.isValid("+91 9876543210"))
        XCTAssertTrue(PhoneValidator.isValid("919876543210"))
        XCTAssertTrue(PhoneValidator.isValid("7000000000"))
        XCTAssertTrue(PhoneValidator.isValid("6234567890"))
    }
    
    func testInvalidNumbers() {
        XCTAssertFalse(PhoneValidator.isValid("12345"))
        XCTAssertFalse(PhoneValidator.isValid("1234567890"))
        XCTAssertFalse(PhoneValidator.isValid("abcdefghij"))
    }
    
    func testRawNumberExtraction() {
        let raw = PhoneValidator.rawNumber("+91 (987) 654-3210")
        XCTAssertEqual(raw, "9876543210")
    }
}
