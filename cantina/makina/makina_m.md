## 用户交互流程图
1. 1.
   存款流程 ：用户 → DirectDepositor.deposit() → Machine.deposit() → 获得Machine份额
2. 2.
   赎回流程 ：
   
   - 用户 → AsyncRedeemer.requestRedeem() → 获得赎回NFT
   - 操作员 → AsyncRedeemer.finalizeRequests() → 最终确定赎回请求
   - 用户 → AsyncRedeemer.claimAssets() → 销毁NFT并领取资产
3. 3.
   安全模块参与流程 ：
   
   - 用户 → SecurityModule.lock() → 锁定Machine份额并获得安全模块份额
   - 用户 → SecurityModule.startCooldown() → 启动冷却期并获得冷却NFT
   - (可选)用户 → SecurityModule.cancelCooldown() → 取消冷却期
   - 冷却期结束后，用户 → SecurityModule.redeem() → 赎回Machine份额

## ERC-7201 命名空间化存储对象（namespaced storage object）
把某个逻辑模块的状态变量固定存放在一个唯一的 storage slot 中，以避免冲突

## ERC1967Proxy 和 BeaconProxy 有什么区别

## Create3Factory 如何部署合约


