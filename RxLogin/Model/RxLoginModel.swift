//
//  RxLoginModel.swift
//  DZDemo
//
//  Created by Darren Zheng on 2018/7/18.
//  Copyright © 2018 Darren Zheng. All rights reserved.
//

import RxSwift
import RxCocoa

enum RxLoginModelError: Error { case fail }

class RxLoginModel {
    
    private var loginSubject = PublishSubject<(username: String?, password: String?)>()
    private let bag = DisposeBag()
    
    init() {
        setup()
        bind()
    }
    
    func login(username: String?, password: String?) -> Observable<Bool?> {
        return self.loginRequest(username: username, password: password)
            .flatMapLatest({ person -> Observable<Bool?> in
                self.person = person // Persistence
                return Observable.just(true)
            })
    }
}

// MARK: Setup & Bind
extension RxLoginModel {
    
    private func setup() {
        
    }
    
    private func bind() {
        
    }
}

// MARK: Persistence
extension RxLoginModel {
    static let kRxLoginModelPersonKey = "kRxLoginModelPersonKey"
    private var person: Person? {
        get {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: RxLoginModel.kRxLoginModelPersonKey) {
                return try? decoder.decode(Person.self, from: data)
            }
            return nil
        }
        set {
            guard let newItems = newValue else { return }
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newItems) {
                UserDefaults.standard.set(encoded, forKey: RxLoginModel.kRxLoginModelPersonKey)
            }
        }
    }
}


// MARK: Networking
extension RxLoginModel {
    
    private func loginRequest(username: String?, password: String?) -> Observable<Person> {
        return Observable<Person>.create { observer in
            DispatchQueue.global().async {
                sleep(1) // Simulating delay
                DispatchQueue.main.async {
                    let person = Person(username: username, password: password) // Simulating callback
                    observer.onNext(person)
                }
            }
            return Disposables.create()
        }
    }
}


