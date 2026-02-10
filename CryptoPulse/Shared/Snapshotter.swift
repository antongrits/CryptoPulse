import UIKit

enum Snapshotter {
    static func captureScreen() -> UIImage? {
        let window = keyWindow()
        guard let window else {
            return nil
        }

        let bounds = window.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            let rendered = window.drawHierarchy(in: bounds, afterScreenUpdates: false)
            if !rendered {
                window.layer.render(in: context.cgContext)
            }
        }
    }

    private static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        if let key = windows.first(where: { $0.isKeyWindow }) {
            return key
        }
        if let rootWindow = windows.first {
            return rootWindow
        }
        return nil
    }
}
