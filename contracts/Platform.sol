pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./Commodity.sol";
import "./SafeMath.sol";
import "./lib/Shared.sol";

contract Platform {
    using SafeMath for uint256;

    /// @notice Order for specific commodity.
    /// e.g. car part from supplier, car from manufacturer.
    struct Order {
        address payable creator;
        uint256 due;
        uint256 commodity; // index of commodity
        uint256 price;
        uint256 margin;
        address payable filler;
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

    Commodity CMD;

    Order[] public orders;
    uint256 public MAKER_FEE = 0 wei;
    uint256 public TAKER_FEE = 0 wei;
    uint256 public MARGIN_RATE = 0; // 0.0 to 100.0%

    mapping(address => uint8) public entities;

    //

    event orderCreated(address creator, uint256 due, uint256 commodity);
    event orderTaken(address filler, uint256 index);
    event orderFilled(address filler, uint256 index);
    event orderStoked(address filler, uint256 index);
    event orderCompleted(address creator, address filler, uint256 index);
    event orderCanceled(address creator, uint256 index);
    event orderOverdued(address creator, uint256 index, uint256 due);

    event makerFeeChange(uint256 from, uint256 to);
    event takerFeeChange(uint256 from, uint256 to);
    event marginRateChange(uint256 from, uint256 to);

    //

    constructor() public {
        entities[msg.sender] = uint8(Shared.Entity.SUPERVISOR);
    }

    modifier registered() {
        require(entities[msg.sender] > 0);
        _;
    }

    modifier supervisor() {
        require(entities[msg.sender] == uint8(Shared.Entity.SUPERVISOR));
        _;
    }

    function queryEntity(address addr) public view returns (uint8) {
        return entities[addr];
    }

    function register(address addr, uint8 entity) public supervisor {
        entities[addr] = entity;
    }

    function setMakerFee(uint256 mf) external supervisor {
        emit makerFeeChange(MAKER_FEE, mf);

        MAKER_FEE = mf;
    }

    function setTakerFee(uint256 tf) external supervisor {
        emit takerFeeChange(TAKER_FEE, tf);

        TAKER_FEE = tf;
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

    /// @param index The index of the commodity in the CMD.commodities list
    /// @return the index of the order created
    function createOrder(uint256 index, uint256 due)
        external
        payable
        registered
        returns (uint256)
    {
        require(msg.value >= MAKER_FEE, "Platform: make order fee not enough");
        require(due > now, "Platform: malformed parameter due");
        Shared.Detail memory commodity = CMD.getCommodity(index);

        uint256 price = commodity.price;
        uint256 margin = price.mul(MARGIN_RATE).div(1000);
        require(
            msg.value - MAKER_FEE > margin,
            "Platform: make order margin not enough"
        );
        orders.push(
            Order(
                msg.sender,
                now,
                index,
                price,
                margin,
                address(0),
                OrderStatus.OPEN
            )
        );

        emit orderCreated(msg.sender, due, index);
        return orders.length - 1;
    }

    /// @param index The index in the order list
    function takeOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(msg.value >= TAKER_FEE, "Platform: take order fee not enough");
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }

        order.filler = msg.sender;
        order.status = OrderStatus.TAKEN;

        emit orderTaken(msg.sender, index);
    }

    /// @param index The index in the order list
    function cancelOrder(uint256 index) external registered {
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

        order.status = OrderStatus.CANCELD;
        msg.sender.transfer(order.margin);

        emit orderCanceled(msg.sender, index);
    }

    /// @param index The index in the order list
    function fillOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(msg.sender == order.filler, "Platform: order not yours");
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }

        order.status = OrderStatus.FILLED;

        emit orderFilled(msg.sender, index);
    }

    function stockOrder(uint256 index, address stocker)
        external
        payable
        registered
    {
        Order storage order = orders[index];
        require(msg.sender == order.filler, "Platform: order not yours");
        require(entities[stocker] == uint8(Shared.Entity.DISTRIBUTOR));
        if (now > order.due) {
            order.status = OrderStatus.OVERDUE;
            revert("Platform: order overdue");
        }

        order.status = OrderStatus.STOCKED;

        emit orderStoked(msg.sender, index);
    }

    /// @notice Order creator finally completes by confirming received commodity.
    function completeOrder(uint256 index) external payable registered {
        Order storage order = orders[index];
        require(msg.sender == order.creator, "Platform: order not yours");
        require(
            order.status != OrderStatus.COMPLETED,
            "Platform: order already completed"
        );
        require(
            msg.value == order.price - order.margin,
            "Platform: payment not enough"
        );

        order.status = OrderStatus.COMPLETED;
        order.filler.transfer(order.price);

        emit orderCompleted(msg.sender, order.filler, index);
    }
}
