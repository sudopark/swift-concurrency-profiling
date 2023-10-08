//
//  ViewController.swift
//  SwiftConcurrencyProfiling
//
//  Created by sudo.park on 2023/10/08.
//

import UIKit


enum Constant {
    static let size = 1_000_000_000
}

final class HeavyWorker: Sendable {
    func makeInt() -> Int {
        return Constant.size.sum()
    }
}

actor HeavyWorkActor {
    
    func makeInt() -> Int {
        return Constant.size.sum()
    }
    
    nonisolated func makeIntWithoutIsolation() -> Int {
        return Constant.size.sum()
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    private let normalWorker = HeavyWorker()
    private let heavyWorkActor = HeavyWorkActor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonTap(_ sender: Any) {
        self.runTaskTest()
    }
    
    private func appendLog(_ message: String) {
        let newText = (self.label.text ?? "") + "\n\(message)"
        self.label.text = newText
    }
    
    private func runTaskTest() {
        let size = Constant.size
        Task {
//             suspendion point 없음 -> 메인스레드 행
            let syncResult = size.sum()
            self.appendLog("result without await: \(syncResult)")

//             suspension point 만남 + main actor -> context switching 발생
//             다른 스레드에서 결과 돌아가고 재시작될때 메인스레드로 다시 돌아옴
            let asyncResult = await size.asyncSum()
            self.appendLog("result with await: \(asyncResult)")
            
//            일단 suspension point 만났기에 context switching + await가 끝나면 다시 메인스레드로 돌아옴
            let resultWithCont = await size.sumWithContinuation()
            self.appendLog("result with continuation await: \(resultWithCont)")
            
            // await만 봤을때는 위의 상황과 동일하지만 withCheckedContinuation의 틍성에 의해 현재 task -> 결과적으로 main thread가 행걸림
            // The body of the closure executes synchronously on the calling task, and once it returns the calling task is suspended.
            let resultWithCont2 = await withCheckedContinuation { cont in
                print("thread inside: \(Thread.current)")
                let result = size.sum()
                cont.resume(returning: result)
            }
            self.appendLog("result with continuation await: \(resultWithCont2)")
            
            // 1번
            // 여기서의 await는 suspension point로 동작 안함 -> task의 sync한 실행구문으로 인식하고 main thread에서 돌림
            // -> syncResult = size.sum()와 같은 결과
            let resultByCallDoHeavyWork = await self.doAsyncHeavyWork(size)
            self.appendLog("resultByCallDoHeavyWork: \(resultByCallDoHeavyWork)")
            
            // 2번
            // 차이점은 callAsycnHeavyWork 내부에서 한번 더 await
            // doAsyncHeavyWork, callAsycnHeavyWork 인터페이스만 보았을때는 차이점이 없음 왜?
            let resultByCallAsyncHeavyWork = await self.callAsycnHeavyWork(size)
            self.appendLog("resultByCallAsyncHeavyWork: \(resultByCallAsyncHeavyWork)")
            
            // 3번
            // 결과는 1번과 동일, 2번과 비슷한 구조이지만 왜?
            let resultByCallFakeAsyncHeavyWork = await self.callFakeAsyncHeavyWork(size)
            self.appendLog("resultByCallFakeAsyncHeavyWork: \(resultByCallFakeAsyncHeavyWork)")
            
            // 4번
            // 결과는 3, 4번 둘다 suspension point라 인식 x -> 하나의 동기 구문으로 인식
            // 3번과 다른점은 self(main actor)의 fake async 함수를 호출하는 것이 아니라 int의 ayns 함수를 호출
            // 2번과 다른점은 callFakeAsyncHeavyWork2 내부에 연산로직이 있다는점
            let resultByCallFakeAsyncHeavyWork2 = await self.callFakeAsyncHeavyWork2(size)
            self.appendLog("resultByCallFakeAsyncHeavyWork2: \(resultByCallFakeAsyncHeavyWork2)")
            
            let resultByNormalObject = self.normalWorker.makeInt()
            self.appendLog("resultByNormalObject: \(resultByNormalObject)")
            
            let resultByActorIsolation = await self.heavyWorkActor.makeInt()
            self.appendLog("resultByActorIsolation: \(resultByActorIsolation)")
            
            let resultByActorNonIsolatoin = self.heavyWorkActor.makeIntWithoutIsolation()
            self.appendLog("resultByActorNonIsolatoin: \(resultByActorNonIsolatoin)")
            
            self.appendLog("end")
        }
    }
    
    private func callAsycnHeavyWork(_ size: Int) async -> Int {
        return await size.asyncSum()
    }
    
    private func doAsyncHeavyWork(_ size: Int) async -> Int {
        return size.sum()
    }
    
    private func callFakeAsyncHeavyWork(_ size: Int) async -> Int {
        return await self.fakeSuspend() + size.sum()
    }
    
    private func fakeSuspend() async -> Int {
        return 0
    }
    
    private func callFakeAsyncHeavyWork2(_ size: Int) async -> Int {
        return await size.makeZeroWithAsync() + size.sum()
    }
}


extension Int {
    
    func makeZeroWithAsync() async -> Int {
        return 0
    }
    
    func sum() -> Int {
        return (0..<self).reduce(0, +)
    }
    
    func asyncSum() async -> Int {
        return (0..<self).reduce(0, +)
    }
    
    func sumWithContinuation() async -> Int {
        return await withCheckedContinuation { cont in
            print("thraed inside: \(Thread.current)")
            let result = (0..<self).reduce(0, +)
            cont.resume(returning: result)
        }
    }
}
