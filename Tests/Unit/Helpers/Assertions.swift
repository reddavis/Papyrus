import XCTest

func XCTAsyncAssertThrow<T>(
    _ closure: () async throws -> T,
    errorHandler: ((Error) -> Void)? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await closure()
        XCTFail(
            "Failed to throw error",
            file: file,
            line: line
        )
    } catch {}
}

func XCTAsyncAssertNoThrow<T>(
    _ closure: () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await closure()
    } catch {
        XCTFail(
            "Unexpected error thrown \(error)",
            file: file,
            line: line
        )
    }
}
