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
            let syncResult = size.sum()
            self.appendLog("result without await: \(syncResult)")
            
            let asyncResult = await size.asyncSum()
            self.appendLog("result with await: \(asyncResult)")
            
//            let resultWithCont = await withCheckedContinuation { cont in
//                let result = size.sum()
//                cont.resume(returning: result)
//            }
//            self.appendLog("result with continuation await: \(resultWithCont)")
//            
//            let resultByCallAsyncHeavyWork = await self.callAsycnHeavyWork(size)
//            self.appendLog("resultByCallAsyncHeavyWork: \(resultByCallAsyncHeavyWork)")
//            
//            let resultByCallDoHeavyWork = await self.doAsyncHeavyWork(size)
//            self.appendLog("resultByCallDoHeavyWork: \(resultByCallDoHeavyWork)")
//            
//            let resultByNormalObject = self.normalWorker.makeInt()
//            self.appendLog("resultByNormalObject: \(resultByNormalObject)")
//            
//            let resultByActorIsolation = await self.heavyWorkActor.makeInt()
//            self.appendLog("resultByActorIsolation: \(resultByActorIsolation)")
//            
//            let resultByActorNonIsolatoin = self.heavyWorkActor.makeIntWithoutIsolation()
//            self.appendLog("resultByActorNonIsolatoin: \(resultByActorNonIsolatoin)")
            
            self.appendLog("end")
        }
    }
    
    private func callAsycnHeavyWork(_ size: Int) async -> Int {
        return await size.asyncSum()
    }
    
    private func doAsyncHeavyWork(_ size: Int) async -> Int {
        return size.sum()
    }
}


extension Int {
    
    func sum() -> Int {
        return (0..<self).reduce(0, +)
    }
    
    func asyncSum() async -> Int {
        return (0..<self).reduce(0, +)
    }
}
