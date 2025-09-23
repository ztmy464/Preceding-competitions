# Q & A

### rewardPool 和 deposit pool

用户是把 token 存进 deposit pool，然后 reward pool 根据 deposit pool 的 yield 来分配奖励。

因此 distributedRewards[rewardPoolIndex_][depositPoolAddress] 的两层索引就很合理：奖励池索引 + deposit pool 地址。

### reward 和 yield

奖励分配
deposit pool 按 yield 占比拿 reward
reward pool 根据各 deposit pool 的 yield 分配

### UserData 和 ReferrerData

 1. 两个结构体的定位

* **UserData** → 记录某个用户在 **DepositPool** 里的情况

  * 关心的是：用户自己存了多少、啥时候存的、啥时候能领奖励、绑定的推荐人是谁。

* **ReferrerData** → 记录某个推荐人因为有“下线用户”而获得的累计情况

  * 关心的是：所有下线一共存了多少、加权后的虚拟存款多少、推荐人应得的奖励累计。

 2. 举个例子：Alice → Bob 推荐关系

* Bob 是推荐人（referrer）
* Alice 是用户（user），她通过 Bob 的推荐链接进入平台


# architecture

## `DepositPool.sol`(Stake/Withdraw,Claim)

`Stake` (Withdraw/ Claim) : 

```rust
distributor.distributeRewards  (计算、分配奖励)
↓
distributor.supply  (存款)
↓
calc update pendingRewards （计算为了钱奖励）
↓
Update referrerData （根据推荐人变动情况更新推荐人信息）
    (`_applyReferrerTier` -> `ReferrerLib.applyReferrerTier`)

  - referrerData.pendingRewards             = getCurrentReferrerReward(referrerData, currentPoolRate_);
  - referrerData.rate                       = currentPoolRate_;
  - referrerData.amountStaked               = referrerData.amountStaked + newAmount_ - oldAmount_;
  - referrerData.virtualAmountStaked        = amountStaked * multiplier_;
  - rewardPoolData.totalVirtualDeposited    = (这里更新由refer的虚拟存款变化引起的rewardPool的虚拟存款的变化)
            rewardPoolData.totalVirtualDeposited +
            newVirtualAmountStaked -
            oldVirtualAmountStaked;
↓
Update rewardPoolData & userData：

        rewardPoolData.lastUpdate = uint128(block.timestamp);
        rewardPoolData.rate = currentPoolRate_;
        rewardPoolData.totalVirtualDeposited = 
        (这里再在之前的更新上再更新User的虚拟存款变化引起的rewardPool的虚拟存款的变化)
            rewardPoolData.totalVirtualDeposited +
            virtualDeposited_ -
            userData.virtualDeposited;

        userData.lastStake = uint128(block.timestamp);
        userData.rate = currentPoolRate_;
        userData.deposited = deposited_;
        userData.virtualDeposited = virtualDeposited_;
        userData.claimLockStart = uint128(block.timestamp);
        userData.claimLockEnd = claimLockEnd_;
        userData.referrer = referrer_;
```

## `Distributor.sol` (addDepositPool,supply/withdraw,distributeRewards)

`distributeRewards`:  
分配 rewardPool 的 rewards 到 depositpool  

```rust
(计算 rewardPool 的 rewards)
rewards = rewardPool.getPeriodRewards 
↓
privatepool 直接分配给唯一 depositpool
↓
updateDepositTokensPrices（调用 Oracle Update prices）
↓
(计算各个 depositpool 的yield)
yield[i] = underlyingYieldd[i] * depositPoold[i].tokenPrice
↓
(分配 rewards -> 根据各个 depositpool 的 yield 占比)
distributedRewards[depositpool[i]] +=
                (yields_[i] * rewards_) /
                totalYield_;
```
# Audits

```solidity
//~ @audit-high codehawks https://codehawks.cyfrin.io/c/2024-01-Morpheus/s/47
//~ 解决 “claim 地址和 stake 地址不一致” 的问题，也就是 AA 跨链地址问题
function claimFor(uint256 rewardPoolIndex_, address staker_, address receiver_);

--------------------------------------
//~ @audit-high processing logical errors
//~ impact: causes user funds to be stuck and unwithdrawable
//~ the depositToken balance in the Distributor will be zero.
//~ since when user stake, depositToken was supplied to Aave (stake -> Distributor.supply).
uint256 depositTokenContractBalance_ = IERC20(depositToken).balanceOf(distributor);
if (amount_ > depositTokenContractBalance_) {
    amount_ = depositTokenContractBalance_;
}

--------------------------------------
//~ @audit-medium 没有遵循CEI 如果depositToken 是恶意合约会 reentrance
_stake(_msgSender(), rewardPoolIndex_, amount_, currentPoolRate_, claimLockEnd_, referrer_);
//~ ⬇
//~ IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

//~ reentrance 使 distributedRewards 反复增加
// Update `rewardPoolsProtocolDetails`
rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

--------------------------------------
//~ @audit-medium Updating `rewardPoolLastCalculatedTimestamp` early allows a griefer to deny reward distribution
rewardPoolLastCalculatedTimestamp[rewardPoolIndex_] = uint128(block.timestamp);

--------------------------------------
//~ @audit-medium 多个同 token 池 causes incorrect yield accounting
//~ impact: 使用balance 查询的余额可能是多个同 token 池共同的结果, yield_计算不正确
//~ mitigation: adding validation in addDepositPool to ensure aToken and token_ are unique for each DepositPool.
uint256 balance_ = IERC20(yieldToken_).balanceOf(address(this));

--------------------------------------
//~ @audit-low Chainlink may return stale prices
//~ 只直接取了 answer 当价格，检查了 answer > 0。没有检查 updatedAt 是否太久远
/* mitigation: 检查一下 Oracle 的 updatedAt
try aggregator_.latestRoundData() returns (uint80, int256 answer_, uint256, uint256 updatedAt_, uint80) {
    if (block.timestamp < updatedAt_ || block.timestamp - updatedAt_ > allowedPriceUpdateDelay) {
        return 0;
    }
    */
try aggregator_.latestRoundData() returns (uint80, int256 answer_, uint256, uint256, uint80) {
    if (answer_ <= 0) {
        return 0;
    }

--------------------------------------
//~ @audit-info 合约没有 领取 AAVE 激励 函数
//~ Aave 除了给你利息（yield）之外，还会额外发放 激励代币
//~ claimedAmount = IRewardsController(aaveRewardsController).claimRewards(assets, amount, to, reward);  

```