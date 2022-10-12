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


  // Ledger canister controller
  var ledger = Ledger.Ledger(installer);
    // ledger.takeinPayment(user_principal) return balance async
    // ledter.takeoutPayment(user_accountId) return asycn
    // ledger.paymentAccountId(user_principal) return text

  // Wraped ICP controller
  var fTokens = FungibleTokens.FungibleTokens();
    // fTokens.subdivide()
    // fTokens.balance(auctionId)
    // fTokens.enLock(auctionId)
    // fTokens.unLock(auctionId)
    // fTokens.pay({to:user_principal; from:user_principal; auctionId;})
  
  var nfTokens =  NonFungibleTokens.NonFungibleTokens();

  var auction = Auction.Auction(installer, fTokens, nfTokens);

  
  public shared ({caller}) func enBid(nfTokenId: NfTokenId): async Result.Result<(), Text> {
    let auctionId = nfTokenId;
    auction.enBid(auctionId, caller)
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