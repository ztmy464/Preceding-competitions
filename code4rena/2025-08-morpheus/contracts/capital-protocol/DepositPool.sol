// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {PRECISION} from "@solarity/solidity-lib/utils/Globals.sol";

import {IDepositPool, IERC165} from "../interfaces/capital-protocol/IDepositPool.sol";
import {IRewardPool} from "../interfaces/capital-protocol/IRewardPool.sol";
import {IDistributor} from "../interfaces/capital-protocol/IDistributor.sol";

import {LockMultiplierMath} from "../libs/LockMultiplierMath.sol";
import {ReferrerLib} from "../libs/ReferrerLib.sol";

contract DepositPool is IDepositPool, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    using ReferrerLib for ReferrerData;
    using ReferrerLib for ReferrerTier[];

    uint128 constant DECIMAL = 1e18;

    bool public isNotUpgradeable;

    /** @dev Main stake token for the contract */
    address public depositToken;

    /**
     * @dev `L1SenderV2` contract address
     * v7 update, moved to the `Distributor` contract.
     */
    address public unusedStorage0;

    /**
     * @dev Contain information about reward pools. Removed in `DepositPool`,
     * v6 update, moved to the `RewardPool` contract.
     */
    Pool[] public unusedStorage1;

    /** @dev Contain internal data about the reward pools, necessary for calculations */
    /* 
    struct RewardPoolData {
        uint128 lastUpdate;
        uint256 rate;
        uint256 totalVirtualDeposited;
    }
     */
    mapping(uint256 => RewardPoolData) public rewardPoolsData;

    /* 
    struct UserData {
        uint128 lastStake;
        uint256 deposited;
        uint256 rate;
        uint256 pendingRewards;
        // `DistributionV2` storage updates
        uint128 claimLockStart;
        uint128 claimLockEnd;
        uint256 virtualDeposited;
        // `DistributionV4` storage updates
        uint128 lastClaim;
        // `DistributionV5` storage updates
        address referrer;
    }
     */
    /** @dev Contain internal data about the users deposits, necessary for calculations */
    mapping(address => mapping(uint256 => UserData)) public usersData;

    /** @dev Contain total real deposited amount for `depositToken` */
    uint256 public totalDepositedInPublicPools;

    /**
     * @dev UPGRADE. `DistributionV4` storage updates, add pool limits.
     * Removed in `DepositPool`, v6 update, moved to `rewardPoolsProtocolDetails`
     */
    mapping(uint256 => RewardPoolLimits) public unusedStorage2;

    /** @dev UPGRADE `DistributionV5` storage updates, add referrers. */
    //~ Configuration of the `referrer tiers` corresponding to the `reward pool`
    mapping(uint256 => ReferrerTier[]) public referrerTiers;
    /* 
    struct ReferrerData {
        uint256 amountStaked;          // 这个推荐人“下线用户”们的总存款额
        uint256 virtualAmountStaked;   // 虚拟加权后的存款额（乘以推荐人 tier 的 multiplier）
        uint256 pendingRewards;        // 已累计但还没领取的推荐奖励
        uint256 rate;                  // 上次更新时的 reward pool 的 rate（利率/指数）
    }
    */
    mapping(address => mapping(uint256 => ReferrerData)) public referrersData;
    /** @dev UPGRADE `DistributionV5` end. */

    /** @dev UPGRADE `DistributionV6` storage updates, add addresses allowed to claim. Add whitelisted claim receivers. */
    //~ 用户 A 可以授权某些地址代为领取奖励
    mapping(uint256 => mapping(address => mapping(address => bool))) public claimSender;
    mapping(uint256 => mapping(address => address)) public claimReceiver;
    /** @dev UPGRADE `DistributionV6` end. */

    /** @dev UPGRADE `DepositPool`, v7. Storage updates, add few deposit pools. */
    /** @dev This flag determines whether the migration has been completed. */
    bool public isMigrationOver;

    /** @dev `Distributor` contract address. */
    address public distributor;

    /** @dev Contain information about rewards pools needed for this contract. */
    /* 
    RewardPoolProtocolDetails：某个奖励池的规则配置和全局累计
        struct RewardPoolProtocolDetails {
            uint128 withdrawLockPeriodAfterStake;   // 存款后多久才能取出
            uint128 claimLockPeriodAfterStake;      // 存款后多久才能领取奖励
            uint128 claimLockPeriodAfterClaim;      // 上次领取后多久才能再次领取
            uint256 minimalStake;                   // 最小存款额（门槛）
            uint256 distributedRewards;             // 已经分发出去的奖励总额
        }
     */
    mapping(uint256 => RewardPoolProtocolDetails) public rewardPoolsProtocolDetails;
    /** @dev UPGRADE `DepositPool`, v7 end. */

    /**********************************************************************************************/
    /*** Init, IERC165                                                                          ***/
    /**********************************************************************************************/

    constructor() {
        _disableInitializers();
    }

    function DepositPool_init(address depositToken_, address distributor_) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        depositToken = depositToken_;
        setDistributor(distributor_);
    }

    function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {
        return interfaceId_ == type(IDepositPool).interfaceId || interfaceId_ == type(IERC165).interfaceId;
    }
    //~ ✅
    /**********************************************************************************************/
    /*** Global contract management functionality for the contract `owner()`                    ***/
    /**********************************************************************************************/

    function setDistributor(address value_) public onlyOwner {
        //~ IERC165: Interface check:
        //~ asking `value_` whether provide the implementation of `IDistributor`.
        require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "DR: invalid distributor address");

        if (distributor != address(0)) {
            //~ Reset the allowance to 0
            IERC20(depositToken).approve(distributor, 0);
        }
        IERC20(depositToken).approve(value_, type(uint256).max);

        distributor = value_;

        emit DistributorSet(value_);
    }

    function setRewardPoolProtocolDetails(
        uint256 rewardPoolIndex_,
        uint128 withdrawLockPeriodAfterStake_,
        uint128 claimLockPeriodAfterStake_,
        uint128 claimLockPeriodAfterClaim_,
        uint256 minimalStake_
    ) public onlyOwner {
        RewardPoolProtocolDetails storage rewardPoolProtocolDetails = rewardPoolsProtocolDetails[rewardPoolIndex_];

        rewardPoolProtocolDetails.withdrawLockPeriodAfterStake = withdrawLockPeriodAfterStake_;
        rewardPoolProtocolDetails.claimLockPeriodAfterStake = claimLockPeriodAfterStake_;
        rewardPoolProtocolDetails.claimLockPeriodAfterClaim = claimLockPeriodAfterClaim_;
        rewardPoolProtocolDetails.minimalStake = minimalStake_;

        emit RewardPoolsDataSet(
            rewardPoolIndex_,
            withdrawLockPeriodAfterStake_,
            claimLockPeriodAfterStake_,
            claimLockPeriodAfterClaim_,
            minimalStake_
        );
    }

    function migrate(uint256 rewardPoolIndex_) external onlyOwner {
        require(!isMigrationOver, "DS: the migration is over");
        if (totalDepositedInPublicPools == 0) {
            isMigrationOver = true;
            emit Migrated(rewardPoolIndex_);

            return;
        }

        IRewardPool rewardPool_ = IRewardPool(IDistributor(distributor).rewardPool());
        rewardPool_.onlyExistedRewardPool(rewardPoolIndex_);
        rewardPool_.onlyPublicRewardPool(rewardPoolIndex_);

        // Transfer yield to prevent the reward loss
        uint256 remainder_ = IERC20(depositToken).balanceOf(address(this)) - totalDepositedInPublicPools;
        require(remainder_ > 0, "DS: yield for token is zero");
        IERC20(depositToken).transfer(distributor, remainder_);
        //~ Transfer the deposit of the public pool to the new reward pool
        IDistributor(distributor).supply(rewardPoolIndex_, totalDepositedInPublicPools);

        isMigrationOver = true;

        emit Migrated(rewardPoolIndex_);
    }

    function editReferrerTiers(uint256 rewardPoolIndex_, ReferrerTier[] calldata referrerTiers_) external onlyOwner {
        IRewardPool rewardPool_ = IRewardPool(IDistributor(distributor).rewardPool());
        rewardPool_.onlyExistedRewardPool(rewardPoolIndex_);

        delete referrerTiers[rewardPoolIndex_];

        uint256 lastAmount_;
        uint256 lastMultiplier_;
        for (uint256 i = 0; i < referrerTiers_.length; i++) {
            uint256 amount_ = referrerTiers_[i].amount;
            uint256 multiplier_ = referrerTiers_[i].multiplier;

            if (i != 0) {
                require(amount_ > lastAmount_, "DS: invalid referrer tiers (1)");
                require(multiplier_ > lastMultiplier_, "DS: invalid referrer tiers (2)");
            }

            referrerTiers[rewardPoolIndex_].push(referrerTiers_[i]);

            lastAmount_ = amount_;
            lastMultiplier_ = multiplier_;
        }

        emit ReferrerTiersEdited(rewardPoolIndex_, referrerTiers_);
    }

    // 
    function manageUsersInPrivateRewardPool(
        uint256 rewardPoolIndex_,
        address[] calldata users_,
        uint256[] calldata amounts_,
        uint128[] calldata claimLockEnds_,
        address[] calldata referrers_
    ) external onlyOwner {
        IRewardPool rewardPool_ = IRewardPool(IDistributor(distributor).rewardPool());
        rewardPool_.onlyExistedRewardPool(rewardPoolIndex_);
        rewardPool_.onlyNotPublicRewardPool(rewardPoolIndex_);

        require(users_.length == amounts_.length, "DS: invalid length");
        require(users_.length == claimLockEnds_.length, "DS: invalid length");
        require(users_.length == referrers_.length, "DS: invalid length");

        IDistributor(distributor).distributeRewards(rewardPoolIndex_);
        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);

        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

        //~ Increase or decrease the user's deposit to the specified target amounts_[]
        for (uint256 i; i < users_.length; ++i) {
            uint256 deposited_ = usersData[users_[i]][rewardPoolIndex_].deposited;

            if (deposited_ <= amounts_[i]) {
                _stake(
                    users_[i],
                    rewardPoolIndex_,
                    amounts_[i] - deposited_,
                    currentPoolRate_,
                    claimLockEnds_[i],
                    referrers_[i]
                );
            } else {
                _withdraw(users_[i], rewardPoolIndex_, deposited_ - amounts_[i], currentPoolRate_);
            }
        }
    }

    /**********************************************************************************************/
    /*** Stake, claim, withdraw, lock management                                                ***/
    /**********************************************************************************************/
    //~ ✅
    //~ 用户 A 可以授权某些地址代为领取奖励
    function setClaimSender(
        uint256 rewardPoolIndex_,
        address[] calldata senders_,
        bool[] calldata isAllowed_
    ) external {
        IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);
        require(senders_.length == isAllowed_.length, "DS: invalid array length");

        for (uint256 i = 0; i < senders_.length; ++i) {
            claimSender[rewardPoolIndex_][_msgSender()][senders_[i]] = isAllowed_[i];

            emit ClaimSenderSet(rewardPoolIndex_, _msgSender(), senders_[i], isAllowed_[i]);
        }
    }
    //~ ✅
    //~ 用户 A 可以指定奖励发放到另一个地址 B
    function setClaimReceiver(uint256 rewardPoolIndex_, address receiver_) external {
        IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);

        claimReceiver[rewardPoolIndex_][_msgSender()] = receiver_;

        emit ClaimReceiverSet(rewardPoolIndex_, _msgSender(), receiver_);
    }
    //~ ✅
    function stake(uint256 rewardPoolIndex_, uint256 amount_, uint128 claimLockEnd_, address referrer_) external {
        IRewardPool rewardPool_ = IRewardPool(IDistributor(distributor).rewardPool());
        rewardPool_.onlyExistedRewardPool(rewardPoolIndex_);
        rewardPool_.onlyPublicRewardPool(rewardPoolIndex_);
        //~ 先分发 reward pool 的奖励，保证之前的奖励结算完。
        IDistributor(distributor).distributeRewards(rewardPoolIndex_);
        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);
        //~ @audit-medium 没有遵循CEI 如果depositToken 是恶意合约会 reentrance
        _stake(_msgSender(), rewardPoolIndex_, amount_, currentPoolRate_, claimLockEnd_, referrer_);
        //~ ⬇
        //~ IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

        //~ reentrance 使 distributedRewards 反复增加
        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;
    }
    //~ ✅
    function withdraw(uint256 rewardPoolIndex_, uint256 amount_) external {
        IRewardPool rewardPool_ = IRewardPool(IDistributor(distributor).rewardPool());
        rewardPool_.onlyExistedRewardPool(rewardPoolIndex_);
        rewardPool_.onlyPublicRewardPool(rewardPoolIndex_);

        IDistributor(distributor).distributeRewards(rewardPoolIndex_);

        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);

        _withdraw(_msgSender(), rewardPoolIndex_, amount_, currentPoolRate_);

        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;
    }

    function claim(uint256 rewardPoolIndex_, address receiver_) external payable {
        _claim(rewardPoolIndex_, _msgSender(), receiver_);
    }

    /*     
        claimSender[1][Alice][Bob] = true
        → Bob 被授权代 Alice 领取奖励。
        claimReceiver[1][Alice] = 0xColdWallet
        → 奖励必须发送到 Alice 的冷钱包。
    */
    //~ @audit-high codehawks https://codehawks.cyfrin.io/c/2024-01-Morpheus/s/47
    //~ 解决 “claim 地址和 stake 地址不一致” 的问题，也就是 AA 跨链地址问题
    function claimFor(uint256 rewardPoolIndex_, address staker_, address receiver_) external payable {
        if (claimReceiver[rewardPoolIndex_][staker_] != address(0)) {
            receiver_ = claimReceiver[rewardPoolIndex_][staker_];
        } else {
            require(claimSender[rewardPoolIndex_][staker_][_msgSender()], "DS: invalid caller");
        }

        _claim(rewardPoolIndex_, staker_, receiver_);
    }

    function claimReferrerTier(uint256 rewardPoolIndex_, address receiver_) external payable {
        _claimReferrerTier(rewardPoolIndex_, _msgSender(), receiver_);
    }

    function claimReferrerTierFor(uint256 rewardPoolIndex_, address referrer_, address receiver_) external payable {
        require(claimSender[rewardPoolIndex_][referrer_][_msgSender()], "DS: invalid caller");

        _claimReferrerTier(rewardPoolIndex_, referrer_, receiver_);
    }

    //~ ✅
    //~ 让用户 延长或设置奖励领取的锁定期
    function lockClaim(uint256 rewardPoolIndex_, uint128 claimLockEnd_) external {
        require(isMigrationOver == true, "DS: migration isn't over");
        IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);

        require(claimLockEnd_ > block.timestamp, "DS: invalid lock end value (1)");

        IDistributor(distributor).distributeRewards(rewardPoolIndex_);

        address user_ = _msgSender();
        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);

        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        UserData storage userData = usersData[user_][rewardPoolIndex_];

        require(userData.deposited > 0, "DS: user isn't staked");
        require(claimLockEnd_ > userData.claimLockEnd, "DS: invalid lock end value (2)");

        userData.pendingRewards = _getCurrentUserReward(currentPoolRate_, userData);
        //~ q 之前怎么会没有claimLockStart
        //~ a 如果用户是 从旧版本迁移过来，或者之前从未调用过 lockClaim，这个字段可能是 0
        uint128 claimLockStart_ = userData.claimLockStart > 0 ? userData.claimLockStart : uint128(block.timestamp);
        uint256 multiplier_ = _getUserTotalMultiplier(claimLockStart_, claimLockEnd_, userData.referrer);
        uint256 virtualDeposited_ = (userData.deposited * multiplier_) / PRECISION;

        if (userData.virtualDeposited == 0) {
            userData.virtualDeposited = userData.deposited;
        }

        // Update `rewardPoolData`
        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;
        rewardPoolData.totalVirtualDeposited =
            rewardPoolData.totalVirtualDeposited +
            virtualDeposited_ -
            userData.virtualDeposited;

        // Update `userData`
        userData.rate = currentPoolRate_;
        userData.virtualDeposited = virtualDeposited_;
        userData.claimLockStart = claimLockStart_;
        userData.claimLockEnd = claimLockEnd_;
        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

        emit UserClaimLocked(rewardPoolIndex_, user_, claimLockStart_, claimLockEnd_);
    }

    //~ ✅
    function _stake(
        address user_,
        uint256 rewardPoolIndex_,
        uint256 amount_,
        uint256 currentPoolRate_,
        uint128 claimLockEnd_,
        address referrer_
    ) private {
        require(isMigrationOver == true, "DS: migration isn't over");

        RewardPoolProtocolDetails storage rewardPoolProtocolDetails = rewardPoolsProtocolDetails[rewardPoolIndex_];
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        UserData storage userData = usersData[user_][rewardPoolIndex_];

        if (claimLockEnd_ == 0) {
            claimLockEnd_ = userData.claimLockEnd > block.timestamp ? userData.claimLockEnd : uint128(block.timestamp);
        }
        require(claimLockEnd_ >= userData.claimLockEnd, "DS: invalid claim lock end");

        if (referrer_ == address(0)) {
            referrer_ = userData.referrer;
        }

        // --------------------------- 处理存款 ---------------------------
        //~ 处理公共池存款
        //~ 公共池才需要实际转账
        if (IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolPublic(rewardPoolIndex_)) {
            require(amount_ > 0, "DS: nothing to stake");

            // https://docs.lido.fi/guides/lido-tokens-integration-guide/#steth-internals-share-mechanics
            uint256 balanceBefore_ = IERC20(depositToken).balanceOf(address(this));
            IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);
            uint256 balanceAfter_ = IERC20(depositToken).balanceOf(address(this));

            //~ 用来防止 token 有 transfer fee 或者某些特殊逻辑导致实际到账少于 amount_
            amount_ = balanceAfter_ - balanceBefore_;

            IDistributor(distributor).supply(rewardPoolIndex_, amount_);

            require(userData.deposited + amount_ >= rewardPoolProtocolDetails.minimalStake, "DS: amount too low");

            totalDepositedInPublicPools += amount_;
        }
        // ------------- 计算用户之前应得的奖励 pendingRewards -------------
        userData.pendingRewards = _getCurrentUserReward(currentPoolRate_, userData);

        uint256 deposited_ = userData.deposited + amount_;
        //~ multiplier_ 会根据 锁定时间 + 推荐人 调整
        // ------------- 计算虚拟存款 virtualDeposited_ ------------
        uint256 multiplier_ = _getUserTotalMultiplier(uint128(block.timestamp), claimLockEnd_, referrer_);
        uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;
        //~ 用户第一次存款时，虚拟存款= userData.deposited =0
        if (userData.virtualDeposited == 0) {
            userData.virtualDeposited = userData.deposited;
        }
        // ---------------------------- 更新推荐人的referrerData ----------------------------
        //~ 更新推荐人的referrerData
        //~ 这个函数里没有用到和修改 userData 
        _applyReferrerTier(
            user_,
            rewardPoolIndex_,
            currentPoolRate_,
            userData.deposited,
            deposited_,
            userData.referrer,
            referrer_
        );

        // Update `poolData`
        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;
        rewardPoolData.totalVirtualDeposited =

            rewardPoolData.totalVirtualDeposited +
            virtualDeposited_ -
            userData.virtualDeposited;

        // Update `userData
        userData.lastStake = uint128(block.timestamp);
        userData.rate = currentPoolRate_;
        userData.deposited = deposited_;
        userData.virtualDeposited = virtualDeposited_;
        userData.claimLockStart = uint128(block.timestamp);
        userData.claimLockEnd = claimLockEnd_;
        userData.referrer = referrer_;

        emit UserStaked(rewardPoolIndex_, user_, amount_);
        emit UserClaimLocked(rewardPoolIndex_, user_, uint128(block.timestamp), claimLockEnd_);
    }

    //~ ✅
    function _withdraw(address user_, uint256 rewardPoolIndex_, uint256 amount_, uint256 currentPoolRate_) private {
        require(isMigrationOver == true, "DS: migration isn't over");

        RewardPoolProtocolDetails storage rewardPoolProtocolDetails = rewardPoolsProtocolDetails[rewardPoolIndex_];
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        UserData storage userData = usersData[user_][rewardPoolIndex_];

        uint256 deposited_ = userData.deposited;
        require(deposited_ > 0, "DS: user isn't staked");

        if (amount_ > deposited_) {
            amount_ = deposited_;
        }

        uint256 newDeposited_;
        if (IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolPublic(rewardPoolIndex_)) {
            require(
                block.timestamp > userData.lastStake + rewardPoolProtocolDetails.withdrawLockPeriodAfterStake,
                "DS: pool withdraw is locked"
            );
            //~ @audit-high processing logical errors
            //~ impact: causes user funds to be stuck and unwithdrawable
            //~ the depositToken balance in the Distributor will be zero.
            //~ since when user stake, depositToken was supplied to Aave (stake -> Distributor.supply).
            uint256 depositTokenContractBalance_ = IERC20(depositToken).balanceOf(distributor);
            if (amount_ > depositTokenContractBalance_) {
                amount_ = depositTokenContractBalance_;
            }

            newDeposited_ = deposited_ - amount_;

            require(amount_ > 0, "DS: nothing to withdraw");
            require(
                newDeposited_ >= rewardPoolProtocolDetails.minimalStake ||
                    newDeposited_ == 0 ||
                    depositTokenContractBalance_ == amount_,
                "DS: invalid withdraw amount"
            );
        } else {
            newDeposited_ = deposited_ - amount_;
        }

        userData.pendingRewards = _getCurrentUserReward(currentPoolRate_, userData);

        uint256 multiplier_ = _getUserTotalMultiplier(
            uint128(block.timestamp),
            userData.claimLockEnd,
            userData.referrer
        );
        uint256 virtualDeposited_ = (newDeposited_ * multiplier_) / PRECISION;

        if (userData.virtualDeposited == 0) {
            userData.virtualDeposited = userData.deposited;
        }

        _applyReferrerTier(
            user_,
            rewardPoolIndex_,
            currentPoolRate_,
            deposited_,
            newDeposited_,
            userData.referrer,
            userData.referrer
        );

        // Update pool data
        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;
        rewardPoolData.totalVirtualDeposited =
            rewardPoolData.totalVirtualDeposited +
            virtualDeposited_ -
            userData.virtualDeposited;

        // Update user data
        userData.rate = currentPoolRate_;
        userData.deposited = newDeposited_;
        userData.virtualDeposited = virtualDeposited_;
        userData.claimLockStart = uint128(block.timestamp);

        if (IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolPublic(rewardPoolIndex_)) {
            totalDepositedInPublicPools -= amount_;

            IDistributor(distributor).withdraw(rewardPoolIndex_, amount_);
            IERC20(depositToken).safeTransfer(user_, amount_);
        }

        emit UserWithdrawn(rewardPoolIndex_, user_, amount_);
    }

    //~ ✅
    //~ 更新计算 pendingRewards 和 totalVirtualDeposited，发送 pendingRewards
    function _claim(uint256 rewardPoolIndex_, address user_, address receiver_) private {
        require(isMigrationOver == true, "DS: migration isn't over");
        IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);

        UserData storage userData = usersData[user_][rewardPoolIndex_];

        require(
            block.timestamp >
                userData.lastStake + rewardPoolsProtocolDetails[rewardPoolIndex_].claimLockPeriodAfterStake,
            "DS: pool claim is locked (S)"
        );
        require(
            block.timestamp >
                userData.lastClaim + rewardPoolsProtocolDetails[rewardPoolIndex_].claimLockPeriodAfterClaim,
            "DS: pool claim is locked (C)"
        );
        require(block.timestamp > userData.claimLockEnd, "DS: user claim is locked");

        IDistributor(distributor).distributeRewards(rewardPoolIndex_);

        // ------------- 计算用户之前应得的奖励 pendingRewards -------------
        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);
        uint256 pendingRewards_ = _getCurrentUserReward(currentPoolRate_, userData);
        require(pendingRewards_ > 0, "DS: nothing to claim");

        uint256 deposited_ = userData.deposited;

        // ----------------- 计算虚拟存款 virtualDeposited_ -----------------
        uint256 multiplier_ = _getUserTotalMultiplier(0, 0, userData.referrer);
        uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;

        if (userData.virtualDeposited == 0) {
            userData.virtualDeposited = userData.deposited;
        }

        // Update `rewardPoolData`
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;
        rewardPoolData.totalVirtualDeposited =
            rewardPoolData.totalVirtualDeposited +
            virtualDeposited_ -
            userData.virtualDeposited;

        // Update `userData`
        userData.rate = currentPoolRate_;
        userData.pendingRewards = 0;
        userData.virtualDeposited = virtualDeposited_;
        userData.claimLockStart = 0;
        userData.claimLockEnd = 0;
        userData.lastClaim = uint128(block.timestamp);
        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

        // Transfer rewards
        IDistributor(distributor).sendMintMessage{value: msg.value}(
            rewardPoolIndex_,
            receiver_,
            pendingRewards_,
            _msgSender()
        );

        emit UserClaimed(rewardPoolIndex_, user_, receiver_, pendingRewards_);
    }

    //~ ✅
    //~ 不用计算虚拟存款和Update `userData`相关
    function _claimReferrerTier(uint256 rewardPoolIndex_, address referrer_, address receiver_) private {
        require(isMigrationOver == true, "DS: migration isn't over");

        IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);
        IDistributor(distributor).distributeRewards(rewardPoolIndex_);

        (uint256 currentPoolRate_, uint256 rewards_) = _getCurrentPoolRate(rewardPoolIndex_);

        RewardPoolProtocolDetails storage rewardPoolProtocolDetails = rewardPoolsProtocolDetails[rewardPoolIndex_];
        ReferrerData storage referrerData = referrersData[referrer_][rewardPoolIndex_];

        require(
            block.timestamp > referrerData.lastClaim + rewardPoolProtocolDetails.claimLockPeriodAfterClaim,
            "DS: pool claim is locked (C)"
        );
        //~ 这里会update referrerData
        uint256 pendingRewards_ = ReferrerLib.claimReferrerTier(referrerData, currentPoolRate_);

        // Update `rewardPoolData`
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;

        // Update `rewardPoolsProtocolDetails`
        rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

        // Transfer rewards
        IDistributor(distributor).sendMintMessage{value: msg.value}(
            rewardPoolIndex_,
            receiver_,
            pendingRewards_,
            _msgSender()
        );

        emit ReferrerClaimed(rewardPoolIndex_, referrer_, receiver_, pendingRewards_);
    }

    //~ ✅
    //~ 更新推荐人的referrerData
    function _applyReferrerTier(
        address user_,
        uint256 rewardPoolIndex_,
        uint256 currentPoolRate_,
        uint256 oldDeposited_,
        uint256 newDeposited_,
        address oldReferrer_,
        address newReferrer_
    ) private {
        if (newReferrer_ == address(0)) {
            // we assume that referrer can't be removed, only changed
            return;
        }
        /* 
            struct ReferrerData {
                uint256 amountStaked;          // 这个推荐人“下线用户”们的总存款额
                uint256 virtualAmountStaked;   // 虚拟加权后的存款额（乘以推荐人 tier 的 multiplier）
                uint256 pendingRewards;        // 已累计但还没领取的推荐奖励
                uint256 rate;                  // 上次更新时的 reward pool 的 rate（利率/指数）
            }
        */
        ReferrerData storage newReferrerData = referrersData[newReferrer_][rewardPoolIndex_];

        uint256 oldVirtualAmountStaked;
        uint256 newVirtualAmountStaked;

        // ----------------------- 根据推荐变动情况使用 applyReferrerTier 更新referrerData -----------------------
        if (oldReferrer_ == address(0)) {
            //~ 新用户第一次被推荐
            oldVirtualAmountStaked = newReferrerData.virtualAmountStaked;

            newReferrerData.applyReferrerTier(referrerTiers[rewardPoolIndex_], 0, newDeposited_, currentPoolRate_);
            newVirtualAmountStaked = newReferrerData.virtualAmountStaked;

            emit UserReferred(rewardPoolIndex_, user_, newReferrer_, newDeposited_);
        } else if (oldReferrer_ == newReferrer_) {
            //~ 推荐人没变，但用户存款变动
            //~ 调整推荐人的 virtualAmountStaked（减去旧存款，加入新存款）  
            oldVirtualAmountStaked = newReferrerData.virtualAmountStaked;
            newReferrerData.applyReferrerTier(
                referrerTiers[rewardPoolIndex_],
                oldDeposited_,
                newDeposited_,
                currentPoolRate_
            );
            newVirtualAmountStaked = newReferrerData.virtualAmountStaked;

            emit UserReferred(rewardPoolIndex_, user_, newReferrer_, newDeposited_);
        } else {
            //~ 更换推荐人
            ReferrerData storage oldReferrerData = referrersData[oldReferrer_][rewardPoolIndex_];

            oldVirtualAmountStaked = oldReferrerData.virtualAmountStaked + newReferrerData.virtualAmountStaked;

            oldReferrerData.applyReferrerTier(referrerTiers[rewardPoolIndex_], oldDeposited_, 0, currentPoolRate_);
            newReferrerData.applyReferrerTier(referrerTiers[rewardPoolIndex_], 0, newDeposited_, currentPoolRate_);
            newVirtualAmountStaked = oldReferrerData.virtualAmountStaked + newReferrerData.virtualAmountStaked;

            emit UserReferred(rewardPoolIndex_, user_, oldReferrer_, 0);
            emit UserReferred(rewardPoolIndex_, user_, newReferrer_, newDeposited_);
        }
        // ------------------ 更新 reward pool 的总虚拟存款 ------------------
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];
        rewardPoolData.totalVirtualDeposited =
            rewardPoolData.totalVirtualDeposited +
            newVirtualAmountStaked -
            oldVirtualAmountStaked;
    }

    /**********************************************************************************************/
    /*** Functionality for rewards calculations + getters                                       ***/
    /**********************************************************************************************/

    function getLatestUserReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {
        if (!IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolExist(rewardPoolIndex_)) {
            return 0;
        }

        UserData storage userData = usersData[user_][rewardPoolIndex_];
        (uint256 currentPoolRate_, ) = _getCurrentPoolRate(rewardPoolIndex_);

        return _getCurrentUserReward(currentPoolRate_, userData);
    }

    function getLatestReferrerReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {
        if (!IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolExist(rewardPoolIndex_)) {
            return 0;
        }

        (uint256 currentPoolRate_, ) = _getCurrentPoolRate(rewardPoolIndex_);

        return referrersData[user_][rewardPoolIndex_].getCurrentReferrerReward(currentPoolRate_);
    }

    //~ ✅
    //~ 计算 pendingRewards
    function _getCurrentUserReward(uint256 currentPoolRate_, UserData memory userData_) private pure returns (uint256) {
        uint256 deposited_ = userData_.virtualDeposited == 0 ? userData_.deposited : userData_.virtualDeposited;
        //~ 用户的奖励就是 (当前Rate - 用户进入时的Rate) × 存款
        uint256 newRewards_ = ((currentPoolRate_ - userData_.rate) * deposited_) / PRECISION;

        return userData_.pendingRewards + newRewards_;
    }

    //~ ✅
    //~ 计算 deposit pool 在当前 reward pool 中，
    //~ 可以分到的奖励 `rewards_` 和每单位存款可以分得多少奖励 `rate_` 
    function _getCurrentPoolRate(uint256 rewardPoolIndex_) private view returns (uint256, uint256) {
        RewardPoolData storage rewardPoolData = rewardPoolsData[rewardPoolIndex_];

        uint256 rewards_ = IDistributor(distributor).getDistributedRewards(rewardPoolIndex_, address(this)) -
            rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards;
        //~ 没有任何存款，就不能按比例分配 返回上次 rate 和本次的 rewards_，等待下一轮分配
        if (rewardPoolData.totalVirtualDeposited == 0) {
            return (rewardPoolData.rate, rewards_);
        }
        //~ rewards_ / totalVirtualDeposited：每单位存款可以分得的奖励，再加上之前的 rewardPoolData.rate
        uint256 rate_ = rewardPoolData.rate + (rewards_ * PRECISION) / rewardPoolData.totalVirtualDeposited;

        return (rate_, rewards_);
    }

    /**********************************************************************************************/
    /*** Functionality for multipliers, getters                                                 ***/
    /**********************************************************************************************/

    function getCurrentUserMultiplier(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {
        if (!IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolExist(rewardPoolIndex_)) {
            return PRECISION;
        }

        UserData storage userData = usersData[user_][rewardPoolIndex_];

        return _getUserTotalMultiplier(userData.claimLockStart, userData.claimLockEnd, userData.referrer);
    }

    function getReferrerMultiplier(uint256 rewardPoolIndex_, address referrer_) public view returns (uint256) {
        if (!IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolExist(rewardPoolIndex_)) {
            return 0;
        }

        ReferrerData storage referrerData = referrersData[referrer_][rewardPoolIndex_];
        if (referrerData.amountStaked == 0) {
            return 0;
        }

        return (referrerData.virtualAmountStaked * PRECISION) / referrerData.amountStaked;
    }

    //~ ✅
    //~ 计算 multiplier
    function _getUserTotalMultiplier(
        uint128 claimLockStart_,
        uint128 claimLockEnd_,
        address referrer_
    ) internal pure returns (uint256) {
        return
            LockMultiplierMath.getLockPeriodMultiplier(claimLockStart_, claimLockEnd_) +
            ReferrerLib.getReferralMultiplier(referrer_) -
            PRECISION;
    }

    /**********************************************************************************************/
    /*** UUPS                                                                                   ***/
    /**********************************************************************************************/

    function removeUpgradeability() external onlyOwner {
        isNotUpgradeable = true;
    }

    function version() external pure returns (uint256) {
        return 7;
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {
        require(!isNotUpgradeable, "DS: upgrade isn't available");
    }
}
