import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import MongoDB
import Foundation

// Routing Constants
let signUpRoute = "/signup"
let loginRoute = "/login"

// Database Constants
let mongoClient = "mongodb://shibin:shibin@ds151127.mlab.com:51127/transport"
let dbName = "transport"
let credentialCollection = "credentials"
let mongoIDKey = "_id"

// Server Constants
let port:UInt16 = 8082

// Error Constants
let errorKey = "error"
let errorCodeKey = "code"
let errorDescriptionKey = "description"

// Success Constants
let successKey = "success"
let successDictionaryKey = "responseDictionary"

// Credentials Collection Names
let emailKey = "email"
let passwordKey = "password"
let nameKey = "name"
let phoneNumberKey = "phoneNumber"

// Error Codes
enum ErrorCode:Int {
    case InvalidRequest = 1000
    case DatabaseConnectionError = 1001
    case UserAlreadyExists = 1002
    case DatabaseInsertionError = 1003
    case UserNotRegistered = 1004
    case ParseError = 1005
    case ServerError = 1006

}

// Create HTTP server.
let server = HTTPServer()

// Register your own routes and handlers
var routes = Routes()

/**************************** Signup Service *******************************/

routes.add(method: .post, uri: signUpRoute, handler: {
    request, response in
    
    if request.params().count != 4 {
        
        let errorJSON = [errorCodeKey : ErrorCode.InvalidRequest.rawValue, errorDescriptionKey : "Invalid request."] as [String : Any]
        let responseJSON = [successKey : false ,errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    guard let email = request.param(name: emailKey), let password = request.param(name: passwordKey), let name = request.param(name: nameKey), let phoneNumber = request.param(name: phoneNumberKey) else {
        
        let errorJSON = [errorCodeKey : ErrorCode.InvalidRequest.rawValue, errorDescriptionKey : "Invalid request."] as [String : Any]
        let responseJSON = [successKey : false ,errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    let client = try! MongoClient(uri: mongoClient)
    let db = client.getDatabase(name: dbName)
    
    // define collection
    guard let collection = db.getCollection(name: credentialCollection) else {
        
        let errorJSON = [errorCodeKey : ErrorCode.DatabaseConnectionError.rawValue, errorDescriptionKey : "Error connecting to database."] as [String : Any]
        let responseJSON = [successKey : false,errorKey : errorJSON] as [String : Any]
        
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
    
    let filterBson = try! BSON(json: "{\"email\" : \"\(email)\"}")
    
    defer {
        filterBson.close()
    }
    
    let filterResults = collection.find(query:filterBson)
    
    // Initialize empty array to receive formatted results
    var responseData = [String]()
    
    for result in filterResults! {
        responseData.append(result.asString)
    }
    
    guard responseData.count == 0 else {
        let errorJSON = [errorCodeKey : ErrorCode.UserAlreadyExists.rawValue, errorDescriptionKey : "User already exist."] as [String : Any]
        let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    
    let bson = BSON()
    
    defer {
        bson.close()
    }
    
    bson.append(key: emailKey, string: email)
    bson.append(key: passwordKey, string: password)
    bson.append(key: nameKey, string: name)
    bson.append(key: phoneNumberKey, string: phoneNumber)
    
    let status:MongoResult = collection.insert(document: bson)
    
    switch status {
        
    case .success:
        
        let userDetailJSON = [nameKey : name, emailKey : email, phoneNumberKey : phoneNumber]
        let responseJSON = [successKey : true, successDictionaryKey : userDetailJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        
    default:
        
        let errorJSON = [errorCodeKey : ErrorCode.DatabaseInsertionError.rawValue, errorDescriptionKey : "Error while inserting to database."] as [String : Any]
        let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
})
/**************************************************************************/

/**************************** Login Service *******************************/

routes.add(method: .post, uri: loginRoute, handler: {
    request, response in
    
    if request.params().count != 2 {
        
        let errorJSON = [errorCodeKey : ErrorCode.InvalidRequest.rawValue, errorDescriptionKey : "Invalid request."] as [String : Any]
        let responseJSON = [successKey : false ,errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    guard let email = request.param(name: emailKey), let password = request.param(name: passwordKey)else {
        
        let errorJSON = [errorCodeKey : ErrorCode.InvalidRequest.rawValue, errorDescriptionKey : "Invalid request."] as [String : Any]
        let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    }
    
    let client = try! MongoClient(uri: mongoClient)
    let db = client.getDatabase(name: dbName)
    
    // define collection
    guard let collection = db.getCollection(name: credentialCollection) else {
        
        let errorJSON = [errorCodeKey : ErrorCode.DatabaseConnectionError.rawValue, errorDescriptionKey : "Error connecting to database."] as [String : Any]
        let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
        
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
    
    let bson = try! BSON(json: "{\"email\" : \"\(email)\",\"password\" : \"\(password)\"}")
    
    defer {
        bson.close()
    }
    
    let filterBson = BSON()
    filterBson.append(key: mongoIDKey)
    filterBson.append(key: passwordKey)
    
    defer {
        filterBson.close()
    }

    let filterResults = collection.find(query: bson, fields:filterBson)
    
    // Initialize empty array to receive formatted results
    var responseData = [String]()
    
    for result in filterResults! {
        responseData.append(result.asString)
    }
    
    if responseData.count == 0 {
        
        let errorJSON = [errorCodeKey : ErrorCode.UserNotRegistered.rawValue, errorDescriptionKey : "User does not exist."] as [String : Any]
        let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
        
        do {
            try response.setBody(json: responseJSON)
        } catch {
            print("Error : ",error)
        }
        
        response.completed()
        return
    } else {
        
        let loginResult = responseData.first
        
        guard let data = loginResult?.data(using: .utf8) else {
            
            let errorJSON = [errorCodeKey : ErrorCode.ParseError.rawValue, errorDescriptionKey : "Error in parsing data."] as [String : Any]
            let responseJSON = [successKey : false, errorKey : errorJSON] as [String : Any]
            
            do {
                try response.setBody(json: responseJSON)
            } catch {
                print("Error : ",error)
            }
            
            response.completed()
            return
        }
        
        do {
            var loginDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            
            if (loginDictionary != nil) {
                                
                let responseJSON = [successKey : true, successDictionaryKey : loginDictionary] as [String : Any]
                
                do {
                    try response.setBody(json: responseJSON)
                } catch {
                    print("Error : ",error)
                }
                
                response.completed()
                return
            }
        } catch {
            print(error.localizedDescription)
        }
    }
})

/**************************************************************************/

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port of 8181
server.serverPort = port

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
