//
//  HomeViewController.swift
//  FBex
//
//  Created by AJ Radik on 12/12/19.
//  Copyright © 2019 AJ Radik. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class HomeViewController: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nothingToSeeHereLabel: UILabel!
    @IBOutlet weak var firstName: UILabel!
    @IBOutlet weak var welcome: UILabel!
    @IBOutlet weak var recTutors: UILabel!
    @IBOutlet weak var logOutButton: DesignableButton!
    public var remoteUserCells: [CustomCell] = []
    var timer = Timer()
    static var currentUserImage: UIImage?
    static var currentUserData: [String: String]?
    private var cardListener: ListenerRegistration?
    private var reference: CollectionReference?
    private var action: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        pageControl.numberOfPages = remoteUserCells.count
        recTutors.font = recTutors.font.withSize( (1.3/71) * UIScreen.main.bounds.height)
        firstName.font = firstName.font.withSize( (3.5/71) * UIScreen.main.bounds.height)
        welcome.font = welcome.font.withSize( (3.0/71) * UIScreen.main.bounds.height)
        nothingToSeeHereLabel.font = nothingToSeeHereLabel.font.withSize( (1.5/71) * UIScreen.main.bounds.height)
        downloadCurrentUserImage()
        let currentUser = Auth.auth().currentUser!
        firstName.text! = currentUser.displayName!.components(separatedBy: " ")[0]
        view.bringSubviewToFront(nothingToSeeHereLabel)
        
        if remoteUserCells.isEmpty {
            nothingToSeeHereLabel.isHidden = true
        }
        
        if HomeViewController.currentUserData?[DatabaseKey.Account_Type.name] == DatabaseValue.student.name {
            recTutors.text = "YOUR MATCHED MENTORS"
        } else if HomeViewController.currentUserData?[DatabaseKey.Account_Type.name] == DatabaseValue.mentor.name {
            recTutors.text = "YOUR MATCHED STUDENTS"
        }
        
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            let alertController = UIAlertController(title: "Please let us send you notifications <3",
                                                    message: """
                                                    We'd be really happy if you could allow notifications. \
                                                    This will enable you to receive notifications when your peers message you, \
                                                    or when you're matched with a new peer.
                                                    """,
                                                    preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "No :|", style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes! :D", style: .default, handler: { _ in
                self.setUpNotifications()
            }))
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func setUpNotifications() {
        //Messaging
                if #available(iOS 10.0, *) {
                  // For iOS 10 display notification (sent via APNS)
                  UNUserNotificationCenter.current().delegate = self

                  let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                  UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
                } else {
                  let settings: UIUserNotificationSettings =
                  UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(settings)
                }

                UIApplication.shared.registerForRemoteNotifications()
                
                Messaging.messaging().delegate = self
                
                InstanceID.instanceID().instanceID { (result, error) in
                  if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                  } else if let result = result {
                    print("Remote instance ID token: \(result.token)")
                    Firestore.firestore().collection(DatabaseKey.Users.name).document(Auth.auth().currentUser!.uid).setData([DatabaseKey.Token.name: result.token ], merge: true)
                  }
                }
                //End Messaging
    }
    
    func loadCardLoader(action: @escaping () -> Void) {
        self.action = action
        Firestore.firestore().collection(DatabaseKey.Users.name).document(Auth.auth().currentUser!.uid ).getDocument { (document, error) in
            if let document = document, document.exists {
                var dataDescription = document.data()
                
                dataDescription![DatabaseKey.UID.name] = Auth.auth().currentUser!.uid
                guard let currentUserData = (dataDescription as? [String: String]) else {
                    Utilities.logError(customMessage: "Casting Error.", customCode: 4)
                    return
                }

                HomeViewController.currentUserData = currentUserData
                
                self.reference = Firestore.firestore().collection([DatabaseKey.Users.name, Auth.auth().currentUser!.uid, DatabaseKey.Allow_List.name].joined(separator: "/"))
                
                self.cardListener = self.reference?.addSnapshotListener { querySnapshot, error in
                  guard let snapshot = querySnapshot else {
                    print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                    return
                  }
                    
                    print("snapshot count:  \(snapshot.count)")
                    
                    if snapshot.isEmpty {
                        print("running action")
                        print(action)
                        self.action()
                        self.action = {}
                        self.nothingToSeeHereLabel.isHidden = false
                    }
                  
                    DispatchQueue.main.async {
                        snapshot.documentChanges.forEach { change in
                          self.handleDocumentChange(change)
                        }
                    }
                    
                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        
        switch change.type {
            case .added:
                DispatchQueue.main.async {
                    self.addChange(change)
                }
            
            case .removed:
                DispatchQueue.main.async {
                    self.removeChange(change)
                }
            
            default:
                break
        }
        
    }
    
    func addChange(_ change: DocumentChange) {
        print(change.document.documentID)
        
        for cell in remoteUserCells where cell.data![DatabaseKey.UID.name] == change.document.documentID {
            print("document already present")
            return
        }
        
        Firestore.firestore().collection(DatabaseKey.Users.name).document(change.document.documentID).getDocument { (document, error) in
            
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
                Utilities.logError(customMessage: "An error occured with Firebase.", customCode: 3)
            }
            
            if let document = document, document.exists {
                
                guard var dataDescription = document.data() as? [String: String] else {
                    Utilities.logError(customMessage: "Casting Error.", customCode: 4)
                    return
                }
                
                dataDescription[DatabaseKey.UID.name] = change.document.documentID
                dataDescription[DatabaseKey.Relative_Status.name] = (change.document.data())[DatabaseKey.Relative_Status.name] as? String
                
                guard let customCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "cell",
                    for: IndexPath(item: self.remoteUserCells.count, section: 0)) as? CustomCell else {
                    Utilities.logError(customMessage: "Casting Error.", customCode: 4)
                    return
                }
                
                customCell.data = dataDescription
                
                if !self.remoteUserCells.contains(customCell) {
                    self.remoteUserCells.append(customCell)
                    print("just appended cell for \(customCell.data![DatabaseKey.First_Name.name]!)")
                }
                
                print(dataDescription)
                
                self.collectionView?.reloadData()
                self.pageControl?.numberOfPages = self.remoteUserCells.count

                Firestore.firestore().collection(DatabaseKey.Users.name).document(Auth.auth().currentUser!.uid).collection(DatabaseKey.Allow_List.name).getDocuments(completion: { (querySnapshot, _) in
                    DispatchQueue.main.async {
                        print("QuerySnapshot Count: \(querySnapshot!.count)")
                        if querySnapshot!.count == self.remoteUserCells.count {
                            print("running action")
                            print(self.action)
                            self.action()
                            self.action = {}
                            //GCD here???
                            self.nothingToSeeHereLabel?.isHidden = true
                        }
                    }
                })
                
            } else {
                print("Document does not exist. addChange()")
            }
        }
        print("Remote User Data Count: \(self.remoteUserCells.count)")
    }
    
    func removeChange(_ change: DocumentChange) {
        
        print("processing removal of: \(change.document.documentID)")
        
        print("Remote User Data Count: \(remoteUserCells.count)")
        
        for var index in 0..<remoteUserCells.count {
            print("start loop with i of \(index), current size of remoteUserCells is \(remoteUserCells.count)")
            if remoteUserCells[index].data![DatabaseKey.UID.name] == change.document.documentID {
                remoteUserCells.remove(at: index)
                print("removed card at \(index)")
                index -= 1
                print("decremented i from \(index+1) to \(index)")
                collectionView.reloadData()
                pageControl.numberOfPages = remoteUserCells.count
            }
            print("end loop with i of \(index)")
        }
        
        if remoteUserCells.isEmpty {
            nothingToSeeHereLabel.isHidden = false
        } else {
            nothingToSeeHereLabel.isHidden = true
        }
        
        print("finished processing removal of: \(change.document.documentID)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {
            Utilities.logError(customMessage: "Was not able to sign out.", customCode: 2)
        }
        
        timer.invalidate()
        print("logged out")
        remoteUserCells = []
        collectionView.reloadData()
        transitionToStart()
    }
    
    func transitionToStart() {
        let startViewController = storyboard?.instantiateViewController(identifier: "InitialNavController") as? UINavigationController
        view.window?.rootViewController = startViewController
        view.window?.makeKeyAndVisible()
    }
    
    func downloadCurrentUserImage() {
        let task = URLSession.shared.dataTask(with: Auth.auth().currentUser!.photoURL!) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async { // Make sure you're on the main thread here
                HomeViewController.currentUserImage = UIImage(data: data)!
            }
        }
        task.resume()
    }
    
}

extension HomeViewController: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
      print("Firebase registration token: \(fcmToken)")

      let dataDict: [String: String] = ["token": fcmToken]
      NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remoteUserCells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return remoteUserCells[indexPath.item]
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return self
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return self
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return remoteUserCells.count
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

class CustomCell: UICollectionViewCell {
    
    var data: [String: String]? {
        didSet {
            firstname.font = firstname.font.withSize( (4.0/71) * UIScreen.main.bounds.height)
            state.font = state.font.withSize( (2.2/71) * UIScreen.main.bounds.height)
            blurb.font = blurb.font.withSize( (1.9/71) * UIScreen.main.bounds.height)
            sentence.font = sentence.font.withSize( (1.3/71) * UIScreen.main.bounds.height) //TODO: Font too large?
            
            viewProfileButton.titleLabel!.font = viewProfileButton.titleLabel!.font.withSize( (1.5/71) * UIScreen.main.bounds.height)
            messageAddMentorButton.titleLabel!.font = messageAddMentorButton.titleLabel!.font.withSize( (1.5/71) * UIScreen.main.bounds.height)
            
            button.backgroundColor = UIColor.systemPink

            firstname.text = data![DatabaseKey.First_Name.name]!
            state.text = data![DatabaseKey.State.name]!
            
            setSentenceText()
            downloadImage(url: URL(string: data![DatabaseKey.Photo_URL.name]!)!, imageView: imageView)
            
            setUpMessageAddMentorButton(button: messageAddMentorButton)
        }
    }
    
    func setUpMessageAddMentorButton(button: UIButton) {
        if data![DatabaseKey.Account_Type.name] == DatabaseValue.mentor.name {
            if data![DatabaseKey.Relative_Status.name] == DatabaseValue.matched.name {
                button.backgroundColor = .systemIndigo
                button.setTitle("Message", for: .normal)
            } else {
                button.backgroundColor = .systemGreen
                button.setTitle("Add Mentor", for: .normal)
            }
        }
    }
    
    func setSentenceText() {
        let firstName = data![DatabaseKey.First_Name.name]!
        
        if data![DatabaseKey.Account_Type.name]! == DatabaseValue.student.name {
            let highSchoolYear = DatabaseValue(name: data![DatabaseKey.What_Year_Of_High_School.name]!)!.rawValue
            let interest = DatabaseValue(name: data![DatabaseKey.Which_Of_These_Interests_You_Most.name]!)!.rawValue
            
            var whereInProcess = ""
            
            switch DatabaseValue(name: data![DatabaseKey.Where_Are_You_In_The_College_Application_Process.name]!) {
                case .i_havent_started_looking:
                    whereInProcess = "has /bnot started/b looking"
                case .i_started_looking_but_havent_picked_any_schools:
                    whereInProcess = "has /bstarted looking/b but hasn't picked any schools"
                case .ive_picked_schools_but_havent_started_applying:
                    whereInProcess = "has /bpicked schools/b but hasn't began applying"
                case .ive_started_applications_but_im_stuck:
                    whereInProcess = "has /bstarted applications/b but is stuck"
                case .im_done_with_applications:
                    whereInProcess = "is /bdone/b with applications"
                default:
                    break
            }
                
            var lookingFor = ""
            
            switch DatabaseValue(name: data![DatabaseKey.What_Are_You_Looking_For_From_A_Peer_Counselor.name]!) {
                case .to_help_keep_me_on_track:
                    lookingFor = "to help keep them /bon track/b"
                case .to_provide_info_on_what_colleges_look_for:
                    lookingFor = "to provide info on what /bcolleges look for/b"
                case .to_find_a_support_system_in_college:
                    lookingFor = "that can provide a /bsupport system/b in college"
                case .to_help_with_college_entrance_tests:
                    lookingFor = "to help with college /bentrance tests/b"
                case .to_help_with_essays:
                    lookingFor = "to help with /bessays/b"
                default:
                    break
            }
            
            let kindOfCollege = DatabaseValue(name: data![DatabaseKey.How_Do_You_Feel_About_Applying.name]!) == .i_dont_know ?
                "/bdoesn't know/b what types of colleges they're interested in" :
                "is interested in /b\(DatabaseValue(name: data![DatabaseKey.What_Kind_Of_College_Are_You_Considering.name]!)!.rawValue)/b"
            
            let sentenceString = """
            \(firstName) is a /b\(highSchoolYear)/b in high school, and is interested in /b\(interest)/b. \
            ln regards to the college application process, \(firstName) \(whereInProcess). \
            \(firstName) is looking for someone /b\(lookingFor)/b, and \(kindOfCollege).
            """
            
            sentence.attributedText = Utilities.indigoWhiteText(text: sentenceString)
        } else if data![DatabaseKey.Account_Type.name]! == DatabaseValue.mentor.name {
            let schoolYear = DatabaseValue(name: data![DatabaseKey.What_Year_Of_College.name]!)!.rawValue
            let degree = DatabaseValue(name: data![DatabaseKey.What_Kind_Of_Degree_Are_You_Currently_Pursuing.name]!)!.rawValue
            let major = DatabaseValue(name: data![DatabaseKey.What_Field_Of_Study_Are_You_Currently_Pursuing.name]!)!.rawValue
            let university = data![DatabaseKey.What_College_Do_You_Attend.name]!
            let testScore = data![DatabaseKey.Test_Score.name]!
            let testTaken = DatabaseValue(name: data![DatabaseKey.Which_Test_Did_You_Use_For_Your_College_Application.name]!)!.rawValue
            let highSchoolGPA = DatabaseValue(name: data![DatabaseKey.What_Was_Your_High_School_GPA.name]!)!.rawValue
            let firstGenerationStatus = DatabaseValue(name: data![DatabaseKey.Did_Either_Of_Your_Parents_Attend_Higher_Education.name]!)!
            let firstGenerationString = firstGenerationStatus == .yes ? "isn't" : "is"
            let firstLanguge = data![DatabaseKey.First_Language.name]!
            
            let testingString = testTaken == DatabaseValue.other_or_none.rawValue ?
                "applied to college /bwithout/b the SAT or ACT" :
                "applied to college with a /b\(testScore)/b on the /b\(testTaken)/b exam"
            
            var whyTheyWantToBeCounselor = ""
            
            switch DatabaseValue(name: data![DatabaseKey.Why_Do_You_Want_To_Be_A_Peer_Guidance_Counselor.name]!) {
                case .you_wish_something_like_this_existed_for_you:
                    whyTheyWantToBeCounselor = "they wish they knew /bsomething like this/b existed for them"
                case .you_can_help_write_strong_essays:
                    whyTheyWantToBeCounselor = "they can help write /bstrong essays/b"
                case .you_scored_well_on_admissions_tests:
                    whyTheyWantToBeCounselor = "they /bscored well/b on admissions tests"
                case .you_can_socially_or_emotionally_support_mentees:
                    whyTheyWantToBeCounselor = "they can /bsocially and emotionally/b support you"
                case .something_else:
                    whyTheyWantToBeCounselor = "of an /bUnspecified Reason/b"
                default:
                    break
            }
            
            let sentenceString = """
            \(firstName) is a /b\(schoolYear)/b pursuing a /b\(degree)/b degree as a(n) /b\(major)/b major at /b\(university)/b. \
            \(firstName) \(testingString), and with a GPA of /b\(highSchoolGPA)/b. \
            \(firstName) /b\(firstGenerationString)/b a first generation college student, and their first language is /b\(firstLanguge)/b. \
            \(firstName) wants to be your counselor because \(whyTheyWantToBeCounselor).
            """
            
            sentence.attributedText = Utilities.indigoWhiteText(text: sentenceString)
        }
    }
    
    func downloadImage(url: URL, imageView: UIImageView) {
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async { // Make sure you're on the main thread here
                imageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    @IBOutlet weak var button: DesignableButton!
    @IBOutlet weak var firstname: UILabel!
    @IBOutlet weak var state: UILabel!
    @IBOutlet weak var blurb: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sentence: UILabel!
    @IBOutlet weak var messageAddMentorButton: DesignableButton!
    @IBOutlet weak var viewProfileButton: DesignableButton!
    
    @IBAction func addMentorMessageButtonPressed(_ sender: UIButton) {
                
        if sender.titleLabel?.text == "Add Mentor" {
            data![DatabaseKey.Relative_Status.name] = DatabaseValue.matched.name
            Firestore.firestore()
                .collection(DatabaseKey.Users.name)
                .document(Auth.auth().currentUser!.uid)
                .collection(DatabaseKey.Allow_List.name)
                .document(data![DatabaseKey.UID.name]!)
                .setData([DatabaseKey.Relative_Status.name: DatabaseValue.matched.name], merge: true)
            sender.backgroundColor = .systemIndigo
            sender.setTitle("Message", for: .normal)
            let alertController = UIAlertController(title: "Mentor Added!",
                                                    message: "Congrats, you've added a mentor! Now you can message them, and they can message you.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            let window: UIWindow = (UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first)!
            window.rootViewController!.present(alertController, animated: true, completion: nil)
            return
        }
        
        let viewController = ChatViewController()
        
        if HomeViewController.currentUserData?[DatabaseKey.Account_Type.name] == DatabaseValue.student.name {
            viewController.identifier = "\(data![DatabaseKey.UID.name]!)-\(Auth.auth().currentUser!.uid)"
            print("set ChatVC ID to \(viewController.identifier)")
        } else if HomeViewController.currentUserData?[DatabaseKey.Account_Type.name] == DatabaseValue.mentor.name {
            viewController.identifier = "\(Auth.auth().currentUser!.uid)-\(data![DatabaseKey.UID.name]!)"
            print("set ChatVC ID to \(viewController.identifier)")
        }
        
        viewController.header = data![DatabaseKey.First_Name.name]!
        viewController.customCell = self
        viewController.remoteReceiverImage = imageView.image
        viewController.currentSenderImage = HomeViewController.currentUserImage
        
        let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
        
        if let navigationController = keyWindow?.rootViewController as? UINavigationController {
        //Do something
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.pushViewController(viewController, animated: true)
        }
    }
    
    @IBAction func viewProfileButtonPressed(_ sender: Any) {
        
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ProfileVC") as? ProfileVC else {
            Utilities.logError(customMessage: "Storyboard Instantiation Error", customCode: 1)
            return
        }
        
        viewController.customCell = self
        
        let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
        
        if let navigationController = keyWindow?.rootViewController as? UINavigationController {
        //Do something
            navigationController.navigationBar.prefersLargeTitles = false
            navigationController.pushViewController(viewController, animated: true)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
