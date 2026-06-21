import SwiftUI

struct FCFadeInUp: ViewModifier {
    var delay: Double = 0

    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 25)
            .animation(.easeOut(duration: visible ? 0.4 : 0.01).delay(delay), value: visible)
            .onAppear { visible = true }
    }
}

extension View {
    func fcFadeInUp(delay: Double = 0) -> some View {
        modifier(FCFadeInUp(delay: delay))
    }
}

struct FCStageSpinner: View {
    @State private var spin = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(FCTheme.accent, lineWidth: 2)
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: spin)
            .onAppear { spin = true }
    }
}

struct FCPulseIcon: View {
    let systemName: String
    var color: Color = FCTheme.accent

    @State private var pulse = false

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(color)
            .scaleEffect(pulse ? 1.08 : 0.92)
            .opacity(pulse ? 1 : 0.65)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
