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
    
    
    
    let filterBSON = try! BSON(json: "{\"username\" : \"\(username!)\"}")
    let result = collection.find(query:filterBSON)
    
    // Initialize empty array to receive formatted results
    var responseData = [String]()
    
    for x in result! {
        responseData.append(x.asString)
    }
    
    // return a formatted JSON array.
    //    let responseJSON = "{\"data\":[\(arr.joined(separator: ","))]}"
    
    
    guard responseData.count == 0 else {
        response.appendBody(string: "{\"success\":false}")
        response.completed()
        return
    }
    
    
    let bson = BSON()
    bson.append(key: "username", string: username!)
    bson.append(key: "password", string: password!)
    
    let status = collection.insert(document: bson)
    
    response.appendBody(string: "{\"success\":true}")
    
    
    //    if status ==    {
    //        response.appendBody(string: "{\"success\":true}")
    //    } else {
    //        response.appendBody(string: "{\"success\":false}")
    //
    //    }
    
    response.completed()
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
