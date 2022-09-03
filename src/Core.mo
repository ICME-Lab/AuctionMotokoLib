import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";

module {
  public type User = Text;
  public type Price = Nat;
  public type Bid = (User, Price);
  public type Bids = List.List<Bid>;


  public class State(_auctionType: Text, _bidHistory: Bids, _locks: Bids, _phaseEndTime: Time.Time, _phaseCount: Nat, _buyoutPrice: Nat, _reservePrice: Nat) : State = this {
    // vars
    public var auctionType = _auctionType;
    public var bidHistory =_bidHistory;
    public var locks = _locks;
    public var phaseEndTime = _phaseEndTime;
    public var phaseCount = _phaseCount;
    public var buyoutPrice = _buyoutPrice;
    public var reservePrice = _reservePrice;

    public func copy(): State {
      State(auctionType, bidHistory, locks, phaseEndTime, phaseCount, buyoutPrice, reservePrice);
    };

    /* cond */
    public func isOverEndTime(_if: Bool): ?State {
      let result = (Time.now() > phaseEndTime);
      if (result != _if) null else ?this;
    };
    public func isLastTimeToEnd(_if: Bool, within: Int): ?State {
      let result = (within > (phaseEndTime - Time.now()));
      if (result != _if) null else ?this;
    };
    public func isOverPhaseCount(count: Nat, _if: Bool): ?State {
      let result = (phaseCount > count);
      if (result != _if) null else ?this;
    };
    public func isHigherPrevBid(newBid: Bid, _if: Bool): ?State {
      let result = switch (List.get<Bid>(bidHistory, 0)) {
        case (null) true;
        case (?highestBid) {
          if(newBid.1 > highestBid.1) true else false;
        };
      };
      if (result != _if) null else ?this;
    };
    public func isFirstTimeBidderEver(newBid: Bid, _if: Bool): ?State {
      var result = false;
      List.iterate<Bid>(bidHistory, func(bid){
        if (bid.0 == newBid.0) {
          result := true;
          return;
        };
      });
      if (result != _if) null else ?this;
    };
    public func isLockedBid(newBid: Bid, _if: Bool): ?State {
      var result = false;
      List.iterate<Bid>(locks, func(bid){
        if (bid == newBid) {
          result := true;
          return;
        };
      });
      if (result != _if) null else ?this;
    };
    public func isLockedBidder(newBid: Bid, _if: Bool): ?State {
      var result = false;
      List.iterate<Bid>(locks, func(bid){
        if (bid.0 == newBid.0) {
          result := true;
          return;
        };
      });
      if (result != _if) null else ?this;
    };
    public func isOverReservePrice(newBid: Bid, _if: Bool): ?State {
      let result = (newBid.1 > reservePrice);
      if (result != _if) null else ?this;
    };
    public func isOverbuyoutPrice(newBid: Bid, _if: Bool): ?State {
      let result = (newBid.1 > buyoutPrice);
      if (result != _if) null else ?this;
    };
    public func isEmptyLocks( _if: Bool): ?State {
      let result = (List.isNil<Bid>(locks));
      if (result != _if) null else ?this;
    };

    // public func canSelect(): ?State {
    //   let result = List.isNil<Bid>(bids);
    //   return ?this;
    // };

    /* do */
    // bidding
    public func pushBidHistory(newBid: Bid): ?State {
      bidHistory := List.push<Bid>(newBid, bidHistory);
      return ?this;
    };
    // !!!!! WIP popの代用
    public func replaceTopOrPushToLocks(newBid: Bid): ?State {
      locks := switch locks {
        case (?(h,t)) ?(newBid, t);
        case (null) ?(newBid, null);
      };
      // locks := List.push<Bid>(newBid, List.pop<Bid>(locks));
      return ?this;
    };

    // phase
    public func extendPhaseEnd(extraTime: Int): ?State {
      phaseEndTime += extraTime;
      return ?this;
    };
    public func incPhaseCount(): ?State {
      phaseCount += 1;
      return ?this;
    };

    // owner
    public func downBuyoutPrice(downPrice: Nat): ?State {
      if (downPrice > buyoutPrice) return ?this 
      else {
        buyoutPrice -= downPrice;
        return ?this
      }
    };
    public func unLockBidUnderPrice(price: Nat): ?State {
      locks := List.filter<Bid>(locks, func(bid) {
        if (price > bid.1) {
          // WIP unlock処理
          return false;
        }
        else {
          return true;
        }
      });
      return ?this;
    };

    // /* mutch */
    public func match(cond: ?State, fn: State->?State, fn_null: State->?State): ?State {
      switch (cond) {
        case (?s) fn(s);
        case ( _) fn_null(this); // WIP
      }
    };
    public func custom(fn: State->?State): ?State {
      fn(this);
    };

    /* show */
    public func showBids(): Bids {
      bidHistory;
    }
  };
}