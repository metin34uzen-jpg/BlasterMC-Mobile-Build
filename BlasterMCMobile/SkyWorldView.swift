import SwiftUI

/// A low-overhead animated Minecraft-inspired sky island scene rendered natively.
/// Timeline is capped at 20 FPS and pauses when Reduce Motion is enabled.
struct SkyWorldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            Canvas(opaque: false) { context, size in
                let t = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
                render(in: context, size: size, time: t)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func render(in context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let w = size.width
        let h = size.height

        // Sky glows and orbiting particles remain behind legible hero copy.
        let sun = CGPoint(x: w * 0.82, y: h * 0.27)
        context.fill(Path(ellipseIn: CGRect(x: sun.x-64, y: sun.y-64, width: 128, height: 128)),
                     with: .radialGradient(Gradient(colors: [
                        BlasterTheme.amber.opacity(0.26), .clear
                     ]), center: sun, startRadius: 0, endRadius: 67))

        island(in: context, center: CGPoint(x: w * 0.78, y: h * 0.62 + sin(time*0.7)*6),
               scale: 1.08, opacity: 0.88)
        island(in: context, center: CGPoint(x: w * 0.99, y: h * 0.36 + sin(time*0.55+2)*4),
               scale: 0.49, opacity: 0.42)
        island(in: context, center: CGPoint(x: w * 0.60, y: h * 0.28 + sin(time*0.46+3)*3),
               scale: 0.33, opacity: 0.30)

        for i in 0..<30 {
            let seed = Double(i)
            let x = w * CGFloat((seed*0.61803398875).truncatingRemainder(dividingBy: 1.0))
            let base = (seed*0.376821).truncatingRemainder(dividingBy: 1.0)
            let y = h * CGFloat(base) + CGFloat(sin(time * (0.32 + Double(i%4)*0.13) + seed) * 8)
            let alpha = (i%5==0 ? 0.56 : 0.21)
            let side = CGFloat(i%7==0 ? 4 : 2)
            context.fill(Path(roundedRect: CGRect(x: x, y: y, width: side, height: side),
                              cornerRadius: 0.5),
                         with: .color(BlasterTheme.amber.opacity(alpha)))
        }

        let halo = CGPoint(x: w*0.80, y: h*0.66)
        context.stroke(Path(ellipseIn: CGRect(x: halo.x-92, y: halo.y-28, width: 184, height: 56)),
                       with: .color(BlasterTheme.amber.opacity(0.13)),
                       style: StrokeStyle(lineWidth: 2, dash: [4,8]))
    }

    private func island(in context: GraphicsContext, center: CGPoint,
                        scale: CGFloat, opacity: Double) {
        let x=center.x, y=center.y
        func point(_ a: CGFloat,_ b: CGFloat) -> CGPoint {
            CGPoint(x: x+a*scale, y:y+b*scale)
        }
        var upper=Path()
        upper.move(to:point(0,-51))
        upper.addLine(to:point(78,-13))
        upper.addLine(to:point(0,24))
        upper.addLine(to:point(-78,-13))
        upper.closeSubpath()
        context.fill(upper, with:.color(BlasterTheme.cream.opacity(opacity)))

        var left=Path()
        left.move(to:point(-78,-13))
        left.addLine(to:point(0,24))
        left.addLine(to:point(0,88))
        left.addLine(to:point(-53,22))
        left.closeSubpath()
        context.fill(left, with:.color(Color(red:0.45,green:0.30,blue:0.19).opacity(opacity)))

        var right=Path()
        right.move(to:point(0,24))
        right.addLine(to:point(78,-13))
        right.addLine(to:point(45,35))
        right.addLine(to:point(0,88))
        right.closeSubpath()
        context.fill(right, with:.color(BlasterTheme.gold.opacity(opacity*0.85)))

        // Top grass / pathways as angular gold highlights.
        var crest=Path()
        crest.move(to:point(-56,-15))
        crest.addLine(to:point(0,-42))
        crest.addLine(to:point(58,-12))
        crest.addLine(to:point(0,15))
        crest.closeSubpath()
        context.fill(crest, with:.color(BlasterTheme.amber.opacity(opacity*0.66)))

        // Crystalline light rising out of the floating island.
        var crystal=Path()
        crystal.move(to:point(0,-78))
        crystal.addLine(to:point(18,-41))
        crystal.addLine(to:point(0,-14))
        crystal.addLine(to:point(-18,-41))
        crystal.closeSubpath()
        context.fill(crystal, with:.color(BlasterTheme.amber.opacity(opacity)))
        var seam=Path()
        seam.move(to:point(0,-78))
        seam.addLine(to:point(0,-14))
        context.stroke(seam, with:.color(.white.opacity(opacity*0.7)), lineWidth: 1.2)
    }
}
