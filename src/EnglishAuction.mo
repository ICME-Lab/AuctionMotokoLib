import Core "Core";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Result "mo:base/Result";
import Time "mo:base/Time";


module {
  type User = Core.User;
  type Price = Core.Price;
  type Bid = Core.Bid;
  type Bids =Core.Bids;

  // public func bid(newBid: Bid, state: Core.State): Result.Result<Core.State, Text> {
  //    let st = state.copy();
  //   switch (do?{
  //     // var state = Core.State("English", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);

      st.isAuctionType("English")!
        .isOverEndTime(false)!
        .match(
          st.isLastTimeToEnd(true, 10),
          func(s)=do?{s.extendPhaseEnd(10)!},
          func(s)=do?{s}
        )!
        .isHigherPrevBid(newBid, true)!
        .pushBidHistory(newBid)!
        .replaceTopOrPushToLocks(newBid)!
    }) {
      case (?_) return #ok(st);
      case (_) return #err(st.result)
    }
  };

  // public func close(newBid: Bid): ?Core.State = do ? {
  //   var state = Core.State("Dutch", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);
  //   let st = state.copy();

  //   st
  //     .isOverEndTime(false)!
  //     .isOverbuyoutPrice(newBid, true)!
  //     .isEmptyLocks(true)!
  //     .replaceTopOrPushToLocks(newBid)!
  //     .pushBidHistory(newBid)!
  // };

  // public func priceDown_Dutch(): ?Core.State = do ? {
  //   var state = Core.State("Dutch", List.nil<Bid>(), List.nil<Bid>(), Time.now(), 0, 100, 100);
  //   let st = state.copy();

  //   st
  //     .isOverEndTime(false)!
  //     .isEmptyLocks(true)!
  //     .downBuyoutPrice(1)!
  // };

}