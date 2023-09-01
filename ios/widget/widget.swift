//
//  widget.swift
//  widget
//
//  Created by Chris Stayte on 9/1/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    title: "Test Event",
                    backgroundColor: Color(hex: 0x7877E6, opacity: 1),
                    isGradient: false,
                    configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(),
                                title: "Your Event",
                                backgroundColor: Color(hex: 0x7877E6, opacity: 1),
                                isGradient: false,
                                configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for secondOffset in 0 ..< 120 {
            let entryDate = Calendar.current.date(byAdding: .second, value: secondOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate,
                                    title: "Test Event",
                                    backgroundColor: Color(hex: 0x7877E6, opacity: 1),
                                    isGradient: false,
                                    configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let backgroundColor: Color
    let isGradient: Bool
    let configuration: ConfigurationIntent
}

struct widgetEntryView : View {
    var entry: Provider.Entry
    

    var body: some View {
        VStack {
            Text(entry.date, style: .time).foregroundColor(entry.backgroundColor.contentColor)
        }.background(entry.backgroundColor).edgesIgnoringSafeArea(.all )
    }
}

struct widget: Widget {
    let kind: String = "eve"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Countdowns")
        .description("View your events live")
    }
}

// this is used for xcode to preview an example so I don't need to run the app in a simulator
struct widget_Previews: PreviewProvider {
    static var previews: some View {
        widgetEntryView(entry: SimpleEntry(date: Date(),
                                           title: "Test Event",
                                           backgroundColor: Color(hex: 0x7877E6, opacity: 1),
                                           isGradient: false,
                                           configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
