//
//  AnimatedGIFView.swift
//  Memory Match Kids
//

import SwiftUI
import UIKit
import ImageIO

struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        if let animated = UIImage.animatedGIF(named: resourceName) {
            imageView.image = animated
            imageView.startAnimating()
        }
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard !uiView.isAnimating, uiView.image != nil else { return }
        uiView.startAnimating()
    }
}

extension UIImage {
    static func animatedGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return animatedGIF(data: data)
    }

    static func animatedGIF(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            images.append(UIImage(cgImage: cgImage))

            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
                ?? gifProperties?[kCGImagePropertyGIFDelayTime] as? TimeInterval
                ?? 0.08
            totalDuration += delay < 0.02 ? 0.08 : delay
        }

        guard !images.isEmpty else { return nil }
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }
}
