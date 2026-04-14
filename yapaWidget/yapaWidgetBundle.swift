//
//  yapaWidgetBundle.swift
//  yapaWidget
//
//  Created by David Umoru on 14/04/2026.
//

import WidgetKit
import SwiftUI

@main
struct yapaWidgetBundle: WidgetBundle {
    var body: some Widget {
        yapaWidget()
        yapaWidgetControl()
        yapaWidgetLiveActivity()
    }
}
