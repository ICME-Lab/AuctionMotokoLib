import List "mo:base/List";
import Result "mo:base/Result";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

import Ledger "Ledger/Ledger";
import FungibleTokens "FungibleTokens";
import NonFungibleTokens "NonFungibleTokens";

module {
  /* Types */
  public type Bid = {
    bidder: Principal;
    price: Nat64;
  };
  public type AuctionId = Nat;
  public type AuctionState = {
    #Q1; // init
    #Q2: {  // auction
      owner: Principal;
      bid: Bid;
      bidHistroy: List.List<Bid>;
      end: Time.Time;
    };
    #Q3: { // overtime
      owner: Principal;
      bid: Bid;
      bidHistroy: List.List<Bid>;
      end: Time.Time;
      extensionCount: Nat;
    };
    #Q4: { // end
      winner: Principal;
      winPrice: Nat64;
    };
  };

  public type FTokens = {
    balance: FungibleTokens.AccountId -> FungibleTokens.Account;
    enLock: FungibleTokens.AccountId -> ();
    unLock: FungibleTokens.AccountId -> ();
    pay: (Principal, Principal, Nat, FungibleTokens.Value) -> Result.Result<(), Text>;
  };

  public type NfTokens = {
    transfer: (NonFungibleTokens.TokenId, Principal) -> ();
  };

  /* Class */
  public class Auction(installer: Principal, fTokens: FTokens, nfTokens: NfTokens) {

    public let SEC = 1_000_000_000;
    public let MINUTES =  60 * SEC;
    public let HOUR = 60 * MINUTES;
    public let DAY = 24 * HOUR;
    public let WEEK =  7 * DAY;

    public let EXTENTION_TIME = 5 * MINUTES;
    let INITIAL_BID: Bid = {
      bidder = installer;
      price = 0;
    };
    let AUCTION_PERIOD = 10 * MINUTES;

    // Tokens under management by this service
    let auctionEntries: [(AuctionId, AuctionState)] = [];
    let auctions = HashMap.fromIter<AuctionId, AuctionState>(auctionEntries.vals(), 0, Nat.equal, Hash.hash);
    
    public func enBid(auctionId: AuctionId, bidder: Principal): Result.Result<(), Text>{

      let now = Time.now();

      var state = switch (auctions.get(auctionId)) {
        case (?state) state;
        case (null) return #err("Auction is not exsiting");
      };
      switch (state) {
        case (#Q2(auction)) {
          // Get bidder's bid price
          let bidAccount = fTokens.balance(bidder, auctionId);
          // Only unlocked account can be used
          if(bidAccount.locked == true) return #err("The Account is already locked");
          // Accept higher bid than prev bid
          if (auction.bid.price >= bidAccount.value) return #err("The bid is lower than prev bid");
          // Make new bid
          let newBid = {
            bidder;
            price = bidAccount.value;
          };
          // Check time
          let newState =
          if (now > auction.end) { // over end time
            return #err("Auctio is over");
          }
          else if (now > auction.end-EXTENTION_TIME) { // in extention time
            #Q3{
              owner = auction.owner;
              bid = newBid;
              bidHistroy = List.push<Bid>(newBid, auction.bidHistroy);
              end = now+EXTENTION_TIME;
              extensionCount = 1;
            }
          }
          else { // in nomal auction time
            #Q2{
              owner = auction.owner;
              bid = newBid;
              bidHistroy = List.push<Bid>(newBid, auction.bidHistroy);
              end = auction.end;
            }
          };

          /* change state */
          fTokens.unLock(auction.bid.bidder, auctionId);
          fTokens.enLock(bidder, auctionId);
          auctions.put(auctionId, newState);

          return #ok;
        };
        case (#Q3(auction)) {
          // Get bidder's bid price
          let bidAccount = fTokens.balance(bidder, auctionId);
          // Only unlocked account can be used
          if(bidAccount.locked == true) return #err("The Account is already locked");
          // Accept higher bid than prev bid
          if (auction.bid.price >= bidAccount.value) return #err("The bid is lower than prev bid");
          // Make new bid
          let newBid = {
            bidder;
            price = bidAccount.value;
          };
          let newState =
          if (now > auction.end) { // over end time
            return #err("Auctio is over");
          }
          else { // in extention time
            #Q3{
              owner = auction.owner;
              bid = newBid;
              bidHistroy = List.push<Bid>(newBid, auction.bidHistroy);
              end = now+EXTENTION_TIME; // WIP; now+EXTENTION_TIME or auction.end+EXTENTION_TIME
              extensionCount = auction.extensionCount+1;
            }
          };

          /* change state */
          fTokens.unLock(auction.bid.bidder, auctionId);
          fTokens.enLock(bidder, auctionId);
          auctions.put(auctionId, newState);

          return #ok;
        };
        case (_) {
          return #err(""); // WIP error handling
        };
      };
    };

    public func status(auctionId: AuctionId): ?AuctionState {
      auctions.get(auctionId)
    };

    public func init(auctionId: AuctionId): Result.Result<(), Text> {
      let newState = switch (auctions.get(auctionId)) {
        case (?state) return #err("Auction is not exsiting"); // WIP, Q4
        case (null) {
          #Q1();
        };
      };
      auctions.put(auctionId, newState);
      return #ok;
    };

    public func start(auctionId: AuctionId, owner: Principal): Result.Result<(), Text> {

      let now = Time.now();

      var state = switch (auctions.get(auctionId)) {
        case (?state) state;
        case (null) return #err("Auction is not exsiting");
      };
      switch (state) {
        case (#Q1(_)) {
          let newState = #Q2{
            owner;
            bid = INITIAL_BID;
            bidHistroy = List.nil<Bid>();
            end = now+AUCTION_PERIOD;
          };

          /* change state */
          auctions.put(auctionId, newState);

          return #ok;
        };
        case (_) {
          return #err(""); // WIP error handling
        };
      };
    };

    public func end(auctionId: AuctionId): Result.Result<(), Text> {

      let now = Time.now();

      var state = switch (auctions.get(auctionId)) {
        case (?state) state;
        case (null) return #err("Auction is not exsiting");
      };
      switch (state) {
        case (#Q2(auction)) {
          // Check time
          let newState =
          if (now > auction.end) { // over end time
            #Q4{
              winner = auction.bid.bidder;
              winPrice = auction.bid.price;
            }
          } else {
            return #err("Auction is not over");
          };

          /* change state */
          switch (fTokens.pay(auction.owner, auction.bid.bidder, auctionId, auction.bid.price)) {
            case (#ok(_)) {};
            case (#err(e)) return #err(e);
          };
          // unlock is automatic in pay
          auctions.put(auctionId, newState);
          return #ok();
        };
        case (#Q3(auction)) {
          // Check time
          let newState =
          if (now > auction.end) { // over end time
            #Q4{
              winner = auction.bid.bidder;
              winPrice = auction.bid.price;
            }
          } else {
            return #err("Auction is not over");
          };

          /* change state */
          switch (fTokens.pay(auction.owner, auction.bid.bidder, auctionId, auction.bid.price)) {
            case (#ok(_)) {};
            case (#err(e)) return #err(e);
          };
          let nfTokenId = auctionId;
          nfTokens.transfer(nfTokenId, auction.bid.bidder);
          // unlock is automatic in pay
          auctions.put(auctionId, newState);
          return #ok();
        };
        case (_) {
          return #err(""); // WIP error handling
        };
      };
    };

    /* Debug Functions */
    public func set(auctionId: AuctionId, state: AuctionState) {
      auctions.put(auctionId, state)
    };


  }
}
