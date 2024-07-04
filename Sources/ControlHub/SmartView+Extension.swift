//
//  SmartView+Extension.swift
//  
//
//  Created by Amir Daliri on 4.07.2024.
//

import SmartView

extension PhotoPlayer {
    func playContent(url: URL, title: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.playContent(url, title: title) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
