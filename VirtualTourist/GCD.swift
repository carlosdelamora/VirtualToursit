//
//  GCD.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/19/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
