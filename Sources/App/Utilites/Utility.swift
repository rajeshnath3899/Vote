
import Foundation


class Utility {

class func getSubstringFromMessage(text: String) -> String? {

let subString = text.components(separatedBy: "(voter_id)")

for stringElement in subString {
    
    
    if (stringElement.contains("already exists")) {
        
        let stringList = stringElement.components(separatedBy: "=")
        
        for element in stringList {
            
            if (element.contains("already exists")) {
                
               print(stringElement)
               return stringElement  
                
           }  
            
        }
        
    }
    
 
}

return nil

}
}
