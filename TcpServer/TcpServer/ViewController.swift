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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accept()
    }
    
    func accept(){
        
        sendSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .default))
        do {
            try sendSocket?.accept(onPort: UInt16(serverPort))
            print("accept--成功")
        }catch  {
            print("失败\(error)")
        }
    }

    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        //后台给的是字符串的时候
        let str = String.init(data: data, encoding: .utf8)
        print(str as Any)
        sendSocket?.readData(withTimeout: -1, tag: 0)
    }
}

