//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

enum FileType: String, Codable {
    case jpg
    case png
    case pdf
    case xlsx
    case pptx
    case docx
    case mp4
    case ai
    
    var extensions: String {
        switch self {
            case .jpg: return "jpg"
            case .png: return "png"
            case .pdf: return "pdf"
            case .xlsx: return "xlsx"
            case .pptx: return "pptx"
            case .docx: return "docx"
            case .mp4: return "mp4"
            case .ai: return "ai"
        }
    }
}
