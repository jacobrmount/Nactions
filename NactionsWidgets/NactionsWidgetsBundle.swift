// NactionsWidgets/NactionsWidgetsBundle.swift
import WidgetKit
import SwiftUI
import NactionsKit

// MARK: - Task List Widget
struct TaskListWidget: Widget {
    let kind: String = "TaskListWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TaskWidgetConfigurationIntent.self,
            provider: TaskWidgetProvider()
        ) { entry in
            TaskWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Task List")
        .description("Display your Notion tasks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Progress Widget
struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ProgressWidgetConfigurationIntent.self,
            provider: ProgressWidgetProvider()
        ) { entry in
            ProgressWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Progress Tracker")
        .description("Track progress from your Notion database")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle
@main
struct NactionsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskListWidget()
        ProgressWidget()
    }
}
