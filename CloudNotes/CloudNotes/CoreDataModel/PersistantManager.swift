//
//  PersistantManager.swift
//  CloudNotes
//
//  Created by 이호영 on 2022/02/16.
//

import Foundation
import CoreData

class PersistantManager {
    lazy var notes: [Note] = self.fetch()
    
    func save(noteInformation: NoteInformation) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(
            forEntityName: "Note",
            into: context
        )
        object.setValue(noteInformation.title, forKey: "title")
        object.setValue(noteInformation.content, forKey: "content")
        object.setValue(noteInformation.lastModifiedDate, forKey: "lastModifiedDate")
        
        CoreDataStack.shared.saveContext()
    }
    
    func delete(object: NSManagedObject) {
        let context = CoreDataStack.shared.context
        context.delete(object)
        CoreDataStack.shared.saveContext()
    }
    
    func fetch() -> [Note] {
        let fetchRequest = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "lastModifiedDate", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        do {
            return try CoreDataStack.shared.context.fetch(fetchRequest)
        } catch {
            print(error)
            return []
        }
    }
    
    func update(object: NSManagedObject, noteInformation: NoteInformation) {
        object.setValue(noteInformation.title, forKey: "title")
        object.setValue(noteInformation.content, forKey: "content")
        object.setValue(noteInformation.lastModifiedDate, forKey: "lastModifiedDate")
        
        CoreDataStack.shared.saveContext()
    }
}
