//
//  RxLoginVM.swift
//  DZDemo
//
//  Created by Darren Zheng on 2018/7/18.
//  Copyright © 2018 Darren Zheng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum RxLoginVMError: Error { case fail }

@objcMembers class RxLoginVM: NSObject {
    
    // MARK: Output
    var navigationBarTitleDriver: Driver<String>!
    var loginButtonTitleDriver: Driver<String>!
    var nameFielddPlaceholderDriver: Driver<String>!
    var passwordFieldPlaceholderDriver: Driver<String>!
    var showAlertDriver: Driver<String?> {
        return showAlertSubject.asDriver(onErrorJustReturn: nil)
    }
    var setLoginButtonHiddenDriver: Driver<Bool> {
        return setLoginButtonHiddeSubject.asDriver(onErrorJustReturn: false)
    }
    
    // MARK: Input
    var loginButtonTapObserver: AnyObserver<(username: String?, password: String?)> {
        return loginButtonTapSubject.asObserver()
    }
    
    private var setLoginButtonHiddeSubject = PublishSubject<Bool>()
    private var loginButtonTapSubject = PublishSubject<(username: String?, password: String?)>()
    private let bag = DisposeBag()
    private let model: RxLoginModel
    private var showAlertSubject = PublishSubject<String?>()
    
    init(model: RxLoginModel = RxLoginModel()) {
        self.model = model
        
        super.init()
        setup()
        bind()
        
    }
    
}

extension RxLoginVM {
    
    private func setup() {
        
    }
    
    private func bind() {
        
        //////////////////////////////////////////////////
        // ViewModel -> View
        //////////////////////////////////////////////////
        
        navigationBarTitleDriver = Driver<String>
            .just("Login Page")
        
        loginButtonTitleDriver = Driver<String>
            .just("Login")
        
        nameFielddPlaceholderDriver = Driver<String>
            .just("Username")
        
        passwordFieldPlaceholderDriver = Driver<String>
            .just("Password")
        
        //////////////////////////////////////////////////
        // Model <-> ViewModel <-> View
        //////////////////////////////////////////////////
        
        loginButtonTapSubject.asObserver()
            .throttle(1, scheduler: MainScheduler.instance) 
            .flatMapLatest({ [weak self] tuple -> Observable<Bool?> in
                guard let `self` = self else { return Observable.just(nil) }
                guard let username = tuple.username, !username.isEmpty else {
                    self.showAlertSubject.onNext("empty username")
                    return Observable.just(nil)
                }
                guard let password = tuple.password, !password.isEmpty else {
                    self.showAlertSubject.onNext("empty password")
                    return Observable.just(nil)
                }
                self.setLoginButtonHiddeSubject.onNext(true)
                return self.model.login(username: tuple.username, password: tuple.password)
            })
            .do(onNext: { [weak self] succ in
                guard let `self` = self, let succ = succ else { return }
                self.setLoginButtonHiddeSubject.onNext(!succ)
            })
            .map { ($0 ?? false) ? "Login Succeed" : "Login Failed" }
            .bind(to: showAlertSubject)
            .disposed(by: bag)
     
    }
}
