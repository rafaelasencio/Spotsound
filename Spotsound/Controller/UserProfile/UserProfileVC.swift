//
//  UserProfileVC.swift
//  Spotsound
//
//  Created by Rafa Asencio on 12/04/2020.
//  Copyright © 2020 Rafa Asencio. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "cellId"
private let userProfileHeaderCell = "UserProfileHeaderCell"

class UserProfileVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    
    var user: User?
    var posts = [Post]()
    
    override func viewDidLoad() {
        self.collectionView.backgroundColor = .white
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.register(UserProfileHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: userProfileHeaderCell)
        
        //fetch is user is not current user.
        if self.user == nil {
            fetchCurrentUserData()
        }
        
        //fetch posts
        fetchPost()
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: userProfileHeaderCell, for: indexPath) as! UserProfileHeaderCell
        
        // set delegate
        header.delegate = self
        
        header.user = self.user
        
        navigationItem.title = user?.username
        
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    //MARK: - Api
    
    func fetchPost(){
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {return}
        
        //.childAdded to know when post get added to the structure
        USER_POST_REF.child(currentUserId).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
            POSTS_REF.child(postId).observeSingleEvent(of: .value) { (snapshot) in
                guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else {return}
                let post = Post(postId: postId, dicctionary: dictionary)
                self.posts.append(post)
                print("post \(post.caption)")
            }
        }
    }
    
    func fetchCurrentUserData(){
        // set user property in UserProfileHeaderCell
        guard let currentUserUid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("users").child(currentUserUid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictValues = snapshot.value as? Dictionary<String, AnyObject> else {return}
            
            let uid = snapshot.key
            let user = User(uid: uid, dict: dictValues)
            self.user = user
            self.navigationItem.title = user.username
            self.collectionView.reloadData()
        }
    }

}

extension UserProfileVC: UserProfileHeaderCellDelegate {
    func handleFollowersButtonTapped(for header: UserProfileHeaderCell) {
        let followVC = FollowVC()
        followVC.viewFollowers = true
        followVC.uid = user?.uid
        navigationController?.pushViewController(followVC, animated: true)
    }
    
    func handleFollowingButtonTapped(for header: UserProfileHeaderCell) {
        let followVC = FollowVC()
        followVC.viewFollowing = true
        followVC.uid = user?.uid
        navigationController?.pushViewController(followVC, animated: true)
    }
    
    func handleEditProfileButtonTapped(for header: UserProfileHeaderCell) {
        guard let user = header.user else {return}
        
        if header.editProfileFollowButton.titleLabel?.text == "Edit Profile" {
            print("go to EditProfileVC")
            
        } else {
            if header.editProfileFollowButton.titleLabel?.text == "Follow" {
                header.editProfileFollowButton.setTitle("Following", for: .normal)
                
                user.follow()
            } else {
                header.editProfileFollowButton.setTitle("Follow", for: .normal)
                
                user.unfollow()
            }
        }
    }
    
    func handleSetUserStats(for header: UserProfileHeaderCell) {
        var numberOfFollowers: Int!
        var numberOfFollowings: Int!
        guard let uid = header.user?.uid else {return}
        
        //observe instead observeSingleEvent to update data in realtime
        USER_FOLLOWER_REF.child(uid).observe(.value) { (snapshot) in
            if let snapshot = snapshot.value as? Dictionary<String, AnyObject>{
                numberOfFollowers = snapshot.count
            } else {
                numberOfFollowers = 0
            }
            let attributedText = NSMutableAttributedString(string: "\(numberOfFollowers!)\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
            attributedText.append(NSAttributedString(string: "followers", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            header.followersLabel.attributedText = attributedText
        }
        
        
        USER_FOLLOWING_REF.child(uid).observe(.value) { (snapshot) in
            if let snapshot = snapshot.value as? Dictionary<String, AnyObject>{
                numberOfFollowings = snapshot.count
            } else {
                numberOfFollowings = 0
            }
            let attributedText = NSMutableAttributedString(string: "\(numberOfFollowings!)\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
            attributedText.append(NSAttributedString(string: "following", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            header.followingLabel.attributedText = attributedText
        }
    }
    
    
    
    
}
