import Foundation

// * Create the `Todo` struct.
// * Ensure it has properties: id (UUID), title (String), and isCompleted (Bool).
struct Todo: Identifiable, Codable, CustomStringConvertible {
    var id: UUID
    var title: String
    var isCompleted: Bool
    
    var description: String {
        isCompleted ? "\(title) - ✅" : "\(title) - ❌"
    }
}

// Create the `Cache` protocol that defines the following method signatures:
//  `func save(todos: [Todo])`: Persists the given todos.
//  `func load() -> [Todo]?`: Retrieves and returns the saved todos, or nil if none exist.
protocol Cache {
    func save(todos: [Todo])
    func load() -> [Todo]?
}

// `FileSystemCache`: This implementation should utilize the file system
// to persist and retrieve the list of todos.
// Utilize Swift's `FileManager` to handle file operations.
final class JSONFileManagerCache: Cache {
    private let fileName = "todos.json"
    private var fileURL: URL {
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return currentDirectoryURL.appendingPathComponent(fileName)
    }
    
    func save(todos: [Todo]) {
        do {
            let data = try JSONEncoder().encode(todos)
            try data.write(to: fileURL)
        } catch {
            print("⛔ Failed to save todos: \(error)")
        }
    }
    
    func load() -> [Todo]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            guard !data.isEmpty else {
                return []
            }
            
            let todos = try JSONDecoder().decode([Todo].self, from: data)
            return todos
        } catch {
            print("⛔ Failed to load todos: \(error)")
            return nil
        }
    }
}

// `InMemoryCache`: : Keeps todos in an array or similar structure during the session.
// This won't retain todos across different app launches,
// but serves as a quick in-session cache.
final class InMemoryCache: Cache {
    private var todos: [Todo] = []
    
    func save(todos: [Todo]) {
        self.todos = todos
    }
    
    func load() -> [Todo]? {
        return todos.isEmpty ? nil : todos
    }
}

// The `TodosManager` class should have:
// * A function `func listTodos()` to display all todos.
// * A function named `func addTodo(with title: String)` to insert a new todo.
// * A function named `func toggleCompletion(forTodoAtIndex index: Int)`
//   to alter the completion status of a specific todo using its index.
// * A function named `func deleteTodo(atIndex index: Int)` to remove a todo using its index.
final class TodoManager {
    var todos: [Todo]
    var cache: Cache
    
    func listTodos() {
        print("Your todo list 📋: ")
        for (index, todo) in todos.enumerated() {
            print("\(index + 1).) \(todo)")
        }
    }
    
    func addTodo(with title: String) {
        let todoToAdd = Todo(id: UUID(), title: title, isCompleted: false)
        todos.append(todoToAdd)
        print("\"\(todoToAdd)\" added to list ✍🏾.")
        cache.save(todos: todos)
    }
    
    func toggleCompletion(forTodoAtIndex index: Int) {
        guard index >= 0 && index < todos.count else {
            print("⛔ Please enter a valid number in the list to select a todo to toggle.")
            return
        }
        
        todos[index].isCompleted.toggle()
        cache.save(todos: todos)
        let toggleMessage = "\"\(todos[index].title)\" has been set to"
        todos[index].isCompleted ? print("\(toggleMessage) complete ✅.") : print("\(toggleMessage) incomplete ❌.")
    }
    
    func deleteTodo(atIndex index: Int) {
        guard index >= 0 && index < todos.count else {
            print("⛔ Please enter a valid number in the list to select a todo to delete.")
            return
        }
        
        let todoToDelete = todos.remove(at: index)
        print("\"\(todoToDelete)\" deleted from list.")
        cache.save(todos: todos)
    }
    
    init(cache: Cache) {
        self.cache = cache
        todos = cache.load() ?? []
    }
}


// * The `App` class should have a `func run()` method, this method should perpetually
//   await user input and execute commands.
//  * Implement a `Command` enum to specify user commands. Include cases
//    such as `add`, `list`, `toggle`, `delete`, and `exit`.
//  * The enum should be nested inside the definition of the `App` class
final class App {
    enum Command: String {
        case add
        case list
        case toggle
        case delete
        case exit
    }
    
    func run() {
        let todoManager = TodoManager(cache: JSONFileManagerCache())
        
        print("⚡ The Todos CLI ⚡")
        
        while true {
            print("What would you like to do? (add, list, toggle, delete, exit): ", terminator: "")
            let userInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let command = Command(rawValue: userInput ?? "")
            
            switch command {
            case .add:
                print("Enter todo title: ", terminator: "")
                guard let todoToAdd = readLine() else {
                    continue
                }
                todoManager.addTodo(with: todoToAdd)
            case .list:
                todoManager.listTodos()
            case .toggle:
                todoManager.listTodos()
                print("Type in the number of the todo you want to toggle: ", terminator: "")
                guard let userInput = readLine() else {
                    continue
                }
                
                guard let numberEntered = Int(userInput) else {
                    print("⛔ Invalid input. Please enter a number.")
                    continue
                }
                
                todoManager.toggleCompletion(forTodoAtIndex: numberEntered - 1)
            case .delete:
                todoManager.listTodos()
                print("Type in the number of the todo you want to delete: ", terminator: "")
                guard let userInput = readLine() else {
                    continue
                }
                
                guard let numberEntered = Int(userInput) else {
                    print("⛔ Invalid input. Please enter a number.")
                    continue
                }
                
                todoManager.deleteTodo(atIndex: numberEntered - 1)
            case .exit:
                print("Goodbye 👋🏾")
                exit(0)
            default:
                print("Sorry, command not recognized. Please try again.")
            }
        }
    }
}


// TODO: Write code to set up and run the app.
let app = App()
app.run()



