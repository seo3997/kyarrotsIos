//
//  BlockingLoader.swift
//  kycarrots
//
//  Created by soo on 1/14/26.
//


import UIKit

final class BlockingLoader {
    private var overlay: UIView?

    func show(on view: UIView) {
        guard overlay == nil else { return }

        let v = UIView(frame: view.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.backgroundColor = UIColor.black.withAlphaComponent(0.25)

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()

        v.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])

        view.addSubview(v)
        overlay = v
    }

    func hide() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}
