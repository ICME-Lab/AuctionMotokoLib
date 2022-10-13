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

shared ({caller=installer}) actor class AuctionSample() {

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
  // Ledger canister controller
  var ledger = Ledger.Ledger(installer);
  // Wraped ICP controller
  var fTokens = FungibleTokens.FungibleTokens();
  // Wraped NFT controller
  var nfTokens =  NonFungibleTokens.NonFungibleTokens();
  // Auction controller
  var auction = Auction.Auction(installer, fTokens, nfTokens);

  /* helper functions */
  func toNfTokenIdFromAuctionId(nfTokenId: NfTokenId): AuctionId {
    nfTokenId;
  };

  
  /* public functions */
  // create payment account
  public shared ({caller}) func paymentAccountId(): async Text {
    ledger.paymentAccountId(caller)
  };

  // take in new payment
  public shared ({caller}) func wrap(): async Result.Result<(Ledger.BlockIndex, Ledger.Tokens), Error> {
    // recieve icp
    let (blockIndex, tokens) = switch (await ledger.takeinPayment(caller)) {
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
    await後の実行が連続ではに場合，残高に不整合が起こるかもしれない． 
    peddingを挟んだ方が良いか？
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
    エラーが起こらないように，直接HashMapへputしてしまうか？
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
    入金したが，入札条件に合わない場合，lockされているのに，実際の入札額と残高が異なる可能性がある．
    なので，落札時に全ての残高を支払うと不整合になる可能性がある．　-> 落札額のみ支払っているからおk
    */

    switch (auction.enBid(auctionId, caller)) {
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
    auction.start(auctionId, caller)
  };

  public shared ({caller}) func end(nfTokenId: NfTokenId): async Result.Result<(), Text> {
    // if (not nfTokens.isOwner(nfTokenId, caller)) return #err("");
    let auctionId = nfTokenId;
    auction.end(auctionId)
  };


}