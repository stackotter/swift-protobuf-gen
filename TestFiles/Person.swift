enum Response {
  case yes
  case no
}

struct Thing {
  var name: String
  var price: String?
}

struct Person {
  var firstName: String
  var lastName: String
  var age: Int?
  var favoriteThings: [Thing]?
  var eulaResponse: Response

  var twiceAge: Int { age * 2 }
}
