//
//  AppServiceProvider.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

enum AppServiceProvider {
    static let shared: AppService = {
        let repository = RemoteRepository(api: .shared)
        return AppService(repo: repository)
    }()
}
