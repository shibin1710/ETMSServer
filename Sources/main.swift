import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import MongoDB

// Create HTTP server.
let server = HTTPServer()

// Register your own routes and handlers
var routes = Routes()
routes.add(method: .post, uri: "/signup", handler: {
    request, response in
    
    guard let email = request.param(name: "email"), let password = request.param(name: "password"), let name = request.param(name: "name"), let phoneNumber = request.param(name: "phoneNumber") else {
        
        let errorJSON = ["code" : "1000", "description" : "Invalid request."]
        let responseJSON = ["success" : "false","error" : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }

    let client = try! MongoClient(uri: "mongodb://shibin:shibin@ds151127.mlab.com:51127/transport")
    let db = client.getDatabase(name: "transport")
    
    // define collection
    guard let collection = db.getCollection(name: "credentials") else {
        
        let errorJSON = ["code" : "1001", "description" : "Error connecting to database."]
        let responseJSON = ["success" : "false","error" : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    // Here we clean up our connection,
    // by backing out in reverse order created
    defer {
        collection.close()
        db.close()
        client.close()
    }
    
    let filterBSON = try! BSON(json: "{\"email\" : \"\(email)\"}")
    let filterResults = collection.find(query:filterBSON)
    
    // Initialize empty array to receive formatted results
    var responseData = [String]()
    
    for result in filterResults! {
        responseData.append(result.asString)
    }
    
    guard responseData.count == 0 else {
        let errorJSON = ["code" : "1002", "description" : "User already exist."]
        let responseJSON = ["success" : "false","error" : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    
    let bson = BSON()
    bson.append(key: "email", string: email)
    bson.append(key: "password", string: password)
    bson.append(key: "name", string: name)
    bson.append(key: "phoneNumber", string: phoneNumber)

    let status:MongoResult = collection.insert(document: bson)
    
    switch status {
        
        case .success:
        
            let userDetailJSON = ["name" : name, "email" : email, "phoneNumber" : phoneNumber]
            let responseJSON = ["success" : "true","responseDictionary" : userDetailJSON] as [String : Any]
        
            do {
                try response.setBody(json: responseJSON)
            } catch {
                print("Error : ",error)
            }
        
            response.completed()
    
        default:
        
            let errorJSON = ["code" : "1003", "description" : "Error while inserting to database."]
            let responseJSON = ["success" : "false","error" : errorJSON] as [String : Any]
        
            do {
                try response.setBody(json: responseJSON)
            } catch {
                print("Error : ",error)
            }
        
            response.completed()
            return
        }
    }
)

routes.add(method: .post, uri: "/login", handler: {
    request, response in
    
    let username = request.param(name: "username")
    let password = request.param(name: "password")
    
    //    let client = try! MongoClient(uri: "mongodb://localhost")
    let client = try! MongoClient(uri: "mongodb://shibin:shibin@ds151127.mlab.com:51127/transport")
    
    
    let db = client.getDatabase(name: "transport")
    
    // define collection
    guard let collection = db.getCollection(name: "credentials") else {
        return
    }
    
    // Here we clean up our connection,
    // by backing out in reverse order created
    defer {
        collection.close()
        db.close()
        client.close()
    }
    
    
    // Perform a "find" on the perviously defined collection
    
    let str = "username : \(username!)"
    let bson = try! BSON(json: "{\"username\" : \"\(username!)\",\"password\" : \"\(password!)\"}")
    let result = collection.find(query:bson)
    
    // Initialize empty array to receive formatted results
    var responseData = [String]()
    
    for x in result! {
        responseData.append(x.asString)
    }
    
    // return a formatted JSON array.
    //    let responseJSON = "{\"data\":[\(arr.joined(separator: ","))]}"
    
    if responseData.count == 0 {
        response.appendBody(string: "{\"success\":false}")
    } else {
        response.appendBody(string: "{\"success\":true}")
        
    }
    
    response.completed()
    }
)

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port of 8181
server.serverPort = 8082

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
