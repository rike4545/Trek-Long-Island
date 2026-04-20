// Copyright Bryan Carroll. All rights reserved.
//
//  CaptainsChairSilhouette.swift
//  Trek Long Island
//
//  A simple, generic “captain’s chair” silhouette (non-specific geometry)
//  Swift 6 • iOS 17+
//

import SwiftUI

struct CaptainsChairSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var p = Path()

        // Seat base
        let seat = RoundedRectangle(cornerRadius: w * 0.06, style: .continuous)
        p.addPath(seat.path(in: CGRect(
            x: rect.minX + 0.18*w,
            y: rect.minY + 0.62*h,
            width: 0.64*w,
            height: 0.16*h
        )))

        // Backrest
        var back = Path()
        back.move(to: pt(0.26, 0.62))
        back.addCurve(to: pt(0.30, 0.24),
                      control1: pt(0.24, 0.50),
                      control2: pt(0.24, 0.30))
        back.addCurve(to: pt(0.70, 0.24),
                      control1: pt(0.40, 0.16),
                      control2: pt(0.60, 0.16))
        back.addCurve(to: pt(0.74, 0.62),
                      control1: pt(0.76, 0.30),
                      control2: pt(0.76, 0.50))
        back.closeSubpath()
        p.addPath(back)

        // Armrests
        let armL = RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
        p.addPath(armL.path(in: CGRect(
            x: rect.minX + 0.12*w,
            y: rect.minY + 0.58*h,
            width: 0.18*w,
            height: 0.12*h
        )))

        let armR = RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
        p.addPath(armR.path(in: CGRect(
            x: rect.minX + 0.70*w,
            y: rect.minY + 0.58*h,
            width: 0.18*w,
            height: 0.12*h
        )))

        // Pedestal stem
        let stem = RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
        p.addPath(stem.path(in: CGRect(
            x: rect.minX + 0.44*w,
            y: rect.minY + 0.76*h,
            width: 0.12*w,
            height: 0.12*h
        )))

        // Pedestal foot
        let foot = RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
        p.addPath(foot.path(in: CGRect(
            x: rect.minX + 0.30*w,
            y: rect.minY + 0.86*h,
            width: 0.40*w,
            height: 0.10*h
        )))

        return p
    }
}
