import SwiftUI

/// Hangers use the same coordinates as the rail so every hook meets the line.
struct HangerView: View {
    var category: ClothingCategory = .tops

    var body: some View {
        Canvas { context, size in
            let scale = size.width / 160
            context.scaleBy(x: scale, y: scale)

            var hook = Path()
            hook.move(to: CGPoint(x: 73, y: 8))
            hook.addCurve(to: CGPoint(x: 85, y: 3), control1: CGPoint(x: 75, y: -1), control2: CGPoint(x: 85, y: -2))
            hook.addCurve(to: CGPoint(x: 82, y: 16), control1: CGPoint(x: 92, y: 10), control2: CGPoint(x: 83, y: 14))
            hook.addQuadCurve(to: CGPoint(x: 80, y: 21), control: CGPoint(x: 80, y: 18))
            hook.addLine(to: CGPoint(x: 80, y: 31))
            context.stroke(hook, with: .linearGradient(
                Gradient(colors: [Color(white: 0.48), Color(white: 0.76), Color(white: 0.44)]),
                startPoint: CGPoint(x: 73, y: 0), endPoint: CGPoint(x: 88, y: 27)
            ), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))

            let wood = Gradient(colors: [
                Color(red: 0.92, green: 0.77, blue: 0.56),
                Color(red: 0.79, green: 0.59, blue: 0.36),
                Color(red: 0.86, green: 0.67, blue: 0.43)
            ])

            if category == .tops {
                var shoulders = Path()
                shoulders.move(to: CGPoint(x: 14, y: 68))
                shoulders.addQuadCurve(to: CGPoint(x: 71, y: 34), control: CGPoint(x: 48, y: 52))
                shoulders.addQuadCurve(to: CGPoint(x: 89, y: 34), control: CGPoint(x: 80, y: 26))
                shoulders.addQuadCurve(to: CGPoint(x: 146, y: 68), control: CGPoint(x: 111, y: 52))
                shoulders.addQuadCurve(to: CGPoint(x: 143, y: 77), control: CGPoint(x: 151, y: 75))
                shoulders.addLine(to: CGPoint(x: 17, y: 77))
                shoulders.addQuadCurve(to: CGPoint(x: 14, y: 68), control: CGPoint(x: 9, y: 76))
                shoulders.closeSubpath()
                // The open center leaves a real hanger silhouette instead of a filled triangle.
                shoulders.move(to: CGPoint(x: 29, y: 70))
                shoulders.addLine(to: CGPoint(x: 131, y: 70))
                shoulders.addQuadCurve(to: CGPoint(x: 85, y: 45), control: CGPoint(x: 105, y: 58))
                shoulders.addQuadCurve(to: CGPoint(x: 75, y: 45), control: CGPoint(x: 80, y: 43))
                shoulders.addQuadCurve(to: CGPoint(x: 29, y: 70), control: CGPoint(x: 55, y: 58))
                shoulders.closeSubpath()

                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: .black.opacity(0.10), radius: 1.5, x: 0, y: 2))
                    layer.fill(shoulders, with: .linearGradient(wood,
                        startPoint: CGPoint(x: 0, y: 32), endPoint: CGPoint(x: 0, y: 80)),
                        style: FillStyle(eoFill: true))
                }
                var grain = Path()
                grain.move(to: CGPoint(x: 19, y: 70))
                grain.addQuadCurve(to: CGPoint(x: 76, y: 37), control: CGPoint(x: 51, y: 53))
                context.stroke(grain, with: .color(.white.opacity(0.20)), style: StrokeStyle(lineWidth: 0.75, lineCap: .round))
            } else {
                let bar = Path(roundedRect: CGRect(x: 17, y: 31, width: 126, height: 8), cornerRadius: 2)
                context.addFilter(.shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1))
                context.fill(bar, with: .linearGradient(wood,
                    startPoint: CGPoint(x: 0, y: 30), endPoint: CGPoint(x: 0, y: 41)))
                for x in [22.0, 130.0] {
                    let clip = Path(roundedRect: CGRect(x: x, y: 30, width: 8, height: 18), cornerRadius: 1.5)
                    context.fill(clip, with: .linearGradient(
                        Gradient(colors: [Color(white: 0.55), Color(white: 0.86), Color(white: 0.62)]),
                        startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + 8, y: 0)))
                }
            }
        }
        .frame(height: 90)
        .accessibilityHidden(true)
    }
}

struct ClothesRail: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color(white: 0.82), Color(white: 0.64), Color(white: 0.85)], startPoint: .top, endPoint: .bottom))
            .frame(height: 2)
            .shadow(color: .black.opacity(0.035), radius: 1, y: 1)
            .accessibilityHidden(true)
    }
}
