//
//  yapaWidgetLiveActivity.swift
//  yapaWidget
//
//  Created by David Umoru on 14/04/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct yapaWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct yapaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: yapaWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension yapaWidgetAttributes {
    fileprivate static var preview: yapaWidgetAttributes {
        yapaWidgetAttributes(name: "World")
    }
}

extension yapaWidgetAttributes.ContentState {
    fileprivate static var smiley: yapaWidgetAttributes.ContentState {
        yapaWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: yapaWidgetAttributes.ContentState {
         yapaWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: yapaWidgetAttributes.preview) {
   yapaWidgetLiveActivity()
} contentStates: {
    yapaWidgetAttributes.ContentState.smiley
    yapaWidgetAttributes.ContentState.starEyes
}
