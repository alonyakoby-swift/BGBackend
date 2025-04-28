//
//  File.swift
//  
//
//  Created by Alon Yakoby on 27.06.24.
//

import Foundation
// Full  LIST
//enum Language: String, CaseIterable, Codable {
//    case bg = "BG"
//    case cs = "CS"
//    case da = "DA"
//    case de = "DE"
//    case el = "EL"
//    case enGB = "EN-GB"
//    case enUS = "EN-US"
//    case es = "ES"
//    case et = "ET"
//    case fi = "FI"
//    case fr = "FR"
//    case hu = "HU"
//    case id = "ID"
//    case it = "IT"
//    case ja = "JA"
//    case ko = "KO"
//    case lt = "LT"
//    case lv = "LV"
//    case nb = "NB"
//    case nl = "NL"
//    case pl = "PL"
//    case ptBR = "PT-BR"
//    case ptPT = "PT-PT"
//    case ro = "RO"
//    case ru = "RU"
//    case sk = "SK"
//    case sl = "SL"
//    case sv = "SV"
//    case tr = "TR"
//    case uk = "UK"
//    case zh = "ZH"
//    
//    var code: String {
//        return self.rawValue
//    }
//    
//    var name: String {
//        switch self {
//        case .bg: return "Bulgarian"
//        case .cs: return "Czech"
//        case .da: return "Danish"
//        case .de: return "German"
//        case .el: return "Greek"
//        case .enGB: return "English (British)"
//        case .enUS: return "English (American)"
//        case .es: return "Spanish"
//        case .et: return "Estonian"
//        case .fi: return "Finnish"
//        case .fr: return "French"
//        case .hu: return "Hungarian"
//        case .id: return "Indonesian"
//        case .it: return "Italian"
//        case .ja: return "Japanese"
//        case .ko: return "Korean"
//        case .lt: return "Lithuanian"
//        case .lv: return "Latvian"
//        case .nb: return "Norwegian"
//        case .nl: return "Dutch"
//        case .pl: return "Polish"
//        case .ptBR: return "Portuguese (Brazilian)"
//        case .ptPT: return "Portuguese (European)"
//        case .ro: return "Romanian"
//        case .ru: return "Russian"
//        case .sk: return "Slovak"
//        case .sl: return "Slovenian"
//        case .sv: return "Swedish"
//        case .tr: return "Turkish"
//        case .uk: return "Ukrainian"
//        case .zh: return "Chinese (simplified)"
//        }
//    }
//    
//    var supportsFormality: Bool {
//        switch self {
//        case .de, .es, .fr, .it, .ja, .nl, .pl, .ptBR, .ptPT, .ru:
//            return true
//        default:
//            return false
//        }
//    }
//}

enum Language: String, CaseIterable, Codable {
    case bg = "BG"
    case cs = "CS"
    case da = "DA"
    case de = "DE"
    case el = "EL"
    case enUS = "EN-US"
    case es = "ES"
    case et = "ET"
    case fi = "FI"
    case fr = "FR"
    case hu = "HU"
    case id = "ID"
    case it = "IT"
    case ja = "JA"
    case ko = "KO"
    case lt = "LT"
    case lv = "LV"
    case nb = "NB"
    case nl = "NL"
    case pl = "PL"
    case ptBR = "PT-BR"
    case ro = "RO"
    case ru = "RU"
    case sk = "SK"
    case sl = "SL"
    case sv = "SV"
    case tr = "TR"
    case uk = "UK"
    case zh = "ZH"
    
    var code: String {
        return self.rawValue
    }
    
    var name: String {
        switch self {
        case .bg: return "Bulgarian"
        case .cs: return "Czech"
        case .da: return "Danish"
        case .de: return "German"
        case .el: return "Greek"
        case .enUS: return "English (American)"
        case .es: return "Spanish"
        case .et: return "Estonian"
        case .fi: return "Finnish"
        case .fr: return "French"
        case .hu: return "Hungarian"
        case .id: return "Indonesian"
        case .it: return "Italian"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .lt: return "Lithuanian"
        case .lv: return "Latvian"
        case .nb: return "Norwegian"
        case .nl: return "Dutch"
        case .pl: return "Polish"
        case .ptBR: return "Portuguese (Brazilian)"
        case .ro: return "Romanian"
        case .ru: return "Russian"
        case .sk: return "Slovak"
        case .sl: return "Slovenian"
        case .sv: return "Swedish"
        case .tr: return "Turkish"
        case .uk: return "Ukrainian"
        case .zh: return "Chinese (simplified)"
        }
    }
    
    var supportsFormality: Bool {
        switch self {
        case .de, .es, .fr, .it, .ja, .nl, .pl, .ptBR, .ru:
            return true
        default:
            return false
        }
    }
}

extension Language {
    var deeplCode: String {
        switch self {
        case .enUS: return "EN"
        default: return self.rawValue
        }
    }

    var isEnglish: Bool {
        return self == .enUS
    }
}
