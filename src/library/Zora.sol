/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

library Zora {
  struct Decimal {
    uint256 value;
  }

  struct BidShares {
    // % of sale value that goes to the _previous_ owner of the nft
    Decimal prevOwner;
    // % of sale value that goes to the original creator of the nft
    Decimal creator;
    // % of sale value that goes to the seller (current owner) of the nft
    Decimal owner;
  }
}
