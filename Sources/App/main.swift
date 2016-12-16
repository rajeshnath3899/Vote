import Vapor
//import PostgreSQL
import VaporPostgreSQL

let drop = Droplet( 
	providers: [VaporPostgreSQL.Provider.self]
)

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
*/

drop.get("emp") { request in 

if let db = drop.database?.driver as? PostgreSQLDriver {

let results = try db.raw("SELECT * from employee")

print (results)

return try JSON(node: results)

} else {
	return "No db connection"

}

}
drop.resource("posts", PostController())

drop.run()