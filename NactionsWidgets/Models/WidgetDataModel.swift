// NactionsWidgets/Models/WidgetDataModel.swift
import Foundation
import WidgetKit
import NactionsKit

// MARK: - Provider Models
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
