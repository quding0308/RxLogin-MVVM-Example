//
//  RxLoginVC.swift
//  DZDemo
//
//  Created by Darren Zheng on 2018/7/18.
//  Copyright © 2018 Darren Zheng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

enum RxLoginVCError: Error { case fail }

@objcMembers class RxLoginVC: UIViewController {
    
    // MARK: Input
    var showAlertObserver: AnyObserver<String?>!
    var setLoginButtonHiddenObserver: AnyObserver<Bool>!
    
    private var nameField: UITextField!
    private var passwordField: UITextField!
    private var loginButton: UIButton!
    
    private let viewModel: RxLoginVM
    private let bag = DisposeBag()
    
    init(viewModel: RxLoginVM = RxLoginVM()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    deinit {
        
        
    }
    
}

extension RxLoginVC {
    
    private func setup() {
        
        nameField = {
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            view.addSubview(textField)
            textField.snp.makeConstraints {
                $0.top.equalToSuperview().offset(200)
                $0.width.equalTo(200)
                $0.height.equalTo(40)
                $0.centerX.equalToSuperview()
            }
            return textField
        }()
        
        passwordField = {
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            textField.isSecureTextEntry = true
            view.addSubview(textField)
            textField.snp.makeConstraints {
                $0.top.equalTo(nameField.snp.bottom).offset(20)
                $0.width.equalTo(200)
                $0.height.equalTo(40)
                $0.centerX.equalToSuperview()
            }
            return textField
        }()
        
        loginButton = {
            let button = UIButton()
            button.setTitleColor(UIColor.gray, for: .normal)
            view.addSubview(button)
            button.snp.makeConstraints {
                $0.top.equalTo(passwordField.snp.bottom).offset(20)
                $0.width.equalTo(200)
                $0.height.equalTo(40)
                $0.centerX.equalToSuperview()
            }
            return button
        }()
        
    }
    
    private func bind() {
        
        //////////////////////////////////////////////////
        // View
        //////////////////////////////////////////////////
        
        showAlertObserver = AnyObserver(eventHandler: { [weak self] (event) in
            guard let `self` = self, let element = event.element else { return }
            self.showAlert(element)
        })
        
        setLoginButtonHiddenObserver = AnyObserver(eventHandler: { [weak self] (event) in
            guard let `self` = self, let element = event.element else { return }
            self.loginButton.isHidden = element
        })
        
        //////////////////////////////////////////////////
        // ViewModel <- View
        //////////////////////////////////////////////////
        
        loginButton.rx.tap
            .flatMapLatest({ [weak self] _ -> Observable<(username: String?, password: String?)> in
                guard let `self` = self else { return Observable.error(RxLoginVCError.fail) }
                return Observable.just((username: self.nameField.text, password: self.passwordField.text))
            })
            .bind(to: viewModel.loginButtonTapObserver)
            .disposed(by: bag)
        
        //////////////////////////////////////////////////
        // ViewModel -> View
        //////////////////////////////////////////////////
        
        viewModel.navigationBarTitleDriver
            .drive(rx.title)
            .disposed(by: bag)

        viewModel.loginButtonTitleDriver
            .drive(loginButton.rx.title(for: .normal))
            .disposed(by: bag)
        
        viewModel.nameFielddPlaceholderDriver
            .drive(onNext: { [weak self] text in
                guard let `self` = self else { return }
                self.nameField.placeholder = text
            })
            .disposed(by: bag)
        
        viewModel.passwordFieldPlaceholderDriver
            .drive(onNext: { [weak self] text in
                guard let `self` = self else { return }
                self.passwordField.placeholder = text
            })
            .disposed(by: bag)
        
        viewModel.showAlertDriver
            .drive(showAlertObserver)
            .disposed(by: bag)
        
        viewModel.setLoginButtonHiddenDriver
            .drive(setLoginButtonHiddenObserver)
            .disposed(by: bag)
       
    }
}

extension RxLoginVC {
    
    private func showAlert(_ text: String?) {
        guard let text = text else { return }
        present({
            let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            }))
            return alert
        }(),animated: true, completion: nil)
    }
    
    func test() {
        let observable = Observable.from(["1"])
        let driver = observable.asDriver(onErrorJustReturn: "0")
        
        let observer = AnyObserver<String> { [weak self] (event) in
            print(event.element)
        }
        
        let binder = Binder<String>(self) { (vc, name) in
            print("")
        }
        
        let textField = UITextField()
        let btn = UIButton()
        
        
        
//        btn.rx.tap.subscribe(onNext: {
//            print("tapped")
//        }).disposed(by: disposebag)
//
        
//        let observable1 = Observable.from(Void)
//        observable1.bind(to: btn.rx.tap)
        
    }

}

