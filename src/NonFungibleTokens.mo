// Motoko base
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";



module {

  public type TokenId = Nat;
  public type Entries = [(TokenId, Principal)];

  public class NonFungibleTokens(tokenEntries: Entries) = this {

    // Tokens under management by this service
    let tokens = HashMap.fromIter<TokenId, Principal>(tokenEntries.vals(), 0, Nat.equal, Hash.hash);

    public func export(): Entries {
      Iter.toArray(tokens.entries());
    };

    public func wrap(tokenId: TokenId, owner: Principal): Result.Result<(), Text> {
      switch (tokens.get(tokenId)) {
        case (?owner) return #err("");
        case (null) tokens.put(tokenId, owner);
      };
      return #ok;
    };
    
    public func unwrap() {};

    public func transfer(tokenId: TokenId, to: Principal) { // WIP; return types
      tokens.put(tokenId, to);
    };

    public func isOwner(tokenId: TokenId, p: Principal): Bool {
      switch (tokens.get(tokenId)) {
        case (?owner) (owner == p);
        case (null) false;
      }
    };

  };
}