pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "../Platform.sol";
import "../Commodity.sol";
import "../lib/Shared.sol";
import "../Part.sol";

contract Supplier {
    Platform plt;
    Commodity CMD;
    Part pt;
    address private supervisor;

    constructor() public {
        supervisor = msg.sender;
    }

    function addCommodity(
        string calldata name,
        uint256 price,
        bool available
    ) external payable returns (uint256) {
        return CMD.add(name, price, available);
    }

    function createOrder(uint256 index, uint256 due)
        external
        payable
        returns (uint256)
    {
        return plt.createOrder(index, due);
    }

    function takeOrder(uint256 index) external payable {
        plt.takeOrder(index);
    }

    function fillOrder(uint256 index, address distributor)
        external
        payable
        returns (uint256)
    {
        uint256 tokenId = pt.mint(msg.sender);
        pt.approve(distributor, 1);
        Shared.Order memory detail = plt.getOrder(index);
        return tokenId;
    }

    function completeOrder(uint256 index) external payable {
        Shared.Order memory detail = plt.getOrder(index);
    }
}
