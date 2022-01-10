import ComposableArchitecture
import Foundation

// MARK: - WolframAlphaResult

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult

    struct QueryResult: Decodable {
        let pods: [Pod]

        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]

            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

func wolframAlpha(query: String) -> Effect<WolframAlphaResult?> {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

    return dataTask(with: components.url(relativeTo: nil)!)
        .map(\.data)
        .decode(as: WolframAlphaResult.self)
}

func dataTask(with request: URL) -> Effect<(data: Data?, response: URLResponse?, error: Error?)> {
    return Effect { callback in
        URLSession.shared.dataTask(with: request) { data, response, error in
            callback((data, response, error))
        }
        .resume()
    }
}

func nthPrime(_ n: Int) -> Effect<Int?> {
    wolframAlpha(query: "prime \(n)")
        .map { result in
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == .some(true) })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        }
}

extension Effect {
    func decode<B: Decodable>(as _: B.Type) -> Effect<B?> where Action == (Data?, URLResponse?, Error?) {
        return map { data, _, _ in
            data
                .flatMap { try? JSONDecoder().decode(B.self, from: $0) }
        }
    }

    func decode<B: Decodable>(as _: B.Type) -> Effect<B?> where Action == Data? {
        return map { data in
            data
                .flatMap { try? JSONDecoder().decode(B.self, from: $0) }
        }
    }
}
