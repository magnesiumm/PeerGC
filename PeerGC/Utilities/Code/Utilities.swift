//
//  Utilities.swift
//  FBex
//
//  Created by AJ Radik on 1/2/20.
//  Copyright © 2020 AJ Radik. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class Utilities {
    
    static func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAcwvPqgU:APA91bHuy-lLYO2EYgE-CPPRNBOcfs4bE09ovTWoRdHwj1OYNFYE8DL015xD0R5tDF09uiv4Lx3O3cUVEzrQTCq9MrcVjKsPRyHROoJ-M4060uTU9d0urYslX5HoqmkKU_4aJ7OFvbnw", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    static func loadHomeScreen() {
        let window: UIWindow = (UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first)!
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navVC = storyboard.instantiateViewController(identifier: "HomeNavigationController") as! UINavigationController
        let homeVC = navVC.viewControllers.first as! HomeViewController
        
        homeVC.loadView()
        homeVC.awakeFromNib()
        
        homeVC.loadCardLoader {
            navVC.modalPresentationStyle = .overFullScreen
            window.rootViewController = navVC
            window.makeKeyAndVisible()
        }
    }
    
    static func coloredText(text: String, specialColor: UIColor, regularColor: UIColor) -> NSMutableAttributedString {
        let components = text.components(separatedBy: "/b")
        let toReturn = NSMutableAttributedString(string: "")
        
        var makeBlue = false
        
        for component in components {
            if makeBlue {
                let temp = NSMutableAttributedString(string: component)
                temp.addAttribute(NSAttributedString.Key.foregroundColor, value: specialColor, range: NSRange(location:0, length: temp.length))
                toReturn.append(temp)
            }
            
            else {
                let temp = NSMutableAttributedString(string: component)
                temp.addAttribute(NSAttributedString.Key.foregroundColor, value: regularColor, range: NSRange(location:0, length: temp.length))
                toReturn.append(temp)
            }
            
            makeBlue = !makeBlue
        }
        
        return toReturn
    }
    
    static func blueWhiteText(text: String) -> NSMutableAttributedString {
        return coloredText(text: text, specialColor: .systemBlue, regularColor: .white)
    }
    
    static func blueLabelText(text: String) -> NSMutableAttributedString {
        return coloredText(text: text, specialColor: .systemBlue, regularColor: .label)
    }
    
    static func getSimilarZipCodes(zipcode: String) -> [String] {
        let zipCodeValue = Double(getValueByZipCode(zipcode: zipcode)!)
        let path: String? = Bundle.main.path(forResource: "zipCodesToValue", ofType: "csv")
        let dataString = getDataString(path: path)!
        let data = csv(data: dataString)
        
        var zipCodesWrapped: [ZipCodeWrapper] = []
        
        for row in data {
            zipCodesWrapped.append(ZipCodeWrapper(zipcode: row[0], difference: Double(row[1])!-zipCodeValue!))
        }
        
        zipCodesWrapped.sort()
        
        var toReturn: [String] = []
        
        for wrappedZipCode in zipCodesWrapped {
            toReturn.append(wrappedZipCode.zipcode)
        }
        
        return toReturn
    }

    class ZipCodeWrapper: Comparable {

        let zipcode: String
        let difference: Double
        
        init(zipcode: String, difference: Double) {
            self.zipcode = zipcode
            self.difference = abs(difference)
        }
        
        static func < (lhs: Utilities.ZipCodeWrapper, rhs: Utilities.ZipCodeWrapper) -> Bool {
            return lhs.difference < rhs.difference
        }

        static func == (lhs: Utilities.ZipCodeWrapper, rhs: Utilities.ZipCodeWrapper) -> Bool {
            return lhs.difference == rhs.difference
        }

    }
    
    static func zipCodeDoesExist(zipcode: String) -> Bool {
        let path: String? = Bundle.main.path(forResource: "zipCodes", ofType: "txt")
        let dataString = getDataString(path: path)!
        let data = csv(data: dataString)
        
        for row in data {
            if row[0] == zipcode {
                return true
            }
        }
        
        return false
    }
    
    static func getValueByZipCode(zipcode: String) -> String? {
        let path: String? = Bundle.main.path(forResource: "zipCodesToValue", ofType: "csv")
        let dataString = getDataString(path: path)!
        let data = csv(data: dataString)
        
        for row in data {
            if row[0] == zipcode {
                return row[1]
            }
        }
        return nil
    }
    
    static func getCityByZipCode(zipcode: String) -> String? {
        let path: String? = Bundle.main.path(forResource: "zipCodesToLocation", ofType: "csv")
        let dataString = getDataString(path: path)!
        let data = csv(data: dataString)
        
        for row in data {
            if row[0] == zipcode {
                return row[1]
            }
        }
        return nil
    }
    
    static func getStateByZipCode(zipcode: String) -> String? {
         let path: String? = Bundle.main.path(forResource: "zipCodesToLocation", ofType: "csv")
               let dataString = getDataString(path: path)!
               let data = csv(data: dataString)
               
               for row in data {
                   if row[0] == zipcode {
                    return row[2].trimmingCharacters(in: ["\r"])
                   }
               }
               return nil
    }
    
    static func getDataString(path: String?) -> String? {
        do {
            let dataString = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            return dataString
        }
        
        catch let error {
            print(error)
        }
        return nil
    }
    
    static func csv(data: String) -> [[String]] {
           let dataTrimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
           var result: [[String]] = []
           let rows = dataTrimmed.components(separatedBy: "\n")
           for row in rows {
               let columns = row.components(separatedBy: ", ")
               result.append(columns)
           }
           return result
       }
    
    static func createTestUsers() {
        
        var firstNamesString: String? = nil
        var lastNamesString: String? = nil
        var zipCodesString: String? = nil
        
        do {
          
            var path = Bundle.main.path(forResource: "firstNames", ofType: "txt")
            firstNamesString = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            
            path = Bundle.main.path(forResource: "lastNames", ofType: "txt")
            lastNamesString = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            
            path = Bundle.main.path(forResource: "zipCodes", ofType: "txt")
            zipCodesString = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        }
      
        catch let error {
            print(error)
        }
        
        let firstNames: [String] = firstNamesString!.components(separatedBy: "\n")
        let lastNames: [String] = lastNamesString!.components(separatedBy: "\n")
        let zipCodes: [String] = zipCodesString!.components(separatedBy: "\n")
        let accTypes: [String] = ["Student", "Tutor"]
        let genders: [String] = ["Male", "Female", "Other"]
        let interests: [String] =  ["S.T.E.M.", "Arts", "Other"]
        let races: [String] = ["White", "Black", "Native A.", "Asian", "Pacific"]
        
        let NUMBER_OF_USERS = 16
        
        for i in 0..<NUMBER_OF_USERS {
            
            let firstName = firstNames[Int.random(in: 0..<firstNames.count)].trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNames[Int.random(in: 0..<lastNames.count)].trimmingCharacters(in: .whitespacesAndNewlines)
            let email = "\(firstName)\(lastName)@gmail.com"
            let password = "\(firstName)\(lastName)"
            let accType = accTypes[Int.random(in: 0..<accTypes.count)]
            let zipCode = zipCodes[Int.random(in: 0..<zipCodes.count)]
            let gender = genders[Int.random(in: 0..<genders.count)]
            let interest = interests[Int.random(in: 0..<interests.count)]
            let race: String = races[Int.random(in: 0..<races.count)]
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
              
                
                let user = authResult!.user
                
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = "\(firstName) \(lastName)"
                   
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print(error)
                        } else {
                            // Profile updated.
                        }
                    }
                
                let uid = authResult!.user.uid
                Firestore.firestore().collection("users").document(uid).setData(["accountType": accType, "zipCode": zipCode, "gender": gender, "interest": interest, "race": race]) { (error) in
                    
                    if error != nil {
                        // Show error message
                        print("Error saving user data")
                    }
                }
                
                print("created user \(i): \(uid)")
                
            }
            
        }
        
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
