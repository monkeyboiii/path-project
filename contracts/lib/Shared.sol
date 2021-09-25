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
}
