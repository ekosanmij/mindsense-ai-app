import SwiftUI

struct FlexibleChipGrid: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    let items: [String]
    @Binding var selectedItems: Set<String>
    var onSelectionChange: ((String, Bool) -> Void)? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 104), spacing: 8)
    ]

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    let isSelected: Bool
                    if selectedItems.contains(item) {
                        if reduceMotion {
                            selectedItems.remove(item)
                        } else {
                            _ = withAnimation(MindSenseMotion.selectionSpring) {
                                selectedItems.remove(item)
                            }
                        }
                        isSelected = false
                    } else {
                        if reduceMotion {
                            selectedItems.insert(item)
                        } else {
                            _ = withAnimation(MindSenseMotion.selectionSpring) {
                                selectedItems.insert(item)
                            }
                        }
                        isSelected = true
                    }
                    onSelectionChange?(item, isSelected)
                } label: {
                    PillChip(label: item, selected: selectedItems.contains(item))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityHint(selectedItems.contains(item) ? "Double tap to remove." : "Double tap to add.")
            }
        }
    }
}
