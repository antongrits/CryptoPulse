import SwiftUI

struct TabBarSwipeDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        Controller()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class Controller: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            disableSwipeIfNeeded()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            disableSwipeIfNeeded()
        }

        private func disableSwipeIfNeeded() {
            guard let tabBarController = findTabBarController() else { return }
            for scroll in allScrollViews(in: tabBarController.view) where scroll.isPagingEnabled {
                scroll.isScrollEnabled = false
                scroll.panGestureRecognizer.isEnabled = false
            }
        }

        private func findTabBarController() -> UITabBarController? {
            var parent = self.parent
            while parent != nil {
                if let tab = parent as? UITabBarController { return tab }
                parent = parent?.parent
            }
            return nil
        }

        private func allScrollViews(in view: UIView) -> [UIScrollView] {
            var result: [UIScrollView] = []
            if let scroll = view as? UIScrollView {
                result.append(scroll)
            }
            for subview in view.subviews {
                result.append(contentsOf: allScrollViews(in: subview))
            }
            return result
        }
    }
}
