// NactionsWidgets/Models/WidgetDataModel.swift
import Foundation
import WidgetKit
import NactionsShared

// MARK: - Provider Models
struct TaskEntry: TimelineEntry {
    let date: Date
    let configuration: TaskWidgetConfigurationIntent
    let tasks: [NactionsShared.TaskItem]
    let error: String?
}

struct ProgressEntry: TimelineEntry {
    let date: Date
    let configuration: ProgressWidgetConfigurationIntent
    let progress: NactionsShared.ProgressData
    let error: String?
}
