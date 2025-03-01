// NactionsWidgets/Models/SharedWidgetModels.swift
import WidgetKit
import Foundation
import NactionsKit

// MARK: - Shared Widget Entry Models
struct TaskEntry: TimelineEntry {
    let date: Date
    let configuration: TaskWidgetConfigurationIntent
    let tasks: [NactionsKit.TaskItem]
    let error: String?
}

struct ProgressEntry: TimelineEntry {
    let date: Date
    let configuration: ProgressWidgetConfigurationIntent
    let progress: NactionsKit.ProgressData
    let error: String?
}
