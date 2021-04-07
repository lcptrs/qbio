import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct qbio_lib: ArtistDataSource {
    private var baseUrl = URLComponents(
        string: "https://www.theaudiodb.com/api/v1/json/1/search.php")!

    func getBio(artist: String) -> String {
        guard let queryUrl = try? createQueryUrl(artist: artist) else {
            return "No bio found"
        }

        return executeQuery(query: queryUrl)
    }

    private func createQueryUrl(artist: String) throws -> URL {
        // create and use a copy to not modify the base url of this struct
        var baseUrlCopy = baseUrl
        let baseUrlItem = URLQueryItem(name: "s", value: artist)
        baseUrlCopy.queryItems = [baseUrlItem]

        if let url = baseUrlCopy.url {
            return url
        } else {
            throw QueryError.invalidQueryString
        }
    }

    private func executeQuery(query: URL) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""

        let task = URLSession.shared.dataTask(with: query) { (data, response, error) in
            if let data = data {
                let res = try! JSONDecoder().decode(ArtistQueryResponse.self, from: data)

                result = res.artists.first!.strBiographyEN
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        return result
    }
}

enum QueryError: Error {
    case invalidQueryString
}

struct Artist : Codable {
    let strBiographyEN: String
}

struct ArtistQueryResponse : Codable {
    let artists: [Artist]
}

