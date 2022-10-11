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

shared ({caller=installer}) actor class AuctionSample() {
  // Ledger canister controller
  var ledger = Ledger.Ledger(installer);
    // ledger.takeinPayment(user_principal) return balance async
    // ledter.takeoutPayment(user_accountId) return asycn
    // ledger.paymentAccountId(user_principal) return text

   // Wraped ICP controller
  var fTokens = FungibleTokens.FungibleTokens();
    // fTokens.subdivide()
    // fTokens.balance(user_principal, ?auctionId)
    // fTokens.enLock(user_principal, auctionId)
    // fTokens.unLock(user_principal, auctionId)
    // fTokens.pay({to:user_principal; from:user_principal; auctionId;})

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

  let SEC = 1_000_000_000;
  let MINUTES =  60 * SEC;
  let EXTENTION_TIME = 1 * MINUTES;
  let INITIAL_BID: Bid = {
    bidder = installer;
    price = 0;
  };
  let AUCTION_PERIOD = 10 * MINUTES;

  // Tokens under management by this service
  let auctionEntries: [(AuctionId, AuctionState)] = [];
  let auctions = HashMap.fromIter<AuctionId, AuctionState>(auctionEntries.vals(), 0, Nat.equal, Hash.hash);
  
  public func enBid(auciotnId: AuctionId, bidder: Principal): async () {

    let now = Time.now();

    var state = switch (auctions.get(auciotnId)) {
      case (?state) state;
      case (null) return ();
    };
    switch (state) {
      case (#Q2(auction)) {
        // Get bidder's bid price
        let bidAccount = fTokens.balance(bidder, auciotnId);
        // Only unlocked account can be used
        if(bidAccount.locked == true) return (); // WIP, already bided
        // Accept higher bid than prev bid
        if (auction.bid.price >= bidAccount.value) return (); // WIP
        // Make new bid
        let newBid = {
          bidder;
          price = bidAccount.value;
        };
        // Check time
        let newState =
        if (now > auction.end) { // over end time
          return (); // WIP
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
        fTokens.unLock(auction.bid.bidder, auciotnId);
        fTokens.enLock(bidder, auciotnId);
        auctions.put(auciotnId, newState);
      };
      case (#Q3(auction)) {
        // Get bidder's bid price
        let bidAccount = fTokens.balance(bidder, auciotnId);
        // Only unlocked account can be used
        if(bidAccount.locked == true) return (); // WIP, already bided
        // Accept higher bid than prev bid
        if (auction.bid.price >= bidAccount.value) return (); // WIP
        // Make new bid
        let newBid = {
          bidder;
          price = bidAccount.value;
        };
        let newState =
        if (now > auction.end) { // over end time
          return (); // WIP
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
        fTokens.unLock(auction.bid.bidder, auciotnId);
        fTokens.enLock(bidder, auciotnId);
        auctions.put(auciotnId, newState);
      };
      case (_) {
        return (); // WIP error handling
      };
    };
  };

  public func start(auciotnId: AuctionId, owner: Principal): async () {

    let now = Time.now();

    var state = switch (auctions.get(auciotnId)) {
      case (?state) state;
      case (null) return ();
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
        auctions.put(auciotnId, newState);
      };
      case (_) {
        return (); // WIP error handling
      };
    };
  };

  public func end(auciotnId: AuctionId): async () {

    let now = Time.now();

    var state = switch (auctions.get(auciotnId)) {
      case (?state) state;
      case (null) return ();
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
          return (); // WIP
        };

        /* change state */
        fTokens.unLock(auction.bid.bidder, auciotnId);
        fTokens.pay(auction.owner, auction.bid.bidder, auciotnId, auction.bid.price);
        auctions.put(auciotnId, newState);
      };
      case (#Q3(_)) {
        // change phase
      };
      case (_) {
        return (); // WIP error handling
      };
    };
  };


}