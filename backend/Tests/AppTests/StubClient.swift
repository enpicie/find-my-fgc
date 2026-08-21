import Vapor
import XCTest

/// A `Client` that never touches the network.
///
/// Service tests use this so they drive the *real* service functions — the same code
/// the server runs — instead of re-implementing the logic inline and asserting against
/// their own copy. Every outgoing request is recorded so tests can also pin the request
/// contract (URL, headers, body), not just the parsed result.
final class StubClient: Client, @unchecked Sendable {
    let eventLoop: EventLoop

    private let handler: @Sendable (ClientRequest) throws -> ClientResponse
    private let lock = NSLock()
    private var recorded: [ClientRequest] = []

    /// Every request the service handed to this client, in order.
    var requests: [ClientRequest] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recorded
    }

    init(
        eventLoop: EventLoop = MultiThreadedEventLoopGroup.singleton.next(),
        handler: @escaping @Sendable (ClientRequest) throws -> ClientResponse
    ) {
        self.eventLoop = eventLoop
        self.handler = handler
    }

    func delegating(to eventLoop: EventLoop) -> any Client { self }

    func logging(to logger: Logger) -> any Client { self }

    func allocating(to byteBufferAllocator: ByteBufferAllocator) -> any Client { self }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        self.lock.lock()
        self.recorded.append(request)
        self.lock.unlock()

        do {
            return self.eventLoop.makeSucceededFuture(try self.handler(request))
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}

/// Builds a JSON response shaped the way `ClientResponse.content.decode` expects:
/// the content type header is what selects the decoder, so omitting it makes every
/// decode fail for the wrong reason.
func jsonClientResponse(_ json: String, status: HTTPStatus = .ok) -> ClientResponse {
    var headers = HTTPHeaders()
    headers.contentType = .json
    return ClientResponse(status: status, headers: headers, body: ByteBuffer(string: json))
}

let testLogger = Logger(label: "AppTests")
