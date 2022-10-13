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



module {

  public type AccountId = (Principal, Nat);
  public type Value = Nat64;
  public type Account = {
    value: Value;
    locked: Bool;
  };

  public class FungibleTokens() = this {

    let ZERO_VALUE: Value = 0;
    let EMPTY_ACCOUNT: Account = {
      value = ZERO_VALUE;
      locked = false;
    };

    func equalId(a: AccountId, b: AccountId): Bool {a.0 == b.0 and a.1 == b.1};
    func hashId(a: AccountId): Hash.Hash {Text.hash(Principal.toText(a.0) # Nat.toText(a.1))};

    // Tokens under management by this service
    let tokenEntries: [(AccountId, Account)] = [];
    let tokens = HashMap.fromIter<AccountId, Account>(tokenEntries.vals(), 0, equalId, hashId);

    public func wrap(user: Principal, amount: Value) {
      let mainAccountId = (user, 0);
      let mainAccount = switch (tokens.get(mainAccountId)) {
        case (?account) {
          {
            value = account.value + amount;
            locked = false; // main account is always unlocked
          }
        };
        case (_) {
          {
            value = ZERO_VALUE + amount;
            locked = false; // main account is always unlocked
          }
        }
      };

      // change state
      tokens.put(mainAccountId, mainAccount);
    };

    public func unwrap(user: Principal, amount: Value): Result.Result<(), Text> {
      let mainAccountId = (user, 0);
      let mainAccount = switch (tokens.get(mainAccountId)) {
        case (?account) {
          if (amount > account.value) return #err("InsufficientFunds");
          {
            value = account.value - amount;
            locked = false; // main account is always unlocked
          }
        };
        case (_) return #err("InsufficientFunds");
      };

      // change state
      tokens.put(mainAccountId, mainAccount);
      
      return #ok;
    };

    public func subdivide((user, sub): AccountId, amount: Value): Result.Result<(), Text> {
      let mainAccountId = (user, 0);
      let subAccountId = (user, sub);

      let mainAccount = switch (tokens.get(mainAccountId)) {
        case (?account) {
          if (amount > account.value) return #err("InsufficientFunds");
          {
            value = account.value - amount;
            locked = false; // main account is always unlocked
          }
        };
        case (_) return #err("InsufficientFunds -The account does not exist.-");
      };
      let subAccount = switch (tokens.get(subAccountId)) {
        case (?account) {
          {
            value = account.value + amount;
            locked = account.locked;
          }
        };
        case (_) {
          {
            value = amount;
            locked = false; // initial lock state is false
          }
        };
      };

      // change state
      tokens.put(mainAccountId, mainAccount);
      tokens.put(subAccountId, subAccount);

      return #ok;

    };

    public func putbackAll((user, sub): AccountId): Result.Result<(), Text> {
      let mainAccountId = (user, 0);
      let subAccountId = (user, sub);
      let subAccount = this.balance(subAccountId);

      if (subAccount.locked == true) return #err("The Account is locked");

      let mainAccount = switch (tokens.get(mainAccountId)) {
        case (?account) {
          {
            value = account.value + subAccount.value;
            locked = false; // main account is always unlocked
          }
        };
        case (_) {
          /* If it comes here, it might be wrong. */
          Debug.print(" it might be wrong");
          {
            value = ZERO_VALUE + subAccount.value;
            locked = false; // main account is always unlocked
          }
        };
      };

      // change state
      tokens.put(mainAccountId, mainAccount);
      tokens.put(subAccountId, EMPTY_ACCOUNT); // subAcount must be empty

      return #ok;
    };

    public func balance(accountId: AccountId): Account {
      switch (tokens.get(accountId)) {
        case (?account) account;
        case (_) EMPTY_ACCOUNT;
      }
    };


    // only service
    public func enLock(accountId: AccountId) {
      if (accountId.1 == 0) assert(false); // WIP, error handling
      let account = switch (tokens.get(accountId)) {
        case (?account) {
          {
            value = account.value;
            locked = true;
          }
        };
        case (_) { // WIP, Return error or initialize hashmap value
          {
            value = ZERO_VALUE;
            locked = true;
          }
        };
      };

      // change state
      tokens.put(accountId, account);
    };

    // only service
    public func unLock(accountId: AccountId) {
      if (accountId.1 == 0) assert(false); // WIP, error handling
      let account = switch (tokens.get(accountId)) {
        case (?account) {
          {
            value = account.value;
            locked = false;
          }
        };
        case (_) { // WIP, Return error or initialize hashmap value
          {
            value = ZERO_VALUE;
            locked = false;
          }
        };
      };

      // change state
      tokens.put(accountId, account);
    };
      // only service
    public func pay(to: Principal, from: Principal, sub: Nat, amount: Value): Result.Result<(), Text> {
      if (sub == 0) assert(false); // WIP, error handling

      let toAccountId = (to, 0);
      let fromAccountId = (from, sub);

      let fromAccount = switch (tokens.get(fromAccountId)) {
        case (?account) {
          if (amount > account.value) return #err("InsufficientFunds");
          if (account.locked != true) return #err("Account is already locked");
          {
            value = account.value - amount;
            locked = false; // 
          }
        };
        case (_) return #err("InsufficientFunds -The \"from\" account does not exist.-");
      };

      let toAccount = switch (tokens.get(toAccountId)) {
        case (?account) {
          {
            value = account.value + amount;
            locked = false; // 
          }
        };
        case (_) return #err("The \"to\" account does not exist"); // WIP, Return error or initialize hashmap value
      };

      // change state
      tokens.put(toAccountId, toAccount);
      tokens.put(fromAccountId, fromAccount);

      return #ok;

    };
  };
}