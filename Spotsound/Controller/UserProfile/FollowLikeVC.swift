//
//  FollowLikeVC.swift
//  Spotsound
//
//  Created by Rafa Asencio on 14/04/2020.
//  Copyright © 2020 Rafa Asencio. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "FollowCell"

class FollowLikeVC: UITableViewController {
    
    //MARK: - Properties
    
    enum ViewingMode: Int {
        case Following
        case Followers
        case Likes
        
        init(index: Int){
            switch index {
            case 0: self = .Following
            case 1: self = .Followers
            case 2: self = .Likes
            default: self = .Following
            }
        }
    }
    
    var postId: String!
    var viewingMode: ViewingMode!
    var uid: String?
    var users = [User]()
    var followCurrentKey: String?
    var likeCurrentKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register cell
        tableView.register(FollowLikeCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        // configure nav controller
        configureNavTitle()
        // fetch users
        fetchUsers()
        tableView.separatorColor = .clear
        
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if users.count > 3 {
            if indexPath.item == users.count - 1 {
                fetchUsers()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! FollowLikeCell
        cell.user = users[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let user = users[indexPath.row]
        let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileVC.user = user
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    //MARK: - Handlers
    
    func configureNavTitle() {
        
        guard let viewingMode = self.viewingMode else {return}
        
        switch viewingMode {
            case .Followers: self.navigationItem.title = "Followers"
            case .Following: self.navigationItem.title = "Following"
            case .Likes: self.navigationItem.title = "Likes"
        }
    }
    
    //MARK: - Api
    
    func getDatabaseReference() -> DatabaseReference? {
        
        guard let viewingMode = self.viewingMode else {return nil}
        
        switch viewingMode {
            case .Followers: return USER_FOLLOWER_REF
            case .Following: return USER_FOLLOWING_REF
            case .Likes: return POST_LIKES_REF
        }
        
    }
    
    func fetchUser(with uid: String){
        
        Database.fetchUser(with: uid) { (user) in
            self.users.append(user)
            self.tableView.reloadData()
        }
    }
    
    func fetchUsers(){
        guard let viewingMode = self.viewingMode else {return }
        guard let ref = getDatabaseReference() else {return}
        
        switch viewingMode {
            
            case .Followers, .Following: //fetching users by currentUserUid
                
                guard let uid = self.uid else {return}
                
                if followCurrentKey == nil {
                    ref.child(uid).queryLimited(toLast: 4).observeSingleEvent(of: .value) { (snapshot) in
                        
                        guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                        guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                        
                        allObjects.forEach { (snapshot) in
                            let followUid = snapshot.key
                            self.fetchUser(with: followUid)
                        }
                        self.followCurrentKey = first.key
                    }
                    
                } else {
                    ref.child(uid).queryOrderedByKey().queryEnding(atValue: self.followCurrentKey).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                        
                        guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                        guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                        
                        allObjects.forEach { (snapshot) in
                            let followUid = snapshot.key
                            if followUid != self.followCurrentKey {
                                self.fetchUser(with: followUid)
                            }
                        }
                        self.followCurrentKey = first.key
                    }
                    
                }
                
            
            case .Likes: //fetching users by postId
            
                guard let postId = self.postId else {return}
                
                if likeCurrentKey == nil {
                    
                    ref.child(postId).queryLimited(toLast: 4).observeSingleEvent(of: .value) { (snapshot) in
                        
                        guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                        guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                        
                        allObjects.forEach { (snapshot) in
                            let likeUid = snapshot.key
                            self.fetchUser(with: likeUid)
                        }
                        self.likeCurrentKey = first.key
                    }
                } else {
                    ref.child(postId).queryOrderedByKey().queryEnding(atValue: self.likeCurrentKey).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                        
                        guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                        guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                        
                        allObjects.forEach { (snapshot) in
                            let likeUid = snapshot.key
                            
                            if likeUid != self.likeCurrentKey {
                                self.fetchUser(with: likeUid)
                            }
                        }
                        self.likeCurrentKey = first.key
                    }
                }
        }
        
        
    }
}

extension FollowLikeVC: FollowCellDelegate {
    
    func handleFollowTapped(for cell: FollowLikeCell) {
        guard let user = cell.user else {return}
        
        if user.isFollowed {
            print("unfollow")
            user.unfollow()
            
            cell.followButton.setTitle("Follow", for: .normal)
            cell.followButton.setTitleColor(.white, for: .normal)
            cell.followButton.layer.borderWidth = 0
            cell.followButton.backgroundColor = UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)
        } else {
            print("following")
            user.follow()
            
            cell.followButton.setTitle("Following", for: .normal)
            cell.followButton.setTitleColor(.black, for: .normal)
            cell.followButton.layer.borderColor = UIColor.lightGray.cgColor
            cell.followButton.layer.borderWidth = 0.5
            cell.followButton.backgroundColor = .white
        }
    }
    
    
}
