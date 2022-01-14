import XCTest


public func XCTAssertAsyncThrowsError<T>(
    _ closure: () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await closure()
        XCTFail(message())
    } catch { }
}
