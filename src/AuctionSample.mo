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
import Auction "Auction";

shared ({caller=installer}) actor class AuctionSample() = this {

  /* Types */
  public type NfTokenId = Nat;
  public type AuctionId = Auction.AuctionId;
  // Error
  public type Error = {
    #Ledger: Ledger.TransferError;
    #FTokens: Text;
    #Auction: Text;
  };

  /*  */
  // stable var ledgerEntires: Ledger.Entries = {
  //   controller = Principal.fromActor(this);
  //   ledgerCanisterId = Ledger.defaultLedgerCanisterId();
  //   gas = Ledger.defaultLedgerGas();
  // };
  stable var fTokenEntries: FungibleTokens.Entries = [];
  stable var nfTokenEntries: NonFungibleTokens.Entries = [];
  stable var auctionEntries: Auction.Entries = [];

  // Ledger canister controller
  var ledger = Ledger.Ledger(Ledger.defaultLedgerCanisterId());
  // Wraped ICP controller
  let fTokens = FungibleTokens.FungibleTokens(fTokenEntries);
  // Wraped NFT controller
  let nfTokens = NonFungibleTokens.NonFungibleTokens(nfTokenEntries);
  // Auction controller
  let auctions = Auction.Auction(installer, fTokens, nfTokens, auctionEntries);

  /* System */
  system func preupgrade() {
    // ledgerEntires := ledger.export();
    fTokenEntries := fTokens.export();
    nfTokenEntries := nfTokens.export();
    auctionEntries := auctions.export();
  };
  system func postupgrade() {
    fTokenEntries := [];
    nfTokenEntries := [];
    auctionEntries := [];
  };

  /* helper functions */
  func toNfTokenIdFromAuctionId(nfTokenId: NfTokenId): AuctionId {
    nfTokenId;
  };

  
  /* public functions */
  // create payment account
  public shared ({caller}) func paymentAccountId(): async Text {
    ledger.paymentAccountId(Principal.fromActor(this), caller)
  };

  // take in new payment
  public shared ({caller}) func wrap(): async Result.Result<(Ledger.BlockIndex, Ledger.Tokens), Error> {
    // recieve icp
    let (blockIndex, tokens) = switch (await ledger.takeinPayment(Principal.fromActor(this), caller)) {
      case (#ok(o)) o;
      case (#err(e)) return #err(#Ledger(e));
    };
    // wrap icp
    fTokens.wrap(caller, tokens.e8s);

    return #ok(blockIndex, tokens);
  };

  // take out balance
   public shared ({caller}) func unwrap(ledgerTextAccountId: Ledger.TextAccountIdentifier, amount: FungibleTokens.Value): async Result.Result<(Ledger.BlockIndex, Ledger.Tokens), Error> {
    // check balance
    let value = fTokens.balance(caller, 0).value;
    if (amount > value) return #err(#FTokens("InsufficientFunds"));

    /* WIP, 
    await?????????????????????????????????????????????????????????????????????????????????????????? 
    pedding??????????????????????????????
    */
    
    // transfer icp
    let (blockIndex, tokens) = switch (await ledger.takeoutPayment(ledgerTextAccountId, amount)) {
      case (#ok(o)) o;
      case (#err(e)) return #err(#Ledger(e));
    };

    // unwrap icp on fTokens
    switch (fTokens.unwrap(caller, amount)) {
      case (#ok(_)) return #ok(blockIndex, tokens);
      case (#err(e)) assert(false); // WIP, need rolle back
    };

    /*
    ?????????????????????????????????????????????HashMap???put?????????????????????
    */

    return #ok(blockIndex, tokens);
  };

  public shared ({caller}) func enBid(nfTokenId: NfTokenId, amount: FungibleTokens.Value): async Result.Result<(), Error> {
    let auctionId = toNfTokenIdFromAuctionId(nfTokenId);
    
    switch (fTokens.subdivide((caller, auctionId), amount)) {
      case (#ok(_)) {};
      case (#err(e)) return #err(#FTokens(e));
    };

    /* WIP,  
    ??????????????????????????????????????????????????????lock????????????????????????????????????????????????????????????????????????????????????
    ????????????????????????????????????????????????????????????????????????????????????????????????-> ??????????????????????????????????????????k
    */

    switch (auctions.enBid(auctionId, caller)) {
      case (#ok(_)) {};
      case (#err(e)) return #err(#Auction(e));
    };

    return #ok;
  };

  public  shared ({caller}) func unBid(nfTokenId: NfTokenId): async Result.Result<(), Error> {
    let auctionId = toNfTokenIdFromAuctionId(nfTokenId);

    switch (fTokens.putbackAll(caller, auctionId)) {
      case (#ok(_)) {};
      case (#err(e)) return #err(#FTokens(e));
    };

    return #ok;
  };

  public shared ({caller}) func start(nfTokenId: NfTokenId): async Result.Result<(), Text> {
    if (not nfTokens.isOwner(nfTokenId, caller)) return #err("");
    let auctionId = nfTokenId;
    auctions.start(auctionId, caller)
  };

  public shared ({caller}) func end(nfTokenId: NfTokenId): async Result.Result<(), Text> {
    // if (not nfTokens.isOwner(nfTokenId, caller)) return #err("");
    let auctionId = nfTokenId;
    auctions.end(auctionId)
  };


}