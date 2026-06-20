// Copyright Bryan Carroll. All rights reserved.
import Foundation
import SwiftUI

struct LinkifiedText: View {
    let text: String
    var font: Font = .body
    var foregroundStyle: Color = .primary

    var body: some View {
        Text(linkifiedText)
            .font(font)
            .foregroundStyle(foregroundStyle)
            .tint(Color("AccentColor"))
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
    }

    private var linkifiedText: AttributedString {
        var attributed = AttributedString(text)
        guard
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else {
            return attributed
        }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in detector.matches(in: text, options: [], range: fullRange) {
            guard
                let url = match.url,
                let textRange = Range(match.range, in: text),
                let lowerBound = AttributedString.Index(textRange.lowerBound, within: attributed),
                let upperBound = AttributedString.Index(textRange.upperBound, within: attributed)
            else {
                continue
            }

            attributed[lowerBound..<upperBound].link = url
        }

        return attributed
    }
}
