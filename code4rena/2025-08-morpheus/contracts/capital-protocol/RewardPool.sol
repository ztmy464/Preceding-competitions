// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LinearDistributionIntervalDecrease} from "../libs/LinearDistributionIntervalDecrease.sol";

import {IRewardPool, IERC165} from "../interfaces/capital-protocol/IRewardPool.sol";

contract RewardPool is IRewardPool, OwnableUpgradeable, UUPSUpgradeable {
    /* 
        struct RewardPool {
            uint128 payoutStart;
            uint128 decreaseInterval;
            uint256 initialReward;
            uint256 rewardDecrease;
            bool isPublic;
        }
     */
    RewardPool[] public rewardPools; // An array to store all reward pool configurations.

    /**********************************************************************************************/
    /*** Init, IERC165                                                                          ***/
    /**********************************************************************************************/

    // The constructor is used to disable initializers for the upgradeable proxy.
    constructor() {
        _disableInitializers(); // Prevents initialization on the implementation contract.
    }

    // Initializes the contract with a set of reward pools.
    function RewardPool_init(RewardPool[] calldata poolsInfo_) external initializer {
        __Ownable_init(); // Initializes Ownable features.
        __UUPSUpgradeable_init(); // Initializes UUPS upgradeable features.

        // Loops through the provided pool configurations and adds them.
        for (uint256 i = 0; i < poolsInfo_.length; i++) {
            addRewardPool(poolsInfo_[i]);
        }
    }

    // Checks if the contract supports a given interface ID (IERC165).
    function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {
        return interfaceId_ == type(IRewardPool).interfaceId || interfaceId_ == type(IERC165).interfaceId;
    }

    /**********************************************************************************************/
    /*** Reward pools management, `owner()` functionality                                       ***/
    /**********************************************************************************************/

    // Adds a new reward pool configuration to the contract.
    function addRewardPool(RewardPool calldata rewardPool_) public onlyOwner {
        require(rewardPool_.decreaseInterval > 0, "RP: invalid decrease interval"); // Ensures the decrease interval is valid.

        rewardPools.push(rewardPool_); // Appends the new pool to the array.

        emit RewardPoolAdded(rewardPools.length - 1, rewardPool_); // Emits an event with the new pool's index and data.
    }

    /**********************************************************************************************/
    /*** Main getters                                                                           ***/
    /**********************************************************************************************/

    // Checks if a reward pool exists at the given index.
    function isRewardPoolExist(uint256 index_) public view returns (bool) {
        return index_ < rewardPools.length; // Returns true if the index is within the array bounds.
    }

    // Checks if the reward pool at the given index is public.
    function isRewardPoolPublic(uint256 index_) public view returns (bool) {
        return rewardPools[index_].isPublic; // Returns the 'isPublic' flag of the pool.
    }

    // A view function that reverts if the specified reward pool does not exist.
    function onlyExistedRewardPool(uint256 index_) external view {
        require(isRewardPoolExist(index_), "RP: the reward pool doesn't exist");
    }

    // A view function that reverts if the specified reward pool is not public.
    function onlyPublicRewardPool(uint256 index_) external view {
        require(isRewardPoolPublic(index_), "RP: the pool isn't public");
    }

    // A view function that reverts if the specified reward pool is public.
    function onlyNotPublicRewardPool(uint256 index_) external view {
        require(!isRewardPoolPublic(index_), "RP: the pool is public");
    }

    //~ Calculates the total rewards for a given pool over a specified time period.
    function getPeriodRewards(uint256 index_, uint128 startTime_, uint128 endTime_) external view returns (uint256) {
        // Returns 0 if the pool does not exist.
        if (!isRewardPoolExist(index_)) {
            return 0;
        }

        RewardPool storage rewardPool = rewardPools[index_]; // Gets the pool configuration from storage.

        // Delegates the calculation to the LinearDistributionIntervalDecrease library.
        return
            LinearDistributionIntervalDecrease.getPeriodReward(
                rewardPool.initialReward,
                rewardPool.rewardDecrease,
                rewardPool.payoutStart,
                rewardPool.decreaseInterval,
                startTime_,
                endTime_
            );
    }

    /**********************************************************************************************/
    /*** UUPS                                                                                   ***/
    /**********************************************************************************************/

    // Returns the version of the contract.
    function version() external pure returns (uint256) {
        return 1;
    }

    // Authorizes an upgrade, restricted to the owner.
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}