//
//  AppiaService.swift
//  NanoBlocks
//
//  Created by Alessandro Viganò on 23/01/2019.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation
import Moya

enum AppiaService {
//    case process(block: BlockAdapter)
//    case generateWork(hash: String)
}


extension AppiaService: TargetType {
    var baseURL: URL {
        return URL(string: "http://192.168.20.160:8000")!
    }

    var path: String {
        return "rpc"
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
//        case .generateWork(let hash):
//            return params(for: "work_generate", params: ["hash": hash])
//        case .process(let block):
//            guard let jsonData = try? JSONSerialization.data(withJSONObject: block.json, options: []),
//                let blockString = String(data: jsonData, encoding: .ascii) else { return .requestPlain }
//            return params(for: "process", params: ["block": blockString])
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    fileprivate func params(for action: String, params: [String: Any] = [:]) -> Task {
        var p: [String: Any] = ["action": action]
        p.merge(params) { (current, _) in current }
        return .requestParameters(parameters: p, encoding: JSONEncoding.default)
    }
}
