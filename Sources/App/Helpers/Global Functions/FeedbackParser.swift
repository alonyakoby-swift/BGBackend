import Foundation

struct FeedbackParser {
    let response: String
    
    func parseFeedback() -> String {
        // Extract feedback from the response
        if let range = response.range(of: "Suggested correction:") {
            return String(response[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if response.contains("The translation is accurate.") {
            // Check for additional comments
            let comments = parseComments()
            return "The translation is accurate." + (comments.isEmpty ? "" : " Comments: \(comments)")
        }
        return "No clear feedback provided."
    }
    
    func parseRating() -> Int? {
        // Extract rating (e.g., "Rating: X")
        let ratingRegex = try? NSRegularExpression(pattern: "Rating:\\s*(\\d+)", options: .caseInsensitive)
        let matches = ratingRegex?.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
        if let match = matches?.first, let range = Range(match.range(at: 1), in: response) {
            return Int(response[range])
        }
        return nil
    }
    
    func parseComments() -> String {
        // Extract comments, if any
        let commentsRegex = try? NSRegularExpression(pattern: "Comments:\\s*(.*)", options: .caseInsensitive)
        let matches = commentsRegex?.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
        if let match = matches?.first, let range = Range(match.range(at: 1), in: response) {
            return String(response[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
