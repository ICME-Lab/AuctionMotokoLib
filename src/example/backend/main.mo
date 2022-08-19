import Auction "../../Auction";

actor {
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
