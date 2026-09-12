import SwiftUI
import UIKit

struct PhotoViewer: View {
    let photo: Data
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var zoomed = false

    var body: some View {
        NavigationStack {
            ZoomablePhoto(photo: photo, zoomed: $zoomed)
                .background(ClosetStyle.background)
                .safeAreaInset(edge: .bottom) {
                    Text("Pinch or double tap to zoom")
                        .font(.footnote).foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                }
                .navigationTitle(name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(zoomed ? "Zoom out" : "Zoom in",
                               systemImage: zoomed ? "minus.magnifyingglass" : "plus.magnifyingglass") {
                            zoomed.toggle()
                        }
                        .accessibilityIdentifier("photoZoomToggle")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }.accessibilityIdentifier("closePhotoButton")
                    }
                }
        }
    }
}

private struct ZoomablePhoto: UIViewRepresentable {
    let photo: Data
    @Binding var zoomed: Bool

    func makeUIView(context: Context) -> PhotoScrollView {
        let view = PhotoScrollView()
        view.imageView.image = UIImage(data: photo)
        view.onZoomChanged = { zoomed = $0 }
        return view
    }

    func updateUIView(_ view: PhotoScrollView, context: Context) {
        // The button is also a zoom control for VoiceOver and one-handed use.
        if zoomed != (view.zoomScale > 1.05), !view.isZooming, !view.isZoomBouncing {
            view.setZoomScale(zoomed ? 2.5 : 1, animated: true)
        }
    }
}

final class PhotoScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()
    var onZoomChanged: ((Bool) -> Void)?
    private var laidOutSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumZoomScale = 1
        maximumZoomScale = 6
        bouncesZoom = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        delegate = self
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Clothing photo"
        imageView.accessibilityIdentifier = "zoomablePhoto"
        addSubview(imageView)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != laidOutSize, bounds.width > 0, bounds.height > 0 {
            laidOutSize = bounds.size
            setZoomScale(1, animated: false)
            if let image = imageView.image {
                let fit = min(bounds.width / image.size.width, bounds.height / image.size.height)
                imageView.frame = CGRect(origin: .zero,
                                         size: CGSize(width: image.size.width * fit, height: image.size.height * fit))
                contentSize = imageView.bounds.size
            }
        }
        centerPhoto()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerPhoto() }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        onZoomChanged?(scale > 1.05)
    }

    private func centerPhoto() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        imageView.accessibilityValue = "\(Int((zoomScale * 100).rounded())) percent"
    }

    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        guard zoomScale < 1.1 else { setZoomScale(1, animated: true); return }
        let point = gesture.location(in: imageView)
        let width = bounds.width / 2.5
        let height = bounds.height / 2.5
        zoom(to: CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height), animated: true)
    }
}
