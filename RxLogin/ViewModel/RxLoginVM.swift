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
        
        loginButtonTapSubject.asObserver()                                                  // 用户点击登录按钮 VM <- View
            .throttle(1, scheduler: MainScheduler.instance)                                 // 节流，一秒最多处理一次 VM <- View
            .flatMapLatest({ [weak self] tuple -> Observable<Bool?> in
                guard let `self` = self else { return Observable.just(nil) }
                guard let username = tuple.username, !username.isEmpty else {
                    self.showAlertSubject.onNext("empty username")                          // 提示：用户没输入用户名 VM -> View
                    return Observable.just(nil)
                }
                guard let password = tuple.password, !password.isEmpty else {
                    self.showAlertSubject.onNext("empty password")                          // 提示：用户没输入密码 VM -> View
                    return Observable.just(nil)
                }
                self.setLoginButtonHiddeSubject.onNext(true)                                // 正常登录前隐藏登录按钮 VM -> View
                return self.model.login(username: tuple.username, password: tuple.password) // 正常登录调用 Model <-> VM
            })
            .do(onNext: { [weak self] _ in
                self?.setLoginButtonHiddeSubject.onNext(false)                              // 无论结果如何显示登录按钮 VM -> View
            })
            .filter({
                $0 != nil                                                                   // 把异常情况过滤，因为已经提示过
            })
            .map { ($0 ?? false) ? "Login Succeed" : "Login Failed" }                       // 把登录结果的bool值转换为适当文本
            .bind(to: showAlertSubject)                                                     // 把文本绑定到UI的提示控件上展示 VM -> View
            .disposed(by: bag)
     
    }
}
