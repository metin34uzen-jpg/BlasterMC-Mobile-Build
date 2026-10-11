import SwiftUI
import UIKit

// BLASTERMC / REFORGED — original native illustration and design system.
enum Forge {
    static let base = Color(red: 0.969, green: 0.960, blue: 0.936)
    static let white = Color(red: 1, green: 0.994, blue: 0.978)
    static let midnight = Color(red: 0.084, green: 0.153, blue: 0.243)
    static let midnight2 = Color(red: 0.14, green: 0.225, blue: 0.331)
    static let gold = Color(red: 0.81, green: 0.47, blue: 0.13)
    static let sun = Color(red: 1.0, green: 0.78, blue: 0.37)
    static let bronze = Color(red: 0.55, green: 0.29, blue: 0.15)
    static let muted = Color(red: 0.46, green: 0.49, blue: 0.53)
    static let stroke = Color(red: 0.83, green: 0.80, blue: 0.73)

    static func impact() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ForgeCut: InsettableShape {
    var cut: CGFloat = 16
    var insetAmount: CGFloat = 0
    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var p = Path()
        let c = min(cut, min(r.width, r.height) / 4)
        p.move(to: CGPoint(x: r.minX+c, y:r.minY))
        p.addLine(to: CGPoint(x:r.maxX-c, y:r.minY))
        p.addLine(to: CGPoint(x:r.maxX, y:r.minY+c))
        p.addLine(to: CGPoint(x:r.maxX, y:r.maxY-c))
        p.addLine(to: CGPoint(x:r.maxX-c, y:r.maxY))
        p.addLine(to: CGPoint(x:r.minX+c, y:r.maxY))
        p.addLine(to: CGPoint(x:r.minX, y:r.maxY-c))
        p.addLine(to: CGPoint(x:r.minX, y:r.minY+c))
        p.closeSubpath()
        return p
    }
}

struct ForgeBackground: View {
    var body: some View {
        ZStack {
            Forge.base
            Canvas { ctx, size in
                var grid = Path()
                let pitch: CGFloat = 32
                stride(from: CGFloat(0), through: size.width, by: pitch).forEach {
                    grid.move(to: CGPoint(x: $0, y: 0))
                    grid.addLine(to: CGPoint(x: $0, y: size.height))
                }
                stride(from: CGFloat(0), through: size.height, by: pitch).forEach {
                    grid.move(to: CGPoint(x: 0, y: $0))
                    grid.addLine(to: CGPoint(x: size.width, y: $0))
                }
                ctx.stroke(grid, with: .color(Forge.gold.opacity(0.035)), lineWidth: 0.65)
            }
            LinearGradient(colors: [.white.opacity(0.28), .clear, Forge.sun.opacity(0.035)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .ignoresSafeArea()
    }
}

struct ForgeSurface<Content: View>: View {
    var dark = false
    var inset: CGFloat = 17
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(inset)
            .background {
                ForgeCut(cut: 16)
                    .fill(dark ?
                          LinearGradient(colors: [Forge.midnight, Forge.midnight2],
                                         startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Forge.white, Color(red: 0.983, green: 0.976, blue: 0.954)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                ForgeCut(cut: 16)
                    .strokeBorder(dark ? Forge.sun.opacity(0.35) : Forge.stroke.opacity(0.60), lineWidth: 1)
            }
            .shadow(color: Forge.midnight.opacity(dark ? 0.15 : 0.06), radius: 12, y: 7)
    }
}

struct ForgeLabel: View {
    let text: String
    var onDark = false
    var body: some View {
        HStack(spacing: 7) {
            Rectangle().fill(Forge.sun).frame(width: 15, height: 3)
            Text(text.uppercased())
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(onDark ? Forge.sun : Forge.bronze)
                .lineLimit(2)
        }
    }
}

struct ForgeHeading: View {
    let eyebrow: String
    let title: String
    var subtitle = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForgeLabel(text: eyebrow)
            Text(title)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .tracking(-0.9)
                .foregroundStyle(Forge.midnight)
                .fixedSize(horizontal: false, vertical: true)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Forge.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ForgeButton: View {
    let title: String
    let symbol: String
    var quiet = false
    let action: () -> Void
    var body: some View {
        Button {
            Forge.impact()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(0.3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundStyle(quiet ? Forge.midnight : Forge.midnight)
            .padding(.horizontal, 15)
            .frame(height: 47)
            .background {
                ForgeCut(cut: 10).fill(quiet ? Forge.white : Forge.sun)
            }
            .overlay {
                ForgeCut(cut: 10)
                    .strokeBorder(quiet ? Forge.stroke : Forge.gold.opacity(0.48), lineWidth: 1)
            }
        }
        .buttonStyle(BlasterTapStyle())
    }
}

struct ForgeMonoStat: View {
    let value: String
    let label: String
    var light = false
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(light ? .white : Forge.midnight)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(light ? .white.opacity(0.65) : Forge.muted)
                .lineLimit(2)
        }
    }
}

struct ForgePixelChip: View {
    let title: String
    let symbol: String
    var selected = false
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(title).lineLimit(1)
        }
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .foregroundStyle(selected ? Forge.sun : Forge.midnight)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ForgeCut(cut: 8).fill(selected ? Forge.midnight : Forge.white))
        .overlay(ForgeCut(cut: 8).strokeBorder(selected ? Forge.gold.opacity(0.65) : Forge.stroke.opacity(0.6), lineWidth: 1))
    }
}

struct ForgeEmblem: View {
    var width: CGFloat = 50
    var body: some View {
        BlasterLogo(size: width)
            .padding(3)
            .background(ForgeCut(cut: 9).fill(Forge.midnight))
            .overlay(ForgeCut(cut: 9).strokeBorder(Forge.sun.opacity(0.64), lineWidth: 1))
    }
}

/// Original, deterministic isometric floating island.
struct ForgeVoxelIsland: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let cx = w * 0.60
            let top = h * 0.20
            let rx = w * 0.34
            let ry = h * 0.21
            let depth = h * 0.32

            func poly(_ pts: [CGPoint]) -> Path {
                var p = Path()
                guard let first = pts.first else { return p }
                p.move(to: first)
                for next in pts.dropFirst() { p.addLine(to: next) }
                p.closeSubpath()
                return p
            }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
            func paint(_ p: Path, _ c: Color, stroke: Color? = nil) {
                ctx.fill(p, with: .color(c))
                if let stroke { ctx.stroke(p, with: .color(stroke), lineWidth: 1) }
            }
            // Orbit flecks and floating particles; no network or animation timers.
            for n in 0..<31 {
                let fx = CGFloat((n * 61 + 7) % 97) / 100 * w
                let fy = CGFloat((n * 37 + 23) % 93) / 100 * h
                let d: CGFloat = n.isMultiple(of: 5) ? 3 : 1.3
                ctx.fill(Path(CGRect(x:fx,y:fy,width:d,height:d)),
                         with:.color(Forge.sun.opacity(n.isMultiple(of: 5) ? 0.75 : 0.22)))
            }

            let west = pt(cx-rx,top+ry), north = pt(cx,top), east = pt(cx+rx,top+ry), south = pt(cx,top+2*ry)
            let tip = pt(cx+rx*0.07, top+ry*2+depth)
            paint(poly([west,south,tip,pt(cx-rx*0.60,top+ry*2+depth*0.42)]),
                  Color(red:0.40,green:0.31,blue:0.28))
            paint(poly([south,east,pt(cx+rx*0.65,top+ry*2+depth*0.45),tip]),
                  Color(red:0.25,green:0.28,blue:0.33))
            paint(poly([west,north,east,south]),
                  Color(red:0.86,green:0.68,blue:0.42), stroke:Forge.sun.opacity(0.75))
            // Pixel-like top grid.
            let n = 7
            for a in 0..<n {
                for b in 0..<n {
                    let x0 = CGFloat(a)/CGFloat(n), x1 = CGFloat(a+1)/CGFloat(n)
                    let y0 = CGFloat(b)/CGFloat(n), y1 = CGFloat(b+1)/CGFloat(n)
                    func tile(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                        pt(cx + rx*(x-y), top + ry*(x+y))
                    }
                    let cell = poly([tile(x0,y0),tile(x1,y0),tile(x1,y1),tile(x0,y1)])
                    let tint = (a * 5 + b * 11) % 4
                    paint(cell,
                          tint == 0 ? Color(red:0.96,green:0.78,blue:0.48) :
                          tint == 1 ? Color(red:0.91,green:0.71,blue:0.40) :
                          tint == 2 ? Color(red:0.84,green:0.61,blue:0.31) :
                          Color(red:0.95,green:0.73,blue:0.39),
                          stroke: Forge.midnight.opacity(0.09))
                }
            }
            // Exposed layered ore veins in rock sides.
            for row in 0..<4 {
                let yy = top+ry*2+CGFloat(row)*depth/5
                let leftX = cx-rx*0.44+CGFloat(row)*rx*0.09
                let rightX = cx+rx*0.52-CGFloat(row)*rx*0.11
                let tone = row.isMultiple(of:2) ? Forge.sun.opacity(0.26) : Forge.midnight.opacity(0.25)
                paint(poly([pt(leftX,yy),pt(leftX+rx*0.18,yy+ry*0.12),
                            pt(leftX+rx*0.18,yy+ry*0.12+4),pt(leftX,yy+4)]),tone)
                paint(poly([pt(rightX,yy+ry*0.09),pt(rightX-rx*0.18,yy+ry*0.22),
                            pt(rightX-rx*0.18,yy+ry*0.22+4),pt(rightX,yy+ry*0.09+4)]),tone)
            }
            // A miniature castle gate built from angular voxel architecture.
            let bw = rx * 0.20, bh = h * 0.070
            let baseY = top + ry * 0.80
            let baseX = cx - bw * 0.7
            func block(_ x: CGFloat,_ y: CGFloat,_ width: CGFloat,_ height: CGFloat,
                       _ face: Color) {
                let d: CGFloat = 7
                paint(poly([pt(x,y),pt(x+d,y-d),pt(x+width+d,y-d),pt(x+width,y)]),
                      Forge.sun.opacity(0.90))
                paint(poly([pt(x+width,y),pt(x+width+d,y-d),pt(x+width+d,y+height-d),pt(x+width,y+height)]),
                      Forge.bronze)
                paint(poly([pt(x,y),pt(x+width,y),pt(x+width,y+height),pt(x,y+height)]),
                      face,stroke:Forge.midnight.opacity(0.40))
            }
            block(baseX,baseY,bw*2.0,bh*1.9,Forge.midnight2)
            block(baseX-bw*0.31,baseY-bh*0.72,bw*0.75,bh*2.3,Forge.midnight)
            block(baseX+bw*1.60,baseY-bh*0.72,bw*0.75,bh*2.3,Forge.midnight)
            block(baseX+bw*0.55,baseY-bh*0.44,bw*1.1,bh*0.60,Color(red:0.70,green:0.42,blue:0.17))
            for n in 0..<4 {
                block(baseX-bw*0.30+CGFloat(n)*bw*0.61,baseY-bh*0.97,
                      bw*0.27,bh*0.30,Forge.midnight2)
            }
            let gate=CGRect(x:baseX+bw*0.80,y:baseY+bh*0.82,width:bw*0.45,height:bh*1.08)
            paint(Path(gate),Color(red:0.14,green:0.13,blue:0.20))
            // Beacon and golden portal spark.
            let beacon=CGRect(x:baseX+bw*0.98,y:baseY-bh*1.43,width:4,height:bh*0.48)
            ctx.fill(Path(beacon),with:.color(Forge.sun))
            let light=CGRect(x:baseX+bw*0.90,y:baseY-bh*1.72,width:12,height:12)
            ctx.fill(Path(ellipseIn:light),with:.color(.white.opacity(0.8)))
        }
        .accessibilityLabel("Altın renkli havada süzülen Minecraft adası, kale ve geçit illüstrasyonu")
    }
}

struct ForgeStoreGlyph: View {
    let category: String
    var body: some View {
        let lower = category.lowercased()
        let symbol = lower.contains("vip") || lower.contains("rütbe") ?
            "crown.fill" : lower.contains("kasa") || lower.contains("anahtar") ?
            "key.horizontal.fill" : lower.contains("kredi") ?
            "circle.hexagongrid.fill" : "shippingbox.fill"
        ZStack {
            ForgeCut(cut: 13).fill(
                LinearGradient(colors:[Forge.midnight,Forge.midnight2],
                               startPoint:.topLeading,endPoint:.bottomTrailing))
            Canvas { c,s in
                for i in 0..<6 {
                    let x = CGFloat(i*31 % 91)/100*s.width
                    let y = CGFloat(i*29 % 85)/100*s.height
                    c.fill(Path(CGRect(x:x,y:y,width:3,height:3)),
                           with:.color(Forge.sun.opacity(0.65)))
                }
            }
            Image(systemName:symbol)
                .font(.system(size: 37, weight: .black))
                .foregroundStyle(Forge.sun)
                .shadow(color:Forge.sun.opacity(0.4),radius:9)
        }
        .overlay(ForgeCut(cut:13).strokeBorder(Forge.sun.opacity(0.46),lineWidth:1))
    }
}
