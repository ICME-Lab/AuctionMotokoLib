import Core "Core";


import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";

module {
  type User = Core.User;
  type Price = Core.Price;
  type Bid = Core.Bid;
  type Bids =Core.Bids;

  public func bid_English(newBid: Bid): ?Core.State = do ? {
    var state = Core.State("English", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);
    let st = state.copy();

    st.isOverEndTime(false)!
      .match(
        st.isLastTimeToEnd(true, 10),
        func(s)=do?{s.extendPhaseEnd(10)!},
        func(s)=do?{s}
      )!
      .isHigherPrevBid(newBid, true)!
      .pushBidHistory(newBid)!
      .replaceTopOrPushToLocks(newBid)!
  };

  public func bid_Dutch(newBid: Bid): ?Core.State = do ? {
    var state = Core.State("Dutch", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);
    let st = state.copy();

    st
      .isOverEndTime(false)!
      .isOverbuyoutPrice(newBid, true)!
      .isEmptyLocks(true)!
      .replaceTopOrPushToLocks(newBid)!
      .pushBidHistory(newBid)!
  };

  public func priceDown_Dutch(): ?Core.State = do ? {
    var state = Core.State("Dutch", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);
    let st = state.copy();

    st
      .isOverEndTime(false)!
      .isEmptyLocks(true)!
      .downBuyoutPrice(1)!
  };

}