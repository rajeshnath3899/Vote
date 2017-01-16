import Vapor
import Fluent
import Foundation

final class Voter: Model {
    var id: Node?
    var voterid: String
    var votername: String
    
    init(voterId: String, voterName: String) {
        self.id = UUID().uuidString.makeNode()
	self.voterid = voterId
	self.votername = voterName
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
	voterid = try node.extract("voterid")
        votername = try node.extract("votername")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [ "id": id,
            "voterid": voterid,
            "votername": votername
        ])
    }
}

/*
extension Voter {
    /**
        This will automatically fetch from database, using example here to load
        automatically for example. Remove on real models.
    */
    public convenience init?(from string: String) throws {
        self.init(content: string)
    }
}
*/
extension Voter: Preparation {
    static func prepare(_ database: Database) throws {

	 try database.create("voters") { voters in
            voters.id()
	    voters.string("voterid")
            voters.string("votername")
        }

       
    }

    static func revert(_ database: Database) throws {
        
	try database.delete("voters")
    }
}
