import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(shimmerOverlay)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 2)
            .offset(x: -geo.size.width + (geo.size.width * 3 * phase))
        }
        .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

//struct ShimmerCardView: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(.systemGray5))
//                .aspectRatio(9/16, contentMode: .fit)
//                .shimmer()
//
//            RoundedRectangle(cornerRadius: 4)
//                .fill(Color(.systemGray5))
//                .frame(height: 10)
//                .shimmer()
//
//            RoundedRectangle(cornerRadius: 4)
//                .fill(Color(.systemGray5))
//                .frame(width: 50, height: 8)
//                .shimmer()
//        }
//    }
//}

struct ShimmerGridView: View {
    let colWidth: CGFloat
    let columns: Int
    let spacing: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<6, id: \.self) { row in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .shimmer()
                            .frame(width: colWidth, height: shimmerHeight(col: col, row: row))
                    }
                }
                .frame(width: colWidth)
            }
        }
        .padding(.horizontal, spacing)
    }

    /// Skeleton during intitial load. Random values to make it look good.
    private func shimmerHeight(col: Int, row: Int) -> CGFloat {
        let heights: [[CGFloat]] = [
            [90, 130, 80, 110, 95, 120],
            [110, 85, 125, 90, 130, 80],
            [95, 120, 100, 115, 85, 110]
        ]
        return heights[col % heights.count][row % heights[0].count]
    }
}
