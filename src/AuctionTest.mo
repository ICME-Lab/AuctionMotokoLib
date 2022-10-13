import List "mo:base/List";
import Result "mo:base/Result";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

import Ledger "Ledger/Ledger";
import FungibleTokens "FungibleTokens";
import NonFungibleTokens "NonFungibleTokens";
import Auction "Auction";

shared ({caller=installer}) actor class AuctionTest() {

  /* Types */
  public type NfTokenId = Nat;


  public func Test() {
    var fTokens = FungibleTokens.FungibleTokens();  
    var nfTokens = NonFungibleTokens.NonFungibleTokens();
    var auctions = Auction.Auction(installer, fTokens, nfTokens);
    
    let nfTokenId = 1;
    let auctionId = nfTokenId;

    let Alice = Principal.fromText("xi3x7-bvhmp-4ac6n-yh5oc-znztw-deom2-egqt5-imnk3-jsdps-taeli-2qe");
    let Bob = Principal.fromText("64hoy-zkyv5-2mpjz-dgzoo-xtdbn-7ykzz-mdx7j-cwtac-4ysyr-xut3j-fae");
    let Carol = Principal.fromText("vjedb-vgjea-hh6sz-tfrdw-ry2i4-yvn5e-4uvop-jzkrt-bkivj-l3mph-uae");


    // wrap icp
    fTokens.wrap(Alice, 10_000);
    fTokens.wrap(Bob, 70_000);
    fTokens.wrap(Carol, 70_000);

    // wrap nft
    ignore nfTokens.wrap(nfTokenId, Alice);

    // enbid to empty auction
    assert(fTokens.subdivide((Bob, auctionId), 10_000) == #ok()); // transfer wraped icp to biding acount
    assert(auctions.enBid(auctionId, Bob) == #err("Auction is not exsiting"));

    // init
    assert(auctions.init(auctionId) == #ok());
    assert(auctions.enBid(auctionId, Bob) == #err(""));

    // start
    assert(auctions.start(auctionId, Alice) == #ok());
    assert(auctions.enBid(auctionId, Bob) == #ok());

    // double bid
    assert(auctions.enBid(auctionId, Bob) == #err("The Account is already locked"));

    // same bid price
    assert(fTokens.subdivide((Carol, auctionId), 10_000)  == #ok());
    assert(auctions.enBid(auctionId, Carol) == #err("The bid is lower than prev bid"));

    // higher bid price
    assert(fTokens.subdivide((Carol, auctionId), 10_000)  == #ok());
    assert(auctions.enBid(auctionId, Carol) == #ok);

    // check unlock
    assert(auctions.enBid(auctionId, Bob) == #err("The bid is lower than prev bid"));


    // check extention
    var state: Auction.AuctionState = switch (auctions.status(auctionId)) {
      case (?#Q2(auction)) {
        #Q2{
          owner = auction.owner;
          bid = auction.bid;
          bidHistroy = auction.bidHistroy;
          end = Time.now() + 2 * auctions.MINUTES;
        }
      };
      case (_) { assert(false); return ();};
    };
    auctions.set(auctionId, state);
    assert(fTokens.subdivide((Bob, auctionId), 20_000) == #ok());
    assert(auctions.enBid(auctionId, Bob) == #ok());
    switch (auctions.status(auctionId)) {
      case (?#Q3(auction)) {
        if (auction.extensionCount != 1) assert(false);
      };
      case (_) assert(false);
    };

    // bid in extention
    assert(fTokens.subdivide((Carol, auctionId), 20_000) == #ok());
    assert(auctions.enBid(auctionId, Carol) == #ok());
    switch (auctions.status(auctionId)) {
      case (?#Q3(auction)) {
        if (auction.extensionCount != 2) assert(false);
      };
      case (_) assert(false);
    };

    // check over in Q2
    state := switch (auctions.status(auctionId)) {
      case (?#Q3(auction)) {
        #Q2{
          owner = auction.owner;
          bid = auction.bid;
          bidHistroy = auction.bidHistroy;
          end = Time.now() - 2 * auctions.MINUTES;
        }
      };
      case (_) { assert(false); return ();};
    };
    auctions.set(auctionId, state);
    assert(fTokens.subdivide((Bob, auctionId), 20_000) == #ok());
    assert(auctions.enBid(auctionId, Bob) == #err("Auctio is over"));


    // check over in Q3
    state := switch (auctions.status(auctionId)) {
      case (?#Q2(auction)) {
        #Q3{
          owner = auction.owner;
          bid = auction.bid;
          bidHistroy = auction.bidHistroy;
          end = Time.now() - 2 * auctions.MINUTES;
          extensionCount = 3;
        }
      };
      case (_) { assert(false); return ();};
    };
    auctions.set(auctionId, state);
    assert(auctions.enBid(auctionId, Bob) == #err("Auctio is over"));

    assert(fTokens.putbackAll((Carol, auctionId)) == #err("The Account is locked") );

    
    assert(auctions.end(auctionId) == #ok());


    // check receive payment
    assert(fTokens.balance((Alice, 0)).value == 50_000);
    assert(fTokens.balance((Carol, 0)).value == 30_000);
    assert(fTokens.balance((Carol, 1)).value == 0);
    assert(fTokens.balance((Carol, 1)).locked == false);
    assert(fTokens.balance((Bob, 1)).locked == false);

    assert(nfTokens.isOwner(nfTokenId, Alice) == false);
    assert(nfTokens.isOwner(nfTokenId, Bob) == false);
    assert(nfTokens.isOwner(nfTokenId, Carol) == true);

    // put back bid price of bob
    assert(fTokens.putbackAll((Bob, auctionId)) == #ok() );
    assert(fTokens.putbackAll((Carol, auctionId)) == #ok() );





  }


}