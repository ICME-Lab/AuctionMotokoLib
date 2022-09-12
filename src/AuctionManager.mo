import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Time "mo:base/Time";

//locak
import Core "Core";

module {
  public type Bid = (BoxId, Nat);
  public type Bids = List.List<Bid>;

  public type User = Principal;
  public type BoxId = (User, Nat);
  public type TokenType = {
     #ICP;
  };
  public type Box = {
    tokenType: TokenType;
    var balance: Nat;
    var state: {
      #None;
      #Bidded: (BoxId, Nat);
      #InAuction: {
        var bidTokenType: TokenType;
        var auctionType: Text;
        var bidList: Bids;
        var phaseEndTime: Time.Time;
        var phaseCount: Nat;
        var buyoutPrice: Nat;
        var reservePrice: Nat;
      }
    }; 
  };
  public type Boxes = HashMap.HashMap<BoxId, Box>;

  func equalBoxId(a:BoxId, b:BoxId): Bool {
    (a.0 == b.0) and (a.1 == b.1)
  };
  func hashBoxId((p, n): BoxId): Hash.Hash {
    let pText = Principal.toText(p);
    // !!!! WIP !!!! using debug_show to avoid warning
    let nText = debug_show(n); // let nText = Nat.toText(n);
    let b = Text.encodeUtf8(pText # nText);
    Blob.hash(b)
  };

  // iter type is error, why?
  public func fromIter(iter: [(BoxId, Box)], initCapacity: Nat): AuctionManager {
    let boxes = HashMap.fromIter<BoxId, Box>(iter.vals(), initCapacity, equalBoxId, hashBoxId);
    AuctionManager(boxes)
  };

  public class AuctionManager(boxes: Boxes) {
    /* For Auction Manage */




    /* For Token Manage */
    public func newBox(newBoxId: BoxId, tokenType: TokenType): Result.Result<(),()> {
      switch (boxes.get(newBoxId)) {
        case (?_) return #err();
        case (null) boxes.put(newBoxId, {tokenType; var balance=0; var state=#None});
      };
      return #ok();
    };

    public func mintToken(boxId: BoxId, tokenType: TokenType, balance: Nat): Result.Result<(),()> {
      switch (boxes.get(boxId)) {
        case (?box) {
          if (box.tokenType != tokenType) return #err;
          box.balance += balance;
        };
        case (_) return #err;
      };
      return #ok;
    };

    public func burnToken(boxId: BoxId, tokenType: TokenType, balance: Nat): Result.Result<(),Text> {
      switch (boxes.get(boxId)) {
        case (?box) {
          if (box.tokenType != tokenType) return  #err("TokenType miss match");
          if (box.balance < balance) return #err("not enough balncex");
          box.balance -= balance;
        };
        case (_) return #err("not exsit");
      };
      return #ok;
    };

    public func transfer(toBoxId: BoxId, fromBoxId: BoxId, tokenType: TokenType, balance: Nat): Result.Result<(),Text> {
      switch (boxes.get(toBoxId), boxes.get(fromBoxId)) {
        case (?toBox, ?fromBox) {
          if (not (toBox.tokenType == fromBox.tokenType and fromBox.tokenType == tokenType)) return #err("TokenType miss match");
          if (fromBox.balance < balance) return #err("not enough balncex");
          toBox.balance += balance;
          fromBox.balance -= balance;
        };
        case (_) return #err("not exsit");
      };
      return #ok;
    };
    // private
    func unBidState(boxId: BoxId, tokenType: TokenType): Result.Result<(),Text> {
      switch (boxes.get(boxId)) {
        case (?box) {
          if (box.tokenType != tokenType) return  #err("TokenType miss match");
          switch (box.state) {
            case (#InAuction(_)) return #err("The token is in Auction");
            case (_) {}
          };
          box.state := #None;
        };
        case (_) return #err("not exsit");
      };
      return #ok;
    };


    // func enBidState(fromBoxId: BoxId, toBoxId: BoxId, tokenType: TokenType): Result.Result<(),Text> {
    //   switch (boxes.get(boxId)) {
    //     case (?box) {
    //       if (box.tokenType != tokenType) return  #err("TokenType miss match");
    //       switch (box.state) {
    //         case (#InAuction(_)) return #err("The token is in Auction");
    //         case (#Bidded(_)) return #err("The token is already bidded");
    //         case (_) {}
    //       };
    //       box.state := #None;
    //     };
    //     case (_) return #err("not exsit");
    //   };
    //   return #ok;
    // };

  };
}