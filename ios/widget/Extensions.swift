//
//  Extensions.swift
//  widgetExtension
//
//  Created by Chris Stayte on 9/1/23.
//

import Foundation
import SwiftUI

extension Color {
    var contentColor: Color {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        let brightness = r * 299 + g * 587 + b * 114 / 1000;
        return brightness >= 0.5 ? Color.black : Color.white
    }
}

extension UIColor {
    var complimentary: UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newHue = (hue + 0.5).truncatingRemainder(dividingBy: 1)
        return UIColor(hue: newHue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

func getGradientLayer(frame: CGRect, color: UIColor) -> CAGradientLayer {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = frame
    gradientLayer.colors = [color.cgColor, color.complimentary.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    return gradientLayer
}

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
