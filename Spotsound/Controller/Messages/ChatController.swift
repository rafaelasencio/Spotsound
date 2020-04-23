//
//  ChatController.swift
//  Spotsound
//
//  Created by Rafa Asencio on 23/04/2020.
//  Copyright © 2020 Rafa Asencio. All rights reserved.
//

import Foundation
import UIKit
import Firebase


private let reuseIdentifier = "ChatCell"

class ChatController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //Mark: - Properties
    
    var user: User?
    var messages = [Message]()
    
    lazy var containerView: UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 55)
    
        
        containerView.addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 50, height: 0)
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        containerView.addSubview(messagesTextfield)
        messagesTextfield.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: sendButton.leftAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        containerView.addSubview(separatorView)
        separatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
       
        
        return containerView
    }()
    
    let messagesTextfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Message"
        return tf
    }()
    
    let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Send", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return btn
    }()
    
    //MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register cell
        self.collectionView.register(ChatCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.backgroundColor = .white
        
        // configure navigation bar
        configureNavigationBar()
        
        //observe messages
        observeMessages()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return containerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 2, height: 50)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ChatCell
        return cell
    }
    
    //MARK: - Handlers
    
    @objc func handleSend(){
        
        uploadMessageToServer()
        
        messagesTextfield.text = nil
    }
    
    @objc func handleInfoTapped(){
        print("handle info")
    }
    
    func configureNavigationBar(){
        guard let user = self.user else { return }
        navigationItem.title = user.username
        let infoButton = UIButton(type: .infoLight)
        infoButton.tintColor = .black
        infoButton.addTarget(self, action: #selector(handleInfoTapped), for: .touchUpInside)
        
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = infoBarButtonItem
    }
    
    
    //MARK: - Api
    
    func uploadMessageToServer() {
        guard let messageText = messagesTextfield.text else { return }
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        guard let user = self.user else { return }
        let creationDate = Int(NSDate().timeIntervalSince1970)
        // unwrap user uid to work with Firebase 5
        guard let uid = user.uid else { return }
        
        let messageValues = [
            "creationDate": creationDate,
            "fromId": currentUserUid,
            "toId": uid,
            "messageText": messageText] as [String: AnyObject]
        
        let messageRef = MESSAGES_REF.childByAutoId()
        // unwrap messageRef key to work with Firebase 5
        guard let messageKey = messageRef.key else { return }
        
        messageRef.updateChildValues(messageValues)
        
        USER_MESSAGES_REF.child(currentUserUid).child(user.uid).updateChildValues([messageKey : 1])
        
        USER_MESSAGES_REF.child(user.uid).child(currentUserUid).updateChildValues([messageKey : 1])
    }
    
    func observeMessages(){
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        guard let chatPartnerId = self.user?.uid else { return }
        
        // called everytime user send message
        USER_MESSAGES_REF.child(currentUserUid).child(chatPartnerId).observe(.childAdded) { (snapshot) in
            
            let messageId = snapshot.key
            self.fetchMessage(withMessageId: messageId)
        }
    }
    
    func fetchMessage(withMessageId messageId: String){
        
        MESSAGES_REF.child(messageId).observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
            let message = Message(dictionary: dictionary)
            self.messages.append(message)
            self.collectionView.reloadData()
        }
    }
    
    
    
}
