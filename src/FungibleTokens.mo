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



module {

  public type AccountId = (Principal, Nat);
  public type Value = Nat64;
  public type Account = {
    value: Value;
    locked: Bool;
  };

  public class FungibleTokens() {

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

    public func subdivide((user, sub): AccountId, amount: Value) {
      let mainAccountId = (user, 0);
      let subAccountId = (user, sub);

      let mainAccount = switch (tokens.get(mainAccountId)) {
        case (?account) {
          if (amount > account.value) return (); // WIP
          {
            value = account.value - amount;
            locked = false; // main account is always unlocked
          }
        };
        case (_) return ();
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
    public func pay(to: Principal, from: Principal, sub: Nat, amount: Value) {
      if (sub == 0) assert(false); // WIP, error handling

      let toAccountId = (to, 0);
      let fromAccountId = (from, sub);

      let fromAccount = switch (tokens.get(fromAccountId)) {
        case (?account) {
          if (amount > account.value) return (); // WIP
          if (account.locked != true) return (); // WIP
          {
            value = account.value - amount;
            locked = false; // 
          }
        };
        case (_) return (); // WIP
      };

      let toAccount = switch (tokens.get(toAccountId)) {
        case (?account) {
          {
            value = account.value + amount;
            locked = false; // 
          }
        };
        case (_) return (); // WIP, Return error or initialize hashmap value
      };

      // change state
      tokens.put(toAccountId, toAccount);
      tokens.put(fromAccountId, fromAccount);

    };
  };
}