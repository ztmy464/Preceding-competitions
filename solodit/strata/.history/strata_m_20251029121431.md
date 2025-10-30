# strata

[What is Strata? | Strata](https://docs.strata.money/?q=yUSde)

https://github.com/solodit/solodit_content/blob/main/reports/Cyfrin/2025-06-11-cyfrin-strata-v2.1.md

https://github.com/Strata-Money/contracts

MetaVault架构 ：允许接受多种底层资产（vault share）作为存款（只要base token 是USDe）

### 两阶段运营模式
- PointsPhase（积分阶段） ：用户存入资产获取pUSDe凭证
- YieldPhase（收益阶段） ：用户可将pUSDe存入yUSDeVault获取实际收益

- 在YieldPhase阶段，USDe资产被质押成sUSDe以生成收益
- yUSDeVault为用户提供基于份额的收益分配机制
- 收益仅分配给选择将pUSDe存入yUSDeVault的用户

# review summary
`maxWithdraw` 与`previewRedeem` 的区别

`previewWithdraw`  与`convertToShares` 的区别

 1.  state `withdraw` 时，从本金 `depositedBase` 状态变量上减去了 本金+yield，多次这样操作后，`depositedBase → 0`，pUSDe share 几乎兑换不到 USDe

attack：先向 USDe 金库捐赠足够多 USDe（会被视为 yield ），然后使得自己`withdraw`时的`previewYield` 等于`depositedBase` ，这样一次性使 totalAssets 为 0，之后用户无法赎回

1. ex-4626 某个 vault 被暂停或受限（`maxWithdraw` 很小），但 `previewRedeem` 仍然返回较大值 。
    
    应该使用 maxWithdraw 而不是 previewRedeem/previewWithdraw 来判断“可用基础资产”
    
2. ex-4626 / round 使用 `previewWithdraw` 将上取整，导致协议了用户比他应得的略多的 sUSDe
`previewWithdraw` 返回必须销毁的 shares amount（向上取整），以确保用户一定能拿到请求的资产数额（与 `convertToShares()` 向下取整 刚好相反）
3. mac 进入 yield phase 后，移除其了它 vaults，但没有暂停 `addVault`函数，还可以添加回来