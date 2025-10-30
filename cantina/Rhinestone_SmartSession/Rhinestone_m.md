# project intro
https://github.com/erc7579/smartsessions

SmartSession 是一个 **模块化账户安全模型** 为 ERC-7579 兼容的智能账户 提供 临时会话密钥 / 权限控制 的模块。
它允许用户为他们的账户生成子密钥（session keys），并对这些子密钥设置细粒度的权限、有效期、策略等。

# ERC-4337

# ERC-7579
https://eips.ethereum.org/EIPS/eip-7579

旨在为“模块化智能账户（modular smart accounts）”提供一个最小化、跨实现兼容的接口规范

# session（会话） 和 policy（策略）

## 🧩 一、什么是 **Session（会话）**

### ✅ 定义（在 SmartSession / ERC-7579 中）

> **Session** 是一种“临时授权上下文 (temporary permission context)”——
> 用于定义一个账户在一定范围、一定时间内、由谁、可以做什么。

简单说：

> Session = 一组临时生效的权限 + 限制条件。

---

### 🧠 举个例子

假设你有一个智能账户（智能钱包）：

```
0xAliceAccount
```

你不想每次交易都自己签名。
于是你生成一个“**session key**”（会话密钥）交给某个 DApp 用。

你告诉系统：

> “我授权这个 session key 只能在接下来 1 小时内，
> 调用 Uniswap 上的 swap() 函数，每次金额 ≤ 0.1 ETH。”

系统就会创建一个 **session（会话）**，它的 ID 是一个哈希：

```
permissionId = keccak256(session settings)
```
---

### ⚙️ Session 里通常包含的字段

| 字段                          | 含义               |
| --------------------------- | ---------------- |
| **permissionId**            | 唯一标识该会话的 ID      |
| **sessionKey**              | 临时授权的公钥          |
| **validAfter / validUntil** | 会话有效期（开始时间、结束时间） |
| **policies[]**              | 限制条件（策略列表）       |
| **nonce / chainId**         | 防重放参数            |

---

## 🧠 二、什么是 **Policy（策略）**

### ✅ 定义

> Policy 是一个智能合约模块，用来定义“在什么条件下允许执行交易”。

每个 session 可以附加若干个 policy，
它们像防火墙规则一样，逐条检查即将执行的操作是否合法。

---

### 🧩 举例说明

假设你的 session 配置了三个 policy：

| Policy 名称        | 功能                                 |
| ---------------- | ---------------------------------- |
| **TimePolicy**   | 限制可执行时间段（例如只在 9:00–17:00）          |
| **TargetPolicy** | 限制可调用的目标合约（例如只允许调用 Uniswap Router） |
| **AmountPolicy** | 限制交易金额（例如 ≤ 0.1 ETH）               |

当一个交易请求通过 SmartSession 时，系统会：

1. 依次调用每个 policy 合约；
2. 每个返回一个 `ValidationData`（表示是否通过、有效期等）；
3. 用 `intersectValidationData()` 把它们的限制综合起来；
4. 如果任意一个 policy 不通过（`isFailed()`），则整个调用被拒绝。

---

### ⚙️ Policy 的设计思想

在 SmartSession 中，policy 是模块化的：

* 每个策略是一个独立的合约，实现标准接口（如 `IPolicy`）；
* 账户可以自由添加、移除、组合这些策略；
* 未来可以动态扩展更多策略类型（金额限制、调用频率、白名单、签名授权等）。

---

### 🧱 三、Session 与 Policy 的关系

可以用层级关系表示：

```
SmartAccount
 └── Session 1 (permissionId = 0xabc...)
       ├── Policy: TimePolicy (9am–5pm)
       ├── Policy: TargetPolicy (only Uniswap)
       └── Policy: AmountPolicy (< 0.1 ETH)
 └── Session 2 (permissionId = 0xdef...)
       ├── Policy: NFTPolicy (only mint NFTs)
       └── Policy: DailyLimitPolicy (≤ 1 NFT/day)
```

每个 session 是独立的安全上下文；
每个 policy 是独立的规则模块；
组合起来就形成了灵活可扩展的安全系统。

---

### 🧠 四、为什么要这样设计

传统钱包（EOA）的问题：

* 任何签名都是“全权限”；
* 签名泄露 = 账户被盗；
* 无法细粒度控制不同操作的权限。

SmartSession（以及 ERC-7579 模块化账户）的目标是：

> 用 session + policy 的组合，构建“智能账户的访问控制系统”。

---

| 概念                 | 解释                     | 类比           |
| ------------------ | ---------------------- | ------------ |
| **Session（会话）**    | 临时授权上下文，定义“谁、何时、可以做什么” | 登录令牌 (token) |
| **Policy（策略）**     | 安全规则模块，检查每笔操作是否合法      | 防火墙规则        |
| **permissionId**   | 唯一标识 session 的哈希       | 会话 ID        |
| **SessionKey**     | 临时签名密钥                 | 子账户密钥        |
| **ValidationData** | 每个 policy 的检查结果        | 审核报告         |


# intersect Validation Data
1️⃣ 背景：什么是 ValidationData

在 SmartSession / ERC-7579 的架构里，每个 policy 合约 都返回一个结构化的验证结果，叫 ValidationData。

它包含：

validAfter: 从什么时间之后操作才有效
validUntil: 到什么时间之前操作仍有效
isValid: 是否通过检查

多个 policy 需要组合成一个最终的验证结果。
举例：

Policy	validAfter	validUntil	Result
PolicyA	100	1000	✅
PolicyB	200	800	✅

正确的合并方式是：
validAfter = max(100, 200)
validUntil = min(1000, 800)
（取最严格的限制）

# ERC-7739

引入了一个“重新哈希（rehashing）”方案，用来阻止**多智能账户重放**（replay）。它的做法是把要验证的 hash 包一层 EIP-712 的 typed struct，并把 每个账户自身的地址作为 verifyingContract，从而使得同一签名在不同账户上有不同的最终 digest。(把账户地址 (smart account) 纳入 domain)
代码里把 verifyingContract 错误地设置成了 SmartSession 合约的地址（即模块地址），而不是每个 智能账户 的地址。违背了ERC-7739 的初衷。

## 多智能账户重放?

### 先理解 智能账户 体系:

账户本身是一个智能合约，没有私钥。
它需要“外部签名者”提供签名消息来代表自己授权操作。
**一个 EOA 可控制多个智能账户**

假设 Alice 有一个智能账户 SmartAccountA，她用一个普通钱包（EOA 地址 0xAliceEOA）来控制它。
如果她想执行一个 operation，比如：“调用某个 dApp、转账、或安装一个策略模块”
系统不会直接让 SmartAccountA 自己签署（因为它没有私钥），

1. 而是生成一条消息（message）给 Alice，让她的签名者钱包来签名授权。
2. Alice 的签名者地址（EOA 或 session key）使用私钥对消息进行签名
3. 把这条签名连同消息一起发给智能账户合约；
4. 智能账户再通过 ERC-1271 或自定义验证逻辑去验证签名
5. 如果验证通过，智能账户执行 operation。

### 什么是 多智能账户重放,为什么把账户地址 (smart account) 纳入 domain 可以避免?
多个智能账户共用同一签名者 (EOA) 时，将某个签名从账户 A 重用到账户 B 上。
Alice 拥有多个智能合约账户,把账户地址 (smart account) 纳入 domain 可以验证是哪个智能账户在操作,避免重放攻击。

# ERC-4337 storage restrictions 的影响

ERC-4337 规定 模块化账户不能随意使用 storage slot，避免模块之间冲突。
SmartSession 遵循这个原则，用了 “associated storage / namespace storage”，实现方式类似：

```solidity
Policy internal $userOpPolicies;
Policy internal $erc1271Policies;
EnumerableActionPolicy internal $actionPolicies;
EnumerableSet.Bytes32Set internal $enabledSessions;
mapping(PermissionId => EnumerableSet.Bytes32Set) internal $enabledERC7739Content;
mapping(PermissionId => mapping(address => SignerConf)) internal $sessionValidators;
```
这些变量在 SmartSessionBase 中声明，它们真正读写的 是账户的 storage slot，而不是模块合约自己的 storage
每个变量操作时，会根据 账户地址 + permissionId / actionId 形成唯一的 storage 位置（类似命名空间），防止不同 session 或模块之间冲突。
```solidity
            // Add the session to the list of enabled sessions for the caller
            $enabledSessions.add({ account: msg.sender, value: PermissionId.unwrap(permissionId) });
```
```solidity
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, address account, bytes32 value) private returns (bool) {
        if (!_contains(set, account, value)) {
            set._values.push(account, value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value][account] = set._values.length(account);
            return true;
        } else {
            return false;
        }
    }
```
```solidity
// AssociatedArrayLib
function _push(Array storage s, address account, bytes32 value) private {
    assembly {
        mstore(0x00, account)
        mstore(0x20, s.slot)
        let slot := keccak256(0x00, 0x40)      // 计算唯一 slot
        let index := add(sload(slot), 1)       // index = length + 1
        sstore(add(slot, mul(0x20, index)), value) // 写入 value
        sstore(slot, index)                     // 更新长度
    }
}

```

# 智能合约账户使用 SmartSession 模块
* **SmartSession 模块**：ERC-7579 / Rhinestone 提供的模块，实现了 **临时 session key / 限制操作策略 / ERC1271 签名验证**。

1️⃣ 通过 installModule(address module, bytes initData) 将 SmartSession 挂载上去

2️⃣ session 启用阶段（Enable Flow）

启用 session 是 **绑定 session key 和策略到账户** 的过程：

1. **创建 Session 对象**

   * Session 包含：

     * sessionKey / PermissionId
     * actionPolicies（允许的操作）
     * ERC1271 策略
     * UserOp 策略
     * ISessionValidator 地址 + initData

2. **调用 `enableSessions(Session[] calldata sessions)`**

   * 遍历每个 Session：

     1. `$enabledSessions.add(account, permissionId)` → 标记 session 已启用
     2. `$sessionValidators.enable(...)` → 绑定 ISessionValidator
     3. `$userOpPolicies.enable(...)` → 启用 UserOp 策略
     4. `$erc1271Policies.enable(...)` → 启用 ERC1271 策略
     5. `$enabledERC7739Content.enable(...)` → 启用允许的内容（ERC7739）
     6. `$actionPolicies.enable(...)` → 启用操作策略


3️⃣ session 启用后

* **账户验证用户操作**：

  * 用户用 sessionKey 发起操作（UserOperation / execute）
  * SmartSession 的 `validateUserOp()` 被调用
  * 验证 session 是否启用 (`$enabledSessions`)
  * 执行绑定的各类策略（UserOpPolicy、ActionPolicy、ERC1271）
  * ISessionValidator 校验签名

