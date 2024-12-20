import Foundation

final class MockURLSession: URLSession {
    var data = [Data]()
    var request: (() -> Void)?
    var response: HTTPURLResponse?

    override init() {
        super.init()
    }

    override func dataTask(with: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        request?()
        completionHandler(data.popLast(), response, nil)
        return MockDataTask()
    }

    override func dataTask(with: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        request?()
        completionHandler(data.popLast(), response, nil)
        return MockDataTask()
    }
}

private class MockDataTask: URLSessionDataTask {
    override init() {
        super.init()
    }

    override func resume() {
    }
}
