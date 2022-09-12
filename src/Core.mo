import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";

module {
  public type User = Text;
  public type Price = Nat;
  public type Bid = (User, Price);
  public type Bids = List.List<Bid>;


  public class State(
    _auctionType: Text,
    _bidList: Bids,
    _phaseEndTime: Time.Time,
    _phaseCount: Nat,
    _buyoutPrice: Nat,
    _reservePrice: Nat,
    
    ) : State = this {
    // vars
    public var auctionType = _auctionType;
    public var bidList =_bidList;
    public var phaseEndTime = _phaseEndTime;
    public var phaseCount = _phaseCount;
    public var buyoutPrice = _buyoutPrice;
    public var reservePrice = _reservePrice;

    // public var resutl: Result.Result<(),Text> = #ok;
    public var result: Text = "";

    public func copy(): State {
      State(auctionType, bidList, phaseEndTime, phaseCount, buyoutPrice, reservePrice);
    };

    /* cond */
    public func isAuctionType(t: Text) : ?State {
      if (auctionType == t) return ?this
      else {
        result := "isAuctionType";
        null;
      };
    };
    public func isOverEndTime(_if: Bool): ?State {
      let r = (Time.now() > phaseEndTime);
      if (r != _if) {
        result := "isOverEndTime";
        null;
      } else ?this;
    };
    public func isLastTimeToEnd(_if: Bool, within: Int): ?State {
      let r = (within > (phaseEndTime - Time.now()));
      if (r != _if) {
        result := "isLastTimeToEnd";
        null;
      } else ?this;
    };
    public func isOverPhaseCount(count: Nat, _if: Bool): ?State {
      let r = (phaseCount > count);
      if (r != _if) {
        result := "isOverPhaseCount";
        null;
      } else ?this;
    };
    public func isHigherThanPrevBid(newBid: Bid, _if: Bool): ?State {
      let r = switch (List.get<Bid>(bidList, 0)) {
        case (null) true;
        case (?lastBid) {
          if(newBid.1 > lastBid.1) true else false;
        };
      };
      if (r != _if) {
        result := "isHigherPrevBid";
        null;
      } else ?this;
    };
    public func isFirstTimeBidderEver(newBid: Bid, _if: Bool): ?State {
      var r = false;
      List.iterate<Bid>(bidList, func(bid){
        if (bid.0 == newBid.0) {
          r := true;
          return;
        };
      });
      if (r != _if) {
        result := "isFirstTimeBidderEver";
        null;
      } else ?this;
    };
    
    public func isOverReservePrice(newBid: Bid, _if: Bool): ?State {
      let r = (newBid.1 > reservePrice);
      if (r != _if) {
        result := "isOverReservePrice";
        null;
      } else ?this;
    };
    public func isOverbuyoutPrice(newBid: Bid, _if: Bool): ?State {
      let r = (newBid.1 > buyoutPrice);
      if (r != _if) {
        result := "isOverbuyoutPrice";
        null;
      } else ?this;
    };

    /* do */
    // bidding
    public func pushBid(newBid: Bid): ?State {
      bidList := List.push<Bid>(newBid, bidList);
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
      bidList;
    }
  };
}