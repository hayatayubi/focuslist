import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.04, green: 0.05, blue: 0.06),
                Color(red: 0.08, green: 0.10, blue: 0.13),
                Color(red: 0.09, green: 0.08, blue: 0.07)
            ]
        }

        return [
            Color(red: 0.94, green: 0.97, blue: 0.93),
            Color(red: 0.91, green: 0.95, blue: 1.0),
            Color(red: 1.0, green: 0.95, blue: 0.88)
        ]
    }

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(colorScheme == .dark ? 0.06 : 0.45))
                .frame(width: 240, height: 240)
                .blur(radius: 8)
                .offset(x: 92, y: -82)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(.orange.opacity(colorScheme == .dark ? 0.08 : 0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 18)
                .offset(x: -120, y: 120)
        }
    }
}

struct CategoryChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let symbol: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    private var unselectedBackground: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.72)
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(isSelected ? .white : tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? tint : unselectedBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(isSelected ? 0 : colorScheme == .dark ? 0.45 : 0.25), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
