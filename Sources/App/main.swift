import Vapor
import PostgreSQL
import VaporPostgreSQL
import Foundation
import Fluent
import HTTP

let drop = Droplet()

try drop.addProvider(VaporPostgreSQL.Provider.self)

/*
let drop = Droplet( 
	providers: [VaporPostgreSQL.Provider.self]
) */

//drop.preparations.append(Voter.self)


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

		guard let addressID = results[0]?["address_id"]?.int else { throw Abort.badRequest }
		
		print ("the addressID is \(addressID)")
		/*		
		if let nodeObject = results[0],
		let nodeValue = nodeObject["address_id"], 
		let intValue = nodeValue.int { } */

		return try JSON(node: ["status": queryResult.status,"address_id": addressID])

		} catch {

			let queryResult = QueryResult(status: false, errorMessage: "\(error)")

			print ("Database Error : \(error)")
	
			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage])

		}	
	
		}		

		return try JSON(node: ["status": false]) 	
	}


	drop.post("voterzr/voter-add") { request in


	/* extracting the address from request */

	 guard let address = request.json?["voters","address"]?.string, let wardNo = request.json?["voters","wardNo"]?.string, let wardName = request.json?["voters","wardName"]?.string else {

          throw Abort.badRequest

         }

	/* extracting the voter details from request */

	guard let members = request.data["voters","members"]?.array, let leadVoterId = request.json?["voters","leadVoterId"]?.string, let leadRole = request.json?["voters","leadRole"]?.string, let leadName = request.json?["voters","leadName"]?.string
	else {

	throw Abort.badRequest
	}

	 var queryResult = QueryResult()

	/* Insert DB transaction */


	if let dataBase = drop.database?.driver as? PostgreSQLDriver {


	do {

	/* inserting the lead voter Info into lead_voter table */

	print ("Before add lead_voter")

	 _  = try dataBase.raw("INSERT INTO lead_voter(lead_voter_id,lead_name,lead_role) VALUES ('\(leadVoterId)', '\(leadName)','\(leadRole)')")

	 print ("after add lead_voter")
	/* inserting the address into address table */

	 let results = try dataBase.raw("INSERT INTO address(address_detail,ward_name,ward_no) VALUES ('\(address)', '\(wardName)', '\(wardNo)') RETURNING address_id")

          guard let addressId = results[0]?["address_id"]?.int else { throw Abort.badRequest }

	  print ("address id \(addressId)")
	
       	  print ("\(members.count)")
		 for i in 0..<members.count {
        
        guard var voterId = request.json?["voters","members",i,"voterId"],var voterName = request.json?["voters","members",i,"name"], var memberRole = request.json?["voters","members",i,"memberRole"] else {
 
         throw Abort.badRequest
         
         }
         
		print ("\(voterId.string!),\(voterName.string!),\(addressId),\(leadVoterId),\(leadRole),\(memberRole.string!)")

		/* Inserting voter info into voter table */

		var results = try dataBase.raw("INSERT INTO voter(voter_id,voter_name,voter_address_id,voter_lead_id,member_role) VALUES ('\(voterId.string!)','\(voterName.string!)', '\(addressId)', '\(leadVoterId)','\(memberRole.string!)')")


		}

		 return try JSON(node: ["status": queryResult.status])

		} catch DatabaseError.invalidSQL(let message) {

		print ("In invalid SQL")

			if let extractedMessage = Utility.getSubstringFromMessage(text: message) {

			let queryResult = QueryResult(status: false, errorMessage: extractedMessage) 

			print ("DatabaseError: \(extractedMessage)")
	
			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage]) } else {
			
			let queryResult = QueryResult(status: false, errorMessage: "DatabaseError")

			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage]) 
			
			}

		} catch {

			 print ("default catch")
			 let queryResult = QueryResult(status: false, errorMessage: "\(error)")
			 print ("DatabaseError: \(error)")
			return try JSON(node: ["status": queryResult.status,"errorMessage": queryResult.errorMessage])

			
			
		}	
	
		}		

		return try JSON(node: ["status": false]) 	
	}


struct Member {
	
        let voterId: String
        let voterName: String
        let familyRole: String
}

extension Member: NodeRepresentable {
   
	func makeNode() throws -> Node {
    		return try Node(node:
      	[
        	"voterId": voterId,
        	"voterName": voterName,
        	"familyRole": familyRole
      	]
    	)
  }

	func makeNode(context: Context) throws -> Node {
        return try Node(node: [       
                "voterId": voterId,
                "voterName": voterName,
                "familyRole": familyRole
        ])
    }

}


struct Voter {

	let voterId: String
        let name: String
        let role: String
        let address: String
        let wardNo: String
        let wardName: String
        let member: Node
       
}

extension Voter: NodeRepresentable {
    
func makeNode() throws -> Node {
    return try Node(node:
      [
        "leadVoterId": voterId,
        "name": name,
        "role": role,
	"address": address,
	"wardNo": wardNo,
	"wardName": wardName,
	"member": member
      ]
    )
  }

func makeNode(context: Context) throws -> Node {

	return try Node(node:
      	[
        "leadVoterId": voterId,
        "name": name,
        "role": role,
        "address": address,
        "wardNo": wardNo,
        "wardName": wardName,
        "member": member
      	]
    	)
}

}


func fetchMembersFor(voterId: String, withLimit limit: Int, andwithOffset offset: Int)->[Member]? {

        if let db1 = drop.database?.driver as? PostgreSQLDriver {

        do { let results = try db1.raw("SELECT voter.voter_id, voter.voter_name, voter.role FROM voter INNER JOIN address ON voter.voter_address_id= address.address_id WHERE voter.lead_id = '\(voterId)' LIMIT \(limit) OFFSET \(offset)")

	/* guard let addressID = results[0]?["address_id"]?.int else { throw Abort.badRequest } */

	var members:[Member] = []
	
	for i in 0..<(results.array)!.count {

	guard let id = results[i]?["voter_id"]?.string, 
	let name = results[i]?["voter_name"]?.string,
	let role = results[i]?["role"]?.string else { throw Abort.badRequest }
	
	let member = Member(voterId: id, voterName: name, familyRole: role)

	members.append(member)

	/* print("the value is \(i)") */

	}

	return members

                } catch { print("the error is : \(error)") }


        }


	return nil
}

/*	drop.get("voterrzr/lead-voter-list") { request in


	if let voterDb = drop.database?.driver as? PostgreSQLDriver {

                do {



	}

	}

*/

	drop.post("voterzr/voter-list") { request in

		guard let limit = request.json?["limit"]?.int,
		let offset = request.json?["offset"]?.int else { throw Abort.badRequest }	

		if let voterDb = drop.database?.driver as? PostgreSQLDriver {

		do {

		let results = try voterDb.raw("SELECT voter_id, voter_name, role, address.address_detail, address.ward_no, address.ward_name  FROM voter INNER JOIN address ON voter.voter_address_id = address.address_id WHERE lead_id='-1' LIMIT \(limit) OFFSET \(offset)")

		/*print ("The result is \(results)")*/

		/*var voters = [[String:Any?]]() */

		var voters:[Voter] = []

		for i in 0..<(results.array)!.count {
        
        		guard var id = results[i]?["voter_id"]?.string,
			var name = results[i]?["voter_name"]?.string, 
			var role = results[i]?["role"]?.string,
			var address = results[i]?["address_detail"]?.string,
			var wardNo = results[i]?["ward_no"]?.string,
			var wardName = results[i]?["ward_name"]?.string
		  
			else { throw Abort.badRequest }

			var familyMembers = fetchMembersFor(voterId: id, 
							    withLimit: limit, 
							    andwithOffset: offset)
			
			guard let members = familyMembers else { throw Abort.badRequest } 
			/* print("the members are \(members)")*/

			var voter = Voter(voterId: id, name: name,
					  role: role, address: address,
					  wardNo: wardNo,
					  wardName: wardName,
					  member:try members.makeNode())
			voters.append(voter)

			/*print("the voters are \(voters)")*/
			}
			
			 return try JSON(node: ["voters":try voters.makeNode()])
			
			 
        	} catch {
		
		let queryResult = QueryResult(status: false, errorMessage: "\(error)")
                         print ("DatabaseError: \(error)")
                        return try JSON(node: ["status": queryResult.status,
					       "errorMessage": queryResult.errorMessage])
		}

		} else {
        	
		let queryResult = QueryResult(status: false, errorMessage: "Connection Error")
                	print ("Connection Error")
			return try JSON(node: ["status": queryResult.status,
					       "errorMessage": queryResult.errorMessage])

		}		

	}


drop.run()

