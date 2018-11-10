# Rx-MVVM实战

### 1. Bind & Setup

把`viewDidLoad`中的**设置**和**绑定**这种固定操作提取到`extension`中

**VC-Template**
``` swift
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit

@objcMembers class <#name#>VC: UIViewController {
    
    private let viewModel: <#name#>ViewModel
    private let bag = DisposeBag()
    
    init(viewModel: <#name#>ViewModel) {
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

extension <#name#>VC {
    
    private func setup() {
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = UIRectEdge()
    }
    
    private func bind() {
        
    }
}

```

### 2. View的集中设置

通过**闭包**把`view`的**初始化**,**addSubview**和**布局代码**都捆绑到一处

``` swift
titleLabel = {
    let label = UILabel(frame: .zero)
    label.font = FS2
    label.textColor = FC1
    label.backgroundColor = .white
    label.numberOfLines = 1
    contentView.addSubview(label)
    label.snp.makeConstraints {
        $0.left.equalToSuperview().offset(24)
        $0.top.equalToSuperview().offset(38)
    }
    return label
}()
```

### 3. Class Extension

**原则**：私有方法必须另起一个`extension`，原`class/struct/enum`只放拿不出去的东西

### 4. Tuple的声明一定要命名参数

**Bad**
``` swift
let subject = PublishSubject<(IndexPath, UIViewController)>()
subject
    .subscribe(onNext: { 
        print($0.0, $0.1)
    })
    .disposed(by: bag)
```

**Good**
``` swift
let subject = PublishSubject<(indexPath: IndexPath, viewController: UIViewController)>()
subject
    .subscribe(onNext: { 
        print($0.indexPath, $0.viewController)
    })
    .disposed(by: bag)
```

### 5. 公有私有分离

变量/函数声明尽可能的使用`private`，并且和**公开**属性分开放

例如：
``` swift
var selectIndexPathDriver: Driver<(indexPath: IndexPath, rowModel: KDSettingRowModel)?> {
    return selectIndexPathSubject.asDriver()
}
var checkedModelsDriver: Driver<[(indexPath: IndexPath, rowModel: KDSettingRowModel)]> {
    return checkModelsSubject.asDriver()
}
var tableView: KDTableView!
    
private let bag = DisposeBag()
private var switchDriverBag = DisposeBag()
private let cellId = "KDSettingViewCell"
```


### 6. 输入输出分离

``` swift
// MARK: Input
var selectIndexObserver: AnyObserver<(indexPath: IndexPath, rowModel: KDDoNotDisturbPopupRowModel)> {
    return selectIndexSubject.asObserver()
}
    
var selectFooterObserver: AnyObserver<Void> {
    return selectFooterSubject.asObserver()
}
    
// MARK: Output
var sectionDriver: Driver<[KDDoNotDisturbPopupSectionModel]> {
    return sectionSubject.asDriver(onErrorJustReturn: [KDDoNotDisturbPopupSectionModel]())
}

var hidePopupDriver: Driver<Void> {
    return hidePopupSubject.asDriver(onErrorJustReturn: ())
}
    
var pushToSettingDriver: Driver<Void> {
    return pushToSettingSubject.asDriver(onErrorJustReturn: ())
}
```

### 7. 公开单向序列，私有双向序列

遵循迪米特原则，最小化接口暴露。

**Driver-Subject Template**
``` swift
var <#name#>Driver: Driver<<#type#>> {
    return <#name#>Subject.asDriver(onErrorJustReturn: <#return#>)
}
private var <#name#>Subject = PublishSubject<<#type#>>()
```

**Observer-Subject Template**
``` swift
var <#name#>Observer: AnyObserver<<#type#>> {
        return <#name#>Subject.asObserver()
    }
private var <#name#>Subject = PublishSubject<<#type#>>()
```

### 8. 用延迟初始化代替`lazy var`方式的初始化

`lazy var`初始化有个问题就是代码过多拥挤在class/struct/enum的**本体**里，无法拿到扩展中去，而用`!`声明变量，在`extension`里的`func setup()`去做统一的初始化，会保持**本体**的整洁。

``` swift
class KDDoNotDisturbPopupCell: UITableViewCell {
    var titleLabel: UILabel!
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
}
extension KDDoNotDisturbPopupCell {
    private func setup() {
        titleLabel = {
            let label = UILabel(frame: .zero)
            label.font = FS2
            label.textColor = FC1
            label.backgroundColor = .white
            label.numberOfLines = 1
            contentView.addSubview(label)
            label.snp.makeConstraints {
                $0.left.equalToSuperview().offset(24)
                $0.top.equalToSuperview().offset(38)
            }
            return label
        }()
    }
}
```

### 9. RxDataSources的使用

可以模板化

**RxDataSources Template 1**
``` swift

struct <#name#>RowModel {

}

struct <#name#>SectionModel {
    var items: [Item]
}

extension <#name#>SectionModel: SectionModelType {
    typealias Item = <#name#>RowModel
    init(original: <#name#>SectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}
```

**RxDataSources Template 2 (in VM)**

``` swift
var sectionDriver: Driver<[<#name#>SectionModel]> {
        return sectionSubject.asDriver(onErrorJustReturn: [<#name#>SectionModel]())
}
private var sectionSubject: BehaviorRelay<[<#name#>SectionModel]>!

// in bind()
sectionSubject = BehaviorRelay<[<#name#>SectionModel]>(value: )
```

**RxDataSources Template 3 (in VC)**

``` swift
viewModel.sectionDriver
    .drive(tableView.rx.items(dataSource: RxTableViewSectionedReloadDataSource<<#name#>SectionModel>(
    configureCell: { [weak self] (dataSource, tableView, indexPath, rowModel) -> UITableViewCell in
        guard let `self` = self else { return UITableViewCell() }
        if let cell = tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath) as? <#name#>Cell {
          
            return cell
        } else {
            return UITableViewCell()
        }
    }
    )))
    .disposed(by: bag)
```

### 10. RxSwift实现递归

``` swift
func fetchData() -> Observable<String> {
    func recursiveFetchData(observer: AnyObserver<String>) {
        recursiveFetchData(observer: observer)
    }
    return Observable<String>.create { observer in
        recursiveFetchData(observer: observer)
        return Disposables.create()
    }
}
```

### 11. 冷与热

热序列的特点：
- 自带热源，我们只是负责给这个热源搭建管道（Subject）
- 有带状态stateful管道，也有无状态管道stateless
- 中途订阅
- 用于处理用户交互事件

冷序列的特点：
- 所有要发生的事件是我们预先设定好的指令集（Observable）
- 完整订阅
- 是一个单子，chainable
- 用于封装业务逻辑

**所以RxSwift的所谓函数响应式编程就可以这么来看：**
- **对一些热源搭建热序列的管道，进行适当的流控和转换。`比如监听用户点击登录按钮，并做防抖处理`**
- **把业务逻辑封装成细粒度的冷序列，并组合起来完成特定流程。`比如封装登录请求，数据库操作`**
- **把冷热序列进行管道对接（`bind`/`drive`）`完成用户点击->触发登录流程的完整功能`** 

### 12. 慎用Traits

Traits是在ReactiveX的基础概念上的二次封装，用于解决平台特定的问题。
但是使用Traits的时候要留意他的完整特性。

`Completable`
- 是为了封装`Observable<Void>`
- 比`observer.onNext(())`要优雅
- 但是只能触发**一次**`.completed`事件（或是error）

`Single`
- 为了封装**一次性**事件传递
- 比如多数HTTP请求
- 但是要注意有些HTTP请求不是一次性的，比如递归的请求如果封装到一个`Observable`里，就是多次事件

`Driver`
- 不能发出错误事件 `.catchErrorJustReturn(onErrorJustReturn)`
- 接收事件的一方永远在主线程 `observeOn(MainScheduler.instance)`
- 共享副作用 `shareReplayLatestWhileConnected()`

### 13. 用RxSwift实现严格的串行队列

目标就是动态的追加`flatMap`

```swift
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {

    var ob: Observable<Date>?
    private let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Date())
        serialOperation()
        serialOperation()
        serialOperation()
    }
    
    func serialOperation() {
        if ob == nil {
            ob = rawOperation()
            
        } else {
            ob = ob?
                .flatMap { date -> Observable<Date> in
                    return self.rawOperation()
                }
        }
        ob?.subscribe(onNext: { date in
            print(date)
        })
        .disposed(by: bag)
    }

    func rawOperation() -> Observable<Date> {
        return Observable<Date>.create { observer in
            DispatchQueue.global().async {
                sleep(1)
                DispatchQueue.main.async {
                    observer.onNext(Date())
                }
            }
            return Disposables.create()
        }
    }
    
}
```

### 14. 重试

``` swift
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {

    var ob: Observable<Date>?
    private let bag = DisposeBag()
    enum RxCommonError: Error {
        case fail
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Date())
        failableOperation().retry(3)
            .subscribe(onNext: {
                print("succ")
            }, onError: { _ in
                print(Date(), "done trying")
            })
            .disposed(by: bag)
    }

    func failableOperation() -> Observable<Void> {
        return Observable<Void>.create { observer in
            DispatchQueue.global().async {
                sleep(1)
                DispatchQueue.main.async {
                    observer.onError(RxCommonError.fail)
                }
            }
            return Disposables.create()
        }
    }
}
```

### 15. 锁

``` swift
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {
    
    private var refreshSubject = PublishSubject<Void>()
    private var lockSubject = BehaviorRelay<Bool>(value: false)
    private let bag = DisposeBag()
    enum RxCommonError: Error { case fail }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Observable
            .combineLatest(refreshSubject, lockSubject.asObservable())
            .filter({ $1 == false })
            .subscribe(onNext: { _, _ in
                print("refresh")
            })
            .disposed(by: bag)
        
        lock()
        refresh()
        refresh()
        unlock()
    }
    
    private func refresh() {
        refreshSubject.onNext(())
    }
    
    private func unlock() {
        lockSubject.accept(false)
    }
    
    private func lock() {
        lockSubject.accept(true)
    }
    
}
```

### 16. 用RxSwift如何避免回调地狱
因为把部分PromiseKit去掉了，所以需要用rx的单子模型替换promise的。

**如何制造回调地狱：**

``` swift
func fetchData(_ f: (String) -> Void) -> Void {
    f("1")
}

fetchData { (result) in
    print(result)
}
```

那么可以总结出回调地狱的规则为：

`(T -> ()) -> ()`

**如何避免回调地狱：单子的模型（简）**

``` swift
struct Monad<T> {
    var value: T
    func flatMap<U>(_ f: (T) -> Monad<U>) -> Monad<U> {
        return f(value)
    }
}

let monad = Monad(value: 10)
let result = monad
    .flatMap ({
        return Monad(value: String($0)) // "10"
    })
    .flatMap({
        return Monad(value: Float($0)! + 5) // 10.0 + 5
    })

result.value // 15
```

所以单子模型的关键函数flatMap可以抽象成：

`(T -> F(U)) -> F(U)`

![](media/15317872075848.png)

**最后用RxSwift实现**

``` swift
func fetchData() -> Observable<String> {
    return Observable<String>.create { observer in
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                observer.onNext("1")
            }
        }
        return Disposables.create()
    }
}
    
func convertToInt(source: String) -> Observable<Int> {
    return Observable<Int>.create { observer in
        let result = Int(source) ?? 0
        observer.onNext(result)
        return Disposables.create()
    }
}
    
func convertToBool(source: Int) -> Observable<Bool> {
    return Observable<Bool>.create { observer in
        let result = source > 0 ? true : false
        observer.onNext(result)
        return Disposables.create()
    }
}
```

要实现单子就返回Observable即可。

产生回调地狱的调用方式（简化）：

``` swift
fetchData().subscribe(onNext: {
    self.convertToInt(source: $0).subscribe(onNext: {
        self.convertToBool(source: $0).subscribe(onNext: {
            print("final result: \($0)")
        })
    })
})
```

不产生回调地狱（单子）的方式（简化）：

``` swift
self.fetchData()
    .flatMap({
        return self.convertToInt(source: $0)
    })
    .flatMap({
        return self.convertToBool(source: $0)
    })
    .subscribe(onNext: {
        print("final result:\($0)")
    })
```

### 17. View层数据抽象的度

不是所有的VC的元素都需要提取到VM，因为VC的复用性几乎为0，所以只需要提取**业务需要变化**的元素：比如说根据接口请求会改变Label的标题。其它（目前）没有变化的元素在VC上初始化即可，这样能减轻编程负担。
**为了保持某种设计的纯粹性，而牺牲效率，而不产生其它收益，那么就是一种过度设计。**

### 18. View层的Observer/Input可以直接初始化，不需要配套Subject

VM要提供给V直接消费的数据类型，这样V不需要做任何数据转换就可以直接声明AnyObserver来终结事件序列。换句话说，如果V里写不成AnyObserver，而必须写Subject，那要看看VM是否有失职。

### 19. Model层的封装

优先方法返回Observable的方式，而不是Observer+Observable的方式，因为后者会让调用分散。

优选：
``` swift
func login(username: String?, password: String?) -> Observable<Bool?>
```

不要：
``` swift
var loginObserver: AnyObserver<(username: String?, password: String?)>!
var loginResultObservable: Observable<Bool?>
```


