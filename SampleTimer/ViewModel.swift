//
//  ViewModel.swift
//  SampleTimer
//
//  Created by mtanaka on 2022/07/28.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModelInputs: AnyObject {
    var isPauseTimer: PublishRelay<Bool> { get }
    var isResetButtonTaped: PublishRelay<Void> { get }
}

protocol ViewModelOutputs: AnyObject {
    var isTimerWorked: Driver<Bool> { get }
    var timerText: Driver<String> { get }
    var isResetButtonHidden: Driver<Bool> { get }
}

protocol ViewModelType: AnyObject {
    var inputs: ViewModelInputs { get }
    var outputs: ViewModelOutputs { get }
}

final class ViewModel: ViewModelType, ViewModelInputs, ViewModelOutputs {
    
    var inputs: ViewModelInputs { return self }
    var outputs: ViewModelOutputs { return self }
    
    let isPauseTimer = PublishRelay<Bool>()
    let isResetButtonTaped = PublishRelay<Void>()
    
    var isTimerWorked: Driver<Bool>
    var timerText: Driver<String>
    var isResetButtonHidden: Driver<Bool>
    
    private let disposeBag = DisposeBag()
    private let totalTimeDuration = BehaviorRelay<Int>(value: 0)
    
    init() {
        isTimerWorked = isPauseTimer.asDriver(onErrorDriveWith: .empty())
        
        timerText = totalTimeDuration
            .map { String("\(Double($0) / 10)") }
            .asDriver(onErrorDriveWith: .empty())
        
        isResetButtonHidden = Observable.merge(isTimerWorked.asObservable(), isResetButtonTaped.map { _ in true }.asObservable()).skip(1).asDriver(onErrorDriveWith: .empty())
        
        isTimerWorked.asObservable()
            .flatMapLatest { [weak self] isWorked -> Observable<Int> in
                if isWorked {
                    return Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
                        .withLatestFrom(Observable<Int>.just(self?.totalTimeDuration.value ?? 0)) { ($0 + $1) }
                } else {
                    return Observable<Int>.just(self?.totalTimeDuration.value ?? 0)
                }
            }
            .bind(to: totalTimeDuration)
            .disposed(by: disposeBag)
        
        isResetButtonTaped.map { _ in 0 }
            .bind(to: totalTimeDuration)
            .disposed(by: disposeBag)
    }
}
