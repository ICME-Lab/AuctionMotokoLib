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

  public type Entries = {
    controller: Principal;
    ledgerCanisterId: Principal;
    gas: Nat64;
  };

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

  public func defaultLedgerCanisterId(): Principal {
    Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
  };
  public func defaultLedgerGas(): Nat64 {
    10_000;
  };


  /* Class */
  public class Ledger(_ledgerCanisterId: Principal) {

    var ledgerCanisterId: Principal = _ledgerCanisterId;
    var gas: Nat64 = 10_000;

    let ledger : Interface = actor(Principal.toText(ledgerCanisterId));
    let SUBACCOUNT_ZERO : [Nat8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    func controllerAccountId(controller: Principal): Blob = toBlobAccountId(controller, SUBACCOUNT_ZERO);

    public func paymentAccountId(controller: Principal, userPrincipal: Principal): Text {
      toTextPaymentAccountId(controller, userPrincipal)
    };

    func toPaymentBlobAccountId(controller: Principal, userPrincipal: Principal): BlobAccountIdentifier {
      toBlobAccountId(controller, toSubAccount(userPrincipal));
    };

    func toTextPaymentAccountId(controller: Principal, userPrincipal: Principal): TextAccountIdentifier {
      Hex.encode(Blob.toArray(toPaymentBlobAccountId(controller, userPrincipal)));
    };

    func balanceOfAccountId(blobAccountId: BlobAccountIdentifier): async Tokens {
      await ledger.account_balance({
        account = blobAccountId;
      });
    };

    public func takeinPayment(controller: Principal, userPrincipal: Principal): async Result.Result<(BlockIndex, Tokens), TransferError> {// ここの型を後で変える．
      let subAccount = toSubAccount(userPrincipal);
      let paymentBlobAccountId = toPaymentBlobAccountId(controller, userPrincipal);
      let accountBalance = await balanceOfAccountId(paymentBlobAccountId);

      if (gas > accountBalance.e8s) return #err(#BadFee({expected_fee={e8s=gas}}));

      let transferAmount = {e8s = accountBalance.e8s-gas};

      let args : TransferArgs = {
        memo: Memo = 0;
        amount: Tokens = transferAmount;
        fee: Tokens = {e8s=gas};
        from_subaccount: ?SubAccount = ?Blob.fromArray(subAccount);
        to: BlobAccountIdentifier = controllerAccountId(controller);
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