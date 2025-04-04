//
//  Chat_Application_ServerProtocol.swift
//  Chat Application Server
//
//  Created by Kamala Kannan N G on 02/04/25.
//

import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol Chat_Application_ServerProtocol {
    
    /// Replace the API of this protocol with an API appropriate to the service you are vending.
    func registerClient(phoneNumber: String, with reply: @escaping (Bool) -> Void)
    func sendMessage(from senderPhoneNumber: String, to receiverPhoneNumber: String, message: String)
    func showHistory(for requesterPhoneNumber: String, with peerPhoneNumber: String)
}

@objc protocol Chat_Application_ClientProtocol {
    func receiveMessage(from sender: String, message: String)
    func viewHistory(sent: [String], received: [String])
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "com.practice.Chat-Application-Server")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: Chat_Application_ServerProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? Chat_Application_ServerProtocol {
         proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
             NSLog("Result of calculation is: \(result)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
*/
