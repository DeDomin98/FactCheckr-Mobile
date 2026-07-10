import WidgetKit
import SwiftUI
import ActivityKit

@main
struct FactCheckrWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AnalysisLiveActivityWidget()
    }
}

struct AnalysisLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnalysisActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color(red: 0.635, green: 0.608, blue: 0.996))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.displayTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(context.state.stageLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(context.state.isFailed
                              ? Color(red: 1, green: 0.42, blue: 0.42)
                              : Color(red: 0.42, green: 0.36, blue: 0.90))
                }
            } compactLeading: {
                Image(systemName: context.state.isFailed
                      ? "exclamationmark.triangle.fill"
                      : (context.state.isComplete ? "checkmark.circle.fill" : "checkmark.shield.fill"))
                    .foregroundStyle(context.state.isFailed
                                     ? Color(red: 1, green: 0.42, blue: 0.42)
                                     : Color(red: 0.635, green: 0.608, blue: 0.996))
            } compactTrailing: {
                if context.state.isComplete {
                    Text(context.state.isFailed ? "!" : "✓")
                        .font(.caption2.weight(.bold))
                } else {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color(red: 0.635, green: 0.608, blue: 0.996))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<AnalysisActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color(red: 0.635, green: 0.608, blue: 0.996))
                Text("Fact Checkr")
                    .font(.caption.weight(.semibold))
                Spacer()
                if context.state.isComplete {
                    Text(context.state.isFailed ? "Błąd" : "Gotowe")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(context.state.isFailed
                                         ? Color(red: 1, green: 0.42, blue: 0.42)
                                         : Color(red: 0, green: 0.82, blue: 0.63))
                }
            }

            Text(context.attributes.displayTitle)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(context.state.stageLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            ProgressView(value: context.state.progress)
                .tint(context.state.isFailed
                      ? Color(red: 1, green: 0.42, blue: 0.42)
                      : Color(red: 0.42, green: 0.36, blue: 0.90))
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(.white)
    }
}
