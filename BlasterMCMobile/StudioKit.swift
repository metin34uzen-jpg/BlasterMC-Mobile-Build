import SwiftUI
import UIKit

// BlasterMC Studio 10.2 — purposeful hierarchy, restrained color and fluid widths.
enum Studio {
    static let background = Color(red:0.976,green:0.974,blue:0.961)
    static let paper = Color.white
    static let ink = Color(red:0.105,green:0.151,blue:0.224)
    static let secondary = Color(red:0.385,green:0.425,blue:0.485)
    static let line = Color(red:0.88,green:0.88,blue:0.87)
    static let gold = Color(red:0.73,green:0.43,blue:0.145)
    static let sunlight = Color(red:1,green:0.78,blue:0.38)
    static let pale = Color(red:0.993,green:0.958,blue:0.886)
    static let navy = Color(red:0.105,green:0.155,blue:0.255)

    static func touch() { UIImpactFeedbackGenerator(style:.soft).impactOccurred() }
    static func copy(_ value:String) {
        UIPasteboard.general.string=value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct StudioBackground: View {
    var body:some View {
        Studio.background.ignoresSafeArea()
    }
}

struct StudioSection:View {
    let kicker:String
    let title:String
    var accessory:String? = nil
    var body:some View {
        VStack(alignment:.leading,spacing:5) {
            Text(kicker.uppercased())
                .font(.system(size:10,weight:.bold,design:.rounded))
                .tracking(1.25)
                .foregroundStyle(Studio.gold)
            HStack(alignment:.firstTextBaseline,spacing:8) {
                Text(title)
                    .font(.system(size:22,weight:.bold,design:.rounded))
                    .tracking(-0.5)
                    .foregroundStyle(Studio.ink)
                    .fixedSize(horizontal:false,vertical:true)
                    .layoutPriority(1)
                Spacer(minLength:1)
                if let accessory {
                    Text(accessory)
                        .font(.system(size:11,weight:.semibold))
                        .foregroundStyle(Studio.secondary)
                }
            }
        }
    }
}

struct StudioPanel<Content:View>:View {
    var dark=false
    var padding:CGFloat=17
    @ViewBuilder let content:Content
    var body:some View {
        VStack(alignment:.leading,spacing:12) { content }
            .frame(maxWidth:.infinity,alignment:.leading)
            .padding(padding)
            .background(
                dark ? Studio.navy : Studio.paper,
                in: RoundedRectangle(cornerRadius:20,style:.continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius:20,style:.continuous)
                    .strokeBorder(dark ? Studio.sunlight.opacity(0.14) : Studio.line.opacity(0.8),
                                  lineWidth:1)
            )
            .shadow(color:Studio.ink.opacity(dark ? 0.13 : 0.035),radius:14,y:6)
    }
}

struct StudioCTA:View {
    let title:String
    let symbol:String
    var subtle=false
    let action:()->Void
    var body:some View {
        Button {
            Studio.touch()
            action()
        } label: {
            HStack(spacing:10) {
                Text(title)
                    .font(.system(size:13,weight:.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength:3)
                Image(systemName:symbol)
                    .font(.system(size:13,weight:.bold))
            }
            .foregroundStyle(Studio.ink)
            .padding(.horizontal,15)
            .frame(maxWidth:.infinity,minHeight:48)
            .background(
                subtle ? Studio.paper : Studio.sunlight,
                in:RoundedRectangle(cornerRadius:13,style:.continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius:13)
                    .strokeBorder(subtle ? Studio.line : Studio.gold.opacity(0.2),lineWidth:1)
            )
        }
        .buttonStyle(BlasterTapStyle())
    }
}

// Abstract metal inlay — not a fake Minecraft island or a stock visual.
struct StudioArtwork:View {
    var symbol:String="circle.hexagongrid.fill"
    var body:some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(Studio.sunlight.opacity(0.18),lineWidth:1)
                    .frame(width:200,height:200)
                    .offset(x:geo.size.width*0.16,y:0)
                Circle()
                    .stroke(Studio.sunlight.opacity(0.10),lineWidth:20)
                    .frame(width:136,height:136)
                    .offset(x:geo.size.width*0.18,y:3)
                Circle()
                    .fill(Studio.sunlight.opacity(0.08))
                    .frame(width:90,height:90)
                    .offset(x:geo.size.width*0.19,y:0)
                Image(systemName:symbol)
                    .font(.system(size:58,weight:.ultraLight))
                    .foregroundStyle(Studio.sunlight.opacity(0.5))
                    .offset(x:geo.size.width*0.18)
                VStack {
                    HStack {
                        Spacer()
                        Text("B / MC")
                            .font(.system(size:10,weight:.bold,design:.monospaced))
                            .tracking(2)
                            .foregroundStyle(Studio.sunlight.opacity(0.48))
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Studio.sunlight.opacity(0.37))
                            .frame(width:74,height:2)
                    }
                }
                .padding(22)
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct StudioHero<Content:View>:View {
    var symbol:String="circle.hexagongrid.fill"
    var height:CGFloat=190
    @ViewBuilder let content:Content
    var body:some View {
        ZStack(alignment:.leading) {
            RoundedRectangle(cornerRadius:22,style:.continuous)
                .fill(LinearGradient(colors:[Studio.navy,Color(red:0.16,green:0.22,blue:0.33)],
                                     startPoint:.topLeading,endPoint:.bottomTrailing))
            StudioArtwork(symbol:symbol)
            LinearGradient(colors:[Studio.navy.opacity(0.7),Studio.navy.opacity(0.18)],
                           startPoint:.leading,endPoint:.trailing)
            content.padding(20)
        }
        .frame(height:height)
        .clipShape(RoundedRectangle(cornerRadius:22,style:.continuous))
        .overlay(
            RoundedRectangle(cornerRadius:22).strokeBorder(Studio.sunlight.opacity(0.14))
        )
    }
}

struct StudioEmpty:View {
    let title:String
    let detail:String
    let symbol:String
    var body:some View {
        StudioPanel {
            VStack(alignment:.leading,spacing:10) {
                Image(systemName:symbol)
                    .font(.system(size:25))
                    .foregroundStyle(Studio.gold)
                Text(title)
                    .font(.system(size:16,weight:.bold))
                    .foregroundStyle(Studio.ink)
                    .fixedSize(horizontal:false,vertical:true)
                Text(detail)
                    .font(.system(size:12))
                    .foregroundStyle(Studio.secondary)
                    .fixedSize(horizontal:false,vertical:true)
            }
        }
    }
}
