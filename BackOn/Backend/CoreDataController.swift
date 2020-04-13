//
//  CoreDataController.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 15/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI


class CoreDataController {
    static var loggedUser: User?
    static var deviceToken: String?
    static var persistentContainer: NSPersistentContainer?
    static var context: NSManagedObjectContext?
    
    static func initController() {
        persistentContainer = NSPersistentContainer(name: "BackOn")
        persistentContainer!.loadPersistentStores(completionHandler: { (_, error) in
            guard error == nil else {fatalError("Unresolved error \(error!)")}
            context = persistentContainer!.newBackgroundContext()
            loggedUser = getLoggedUser()
            deviceToken = getDeviceToken()
        })
    }
    
    static func saveContext() throws {
        if context!.hasChanges {
            try context!.save()
            print("*** CD - Context saved! ***")
        } else {print("*** CD - Context hasn't got any change! ***")}
    }
    
    static func loadInShared() {
        let cachedUsers = getCachedUsers()
        let cachedTasks = getCachedTasks()
        let today = Date()
        for user in cachedUsers {
            DispatchQueue.main.async {(UIApplication.shared.delegate as! AppDelegate).shared.users[user._id] = user}
        }
        for task in cachedTasks {
            if task.neederID == loggedUser!._id { // è una mia request
                if task.date < today { // è scaduta
                    if task.date < today.advanced(by: -259200) { // è scaduta da più di 3 giorni
                        deleteTask(task: task, save: false)
                    } else { // è scaduta da meno di 3 giorni
                        if task.address == "Locating..." {task.locate()}
                        DispatchQueue.main.async {(UIApplication.shared.delegate as! AppDelegate).shared.myExpiredRequests[task._id] = task}
                    }
                } else { // è attiva
                    if task.address == "Locating..." {task.locate()}
                    DispatchQueue.main.async {(UIApplication.shared.delegate as! AppDelegate).shared.myRequests[task._id] = task}
                }
            } else {
                if task.helperID == loggedUser!._id { // è un mio task
                    if task.date < today { // è scaduto
                        if task.date < today.advanced(by: -259200) { // è scaduto da più di 3 giorni
                            deleteTask(task: task, save: false)
                        } else { // è scaduto da meno di 3 giorni
                            if task.address == "Locating..." {task.locate()}
                            DispatchQueue.main.async {(UIApplication.shared.delegate as! AppDelegate).shared.myExpiredTasks[task._id] = task}
                        }
                    } else { // è attivo
                        DispatchQueue.main.async {(UIApplication.shared.delegate as! AppDelegate).shared.myTasks[task._id] = task}
                        if task.address == "Locating..." {task.locate()}
                        if task.mapSnap == nil {
                            MapController.getSnapshot(location: task.position.coordinate){ snapshot, error in
                                guard error == nil, let snapshot = snapshot else {print("Error while getting snapshot in loadInShared");return}
                                task.mapSnap = snapshot.image
                            }
                        }
                    }
                } else {
                    print("\nloadInShared - inconsistent state for\n\(task)\n")
                    deleteTask(task: task, save: false)
                }
            }
        }
        do {
            try saveContext()
        } catch {print("\nError in loadFromCoreData while saving context\n")}
    }
    
    static func saveDeviceToken(deviceToken: String?){
        print("*** CD - \(#function) ***")
        guard let deviceToken = deviceToken, self.deviceToken == nil else {return} // prima era getDeviceToken() == nil
        let entity = NSEntityDescription.entity(forEntityName: "PDeviceToken", in: context!)
        let newToken = PDeviceToken(entity: entity!, insertInto: context)
        newToken.token = deviceToken
        do {
            try saveContext()
            print("\nSaving context from \(#function)\n")
        } catch {print("Error while saving \(newToken.token!) in memory! The error is:\n\(error)\n");return}
        print("Device token \(deviceToken) saved in memory")
        self.deviceToken = deviceToken
    }
    
    static func getDeviceToken() -> String? {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PDeviceToken> = PDeviceToken.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            guard let temp = array.first else {print("Token not saved yet"); return nil}
            let token = temp.token
            print("DeviceToken from CD is " + (token ?? "Token unavailable"))
            return token
        } catch {print("\nError while getting device token: \(error.localizedDescription)\n");return nil}
    }
    
    static func signUp(user: User) {
        print("*** CD - \(#function) ***")
        let entity = NSEntityDescription.entity(forEntityName: "PLoggedUser", in: context!)
        let newUser = PLoggedUser(entity: entity!, insertInto: context)
        newUser.name = user.name
        newUser.surname = user.surname
        newUser.email = user.email
        newUser.photoURL = user.photoURL
        newUser.photoData = user.photo?.jpegData(compressionQuality: 1)
        newUser.id = user._id
        do {
            try saveContext()
            print("\nSaving context from \(#function)\n")
        } catch {print("Error while saving \(newUser.name!) in memory! The error is:\n\(error)\n");return}
        print("\(user.name) saved in memory")
        loggedUser = user
    }
    
    static func getLoggedUser() -> User? {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PLoggedUser> = PLoggedUser.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            guard let temp = array.first else {print("User not logged yet"); return nil}
            let loggedUser = User(
                _id: temp.id!,
                name: temp.name!,
                surname: temp.surname,
                email: temp.email!,
                photoURL: temp.photoURL,
                photo: temp.photoData == nil ? nil : UIImage(data: temp.photoData!))
            print("\nLogged user is \(loggedUser)")
            return loggedUser
        } catch {print("\nError while getting logged user: \(error.localizedDescription)\n");return nil}
    }
    
    static func deleteLoggedUser() {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PLoggedUser> = PLoggedUser.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            for loggedUser in array {
                context!.delete(loggedUser)
            }
            try saveContext()
            print("\nSaving context from \(#function)\n")
        } catch {print("\nError while deleting logged user: \(error.localizedDescription)\n");return}
    }
    
    static func addUser(user: User, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let entity = NSEntityDescription.entity(forEntityName: "PUsers", in: context!)
        let newUser = PUsers(entity: entity!, insertInto: context!)
        newUser.name = user.name
        newUser.surname = user.surname
        newUser.email = user.email
        newUser.photoURL = user.photoURL
        newUser.photoData = user.photo?.jpegData(compressionQuality: 1)
        newUser.id = user._id
        print("\n\(user)ready to save in memory\n")
        if save {
            do {
                try saveContext()
                print("Saved in memory")
            } catch {print("\nError while saving \(newUser.name!) in memory! The error is:\n\(error)\n");return}
        }
    }
    
    static func updateUser(user: User, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PUsers> = PUsers.fetchRequest()
        do {
            fetchRequest.predicate = NSPredicate(format: "id = %@", user._id)
            fetchRequest.returnsObjectsAsFaults = false
            let array = try context!.fetch(fetchRequest)
            guard let cachedUser = array.first else {return}
            cachedUser.setValue(user.name, forKey: "name")
            cachedUser.setValue(user.surname, forKey: "surname")
            cachedUser.setValue(user.photo?.jpegData(compressionQuality: 1), forKey: "photoData")
            cachedUser.setValue(user.photoURL, forKey: "photoURL")
            if save {
                try saveContext()
                print("\nSaving context from \(#function)\n")
            }
        } catch {print("\nErrore recupero informazioni dal context \n \(error)\n")}
    }
    
    static func getCachedUsers() -> [User] {
        print("*** CD - \(#function) ***")
        var cachedUsers: [User] = []
        let fetchRequest: NSFetchRequest<PUsers> = PUsers.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            for pUser in array {
                cachedUsers.append(User(
                    _id: pUser.id!,
                    name: pUser.name!,
                    surname: pUser.surname,
                    email: pUser.email!,
                    photoURL: pUser.photoURL!,
                    photo: pUser.photoData == nil ? nil : UIImage(data: pUser.photoData!))
                )
            }
        } catch {print("\nError while getting cached tasks: \(error.localizedDescription)\n")}
        return cachedUsers
    }
    
    static func deleteUser(user: User, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PUsers> = PUsers.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            for pUser in array {
                if pUser.email! == user.email {
                    print("\n\(user)ready to be deleted from memory\n")
                    context!.delete(pUser)
                }
            }
            if save {
                try saveContext()
                print("Deleted from memory")
            }
        } catch {print("\nError while deleting logged user: \(error.localizedDescription)\n");return}
    }
    
    static func addTask(task: Task, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let entity = NSEntityDescription.entity(forEntityName: "PTasks", in: context!)
        let newTask = PTasks(entity: entity!, insertInto: context)
        newTask.id = task._id
        newTask.title = task.title
        newTask.descr = task.descr
        newTask.date = task.date
        newTask.address = task.address
        newTask.city = task.city
        newTask.latitude = task.position.coordinate.latitude
        newTask.longitude = task.position.coordinate.longitude
        newTask.helperID = task.helperID
        newTask.neederID = task.neederID
        newTask.mapSnap = task.mapSnap?.pngData()
        print("\n\(task)ready to save in memory\n")
        if save {
            do {
                try saveContext()
                print("Saved in memory")
            } catch {print("\nError while saving \(task) in memory! The error is:\n\(error)\n");return}
        }
    }
    
    static func updateRequest(request: Task, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PTasks> = PTasks.fetchRequest()
        do {
            fetchRequest.predicate = NSPredicate(format: "id = %@", request._id)
            fetchRequest.returnsObjectsAsFaults = false
            let array = try context!.fetch(fetchRequest)
            guard let cachedTask = array.first else {return}
            cachedTask.setValue(request.helperID, forKey: "helperID")
            if save {
                try saveContext()
                print("\nSaving context from \(#function)\n")
            }
        } catch {
            print("\nErrore recupero informazioni dal context \n \(error)\n")
        }
    }
    
    static func getCachedTasks() -> [Task] {
        print("*** CD - \(#function) ***")
        var cachedTasks: [Task] = []
        let fetchRequest: NSFetchRequest<PTasks> = PTasks.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            for task in array {
                cachedTasks.append(Task(
                    neederID: task.neederID!,
                    helperID: task.helperID,
                    title: task.title!,
                    descr: task.descr,
                    date: task.date!,
                    latitude: task.latitude,
                    longitude: task.longitude,
                    _id: task.id!,
                    mapSnap: task.mapSnap == nil ? nil : UIImage(data: task.mapSnap!),
                    address: task.address,
                    city: task.city))
            }
        } catch {print("\nError while getting cached tasks: \(error.localizedDescription)\n")}
        return cachedTasks
    }
    
    static func deleteTask(task: Task, save: Bool = true) {
        print("*** CD - \(#function) ***")
        let fetchRequest: NSFetchRequest<PTasks> = PTasks.fetchRequest()
        do {
            let array = try context!.fetch(fetchRequest)
            for pTask in array {
                if pTask.id! == task._id {
                    print("\n\(task)ready to be deleted from memory\n")
                    context!.delete(pTask)
                }
            }
            if save {
                try saveContext()
                print("Deleted from memory\n")
            }
        } catch {print("\nError while deleting logged user: \(error.localizedDescription)\n");return}
    }

}
