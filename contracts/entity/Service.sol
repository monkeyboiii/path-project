pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "../Part.sol";

contract Service {
    Part pt;

    function trace(uint256 tokenId) external view returns (string memory) {
        return pt.trace(tokenId);
    }
}
