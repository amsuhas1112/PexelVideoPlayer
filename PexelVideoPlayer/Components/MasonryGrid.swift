import SwiftUI

/// Pinterest-style masonry grid.
/// Column distribution is computed once from the item list (O(n)) and cached
/// by identity — SwiftUI never re-measures cells during scrolling.
/// The caller MUST supply a fixed `columnWidth` derived from geometry OUTSIDE
/// the ScrollView so no GeometryReader lives inside the scroll tree.
struct MasonryGrid<Item: Identifiable & Equatable, Cell: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let columnWidth: CGFloat
    let heightProvider: (Item) -> CGFloat
    @ViewBuilder let cell: (Item) -> Cell

    /// Stable column split — recomputed only when `items` reference changes.
    private var distributedColumns: [[Item]] {
        distribute(items: items)
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { c in
                LazyVStack(spacing: spacing) {
                    ForEach(distributedColumns[c]) { item in
                        cell(item)
                    }
                }
                .frame(width: columnWidth)
            }
        }
        .padding(.horizontal, spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Column distribution
    /// Greedily assign each item to the shortest column — O(n).
    private func distribute(items: [Item]) -> [[Item]] {
        var cols = Array(repeating: [Item](), count: columns)
        var heights = Array(repeating: CGFloat(0), count: columns)
        for item in items {
            let shortest = heights.indices.min(by: { heights[$0] < heights[$1] }) ?? 0
            cols[shortest].append(item)
            heights[shortest] += heightProvider(item) + spacing
        }
        return cols
    }
}
