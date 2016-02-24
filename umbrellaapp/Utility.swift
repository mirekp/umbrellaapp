//
//  Utility.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 23/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import Foundation

// utility functions for tracing (useful for debugging)

func DLog(message: String?, function: String = __FUNCTION__) {
#if DEBUG
    //  print("\(function): \(message)")
#endif
}

func DLog(function: String = __FUNCTION__) {
#if DEBUG
    //     print("\(function)")
#endif
}
