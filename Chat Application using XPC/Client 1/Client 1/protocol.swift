//
//  protocol.swift
//  Client 1
//
//  Created by Kamala Kannan N G on 02/04/25.
//

import Foundation

/// Protocol for communication with the XPC server
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
