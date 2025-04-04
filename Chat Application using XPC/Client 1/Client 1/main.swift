//
//  main.swift
//  XPC Client Demo
//
//  Created by Kamala Kannan N G on 02/04/25.
//

enum UserMenu: Int {
    case sendMessage = 1
    case viewHistory = 2
    case exit = 3
}


import Foundation

class XPCClient: NSObject, Chat_Application_ClientProtocol {
    private let connection: NSXPCConnection
    private let phoneNumber: String = "1234567890"
    
    override init() {
        self.connection = NSXPCConnection(machServiceName: "com.practice.Chat-Application-Server")
        super.init()
        
        connection.remoteObjectInterface = NSXPCInterface(with: Chat_Application_ServerProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: Chat_Application_ClientProtocol.self)
        connection.exportedObject = self
        connection.resume()
        
        registerWithServer()
    }
    
    private func registerWithServer() {
        guard let proxy = connection.remoteObjectProxy as? Chat_Application_ServerProtocol else {
            NSLog("Failed to create proxy")
            return
        }
        
        proxy.registerClient(phoneNumber: phoneNumber) { success in
            if success {
                NSLog("Successfully registered with the server! [\(self.phoneNumber)]")
                self.showMenu()
            } else {
                NSLog("Failed to register with the server!")
            }
        }
    }
    
    private func sendMessage() {
        print("Enter receiver's phone number:")
        guard let receiverPhoneNumber = readLine(), !receiverPhoneNumber.isEmpty else {
            print("Invalid input.")
            return
        }
        
        print("Enter your message:")
        guard let message = readLine(), !message.isEmpty else {
            print("Message cannot be empty.")
            return
        }
        
        guard let proxy = connection.remoteObjectProxy as? Chat_Application_ServerProtocol else {
            print("Failed to get proxy to server.")
            return
        }
        
        proxy.sendMessage(from: phoneNumber, to: receiverPhoneNumber, message: message)
        print("Message sent successfully!")
    }
    
    private func showMenu() {
        DispatchQueue.global().async {
            print("PID: \(ProcessInfo.processInfo.processIdentifier)")
            whileLoop: while true {
                print("""
                Enter your choice: 
                1. Send Message
                2. View Message History
                3. Exit
                """)
                if let input = readLine(), let choice = Int(input), let action = UserMenu(rawValue: choice) {
                    switch(action) {
                    case .sendMessage:
                        self.sendMessage()
                    case .viewHistory:
                        self.viewHistory()
                    case .exit:
                        break whileLoop
                    }
                } else {
                    print("Invalid choice.")
                }
            }
        }
    }
    
    func receiveMessage(from sender: String, message: String) {
        print("\nNew message from \(sender): \(message)")
    }
    
    func viewHistory() {
        print("Enter the peer phone number to view chat history:")
        guard let peerPhoneNumber = readLine(), !peerPhoneNumber.isEmpty else {
            print("Invalid input.")
            return
        }
        
        guard let proxy = connection.remoteObjectProxy as? Chat_Application_ServerProtocol else {
            print("Failed to get proxy to server.")
            return
        }

        proxy.showHistory(for: phoneNumber, with: peerPhoneNumber)
    }
    
    func viewHistory(sent: [String], received: [String]) {
        print("\nSent Messages:")
        for message in sent {
            print("-> \(message)")
        }

        print("\nReceived Messages:")
        for message in received {
            print("<- \(message)")
        }
    }

}

let client = XPCClient()

dispatchMain()
