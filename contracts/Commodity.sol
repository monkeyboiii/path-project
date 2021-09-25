pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./Platform.sol";
import "./lib/Shared.sol";

/// parts for sale
contract Commodity {
    Platform platform;
    address private SUPERVISOR;
    uint256 public LIST_FEE = 0 wei;

    Shared.Detail[] public commodities;
    mapping(address => uint256[]) merchants; // index in the commodities array

    //

    event commodityAdded(address merchant, string name, uint256 price);
    event commodityEnabled(address merchant, string name);
    event commodityDisabled(address merchant, string name);
    event commodityRemoved(address merchant, string name);
    event listFeeChange(uint256 from, uint256 to);

    //

    constructor() public {
        SUPERVISOR = msg.sender;
    }

    modifier supervisor() {
        require(msg.sender == SUPERVISOR);
        _;
    }

    modifier merchant() {
        require(
            platform.queryEntity(msg.sender) ==
                uint8(Shared.Entity.MANUFACTURER) ||
                platform.queryEntity(msg.sender) ==
                uint8(Shared.Entity.SUPPLIER)
        );
        _;
    }

    function setFee(uint256 _list_fee) external supervisor {
        emit listFeeChange(LIST_FEE, _list_fee);

        LIST_FEE = _list_fee;
    }

    function getCommodity(uint256 index)
        public
        view
        returns (Shared.Detail memory)
    {
        require(
            index < commodities.length,
            "Commodity: non-existing commodity"
        );
        return commodities[index];
    }

    //

    /// @dev list commodities for sale
    function add(
        string calldata name,
        uint256 price,
        bool available
    ) external payable merchant returns (uint256) {
        require(msg.value >= LIST_FEE, "Commodity: list fee not enough");

        commodities.push(Shared.Detail(name, price, available));
        uint256 index = commodities.length - 1;
        merchants[msg.sender].push(index);

        emit commodityAdded(msg.sender, name, price);
        return index;
    }

    function enableSale(uint256 index) external merchant {
        Shared.Detail storage detail = commodities[index];
        require(
            !detail.available,
            "Commodity: commodity not exist or already available"
        );

        detail.available = true;

        emit commodityEnabled(msg.sender, detail.name);
    }

    function disableSale(uint256 index) external merchant {
        Shared.Detail storage detail = commodities[index];
        require(
            detail.available,
            "Commodity: commodity not exist or already unavailable"
        );

        detail.available = false;

        emit commodityDisabled(msg.sender, detail.name);
    }

    function remove(uint256 index) external merchant {
        Shared.Detail storage detail = commodities[index];
        require(
            bytes(detail.name).length > 0,
            "Commodity: commodity not exist"
        );

        string memory name = detail.name;
        for (uint256 i = 0; i < merchants[msg.sender].length; i++) {
            if (merchants[msg.sender][i] == index) {
                // leave a gap
                delete merchants[msg.sender][i];
                delete commodities[index];

                emit commodityRemoved(msg.sender, name);
                break;
            }
        }
    }
}
