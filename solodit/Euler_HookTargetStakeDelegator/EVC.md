# EVC 机制主要是为「用户账户（EOA）」设计的

EVC 全称 Ethereum Vault Connector，是 Euler v2 系统中的一个关键组件。
它的功能是把用户在不同的 Vault（比如存款、借贷、质押池）中的头寸和身份统一连接到一个 “主账户 (owner)” 上。

EVC 是连接 账户（Account） → 主账户（Owner） 的桥梁

🧩 四、为什么要这样设计？

因为 Euler 允许：

同一个 owner 拥有多个“子账户（account）”；
每个子账户可以用于不同策略或合约；
但风险、抵押、奖励等要在 owner 级别统一管理。

比如：

Alice 有两个子账户：
一个在 ETH Vault 存 ETH；
一个在 USDC Vault 借 USDC；
EVC 会在 owner 层（Alice）把这两个账户关联起来，进行统一抵押和风险计算。


1️⃣ 智能合约账户一般不会注册 EVC owner

很多智能合约（策略池、金库、DeFi 代理）直接与 EVault 交互，但不会通过 EVC 注册；
因此这些账户的 getAccountOwner(account) 永远是 address(0)。