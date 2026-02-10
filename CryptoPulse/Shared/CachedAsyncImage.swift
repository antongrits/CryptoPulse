import SwiftUI
import Combine

final class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading: Bool = false

    private var task: URLSessionDataTask?
    private var currentURL: URL?

    func load(from url: URL) {
        if currentURL != url {
            image = nil
        }
        currentURL = url
        task?.cancel()
        if let diskImage = ImageDiskCache.shared.image(for: url) {
            image = diskImage
            return
        }
        if let cached = URLCache.shared.cachedResponse(for: URLRequest(url: url)) {
            image = UIImage(data: cached.data)
            if let data = image?.pngData() {
                ImageDiskCache.shared.store(data, for: url)
            }
            return
        }

        isLoading = true
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        task = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data, let response else { return }
                if let image = UIImage(data: data) {
                    let cached = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cached, for: request)
                    ImageDiskCache.shared.store(data, for: url)
                    self?.image = image
                }
            }
        }
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func clear() {
        cancel()
        currentURL = nil
        image = nil
        isLoading = false
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @StateObject private var loader = CachedImageLoader()

    init(url: URL?,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            if let url { loader.load(from: url) }
        }
        .onChange(of: url) { newValue in
            guard let newValue else {
                loader.clear()
                return
            }
            loader.load(from: newValue)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
