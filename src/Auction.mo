//import from motoko base
import Time "mo:base/Time";

module {
  /* Types */

  type PhaseCond = {
    
  };
  type BidCond = {
    
  };
  type SelectCond = {

  };
  type Info = {

  };
  type Phase = {
    #SelectPhase: {
      selectCond: SelectCond;
      info: Info;
    };
    #BidPhase: {
      nextPhases:  [(PhaseCond, Phase)];
      bidCondition: BidCond;
      info: Info;
    };
  };
}