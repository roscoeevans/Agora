import Foundation

/// Formats timestamps for social media posts with custom short format
public struct RelativeTimeFormatter {
    public init() {}
    
    /// Formats a date relative to now in a short format
    /// - "now" for < 5 seconds
    /// - "Xs" for 5-59 seconds
    /// - "Xm" for 1-59 minutes
    /// - "Xh" for 1-23 hours
    /// - "Xd" for 1-6 days
    /// - "Xw" for 1-3 weeks
    /// - "MMM d" for longer periods
    public static func format(_ date: Date, relativeTo now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(date)
        
        // Handle future dates
        guard interval >= 0 else {
            return "now"
        }
        
        // Less than 5 seconds
        if interval < 5 {
            return "now"
        }
        
        // 5-59 seconds
        if interval < 60 {
            let seconds = Int(interval)
            return "\(seconds)s"
        }
        
        // 1-59 minutes
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        }
        
        // 1-23 hours
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        }
        
        // 1-6 days
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
        
        // 1-3 weeks
        if interval < 1814400 {
            let weeks = Int(interval / 604800)
            return "\(weeks)w"
        }
        
        // Longer than 3 weeks - show date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

