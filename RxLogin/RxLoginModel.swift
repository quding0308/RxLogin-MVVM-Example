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
    
    // MARK: Input
    var loginObserver: AnyObserver<(username: String?, password: String?)> {
        return loginSubject.asObserver()
    }
    
    // MARK: Output
    var loginResultObservable: Observable<Bool> {
        return loginResultSubject.asObservable()
    }
    
    private var loginResultSubject = PublishSubject<Bool>()
    private var loginSubject = PublishSubject<(username: String?, password: String?)>()
    private let bag = DisposeBag()
    
    init() {
        setup()
        bind()
    }
}

extension RxLoginModel {
    
    private func setup() {
        
    }
    
    private func bind() {
        loginSubject
            .flatMapLatest ({ [weak self] tuple -> Observable<Person>  in
                guard let `self` = self else { return Observable.error(RxLoginModelError.fail) }
                return self.login(username: tuple.username, password: tuple.password)
            })
            .subscribe(onNext: { [weak self] person  in
                guard let `self` = self else { return }
                self.person = person // 持久化
                self.loginResultSubject.onNext(true)
            })
            .disposed(by: bag)
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
    
    func login(username: String?, password: String?) -> Observable<Person> {
        return Observable<Person>.create { observer in
            DispatchQueue.global().async {
                sleep(1) // 模拟网络请求延迟
                DispatchQueue.main.async {
                    let person = Person(username: username, password: password) // 模拟成功回调
                    observer.onNext(person)
                }
            }
            return Disposables.create()
        }
    }
}


