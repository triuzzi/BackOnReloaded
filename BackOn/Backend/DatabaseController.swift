//
//  DatabaseController.swift
//  BackOn
//
//  Created by Giancarlo Sorrentino on 18/02/2020.
//  Copyright © 2020 Giancarlo Sorrentino. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON


struct ServerRoutes {
    private static let mainRoute = "https://8d5da3a1.ngrok.io/api"
    private static let signupRoute = "/auth/signin"
    private static let getUserByIDRoute = "/auth/getUserByid"
    private static let getBondByIDRoute = "/tasks/bond"
    private static let getMyBondsRoute = "/tasks/getTasks"
    private static let removeTaskRoute = "/tasks/cancelTask"
    private static let removeRequestRoute = "/tasks/deleteRequest"
    private static let discoverRoute = "/tasks/discover"
    private static let addRequestRoute = "/tasks/addRequest"
    private static let addTaskRoute = "/tasks/addTask"
    
    static func signUp() -> String{
        return mainRoute + signupRoute
    }
    static func getUserByID () -> String{
        return mainRoute + getUserByIDRoute
    }
    static func getBondByID() -> String{
//        print("\n\n\n" + id)
        return mainRoute + getBondByIDRoute
    }
    static func getMyBonds () -> String{
        return mainRoute + getMyBondsRoute
    }
    static func removeTasks(id: String) -> String{
        return mainRoute + removeTaskRoute + "/" + id
    }
    static func removeRequest (id: String) -> String{
        return mainRoute + removeRequestRoute + "/" + id
    }
    static func discover() -> String{
        return mainRoute + discoverRoute
    }
    static func addRequest () -> String{
        return mainRoute + addRequestRoute
    }
    static func addTask() -> String{
        return mainRoute + addTaskRoute
    }
}

var users: [String:User] = [:]
let serverDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter
}()

struct DatabaseController {
    //    MARK: SignUp
    //    Updating the current user and adding it to the databbase if absent
    static func signUp(name: String, surname: String?, email: String, photoURL: URL, completion: @escaping (User?, ErrorString?)-> Void) {
        print("createNewUser")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["name": name, "surname": surname ?? "", "email" : email, "photo": "\(photoURL)"]
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.signUp())!)
        request.httpMethod = "POST" //set http method as POST
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, "Error in " + #function + " client error: " + error.localizedDescription)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, "Error in " + #function + ": " + error!.localizedDescription)}
            if let data = data {
                if let jsonResponse = try? JSON(data: data){
                    let _id = jsonResponse["_id"].stringValue
                        completion(User(name: name, surname: surname, email: email, photoURL: photoURL, _id: _id), nil)
                    }
            }
        }.resume()
        
    }  ///FINITA, GESTIONE DELL'ERRORE DA FARE
    
    //MARK: GetUserByID
    //Get a user from its id
    static func getUserByID(id: String, completion: @escaping (User?, ErrorString?)-> Void){
        print("getUserByID")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["_id": id]
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.getUserByID())!)
        request.httpMethod = "POST" //set http method as POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, "Error in" + #function + "client error: " + error.localizedDescription)
        }
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, "Error in " + #function + ": " + error!.localizedDescription)}
            if let data = data {
                if let jsonResponse = try? JSON(data: data){
                    let name = jsonResponse["name"].stringValue
                    let email = jsonResponse["email"].stringValue
                    let surname = jsonResponse["surname"].stringValue
                    let photoURL = URL(string: jsonResponse["photo"].stringValue)!
                    completion(User(name: name, surname: surname, email: email, photoURL: photoURL, _id: id), nil)
                }
            }
        }.resume()
    }  ///FINITA, GESTIONE DELL'ERRORE DA FARE
    
    //MARK: GetBondByID
    //Get a user's request or task from its id
//    static func getBondByID(id: String, completion: @escaping ((Task?, User?), ErrorString?)-> Void){
//        print("getBondByID")
//
//        let parameters: [String: String] = ["_id": id]
//        print(parameters)
//        //now create the URLRequest object using the url object
//        var request = URLRequest(url: URL(string: ServerRoutes.getBondByID())!)
//        request.httpMethod = "POST" //set http method as POST
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
//        } catch let error {
//            completion(nil, "Error in" + #function + "client error: " + error.localizedDescription)
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard error == nil else {return completion(nil, "Error in " + #function + ": " + error!.localizedDescription)}
////            print(data ?? "O-OH!")
////            print("Faccio l'if!")
//            if let data = data {
////                print("Hey,sono qui!")
//                if let jsonResponse = try? JSON(data: data){
////                    print("Ci entro!")
//                    let neederID = jsonResponse["neederID"].stringValue
//                    print(neederID)
//                    let title = jsonResponse["title"].stringValue
//                    let descr = jsonResponse["description"].stringValue
////                    let date = serverDateFormatter.date(from: jsonResponse["date"].stringValue)!
//                    let date = Date()
//                    let latitude =  jsonResponse["latitude"].doubleValue
//                    let longitude = jsonResponse["longitude"].doubleValue
//                    let id = jsonResponse["_id"].stringValue
//                    let helperID = jsonResponse["helperID"].stringValue
//                    completion(Task(neederID: neederID, helperID: helperID == "" ? nil : helperID, title: title, descr: descr == "" ? nil : descr, date: date, latitude: latitude, longitude: longitude, _id: id), nil)
//                }
//            }
//        }.resume()
//    }  ///FINITA, GESTIONE DELL'ERRORE DA FARE
    
    //MARK: GetMyTasks
    //Get a user's task' ids and, if absent, adds it into the database
    static func getMyTasks(completion: @escaping ([Task]?, [User]?, ErrorString?)-> Void){
        print("getTasks")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["helperID": CoreDataController.loggedUser!._id]
        print(parameters)
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.getMyBonds())!)
        request.httpMethod = "POST" //set http method as POST
        
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, nil, "Error in" + #function + "client error: " + error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, nil, "Error in " + #function + ": " + error!.localizedDescription)}
            if let data = data {
                if let jsonArray = try? JSON(data: data){
//                    var idSet: Set<String> = []
                    var newTasks: [Task] = []
                    var newUsers: [User] = []
                    for (_,task):(String, JSON) in jsonArray {
                        let taskID = task["_id"].stringValue
//                        print("id arrivato nella getTasks: \(taskid)")
//                        idSet.insert(taskid)
                    }
                    completion(newTasks, newUsers, nil)
                }
            }
        
            
        }.resume()
    }  ///FINITA, GESTIONE DELL'ERRORE DA FARE
    
    //MARK: GetMyRequests
    //Get a user's task' ids
    static func getMyRequests(completion: @escaping ([Task]?, [User]?, ErrorString?)-> Void){
        print("getRequests")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["neederID": CoreDataController.loggedUser!._id]
        print(parameters)
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.getMyBonds())!)
        request.httpMethod = "POST" //set http method as POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, nil, "Error in" + #function + "client error: " + error.localizedDescription)
        }
        
        
        
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, nil, "Error in " + #function + ": " + error!.localizedDescription)}

            if let data = data {
                if let jsonArray = try? JSON(data: data){
//                    var idSet: Set<String> = []
                    var newRequests: [Task] = []
                    var newUsers: [User] = []
                    for (_,request):(String, JSON) in jsonArray {
                        let requestid = request["_id"].stringValue
//                        print("id arrivato nella getRequests: \(requestid)")
//                        idSet.insert(requestid)
//                        print("\n\nrequest id ottenuto nella get requests: " + requestid)
//                        if shared.myRequests[requestid] == nil {getBondByID(id: requestid)}
//                        for requestid in shared.myRequests.keys {
//                            if !idSet.contains(requestid) {shared.myRequests[requestid] = nil}
//                        }
                    }
                    completion(newRequests, newUsers, nil)

                }
            }
        }.resume()
    }  ///FINITA, GESTIONE DELL'ERRORE DA FARE
    
    //MARK: AddRequest
    //Adding a request from current user
    static func addRequest(title: String, description: String?, date: Date, coordinates: CLLocationCoordinate2D, completion: @escaping (Task?, ErrorString?)-> Void){
        print("addRequest")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: Any] = ["title": title, "description": description ?? "" , "neederID" : CoreDataController.getLoggedUser()!._id, "date": serverDateFormatter.string(from: date), "latitude": coordinates.latitude , "longitude": coordinates.longitude]
        print(parameters)
        
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.addRequest())!)
        request.httpMethod = "POST" //set http method as POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, "Error in" + #function + "client error: " + error.localizedDescription)
        }
        
        
        
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, "Error in " + #function + ": " + error!.localizedDescription)}
//            print("DATA:\n" + "\(data)")
//            print("\n\nRESPONSE:\n" + "\(response)")
            if let data = data {
                if let jsonResponse = try? JSON(data: data){
                    let _id = jsonResponse["_id"].stringValue
                    completion(Task(neederID: CoreDataController.getLoggedUser()!._id, helperID: nil, title: title, descr: description, date: date, latitude: coordinates.latitude, longitude: coordinates.longitude, _id: _id), nil)
                }
                
            }
        }.resume()
    } //Error handling missing, but should work
    
    //MARK: AddTask
    //Adding a task for current user
    static func addTask(toAccept: Task, completion: @escaping (ErrorString?)-> Void){
        print("addTask")
        
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["_id": toAccept._id, "helperID": CoreDataController.loggedUser!._id]
        print(parameters)
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.addTask())!)
        request.httpMethod = "PUT" //set http method as POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion("Error in" + #function + "client error: " + error.localizedDescription)
        }
        
        
        
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion("Error in " + #function + ": " + error!.localizedDescription)}
//            print(data)
//            print(request)
//            print(error)
            guard error == nil else {print ("ERRORE!") ; return}
            if let responseCode = (response as? HTTPURLResponse)?.statusCode {
                guard responseCode == 200 else {completion("Invalid response code in \(#function): \(responseCode)"); return}
                completion(nil)
            }
        }.resume()
    } //Error handling missing, but should work
    
    //MARK: RemoveRequest
    //Removes a request by its id
    static func removeRequest(requestid: String, completion: @escaping (ErrorString?)-> Void){
        removeBond(idToRemove: requestid, isRequest: true, completion: completion)
    }
    
    //MARK: RemoveTask
    //Removes a task by its id
    static func removeTask(taskid: String, completion: @escaping (ErrorString?)-> Void){
        removeBond(idToRemove: taskid, isRequest: false, completion: completion)
    }
    
    private static func removeBond(idToRemove: String, isRequest: Bool, completion: @escaping (ErrorString?)-> Void){
        print("removeBond")
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String: String] = ["_id": idToRemove]
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: isRequest ? ServerRoutes.removeRequest(id: idToRemove) : ServerRoutes.removeTasks(id: idToRemove))!)
        request.httpMethod = isRequest ? "DELETE" : "PUT" //set http method as POST
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion("Error in" + #function + "client error: " + error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion("Error in " + #function + " opering with a" + (isRequest ? "request:" : "task:") + error!.localizedDescription)}
            if let responseCode = (response as? HTTPURLResponse)?.statusCode {
            guard responseCode == 200 else {
                completion("Invalid response code in \(#function): \(responseCode)")
                return
            }
                completion(nil)
            }
        }.resume()
    }
    
    static func updateCathegories(lastUpdate: Date){
        //Chiede l'ultima data di aggiornamento delle categorie di request al db e, se diversa da quella che ha internamente, richiede al db di inviarle e le aggiorna
        //Apro la connessione, ottengo la data, se diversa faccio la richiesta altrimenti chiudo
    }
    
    static func discover(completion: @escaping ([Task]?, [User]?, ErrorString?)-> Void){
        print("discover")
        let parameters: [String: String] = ["neederID": CoreDataController.loggedUser!._id]
        print(CoreDataController.loggedUser!._id)
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: URL(string: ServerRoutes.discover())!)
        request.httpMethod = "POST" //set http method as GET
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            completion(nil, nil, "Error in" + #function + "client error: " + error.localizedDescription)
        }
        //create dataTask using the session object to send data to the server
        
        //Next method is to get rerver response
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {return completion(nil, nil, "Error in " + #function + ": " + error!.localizedDescription)}
            if let data = data {
                if let jsonArray = try? JSON(data: data){
                    var discoverableTasks: [Task] = []
                    var discoveraleUsers: [User] = []
                    for (_,discoverable):(String, JSON) in jsonArray {
                        let neederID = discoverable["neederID"].stringValue
                        let title = discoverable["title"].stringValue
                        let descr = discoverable["description"].string
                        let date = Date()
//                            serverDateFormatter.date(from: discoverable["date"].stringValue)!
                        let latitude =  discoverable["latitude"].doubleValue
                        let longitude = discoverable["longitude"].doubleValue
                        let id = discoverable["_id"].stringValue
                        let helperID = discoverable["helperID"].string
//                        print("\n\n\nAO CI ARRIVO")
//                        print(discoverable)
                        
                        completion(discoverableTasks, discoveraleUsers, nil)
                       
                    }
                }
            }
        }.resume()
    }
    
    
    
    
}

