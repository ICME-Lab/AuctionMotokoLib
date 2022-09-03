
import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";

module {
  type User = Text;
  type Price = Nat;
  type Bid = (User, Price);
  type Bids = List.List<Bid>;
  
  type State = {
    var bids: Bids;
    end: Time.Time;
    enBid: Bid -> ?State;
    isOver: () -> ?State;
    select: () -> ?Bid;
  };


  class State1(_bids: Bids, _end: Time.Time) : State = this {
    public var bids = _bids;
    public let end = _end;

    public let enBid = func(newBid: Bid): ?State {
      bids := switch (List.get<Bid>(bids, 0)) {
        case (null) List.push<Bid>(newBid, bids);
        case (?highestBid) {
          if(newBid.1 > highestBid.1) List.push<Bid>(newBid, bids)
          else bids
        };
      };
      return return ?this;
    };
    public let isOver = func(): ?State {
      if (Time.now() > end) return ?State2(bids, end)
      // else return ?this
      else return null // undefine state
    };
    // undefine state
    public let select = func(): ?Bid {
      return null
    };
  };

  class State2(_bids: Bids, _end: Time.Time): State = this {
    public var bids = _bids;
    public let end = _end;

    // undefine state
    public let enBid = func(newBid: Bid): ?State {
      return null
    };
    // undefine state
    public let isOver = func(): ?State {
      return null
    };
    public let select = func(): ?Bid {
      return List.get<Bid>(bids, 0)
    };
  };


  public func test() {
    let sec = 1_000_000_000;
    let minutes =  60 * sec;
    let hour = 60 * minutes;
    let day = 24 * hour;
    let week =  7 * day;

    var state = State2(List.nil<Bid>(), Time.now() + 1*minutes);

    let state_op = do ? {
      state.enBid(("A", 10))!
    };


    switch (state_op) {
      case (?_state)  {
        state := _state;
        Debug.print("ok")
      };
      case (null) {
        Debug.print("error")
      }
    }

  };
}