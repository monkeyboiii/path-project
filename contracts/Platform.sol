pragma solidity ^0.5.1;

import "./Commodity.sol";
import "./SafeMath.sol";

contract Platform {
    using SafeMath for uint256;

    /// @notice Roles in automoblie supply chain industry, regulated by
    /// supervisor.
    enum Entity {
        _NONE,
        CUSTOMER,
        DEALERSHIP,
        DISTRIBUTOR,
        INVESTOR,
        MANUFACTURER,
        SERVICE,
        SUPERVISOR,
        SUPPLIER
    }

    /// @notice Order for specific commodity.
    /// e.g. car part from supplier, car from manufacturer.
    struct Order {
        address creator;
        uint256 time; // time to finish
        uint256 commodity; // index of commodity
        address filler;
        OrderStatus status;
    }

    enum OrderStatus {
        _NONE,
        OPEN,
        TAKEN,
        FILLED,
        STOCKED,
        COMPLETED,
        CANCELD,
        OVERDUE
    }

    //

    mapping(address => uint8) public entities;
    Order[] public orders;
    Commodity cmd;
    uint256 public PLACE_FEE = 0 wei;
    uint256 public MARGIN_RATE = 0; // 0.0 to 100.0%

    //

    event orderCreated(address creator, uint256 due, uint256 commodity);
    event orderTaken(address creator, uint256 index);
    event orderFilled(address creator, uint256 due, uint256 commodity);
    event orderStoked(address creator, uint256 due, uint256 commodity);
    event orderCompleted(address creator, uint256 index);
    event orderCanceled(address creator, uint256 index);
    event orderOverdued(address creator, uint256 index, uint256 due);

    event placeFeeChange(uint256 from, uint256 to);
    event marginRateChange(uint256 from, uint256 to);

    //

    constructor() public {
        entities[msg.sender] = uint8(Entity.SUPERVISOR);
    }

    modifier registered() {
        require(entities[msg.sender] > 0);
        _;
    }

    modifier supervisor() {
        require(entities[msg.sender] == uint8(Entity.SUPERVISOR));
        _;
    }

    function register(address addr, uint8 entity) public supervisor {
        entities[addr] = entity;
    }

    function setPlaceFee(uint256 place_fee) external supervisor {
        emit placeFeeChange(PLACE_FEE, place_fee);

        PLACE_FEE = place_fee;
    }

    function setMarginRate(uint256 margin_rate) external supervisor {
        require(
            margin_rate >= 0 && margin_rate <= 1000,
            "Platform: margin rate out of range [0, 1000]"
        );
        emit marginRateChange(MARGIN_RATE, margin_rate);

        MARGIN_RATE = margin_rate;
    }

    //

    /// @return the index of the order created
    function createOrder(uint256 commodity, uint256 due)
        external
        payable
        registered
        returns (uint256)
    {
        require(msg.value >= PLACE_FEE, "Platform: place order fee not enough");
        require(due > now, "Platform: malformed parameter due");
        require(commodity >= Commodity.commodities.length , "Platform: non-existing commodity");

        orders.push(
            Order(now, commodity, msg.sender, address(0), OrderStatus.OPEN)
        );

        emit orderCreated(msg.sender, due, commodity);
        return orders.length - 1;
    }

    function takeOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(
            msg.value >= order.price.mul(MARGIN_RATE).div(1000),
            "Platform: place order fee not enough"
        );
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }

        order.filler = msg.sender;
        order.status = OrderStatus.TAKEN;

        emit orderTaken(msg.sender, index);
    }

    function cancelOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(msg.sender == order.creator, "Platform: order not yours");
        require(
            order.status == OrderStatus.OPEN,
            "Platform: cannot cancel order"
        );
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }

        order.filler = msg.sender;
        order.status = OrderStatus.TAKEN;

        msg.sender.transfer(order.price);

        emit orderTaken(msg.sender, index);
    }

    function fillOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(msg.sender == order.filler);
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }
    }

    function stockOrder(uint256 index) external payable registered {}

    /// @notice Order creator finally completes by confirming received commodity.
    function completeOrder() external payable registered {}
}
