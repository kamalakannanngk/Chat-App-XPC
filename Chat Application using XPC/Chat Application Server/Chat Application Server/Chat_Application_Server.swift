//
//  Chat_Application_Server.swift
//  Chat Application Server
//
//  Created by Kamala Kannan N G on 02/04/25.
//

import Foundation

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class Chat_Application_Server: NSObject, Chat_Application_ServerProtocol {
    /// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
    private static var connections: [String: NSXPCConnection] = [:]
    private static var messageHistory: [String: [Message]] = [:]

    func getTeamIDFromPID(pid: pid_t) -> String? {
        var secCode: SecCode?
        var staticCode: SecStaticCode?
        
        let status = SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributePid: pid] as CFDictionary, [], &secCode)
        guard status == errSecSuccess, let secCodeRef = secCode else {
            NSLog("[Error] Failed to get SecCode for PID \(pid), error: \(status)")
            return nil
        }

        let staticStatus = SecCodeCopyStaticCode(secCodeRef, [], &staticCode)
        guard staticStatus == errSecSuccess, let secStaticCode = staticCode else {
            NSLog("[Error] Failed to get SecStaticCode")
            return nil
        }

        var signingInfo: CFDictionary?
        let signingStatus = SecCodeCopySigningInformation(secStaticCode, SecCSFlags(), &signingInfo)
        
        guard signingStatus == errSecSuccess, let info = signingInfo as? [String: Any] else {
            NSLog("[Error] Failed to retrieve signing information")
            return nil
        }

        if let entitlements = info["entitlements-dict"] as? [String: Any],
           let teamID = entitlements["com.apple.application-identifier"] as? String {
           return teamID
        }

        print("[Error] Team ID not found")
        return nil
    }

    @objc func registerClient(phoneNumber: String, with reply: @escaping (Bool) -> Void) {
        
        if let clientConnection = NSXPCConnection.current() {
            
            guard let clientPID = clientConnection.value(forKey: "processIdentifier") as? Int else {
                NSLog("No PID for client")
                return
            }
            NSLog("Client PID: \(clientPID)")
            
            guard let clientTeamID = getTeamIDFromPID(pid: pid_t(clientPID)) else {
                NSLog("No Team ID for Client")
                return
            }
            
            print("Client Team ID: \(clientTeamID)")
            
            if clientTeamID == "UT4NRUFU6N." { // Use your own Team ID
                NSLog("Client Authorized Successfully!")
            } else {
                NSLog("Unauthorized Client. Rejected!")
                return
            }
            
            Chat_Application_Server.connections[phoneNumber] = clientConnection
            NSLog("Client Registered Successfully with Phone Number: \(phoneNumber)")
            NSLog("Number of Clients: \(Chat_Application_Server.connections.count)")
            for (key, value) in Chat_Application_Server.connections {
                NSLog("Stored Client: \(key) -> Connection: \(value)")
            }
            
            reply(true)
        }
    }
    
    @objc func sendMessage(from senderPhoneNumber: String, to receiverPhoneNumber: String, message: String) {
        guard let receiverConnection = Chat_Application_Server.connections[receiverPhoneNumber] else {
            NSLog("Client with Phone Number: \(receiverPhoneNumber) is not connected!")
            return
        }
        
        let proxy = receiverConnection.remoteObjectProxy
        NSLog("Proxy Object Type for \(receiverPhoneNumber): \(String(describing: proxy))")
        
        if let clientProxy = receiverConnection.remoteObjectProxy as? Chat_Application_ClientProtocol {
            clientProxy.receiveMessage(from: senderPhoneNumber, message: message)
            
            let sentMessage = Message(peerPhoneNumber: receiverPhoneNumber, message: message, isSent: true)
            Chat_Application_Server.messageHistory[senderPhoneNumber, default: []].append(sentMessage)

            let receivedMessage = Message(peerPhoneNumber: senderPhoneNumber, message: message, isSent: false)
            Chat_Application_Server.messageHistory[receiverPhoneNumber, default: []].append(receivedMessage)
        } else {
            NSLog("Failed to retrieve client proxy for \(receiverPhoneNumber)")
        }
    }
    
    @objc func showHistory(for clientPhoneNumber: String, with peerPhoneNumber: String) {
        guard let connection = Chat_Application_Server.connections[clientPhoneNumber],
              let clientProxy = connection.remoteObjectProxy as? Chat_Application_ClientProtocol else {
            NSLog("Client not found or not connected.")
            return
        }

        let clientHistory = Chat_Application_Server.messageHistory[clientPhoneNumber] ?? []
        let sentMessages = clientHistory
            .filter { $0.peerPhoneNumber == peerPhoneNumber && $0.isSent }
            .map { $0.message }

        let peerHistory = Chat_Application_Server.messageHistory[peerPhoneNumber] ?? []
        let receivedMessages = peerHistory
            .filter { $0.peerPhoneNumber == clientPhoneNumber && $0.isSent }
            .map { $0.message }

        clientProxy.viewHistory(sent: sentMessages, received: receivedMessages)
    }

}
