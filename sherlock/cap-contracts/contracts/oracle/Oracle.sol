// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { Access } from "../access/Access.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { PriceOracle } from "./PriceOracle.sol";
import { RateOracle } from "./RateOracle.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Oracle
/// @author kexley, Cap Labs
/// @notice Price and Rate oracles are unified
contract Oracle is IOracle, UUPSUpgradeable, Access, PriceOracle, RateOracle {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IOracle
    function initialize(address _accessControl) external initializer {
        __Access_init(_accessControl);
        __UUPSUpgradeable_init();
        __PriceOracle_init_unchained();
        __RateOracle_init_unchained();
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override checkAccess(bytes4(0)) { }
}
