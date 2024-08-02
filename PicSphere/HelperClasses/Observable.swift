//
//  Observable.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 22/07/24.
//

import Foundation

class Observable<T> {
    
    var value: T? {
        didSet {
            DispatchQueue.main.async {
                self.listener?(self.value)
            }
        }
    }
    
    init(_ value: T?) {
        self.value = value
    }
    
    private var listener: ((T?) -> Void)?
    
    func bind(_ listener: @escaping (T?) -> Void) {
        // Unwrap the optional value before passing it to the listener
        if let value = value {
            listener(value)
        }
        self.listener = listener
    }
}
