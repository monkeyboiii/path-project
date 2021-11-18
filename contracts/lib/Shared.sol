pragma solidity ^0.5.1;

library Shared {
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

    /// @notice Details of commodity
    struct Detail {
        string name;
        uint256 price;
        bool available;
    }

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
}
