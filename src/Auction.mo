import Core "Core";


import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";


module {
  type User = Core.User;
  type Price = Core.Price;
  type Bid = Core.Bid;
  type Bids = Core.Bids;

  type Auction = {
    #Open: Core.State;
    #Close;
  };

  /*
  NFTの管理
  FTの管理
  <(BoxId, Nat), Balance>, {#lock, #unlock}
  */

}