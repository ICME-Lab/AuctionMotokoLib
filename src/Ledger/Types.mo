// Motoko base
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";

module {
  public type Tokens = {
    e8s: Nat64;
  };
  public type TimeStamp =  {
    timestamp_nanos:  Nat64;
  };
  public type BlobAccountIdentifier = Blob;
  public type SubAccount = Blob;
  public type BlockIndex = Nat64;
  public type Memo = Nat64;

  public type TransferArgs = {
    memo: Memo;
    amount: Tokens;
    fee: Tokens;
    from_subaccount: ?SubAccount;
    to: BlobAccountIdentifier;
    created_at_time: ?TimeStamp;
  };

  public type TransferError = {
    #BadFee : { expected_fee : Tokens; };
    #InsufficientFunds : { balance: Tokens; };
    #TxTooOld : { allowed_window_nanos: Nat64 };
    #TxCreatedInFuture;
    #TxDuplicate : { duplicate_of: BlockIndex; }
  };

  public type TransferResult = {
    #Ok : BlockIndex;
    #Err : TransferError;
  };

  public type AccountBalanceArgs = {
    account: BlobAccountIdentifier;
  };

  public type Interface = actor {
    transfer        : TransferArgs       -> async TransferResult;
    account_balance : AccountBalanceArgs -> async Tokens;
  };
}