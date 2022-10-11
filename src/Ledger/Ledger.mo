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

import Types "Types";
 // Note: Temporarily copied from EXT.
import SHA224 "SHA224";
import Hex "Hex";
import AID "AccountIdentifier";

module {
  public type Tokens = Types.Tokens;
  public type TimeStamp = Types.TimeStamp;
  public type BlobAccountIdentifier = Types.BlobAccountIdentifier;
  public type TextAccountIdentifier = Text;
  public type SubAccount = Types.SubAccount;
  public type BlockIndex = Types.BlockIndex;
  public type Memo = Types.Memo;
  public type TransferArgs = Types.TransferArgs;
  public type TransferError = Types.TransferError;
  public type TransferResult = Types.TransferResult;
  public type AccountBalanceArgs = Types.AccountBalanceArgs;
  public type Interface = Types.Interface;

  public type AssetId = (Principal, Nat);

  /* Utls functions */
  public func toSubAccount(principal : Principal) : [Nat8] {
    let sub_nat32byte : [Nat8] = Blob.toArray(Text.encodeUtf8(Principal.toText(principal)));
    let sub_hash_28 : [Nat8] = SHA224.sha224(sub_nat32byte);
    let sub_hash_32 = Array.append(sub_hash_28, Array.freeze(Array.init<Nat8>(4, 0)));
    sub_hash_32
  };

  public func toBlobAccountId(p : Principal, subAccount :  [Nat8]) : BlobAccountIdentifier {
    return Blob.fromArray(Hex.decode(AID.fromPrincipal(p, ?subAccount)));
  };


  /* Class */
  public class Ledger(installer: Principal) {
    let DefaultLedgerCanisterId: Principal = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
    var ledgerCanisterId: Principal = DefaultLedgerCanisterId;
    var ledger : Interface = actor(Principal.toText(ledgerCanisterId));
    var gas: Nat64 = 10_000;
    let SUBACCOUNT_ZERO : [Nat8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    var installerAccountId: Blob = toBlobAccountId(installer, SUBACCOUNT_ZERO);

    // func equalAssetId(a: AssetId, b: AssetId): Bool {
    //   a.0 == b.0 and a.1 == b.1
    // };
    // func hashAssetId(a: AssetId): Hash.Hash {
    //   Text.hash(Principal.toText(a.0) # Nat.toText(a.1))
    // };

    // Tokens under management by this service
    // let assetsEntries: [(AssetId, Tokens)] = [];
    // let assets = HashMap.fromIter<AssetId, Tokens>(assetsEntries.vals(), 0, equalAssetId, hashAssetId);

    public func paymentAccountId(userPrincipal: Principal): Text {
      toTextPaymentAccountId(userPrincipal)
    };

    func toPaymentBlobAccountId(userPrincipal: Principal): BlobAccountIdentifier {
      toBlobAccountId(installer, toSubAccount(userPrincipal));
    };

    func toTextPaymentAccountId(userPrincipal: Principal): TextAccountIdentifier {
      Hex.encode(Blob.toArray(toPaymentBlobAccountId(userPrincipal)));
    };

    func balanceOfAccountId(blobAccountId: BlobAccountIdentifier): async Tokens {
      await ledger.account_balance({
        account = blobAccountId;
      });
    };

    public func takeinPayment(userPrincipal: Principal): async Result.Result<(BlockIndex, Tokens), TransferError> {// ここの型を後で変える．
      let subAccount = toSubAccount(userPrincipal);
      let paymentBlobAccountId = toPaymentBlobAccountId(userPrincipal);
      let accountBalance = await balanceOfAccountId(paymentBlobAccountId);

      if (gas > accountBalance.e8s) return #err(#BadFee({expected_fee={e8s=gas}}));

      let transferAmount = {e8s = accountBalance.e8s-gas};

      let args : TransferArgs = {
        memo: Memo = 0;
        amount: Tokens = transferAmount;
        fee: Tokens = {e8s=gas};
        from_subaccount: ?SubAccount = ?Blob.fromArray(subAccount);
        to: BlobAccountIdentifier = installerAccountId;
        created_at_time: ?TimeStamp = null;
      };
      switch(await ledger.transfer(args)) {
        case (#Err(e)) return #err(e);
        case (#Ok(o)) return #ok(o, transferAmount);
      }
    };

    public func takeoutPayment(textAccountId: TextAccountIdentifier, amountE8s: Nat64): async Result.Result<(BlockIndex, Tokens), TransferError> {

      if (gas > amountE8s) return #err(#BadFee({expected_fee={e8s=gas}}));

      let transferAmount = {e8s = amountE8s-gas};

      let args : TransferArgs = {
        memo: Memo = 0;
        amount: Tokens = transferAmount;
        fee: Tokens = {e8s=gas};
        from_subaccount: ?SubAccount = null;
        to: BlobAccountIdentifier = Blob.fromArray(Hex.decode(textAccountId));
        created_at_time: ?TimeStamp = null;
      };
      switch(await ledger.transfer(args)) {
        case (#Err(e)) return #err(e);
        case (#Ok(o)) return #ok((o, transferAmount))
      }
    }
  };
}