//
//  ViewController.swift
//  TcpClient
//
//  Created by 6Rooms on 2018/2/26.
//  Copyright © 2018年 6Rooms. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
class ViewController: UIViewController,GCDAsyncSocketDelegate {

    let serverPort: UInt16 = 8080
    var host = "127.0.0.1"
    var sendSocket:GCDAsyncSocket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connect()
        
        let url = URL(fileURLWithPath: NSHomeDirectory()+"/randomNumbers.txt")
        print("url path \(url)")
        self.writeRandomNumbers(totalNum: Int(1.0e6), to: url)
        self.sendFile(fileURL: url)
    }

    func sendFile(fileURL:URL){
        do {
            let fileHandle = try FileHandle(forReadingFrom:fileURL)
            let data = fileHandle.readDataToEndOfFile()
            sendSocket?.write(data, withTimeout: -1, tag: 0)
        } catch {
            print("file hanle error")
        }
    }
    
    @IBAction func click(_ sender: Any) {
       
        let serviceStr: NSMutableString = NSMutableString()
        serviceStr.append("\(1)")
        serviceStr.append("\r\n")
        sendSocket?.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
        
        print("send click")
    }
    
    func writeRandomNumbers(totalNum:Int,to fileURL: URL){
        
        //如果文件不存在则新建一个
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                for index in 0 ... totalNum {
                    let stringToWrite = "\(index)\t\(arc4random_uniform(100000))\n"
                    //找到末尾位置并添加
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
                }
            } catch  {
                print("writing file handler error")
            }
        }
    }
    
    func connect(){
        sendSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .default))
        do {
            try sendSocket?.connect(toHost: host, onPort: UInt16(serverPort))
            print("连接--成功")
        }catch  {
            print("失败\(error)")
        }
    }
    
    
    //读到数据后的回调代理
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        //后台给的是字符串的时候
        let str = String.init(data: data, encoding: .utf8)
        print(str as Any)
        sendSocket?.readData(withTimeout: -1, tag: 0)
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print(host)
        print("连接成功")
        //发起一个读取的请求，当收到数据时didReadData才能被回调,设置一个分割,也就是读到某个data的时候就会停止(分隔符即为0A).可以解决丢包问题
        sendSocket?.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    }
    
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("断开连接")
    }

}

