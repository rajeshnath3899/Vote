import Vapor
import PostgreSQL
import VaporPostgreSQL

let drop = Droplet()

try drop.addProvider(VaporPostgreSQL.Provider.self)

/*
let drop = Droplet( 
	providers: [VaporPostgreSQL.Provider.self]
) */

drop.preparations.append(Voter.self)


drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}


drop.get("find") { request in

if let num = request.data["num"]?.int {

var result = ""

if (num % 2 == 0) {
    
    result = "Even"
    
} else {  
    result = "Odd"
}

 return result

}

return "Invalid Paramater"

}

/*
let postgreSQL =  PostgreSQL.Database(
    dbname: "voterzrdb",
    user: "postgres",
    password: "voteRZR123*_+"
)

let connection = try postgreSQL.makeConnection()

*/

drop.get("version") { request in 

if let db = drop.database?.driver as? PostgreSQLDriver {

let version = try db.raw("SELECT version()")

print (version)

return try JSON(node: version)

} else {
	return "No db connection"

}

}


drop.get("empInfo") { request in

if let db1 = drop.database?.driver as? PostgreSQLDriver {

let results = try db1.raw("SELECT * from employee")

print (results)

return try JSON(node: results)

} else {
        return "No db connection"

}

}

struct QueryResult {
    
    var status: Bool
    var errorMessage: String = ""
    
    init(){
        
        self.status = true
        
    }
    
    init(status: Bool, errorMessage: String) {
        
        self.status = status
        self.errorMessage = errorMessage
        
    }
    
}

	drop.post("voterzr/address-add") { request in

		guard let address = request.json?["address"]?.string, let wardNo = request.json?["ward_no"]?.string, let wardName = request.json?["ward_name"]?.string else {
	
		throw Abort.badRequest

	 }

	 var queryResult = QueryResult()

	/* Insert DB transaction */


	if let dataBase = drop.database?.driver as? PostgreSQLDriver {


	do {

		let results = try dataBase.raw("INSERT INTO address(address_detail,ward_name,ward_no) VALUES ('\(address)', '\(wardName)', '\(wardNo)') RETURNING address_id")

		
	//	let value = results[0]
			
	//	print (value!["address_id"]!.double)

		if let nodeObject = results[0], let nodeValue = nodeObject["address_id"], let intValue = nodeValue.int {

		print (intValue)

		return try JSON(node: ["status": queryResult.status,"address_id": intValue])

		}


		} catch {

			let queryResult = QueryResult(status: false, errorMessage: "\(error)")

			print ("Database Error : \(error)")
	
			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage])

		}	
	
		}		

		return try JSON(node: ["status": false]) 	
	}


	drop.post("voterzr/voter-add") { request in

		guard let voterId = request.json?["voter_id"]?.string, let voterName = request.json?["voter_name"]?.string, let addressId = request.json?["address_id"]?.string, let leadId = request.json?["lead_id"]?.string  else {
	
		throw Abort.badRequest

	 }

	 var queryResult = QueryResult()

	/* Insert DB transaction */


	if let dataBase = drop.database?.driver as? PostgreSQLDriver {


	do {

		let results = try dataBase.raw("INSERT INTO voter(voter_id,voter_name,voter_address_id,lead_id) VALUES ('\(voterId)', '\(voterName)', '\(addressId)', '\(leadId)')")

		return try JSON(node: ["status": queryResult.status])


		} catch DatabaseError.invalidSQL(let message) {

			let queryResult = QueryResult(status: false, errorMessage: message)

//			print ("DatabaseError: \(message)")
	
			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage])

		}	
	
		}		

		return try JSON(node: ["status": false]) 	
	}


drop.run()
