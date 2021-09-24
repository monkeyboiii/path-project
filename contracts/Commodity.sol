pragma solidity ^0.5.1;

import "./Platform.sol";

/// parts for sale
contract Commodity {
    struct Detail {
        string name;
        uint256 price;
        bool available;
    }

    Detail[] public commodities;
    mapping(address => uint256[]) merchants; // index in the commodities array
    Platform platform;
    uint256 public LIST_FEE = 0 wei;
    address private SUPERVISOR;

    event commodityAdded(address merchant, string name, uint256 price);
    event commodityEnabled(address merchant, string name);
    event commodityDisabled(address merchant, string name);
    event commodityRemoved(address merchant, string name);
    event listFeeChange(uint256 from, uint256 to);

    constructor() public {
        SUPERVISOR = msg.sender;
    }

    modifier supervisor() {
        require(msg.sender == SUPERVISOR);
        _;
    }

    modifier merchant() {
        require(
            platform.entities[msg.sender] ==
                uint8(platform.Entity.MANUFACTURER) ||
                platform.entities[msg.sender] == uint8(platform.Entity.SUPPLIER)
        );
        _;
    }

    /// @dev list commodities for sale
    function add(
        string calldata name,
        uint256 price,
        bool available
    ) external payable merchant returns (uint256) {
        require(msg.value >= LIST_FEE, "Commodity: list fee not enough");

        commodities[msg.sender].push(Detail(name, price, available));
        uint256 index = commodities.length - 1;
        merchants[msg.sender].push(index);

        emit commodityAdded(msg.sender, name, price);
        return index;
    }

    function enableSale(uint256 index, bool available) external merchant {
        Detail detail = commodities[index];
        require(
            detail && !detail.available,
            "Commodity: commodity not exist or already available"
        );

        detail.available = true;

        emit commodityEnabled(msg.sender, name);
    }

    function disableSale(uint256 index, bool available) external merchant {
        Detail detail = commodities[index];
        require(
            detail && !detail.available,
            "Commodity: commodity not exist or already unavailable"
        );

        detail.available = false;

        emit commodityDisbled(msg.sender, name);
    }

    function remove(uint256 index) external merchant {
        Detail detail = commodities[index];
        require(detail, "Commodity: commodity not exist");

        delete commodities[index];

        emit commodityAdded(msg.sender, name, price);
    }

    function setFee(uint256 _list_fee) external supervisor {
        emit listFeeChange(LIST_FEE, _list_fee);

        LIST_FEE = _list_fee;
    }
}
