//
//  ViewController.swift
//  TcpServer
//
//  Created by 6Rooms on 2018/2/26.
//  Copyright © 2018年 6Rooms. All rights reserved.
//

import Cocoa
import CocoaAsyncSocket

class ViewController: NSViewController,GCDAsyncSocketDelegate {

    let serverPort: UInt16 = 8080
    var host = "127.0.0.1"
    var sendSocket:GCDAsyncSocket?
    var socketArray = [GCDAsyncSocket]()
    let delegateQueue = DispatchQueue(label: "delegagteQueue")
    let resPonseQueue:DispatchQueue = {
        let label = "resPonseQueue"
        let qos =  DispatchQoS.default
        let attributes = DispatchQueue.Attributes.concurrent
        let autoreleaseFrequency = DispatchQueue.AutoreleaseFrequency.never
        let queue = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: nil)
       return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accept()
    }
    
    func accept(){
        
        sendSocket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        do {
            try sendSocket?.accept(onPort: UInt16(serverPort))
            print("accept--成功")
        }catch  {
            print("失败\(error)")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        if let str = String.init(data: data, encoding: .utf8) {
            resPonseQueue.async {[weak sock] in
                let sSock = sock
                print("read str " + str)
                let resStr = self.response(for: str)
                print("res:\(resStr ?? "")")
                if let resData = resStr?.data(using: String.Encoding.utf8){
                    print("write res for \(str)")
                    sSock?.write(resData, withTimeout: -1, tag: 0)
                }
            }
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("connect new socket")
        socketArray.append(newSocket) //保持新连接的client 连接
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func isPrimeNumber(num:Int)->Bool {
        
        let sleepInterval = 10.0 * Double(arc4random_uniform(1000)) / 1000.0
        sleep(UInt32(sleepInterval))
        
        guard num > 1 else {
            return false
        }
        if num == 2 { return true }
        if num % 2 == 0 { return false }
        let qurt = sqrt(Double(num))
        let interval = 2
        for index in stride(from: 3, to: Int(qurt) + 1, by: interval) {
            // index -> 3,5,7, ...
            if num % index == 0 {return false}
        }
        return true
    }
    
    
    func response(for requestStr:String) -> String?{
        
        var resultStr = ""
        for sigleReuqestStr in requestStr.components(separatedBy: "\r\n") {
            if sigleReuqestStr.count == 0 {continue}
            let requestItems = sigleReuqestStr.components(separatedBy: "\t")
            if requestItems.count == 2 {
                var res = ""
                if self.isPrimeNumber(num: Int(requestItems.last!) ?? 1){
                    res = "\tyes\r\n"
                }else {
                    res = "\tno\r\n"
                }
                 resultStr.append("\(requestItems.first!)" + res)
            }else {
                print("\(sigleReuqestStr) is error")
                return nil
            }
        }
        return resultStr
    }
}

