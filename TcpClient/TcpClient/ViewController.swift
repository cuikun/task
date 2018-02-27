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
    var host = "192.168.3.20"
    var sendSocket:GCDAsyncSocket?
    let randomNumbersFileURL = URL(fileURLWithPath: NSHomeDirectory()+"/randomNumbers.txt")
    let primeCheckFileURL = URL(fileURLWithPath: NSHomeDirectory() + "/primeCheck.txt")
    let delegateQueue = DispatchQueue(label: "delegateQueue")
    var startDate = Date()
    
    @IBAction func click(_ sender: Any) {
        
        let serviceStr: NSMutableString = NSMutableString()
        serviceStr.append("\(1)")
        serviceStr.append("\r\n")
        sendSocket?.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
        
        print("send click")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startDate = Date()
        self.prepareFile()
        self.writeRandomNumbers(totalNum: Int(10000), to: self.randomNumbersFileURL)
        self.connect()
    }
    
    func prepareFile() {
        createFile(fileURL: self.primeCheckFileURL)
        createFile(fileURL: self.randomNumbersFileURL)
    }
    
    func createFile(fileURL:URL) {
        //如果文件不存在则新建一个
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("delete file : \(fileURL.path)")
            } catch {
                print("delete file error")
            }
        }
        print("create file : \(fileURL.path)")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
    }

    func sendFile(fileURL:URL){
        
        guard let streamReader = StreamReader(path: fileURL.path) else {
            print("StreamReader couldn't be created!")
            return
        }
        while !streamReader.atEof {
            guard let nextLine = streamReader.nextLine() else {
                print("Reached the end before printing!")
                break
            }
            let nextLineStr = nextLine + "\r\n"
            print("write str : \(nextLineStr)")
            guard let data = nextLineStr.data(using: String.Encoding.utf8) else {
                print("string to data error")
                return
            }
            sendSocket?.write(data, withTimeout: -1, tag: 0)
        }

    }
    
    func writeRandomNumbers(totalNum:Int,to fileURL: URL){
        for index in 0 ... totalNum {
            let stringToWrite = "\(index)\t\(arc4random_uniform(10000))\r\n"
            self.write(stringToWrite: stringToWrite, to: fileURL)
        }
    }
    
    func write(stringToWrite:String,to fileURL:URL) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            //找到末尾位置并添加
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)

        } catch  {
            print("writing file handler error")
        }
    }
    
    func connect(){
        sendSocket = GCDAsyncSocket(delegate: self, delegateQueue: self.delegateQueue)
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
        self.write(stringToWrite: str!, to: self.primeCheckFileURL)
        let pastSeconds = Date().timeIntervalSince(self.startDate)
        print("time pasted: \(pastSeconds)")
        sendSocket?.readData(withTimeout: -1, tag: 0)
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print(host)
        print("连接成功")
        sendSocket?.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
        self.sendFile(fileURL: self.randomNumbersFileURL) // 发送数据
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("断开连接")
    }
}

