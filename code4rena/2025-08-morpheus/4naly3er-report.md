# Report

- [Report](#report)
  - [Gas Optimizations](#gas-optimizations)
    - [\[GAS-1\] Use ERC721A instead ERC721](#gas-1-use-erc721a-instead-erc721)
    - [\[GAS-2\] Don't use `_msgSender()` if not supporting EIP-2771](#gas-2-dont-use-_msgsender-if-not-supporting-eip-2771)
    - [\[GAS-3\] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)](#gas-3-a--a--b-is-more-gas-effective-than-a--b-for-state-variables-excluding-arrays-and-mappings)
    - [\[GAS-4\] Use assembly to check for `address(0)`](#gas-4-use-assembly-to-check-for-address0)
    - [\[GAS-5\] Comparing to a Boolean constant](#gas-5-comparing-to-a-boolean-constant)
    - [\[GAS-6\] Using bools for storage incurs overhead](#gas-6-using-bools-for-storage-incurs-overhead)
    - [\[GAS-7\] Cache array length outside of loop](#gas-7-cache-array-length-outside-of-loop)
    - [\[GAS-8\] State variables should be cached in stack variables rather than re-reading them from storage](#gas-8-state-variables-should-be-cached-in-stack-variables-rather-than-re-reading-them-from-storage)
    - [\[GAS-9\] Use calldata instead of memory for function arguments that do not get mutated](#gas-9-use-calldata-instead-of-memory-for-function-arguments-that-do-not-get-mutated)
    - [\[GAS-10\] For Operations that will not overflow, you could use unchecked](#gas-10-for-operations-that-will-not-overflow-you-could-use-unchecked)
    - [\[GAS-11\] Use Custom Errors instead of Revert Strings to save Gas](#gas-11-use-custom-errors-instead-of-revert-strings-to-save-gas)
    - [\[GAS-12\] Avoid contract existence checks by using low level calls](#gas-12-avoid-contract-existence-checks-by-using-low-level-calls)
    - [\[GAS-13\] Functions guaranteed to revert when called by normal users can be marked `payable`](#gas-13-functions-guaranteed-to-revert-when-called-by-normal-users-can-be-marked-payable)
    - [\[GAS-14\] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)](#gas-14-i-costs-less-gas-compared-to-i-or-i--1-same-for---i-vs-i---or-i---1)
    - [\[GAS-15\] Splitting require() statements that use \&\& saves gas](#gas-15-splitting-require-statements-that-use--saves-gas)
    - [\[GAS-16\] `uint256` to `bool` `mapping`: Utilizing Bitmaps to dramatically save on Gas](#gas-16-uint256-to-bool-mapping-utilizing-bitmaps-to-dramatically-save-on-gas)
    - [\[GAS-17\] Increments/decrements can be unchecked in for-loops](#gas-17-incrementsdecrements-can-be-unchecked-in-for-loops)
    - [\[GAS-18\] Use != 0 instead of \> 0 for unsigned integer comparison](#gas-18-use--0-instead-of--0-for-unsigned-integer-comparison)
  - [Non Critical Issues](#non-critical-issues)
    - [\[NC-1\] Missing checks for `address(0)` when assigning values to address state variables](#nc-1-missing-checks-for-address0-when-assigning-values-to-address-state-variables)
    - [\[NC-2\] Array indices should be referenced via `enum`s rather than via numeric literals](#nc-2-array-indices-should-be-referenced-via-enums-rather-than-via-numeric-literals)
    - [\[NC-3\] Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked`](#nc-3-use-stringconcat-or-bytesconcat-instead-of-abiencodepacked)
    - [\[NC-4\] `constant`s should be defined rather than using magic numbers](#nc-4-constants-should-be-defined-rather-than-using-magic-numbers)
    - [\[NC-5\] Control structures do not follow the Solidity Style Guide](#nc-5-control-structures-do-not-follow-the-solidity-style-guide)
    - [\[NC-6\] Default Visibility for constants](#nc-6-default-visibility-for-constants)
    - [\[NC-7\] Consider disabling `renounceOwnership()`](#nc-7-consider-disabling-renounceownership)
    - [\[NC-8\] Duplicated `require()`/`revert()` Checks Should Be Refactored To A Modifier Or Function](#nc-8-duplicated-requirerevert-checks-should-be-refactored-to-a-modifier-or-function)
    - [\[NC-9\] Events that mark critical parameter changes should contain both the old and the new value](#nc-9-events-that-mark-critical-parameter-changes-should-contain-both-the-old-and-the-new-value)
    - [\[NC-10\] Function ordering does not follow the Solidity style guide](#nc-10-function-ordering-does-not-follow-the-solidity-style-guide)
    - [\[NC-11\] Functions should not be longer than 50 lines](#nc-11-functions-should-not-be-longer-than-50-lines)
    - [\[NC-12\] Lack of checks in setters](#nc-12-lack-of-checks-in-setters)
    - [\[NC-13\] Missing Event for critical parameters change](#nc-13-missing-event-for-critical-parameters-change)
    - [\[NC-14\] NatSpec is completely non-existent on functions that should have them](#nc-14-natspec-is-completely-non-existent-on-functions-that-should-have-them)
    - [\[NC-15\] Incomplete NatSpec: `@param` is missing on actually documented functions](#nc-15-incomplete-natspec-param-is-missing-on-actually-documented-functions)
    - [\[NC-16\] Incomplete NatSpec: `@return` is missing on actually documented functions](#nc-16-incomplete-natspec-return-is-missing-on-actually-documented-functions)
    - [\[NC-17\] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor](#nc-17-use-a-modifier-instead-of-a-requireif-statement-for-a-special-msgsender-actor)
    - [\[NC-18\] Consider using named mappings](#nc-18-consider-using-named-mappings)
    - [\[NC-19\] `public` functions not called by the contract should be declared `external` instead](#nc-19-public-functions-not-called-by-the-contract-should-be-declared-external-instead)
    - [\[NC-20\] Variables need not be initialized to zero](#nc-20-variables-need-not-be-initialized-to-zero)
  - [Low Issues](#low-issues)
    - [\[L-1\] `approve()`/`safeApprove()` may revert if the current approval is not zero](#l-1-approvesafeapprove-may-revert-if-the-current-approval-is-not-zero)
    - [\[L-2\] Use a 2-step ownership transfer pattern](#l-2-use-a-2-step-ownership-transfer-pattern)
    - [\[L-3\] Some tokens may revert when zero value transfers are made](#l-3-some-tokens-may-revert-when-zero-value-transfers-are-made)
    - [\[L-4\] USDC stablecoin centralization risk](#l-4-usdc-stablecoin-centralization-risk)
    - [\[L-5\] Missing checks for `address(0)` when assigning values to address state variables](#l-5-missing-checks-for-address0-when-assigning-values-to-address-state-variables)
    - [\[L-6\] `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`](#l-6-abiencodepacked-should-not-be-used-with-dynamic-types-when-passing-the-result-to-a-hash-function-such-as-keccak256)
    - [\[L-7\] `decimals()` is not a part of the ERC-20 standard](#l-7-decimals-is-not-a-part-of-the-erc-20-standard)
    - [\[L-8\] Deprecated approve() function](#l-8-deprecated-approve-function)
    - [\[L-9\] Do not use deprecated library functions](#l-9-do-not-use-deprecated-library-functions)
    - [\[L-10\] `safeApprove()` is deprecated](#l-10-safeapprove-is-deprecated)
    - [\[L-11\] Division by zero not prevented](#l-11-division-by-zero-not-prevented)
    - [\[L-12\] Empty Function Body - Consider commenting why](#l-12-empty-function-body---consider-commenting-why)
    - [\[L-13\] External calls in an un-bounded `for-`loop may result in a DOS](#l-13-external-calls-in-an-un-bounded-for-loop-may-result-in-a-dos)
    - [\[L-14\] Initializers could be front-run](#l-14-initializers-could-be-front-run)
    - [\[L-15\] Signature use at deadlines should be allowed](#l-15-signature-use-at-deadlines-should-be-allowed)
    - [\[L-16\] Possible rounding issue](#l-16-possible-rounding-issue)
    - [\[L-17\] Loss of precision](#l-17-loss-of-precision)
    - [\[L-18\] Solidity version 0.8.20+ may not work on other chains due to `PUSH0`](#l-18-solidity-version-0820-may-not-work-on-other-chains-due-to-push0)
    - [\[L-19\] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`](#l-19-use-ownable2steptransferownership-instead-of-ownabletransferownership)
    - [\[L-20\] Unsafe ERC20 operation(s)](#l-20-unsafe-erc20-operations)
    - [\[L-21\] Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions](#l-21-upgradeable-contract-is-missing-a-__gap50-storage-variable-to-allow-for-new-storage-variables-in-later-versions)
    - [\[L-22\] Upgradeable contract not initialized](#l-22-upgradeable-contract-not-initialized)
  - [Medium Issues](#medium-issues)
    - [\[M-1\] Contracts are vulnerable to fee-on-transfer accounting-related issues](#m-1-contracts-are-vulnerable-to-fee-on-transfer-accounting-related-issues)
    - [\[M-2\] Centralization Risk for trusted owners](#m-2-centralization-risk-for-trusted-owners)
      - [Impact](#impact)
    - [\[M-3\] Direct `supportsInterface()` calls may cause caller to revert](#m-3-direct-supportsinterface-calls-may-cause-caller-to-revert)
    - [\[M-4\] Return values of `transfer()`/`transferFrom()` not checked](#m-4-return-values-of-transfertransferfrom-not-checked)
    - [\[M-5\] Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20`](#m-5-unsafe-use-of-transfertransferfromapprove-with-ierc20)
  - [High Issues](#high-issues)
    - [\[H-1\] IERC20.approve() will revert for USDT](#h-1-ierc20approve-will-revert-for-usdt)

## Gas Optimizations

| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Use ERC721A instead ERC721 | 1 |
| [GAS-2](#GAS-2) | Don't use `_msgSender()` if not supporting EIP-2771 | 18 |
| [GAS-3](#GAS-3) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 13 |
| [GAS-4](#GAS-4) | Use assembly to check for `address(0)` | 20 |
| [GAS-5](#GAS-5) | Comparing to a Boolean constant | 5 |
| [GAS-6](#GAS-6) | Using bools for storage incurs overhead | 5 |
| [GAS-7](#GAS-7) | Cache array length outside of loop | 7 |
| [GAS-8](#GAS-8) | State variables should be cached in stack variables rather than re-reading them from storage | 23 |
| [GAS-9](#GAS-9) | Use calldata instead of memory for function arguments that do not get mutated | 4 |
| [GAS-10](#GAS-10) | For Operations that will not overflow, you could use unchecked | 121 |
| [GAS-11](#GAS-11) | Use Custom Errors instead of Revert Strings to save Gas | 63 |
| [GAS-12](#GAS-12) | Avoid contract existence checks by using low level calls | 6 |
| [GAS-13](#GAS-13) | Functions guaranteed to revert when called by normal users can be marked `payable` | 33 |
| [GAS-14](#GAS-14) | `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`) | 8 |
| [GAS-15](#GAS-15) | Splitting require() statements that use && saves gas | 1 |
| [GAS-16](#GAS-16) | `uint256` to `bool` `mapping`: Utilizing Bitmaps to dramatically save on Gas | 1 |
| [GAS-17](#GAS-17) | Increments/decrements can be unchecked in for-loops | 10 |
| [GAS-18](#GAS-18) | Use != 0 instead of > 0 for unsigned integer comparison | 14 |

### <a name="GAS-1"></a>[GAS-1] Use ERC721A instead ERC721

ERC721A standard, ERC721A is an improvement standard for ERC721 tokens. It was proposed by the Azuki team and used for developing their NFT collection. Compared with ERC721, ERC721A is a more gas-efficient standard to mint a lot of of NFTs simultaneously. It allows developers to mint multiple NFTs at the same gas price. This has been a great improvement due to Ethereum's sky-rocketing gas fee.

    Reference: https://nextrope.com/erc721-vs-erc721a-2/

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

4: import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="GAS-2"></a>[GAS-2] Don't use `_msgSender()` if not supporting EIP-2771

Use `msg.sender` if the code does not implement [EIP-2771 trusted forwarder](https://eips.ethereum.org/EIPS/eip-2771) support

*Instances (18)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

240:             claimSender[rewardPoolIndex_][_msgSender()][senders_[i]] = isAllowed_[i];

242:             emit ClaimSenderSet(rewardPoolIndex_, _msgSender(), senders_[i], isAllowed_[i]);

249:         claimReceiver[rewardPoolIndex_][_msgSender()] = receiver_;

251:         emit ClaimReceiverSet(rewardPoolIndex_, _msgSender(), receiver_);

262:         _stake(_msgSender(), rewardPoolIndex_, amount_, currentPoolRate_, claimLockEnd_, referrer_);

277:         _withdraw(_msgSender(), rewardPoolIndex_, amount_, currentPoolRate_);

284:         _claim(rewardPoolIndex_, _msgSender(), receiver_);

291:             require(claimSender[rewardPoolIndex_][staker_][_msgSender()], "DS: invalid caller");

298:         _claimReferrerTier(rewardPoolIndex_, _msgSender(), receiver_);

302:         require(claimSender[rewardPoolIndex_][referrer_][_msgSender()], "DS: invalid caller");

315:         address user_ = _msgSender();

381:             IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

570:             _msgSender()

607:             _msgSender()

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

286:         address depositPoolAddress_ = _msgSender();

305:         address depositPoolAddress_ = _msgSender();

468:         address depositPoolAddress_ = _msgSender();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

102:         require(_msgSender() == distributor, "L1S: the `msg.sender` isn't `distributor`");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="GAS-3"></a>[GAS-3] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)

This saves **16 gas per instance.**

*Instances (13)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

207:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

265:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

280:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

348:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

390:             totalDepositedInPublicPools += amount_;

563:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

600:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

300:         depositPool.deposited += amount_;

301:         depositPool.lastUnderlyingBalance += amount_;

352:             distributedRewards[rewardPoolIndex_][depositPoolAddresses[rewardPoolIndex_][0]] += rewards_;

392:             totalYield_ += yield_;

396:             undistributedRewards += rewards_;

405:             distributedRewards[rewardPoolIndex_][depositPoolAddresses[rewardPoolIndex_][i]] +=

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="GAS-4"></a>[GAS-4] Use assembly to check for `address(0)`

*Saves 6 gas per instance*

*Instances (20)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

104:         if (distributor != address(0)) {

288:         if (claimReceiver[rewardPoolIndex_][staker_] != address(0)) {

372:         if (referrer_ == address(0)) {

622:         if (newReferrer_ == address(0)) {

632:         if (oldReferrer_ == address(0)) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

136:         require(value_ != address(0), "DR: invalid Aave pool address");

147:         require(value_ != address(0), "DR: invalid Aave pool data provider address");

158:         require(value_ != address(0), "DR: invalid Aave rewards controller address");

449:         require(aaveRewardsController != address(0), "DR: rewards controller not set");

450:         require(to != address(0), "DR: invalid recipient address");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

57:         require(value_ != address(0), "L1S: invalid stETH address");

76:         require(value_ != address(0), "L1S: invalid `uniswapSwapRouter` address");

133:         require(stETH != address(0), "L1S: stETH is not set");

134:         require(newConfig_.receiver != address(0), "L1S: invalid receiver");

138:         if (oldConfig_.wstETH != address(0)) {

160:         require(config_.wstETH != address(0), "L1S: wstETH isn't set");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

53:         if (params_.tokenIn != address(0) && params_.tokenIn != newParams_.tokenIn) {

58:         if (params_.tokenOut != address(0) && params_.tokenOut != newParams_.tokenOut) {

145:         require(newParams_.tokenIn != address(0), "L2TR: invalid tokenIn");

146:         require(newParams_.tokenOut != address(0), "L2TR: invalid tokenOut");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="GAS-5"></a>[GAS-5] Comparing to a Boolean constant

Comparing to a constant (`true` or `false`) is a bit more expensive than directly checking the returned boolean value.

Consider using `if(directValue)` instead of `if(directValue == true)` and `if(!directValue)` instead of `if(directValue == false)`

*Instances (5)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

308:         require(isMigrationOver == true, "DS: migration isn't over");

361:         require(isMigrationOver == true, "DS: migration isn't over");

435:         require(isMigrationOver == true, "DS: migration isn't over");

514:         require(isMigrationOver == true, "DS: migration isn't over");

577:         require(isMigrationOver == true, "DS: migration isn't over");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="GAS-6"></a>[GAS-6] Using bools for storage incurs overhead

Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (5)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

24:     bool public isNotUpgradeable;

62:     mapping(uint256 => mapping(address => mapping(address => bool))) public claimSender;

68:     bool public isMigrationOver;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

30:     mapping(address => bool) public isDepositTokenAdded;

39:     mapping(uint256 => bool) public isPrivateDepositPoolAdded;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="GAS-7"></a>[GAS-7] Cache array length outside of loop

If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (7)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

58:         for (uint256 i = 0; i < paths_.length; i++) {

83:         for (uint256 i = 0; i < dataFeeds_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

170:         for (uint256 i = 0; i < referrerTiers_.length; i++) {

209:         for (uint256 i; i < users_.length; ++i) {

239:         for (uint256 i = 0; i < senders_.length; ++i) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

213:         for (uint256 i = 0; i < poolsFee_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

26:         for (uint256 i = 0; i < poolsInfo_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-8"></a>[GAS-8] State variables should be cached in stack variables rather than re-reading them from storage

The instances below point to the second+ access of a state variable within a function. Caching of a state variable replaces each Gwarmaccess (100 gas) with a much cheaper stack read. Other less obvious fixes/optimizations include having local memory caches of state variable structs, or having local caches of state variable contracts/addresses.

*Saves 100 gas per instance*

*Instances (23)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

107:         IERC20(depositToken).approve(value_, type(uint256).max);

153:         IERC20(depositToken).transfer(distributor, remainder_);

155:         IDistributor(distributor).supply(rewardPoolIndex_, totalDepositedInPublicPools);

203:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

259:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

273:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

313:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

381:             IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

382:             uint256 balanceAfter_ = IERC20(depositToken).balanceOf(address(this));

386:             IDistributor(distributor).supply(rewardPoolIndex_, amount_);

503:         if (IRewardPool(IDistributor(distributor).rewardPool()).isRewardPoolPublic(rewardPoolIndex_)) {

506:             IDistributor(distributor).withdraw(rewardPoolIndex_, amount_);

531:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

566:         IDistributor(distributor).sendMintMessage{value: msg.value}(

580:         IDistributor(distributor).distributeRewards(rewardPoolIndex_);

603:         IDistributor(distributor).sendMintMessage{value: msg.value}(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

340:         uint256 rewards_ = IRewardPool(rewardPool).getPeriodRewards(

488:             IERC20(depositPool.token).safeTransfer(l1Sender, yield_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

227:         uint256 amountOut_ = ISwapRouter(uniswapSwapRouter).exactInput(params_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

59:             TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);

151:         TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="GAS-9"></a>[GAS-9] Use calldata instead of memory for function arguments that do not get mutated

When a function with a `memory` array is called externally, the `abi.decode()` step has to use a for-loop to copy each index of the `calldata` to the `memory` index. Each iteration of this for-loop costs at least 60 gas (i.e. `60 * <mem_array>.length`). Using `calldata` directly bypasses this loop.

If the array is passed to an `internal` function which passes the array to another internal function where the array is modified and therefore `memory` is used in the `external` call, it's still more gas-efficient to use `calldata` when the `external` function uses modifiers, since the modifiers may prevent the internal functions from being called. Structs have the same overhead as an array of length one.

 *Saves 60 gas per instance*

*Instances (4)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

66:     function getPathId(string memory path_) public pure returns (bytes32) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

196:         string memory chainLinkPath_,

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

31:         SwapParams memory secondSwapParams_

50:     function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="GAS-10"></a>[GAS-10] For Operations that will not overflow, you could use unchecked

*Instances (121)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

7: import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

9: import {DecimalsConverter} from "@solarity/solidity-lib/libs/decimals/DecimalsConverter.sol";

11: import {IChainLinkDataConsumer, IERC165} from "../interfaces/capital-protocol/IChainLinkDataConsumer.sol";

58:         for (uint256 i = 0; i < paths_.length; i++) {

83:         for (uint256 i = 0; i < dataFeeds_.length; i++) {

91:                 if (block.timestamp < updatedAt_ || block.timestamp - updatedAt_ > allowedPriceUpdateDelay) {

99:                     res_ = (res_ * uint256(answer_)) / (10 ** aggregator_.decimals());

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

4: import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {PRECISION} from "@solarity/solidity-lib/utils/Globals.sol";

10: import {IDepositPool, IERC165} from "../interfaces/capital-protocol/IDepositPool.sol";

11: import {IRewardPool} from "../interfaces/capital-protocol/IRewardPool.sol";

12: import {IDistributor} from "../interfaces/capital-protocol/IDistributor.sol";

14: import {LockMultiplierMath} from "../libs/LockMultiplierMath.sol";

15: import {ReferrerLib} from "../libs/ReferrerLib.sol";

151:         uint256 remainder_ = IERC20(depositToken).balanceOf(address(this)) - totalDepositedInPublicPools;

170:         for (uint256 i = 0; i < referrerTiers_.length; i++) {

207:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

209:         for (uint256 i; i < users_.length; ++i) {

216:                     amounts_[i] - deposited_,

222:                 _withdraw(users_[i], rewardPoolIndex_, deposited_ - amounts_[i], currentPoolRate_);

239:         for (uint256 i = 0; i < senders_.length; ++i) {

265:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

280:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

328:         uint256 virtualDeposited_ = (userData.deposited * multiplier_) / PRECISION;

338:             rewardPoolData.totalVirtualDeposited +

339:             virtualDeposited_ -

348:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

384:             amount_ = balanceAfter_ - balanceBefore_;

388:             require(userData.deposited + amount_ >= rewardPoolProtocolDetails.minimalStake, "DS: amount too low");

390:             totalDepositedInPublicPools += amount_;

395:         uint256 deposited_ = userData.deposited + amount_;

397:         uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;

417:             rewardPoolData.totalVirtualDeposited +

418:             virtualDeposited_ -

451:                 block.timestamp > userData.lastStake + rewardPoolProtocolDetails.withdrawLockPeriodAfterStake,

455:             newDeposited_ = deposited_ - amount_;

463:             newDeposited_ = deposited_ - amount_;

473:         uint256 virtualDeposited_ = (newDeposited_ * multiplier_) / PRECISION;

493:             rewardPoolData.totalVirtualDeposited +

494:             virtualDeposited_ -

504:             totalDepositedInPublicPools -= amount_;

521:                 userData.lastStake + rewardPoolsProtocolDetails[rewardPoolIndex_].claimLockPeriodAfterStake,

526:                 userData.lastClaim + rewardPoolsProtocolDetails[rewardPoolIndex_].claimLockPeriodAfterClaim,

540:         uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;

551:             rewardPoolData.totalVirtualDeposited +

552:             virtualDeposited_ -

563:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

588:             block.timestamp > referrerData.lastClaim + rewardPoolProtocolDetails.claimLockPeriodAfterClaim,

600:         rewardPoolsProtocolDetails[rewardPoolIndex_].distributedRewards += rewards_;

654:             oldVirtualAmountStaked = oldReferrerData.virtualAmountStaked + newReferrerData.virtualAmountStaked;

658:             newVirtualAmountStaked = oldReferrerData.virtualAmountStaked + newReferrerData.virtualAmountStaked;

666:             rewardPoolData.totalVirtualDeposited +

667:             newVirtualAmountStaked -

699:         uint256 newRewards_ = ((currentPoolRate_ - userData_.rate) * deposited_) / PRECISION;

701:         return userData_.pendingRewards + newRewards_;

707:         uint256 rewards_ = IDistributor(distributor).getDistributedRewards(rewardPoolIndex_, address(this)) -

714:         uint256 rate_ = rewardPoolData.rate + (rewards_ * PRECISION) / rewardPoolData.totalVirtualDeposited;

743:         return (referrerData.virtualAmountStaked * PRECISION) / referrerData.amountStaked;

752:             LockMultiplierMath.getLockPeriodMultiplier(claimLockStart_, claimLockEnd_) +

753:             ReferrerLib.getReferralMultiplier(referrer_) -

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

4: import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

7: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

10: import {IPool as AaveIPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

11: import {IPoolDataProvider as AaveIPoolDataProvider} from "@aave/core-v3/contracts/interfaces/IPoolDataProvider.sol";

12: import {IRewardsController} from "../interfaces/aave/IRewardsController.sol";

14: import {DecimalsConverter} from "@solarity/solidity-lib/libs/decimals/DecimalsConverter.sol";

16: import {IDistributor, IERC165} from "../interfaces/capital-protocol/IDistributor.sol";

17: import {IL1SenderV2} from "../interfaces/capital-protocol/IL1SenderV2.sol";

18: import {IChainLinkDataConsumer} from "../interfaces/capital-protocol/IChainLinkDataConsumer.sol";

19: import {IDepositPool} from "../interfaces/capital-protocol/IDepositPool.sol";

20: import {IRewardPool} from "../interfaces/capital-protocol/IRewardPool.sol";

267:         for (uint256 i = 0; i < length_; i++) {

300:         depositPool.deposited += amount_;

301:         depositPool.lastUnderlyingBalance += amount_;

316:         depositPool.deposited -= amount_;

317:         depositPool.lastUnderlyingBalance -= amount_;

352:             distributedRewards[rewardPoolIndex_][depositPoolAddresses[rewardPoolIndex_][0]] += rewards_;

360:         if (block.timestamp <= lastCalculatedTimestamp_ + minRewardsDistributePeriod) return;

372:         for (uint256 i = 0; i < length_; i++) {

386:             uint256 underlyingYield_ = (balance_ - depositPool.lastUnderlyingBalance).to18(decimals_);

387:             uint256 yield_ = underlyingYield_ * depositPool.tokenPrice;

392:             totalYield_ += yield_;

396:             undistributedRewards += rewards_;

402:         for (uint256 i = 0; i < length_; i++) {

405:             distributedRewards[rewardPoolIndex_][depositPoolAddresses[rewardPoolIndex_][i]] +=

406:                 (yields_[i] * rewards_) /

482:         uint256 yield_ = depositPool.lastUnderlyingBalance - depositPool.deposited;

491:         depositPool.lastUnderlyingBalance -= yield_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

4: import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

9: import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

11: import {ILayerZeroEndpoint} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroEndpoint.sol";

13: import {IGatewayRouter} from "@arbitrum/token-bridge-contracts/contracts/tokenbridge/libraries/gateway/IGatewayRouter.sol";

15: import {IL1SenderV2, IERC165} from "../interfaces/capital-protocol/IL1SenderV2.sol";

16: import {IDistributor} from "../interfaces/capital-protocol/IDistributor.sol";

17: import {IWStETH} from "../interfaces/tokens/IWStETH.sol";

205:         require(tokens_.length >= 2 && tokens_.length == poolsFee_.length + 1, "L1S: invalid array length");

213:         for (uint256 i = 0; i < poolsFee_.length; i++) {

216:         path_ = abi.encodePacked(path_, tokens_[tokens_.length - 1]);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

4: import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

8: import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

9: import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

11: import {IL2TokenReceiverV2, IERC165, IERC721Receiver} from "../interfaces/capital-protocol/IL2TokenReceiverV2.sol";

12: import {INonfungiblePositionManager} from "../interfaces/uniswap-v3/INonfungiblePositionManager.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

7: import {LinearDistributionIntervalDecrease} from "../libs/LinearDistributionIntervalDecrease.sol";

9: import {IRewardPool, IERC165} from "../interfaces/capital-protocol/IRewardPool.sol";

26:         for (uint256 i = 0; i < poolsInfo_.length; i++) {

44:         emit RewardPoolAdded(rewardPools.length - 1, rewardPool_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-11"></a>[GAS-11] Use Custom Errors instead of Revert Strings to save Gas

Custom errors are available from solidity version 0.8.4. Custom errors save [**~50 gas**](https://gist.github.com/IllIllI000/ad1bd0d29a0101b25e57c293b4b0c746) each time they're hit by [avoiding having to allocate and store the revert string](https://blog.soliditylang.org/2021/04/21/custom-errors/#errors-in-depth). Not defining the strings also save deployment gas

Additionally, custom errors can be used inside and outside of contracts (including interfaces and libraries).

Source: <https://blog.soliditylang.org/2021/04/21/custom-errors/>:

> Starting from [Solidity v0.8.4](https://github.com/ethereum/solidity/releases/tag/v0.8.4), there is a convenient and gas-efficient way to explain to users why an operation failed through the use of custom errors. Until now, you could already use strings to give more information about failures (e.g., `revert("Insufficient funds.");`), but they are rather expensive, especially when it comes to deploy cost, and it is difficult to use dynamic information in them.

Consider replacing **all revert strings** with custom errors in the solution, and particularly those that have multiple occurrences:

*Instances (63)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

57:         require(paths_.length == feeds_.length, "CLDC: mismatched array lengths");

59:             require(feeds_[i].length > 0, "CLDC: empty feed array");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

102:         require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "DR: invalid distributor address");

138:         require(!isMigrationOver, "DS: the migration is over");

152:         require(remainder_ > 0, "DS: yield for token is zero");

175:                 require(amount_ > lastAmount_, "DS: invalid referrer tiers (1)");

176:                 require(multiplier_ > lastMultiplier_, "DS: invalid referrer tiers (2)");

199:         require(users_.length == amounts_.length, "DS: invalid length");

200:         require(users_.length == claimLockEnds_.length, "DS: invalid length");

201:         require(users_.length == referrers_.length, "DS: invalid length");

237:         require(senders_.length == isAllowed_.length, "DS: invalid array length");

291:             require(claimSender[rewardPoolIndex_][staker_][_msgSender()], "DS: invalid caller");

302:         require(claimSender[rewardPoolIndex_][referrer_][_msgSender()], "DS: invalid caller");

308:         require(isMigrationOver == true, "DS: migration isn't over");

311:         require(claimLockEnd_ > block.timestamp, "DS: invalid lock end value (1)");

321:         require(userData.deposited > 0, "DS: user isn't staked");

322:         require(claimLockEnd_ > userData.claimLockEnd, "DS: invalid lock end value (2)");

361:         require(isMigrationOver == true, "DS: migration isn't over");

370:         require(claimLockEnd_ >= userData.claimLockEnd, "DS: invalid claim lock end");

377:             require(amount_ > 0, "DS: nothing to stake");

388:             require(userData.deposited + amount_ >= rewardPoolProtocolDetails.minimalStake, "DS: amount too low");

435:         require(isMigrationOver == true, "DS: migration isn't over");

442:         require(deposited_ > 0, "DS: user isn't staked");

457:             require(amount_ > 0, "DS: nothing to withdraw");

514:         require(isMigrationOver == true, "DS: migration isn't over");

529:         require(block.timestamp > userData.claimLockEnd, "DS: user claim is locked");

535:         require(pendingRewards_ > 0, "DS: nothing to claim");

577:         require(isMigrationOver == true, "DS: migration isn't over");

770:         require(!isNotUpgradeable, "DS: upgrade isn't available");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

125:         require(IERC165(value_).supportsInterface(type(IL1SenderV2).interfaceId), "DR: invalid L1Sender address");

136:         require(value_ != address(0), "DR: invalid Aave pool address");

147:         require(value_ != address(0), "DR: invalid Aave pool data provider address");

158:         require(value_ != address(0), "DR: invalid Aave rewards controller address");

166:         require(IERC165(value_).supportsInterface(type(IRewardPool).interfaceId), "DR: invalid reward pool address");

181:         require(value_ <= block.timestamp, "DR: invalid last calculated timestamp");

221:             require(!isDepositTokenAdded[token_], "DR: the deposit token already added");

251:         require(depositPools[rewardPoolIndex_][depositPoolAddress_].isExist, "DR: deposit pool doesn't exist");

274:             require(price_ > 0, "DR: price for pair is zero");

290:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

309:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

314:         require(amount_ > 0, "DR: nothing to withdraw");

336:         require(lastCalculatedTimestamp_ != 0, "DR: `rewardPoolLastCalculatedTimestamp` isn't set");

420:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

427:         require(undistributedRewards > 0, "DR: nothing to withdraw");

449:         require(aaveRewardsController != address(0), "DR: rewards controller not set");

450:         require(to != address(0), "DR: invalid recipient address");

451:         require(assets.length > 0, "DR: no assets provided");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

57:         require(value_ != address(0), "L1S: invalid stETH address");

65:         require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "L1S: invalid distributor address");

76:         require(value_ != address(0), "L1S: invalid `uniswapSwapRouter` address");

102:         require(_msgSender() == distributor, "L1S: the `msg.sender` isn't `distributor`");

133:         require(stETH != address(0), "L1S: stETH is not set");

134:         require(newConfig_.receiver != address(0), "L1S: invalid receiver");

160:         require(config_.wstETH != address(0), "L1S: wstETH isn't set");

205:         require(tokens_.length >= 2 && tokens_.length == poolsFee_.length + 1, "L1S: invalid array length");

206:         require(amountIn_ != 0, "L1S: invalid `amountIn_` value");

207:         require(amountOutMinimum_ != 0, "L1S: invalid `amountOutMinimum_` value");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

145:         require(newParams_.tokenIn != address(0), "L2TR: invalid tokenIn");

146:         require(newParams_.tokenOut != address(0), "L2TR: invalid tokenOut");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

40:         require(rewardPool_.decreaseInterval > 0, "RP: invalid decrease interval");

60:         require(isRewardPoolExist(index_), "RP: the reward pool doesn't exist");

64:         require(isRewardPoolPublic(index_), "RP: the pool isn't public");

68:         require(!isRewardPoolPublic(index_), "RP: the pool is public");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-12"></a>[GAS-12] Avoid contract existence checks by using low level calls

Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

151:         uint256 remainder_ = IERC20(depositToken).balanceOf(address(this)) - totalDepositedInPublicPools;

380:             uint256 balanceBefore_ = IERC20(depositToken).balanceOf(address(this));

382:             uint256 balanceAfter_ = IERC20(depositToken).balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

384:             uint256 balance_ = IERC20(yieldToken_).balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

162:         uint256 stETHBalance_ = IERC20(stETH).balanceOf(address(this));

167:         uint256 amount_ = IWStETH(config_.wstETH).balanceOf(address(this));

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="GAS-13"></a>[GAS-13] Functions guaranteed to revert when called by normal users can be marked `payable`

If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (33)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {

56:     function updateDataFeeds(string[] calldata paths_, address[][] calldata feeds_) external onlyOwner {

117:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

101:     function setDistributor(address value_) public onlyOwner {

137:     function migrate(uint256 rewardPoolIndex_) external onlyOwner {

162:     function editReferrerTiers(uint256 rewardPoolIndex_, ReferrerTier[] calldata referrerTiers_) external onlyOwner {

761:     function removeUpgradeability() external onlyOwner {

769:     function _authorizeUpgrade(address) internal view override onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

113:     function setChainLinkDataConsumer(address value_) public onlyOwner {

124:     function setL1Sender(address value_) public onlyOwner {

135:     function setAavePool(address value_) public onlyOwner {

146:     function setAavePoolDataProvider(address value_) public onlyOwner {

157:     function setAaveRewardsController(address value_) public onlyOwner {

165:     function setRewardPool(address value_) public onlyOwner {

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {

250:     function _onlyExistedDepositPool(uint256 rewardPoolIndex_, address depositPoolAddress_) private view {

513:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

56:     function setStETh(address value_) external onlyOwner {

64:     function setDistributor(address value_) external onlyOwner {

75:     function setUniswapSwapRouter(address value_) external onlyOwner {

95:     function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {

132:     function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {

242:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

50:     function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {

65:     function withdrawToken(address recipient_, address token_, uint256 amount_) external onlyOwner {

69:     function withdrawTokenId(address recipient_, address token_, uint256 tokenId_) external onlyOwner {

164:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

39:     function addRewardPool(RewardPool calldata rewardPool_) public onlyOwner {

59:     function onlyExistedRewardPool(uint256 index_) external view {

63:     function onlyPublicRewardPool(uint256 index_) external view {

67:     function onlyNotPublicRewardPool(uint256 index_) external view {

97:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-14"></a>[GAS-14] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)

Pre-increments and pre-decrements are cheaper.

For a `uint256 i` variable, the following is true with the Optimizer enabled at 10k:

**Increment:**

- `i += 1` is the most expensive form
- `i++` costs 6 gas less than `i += 1`
- `++i` costs 5 gas less than `i++` (11 gas less than `i += 1`)

**Decrement:**

- `i -= 1` is the most expensive form
- `i--` costs 11 gas less than `i -= 1`
- `--i` costs 5 gas less than `i--` (16 gas less than `i -= 1`)

Note that post-increments (or post-decrements) return the old value before incrementing or decrementing, hence the name *post-increment*:

```solidity
uint i = 1;  
uint j = 2;
require(j == i++, "This will be false as i is incremented after the comparison");
```
  
However, pre-increments (or pre-decrements) return the new value:
  
```solidity
uint i = 1;  
uint j = 2;
require(j == ++i, "This will be true as i is incremented before the comparison");
```

In the pre-increment case, the compiler has to create a temporary variable (when used) for returning `1` instead of `2`.

Consider using pre-increments and pre-decrements where they are relevant (meaning: not where post-increments/decrements logic are relevant).

*Saves 5 gas per instance*

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

58:         for (uint256 i = 0; i < paths_.length; i++) {

83:         for (uint256 i = 0; i < dataFeeds_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

170:         for (uint256 i = 0; i < referrerTiers_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

267:         for (uint256 i = 0; i < length_; i++) {

372:         for (uint256 i = 0; i < length_; i++) {

402:         for (uint256 i = 0; i < length_; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

213:         for (uint256 i = 0; i < poolsFee_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

26:         for (uint256 i = 0; i < poolsInfo_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-15"></a>[GAS-15] Splitting require() statements that use && saves gas

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

205:         require(tokens_.length >= 2 && tokens_.length == poolsFee_.length + 1, "L1S: invalid array length");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="GAS-16"></a>[GAS-16] `uint256` to `bool` `mapping`: Utilizing Bitmaps to dramatically save on Gas
<https://soliditydeveloper.com/bitmaps>

<https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol>

- [BitMaps.sol#L5-L16](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol#L5-L16):

```solidity
/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, provided the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 *
 * BitMaps pack 256 booleans across each bit of a single 256-bit slot of `uint256` type.
 * Hence booleans corresponding to 256 _sequential_ indices would only consume a single slot,
 * unlike the regular `bool` which would consume an entire slot for a single value.
 *
 * This results in gas savings in two ways:
 *
 * - Setting a zero value to non-zero only once every 256 times
 * - Accessing the same warm slot for every 256 _sequential_ indices
 */
```

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

39:     mapping(uint256 => bool) public isPrivateDepositPoolAdded;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="GAS-17"></a>[GAS-17] Increments/decrements can be unchecked in for-loops

In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (10)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

58:         for (uint256 i = 0; i < paths_.length; i++) {

83:         for (uint256 i = 0; i < dataFeeds_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

170:         for (uint256 i = 0; i < referrerTiers_.length; i++) {

209:         for (uint256 i; i < users_.length; ++i) {

239:         for (uint256 i = 0; i < senders_.length; ++i) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

267:         for (uint256 i = 0; i < length_; i++) {

372:         for (uint256 i = 0; i < length_; i++) {

402:         for (uint256 i = 0; i < length_; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

213:         for (uint256 i = 0; i < poolsFee_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

26:         for (uint256 i = 0; i < poolsInfo_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="GAS-18"></a>[GAS-18] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (14)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

59:             require(feeds_[i].length > 0, "CLDC: empty feed array");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

152:         require(remainder_ > 0, "DS: yield for token is zero");

321:         require(userData.deposited > 0, "DS: user isn't staked");

326:         uint128 claimLockStart_ = userData.claimLockStart > 0 ? userData.claimLockStart : uint128(block.timestamp);

377:             require(amount_ > 0, "DS: nothing to stake");

442:         require(deposited_ > 0, "DS: user isn't staked");

457:             require(amount_ > 0, "DS: nothing to withdraw");

535:         require(pendingRewards_ > 0, "DS: nothing to claim");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

274:             require(price_ > 0, "DR: price for pair is zero");

314:         require(amount_ > 0, "DR: nothing to withdraw");

427:         require(undistributedRewards > 0, "DR: nothing to withdraw");

451:         require(assets.length > 0, "DR: no assets provided");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

163:         if (stETHBalance_ > 0) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

40:         require(rewardPool_.decreaseInterval > 0, "RP: invalid decrease interval");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

## Non Critical Issues

| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Missing checks for `address(0)` when assigning values to address state variables | 8 |
| [NC-2](#NC-2) | Array indices should be referenced via `enum`s rather than via numeric literals | 3 |
| [NC-3](#NC-3) | Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked` | 4 |
| [NC-4](#NC-4) | `constant`s should be defined rather than using magic numbers | 6 |
| [NC-5](#NC-5) | Control structures do not follow the Solidity Style Guide | 4 |
| [NC-6](#NC-6) | Default Visibility for constants | 1 |
| [NC-7](#NC-7) | Consider disabling `renounceOwnership()` | 6 |
| [NC-8](#NC-8) | Duplicated `require()`/`revert()` Checks Should Be Refactored To A Modifier Or Function | 19 |
| [NC-9](#NC-9) | Events that mark critical parameter changes should contain both the old and the new value | 19 |
| [NC-10](#NC-10) | Function ordering does not follow the Solidity style guide | 5 |
| [NC-11](#NC-11) | Functions should not be longer than 50 lines | 83 |
| [NC-12](#NC-12) | Lack of checks in setters | 5 |
| [NC-13](#NC-13) | Missing Event for critical parameters change | 1 |
| [NC-14](#NC-14) | NatSpec is completely non-existent on functions that should have them | 45 |
| [NC-15](#NC-15) | Incomplete NatSpec: `@param` is missing on actually documented functions | 9 |
| [NC-16](#NC-16) | Incomplete NatSpec: `@return` is missing on actually documented functions | 1 |
| [NC-17](#NC-17) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 1 |
| [NC-18](#NC-18) | Consider using named mappings | 16 |
| [NC-19](#NC-19) | `public` functions not called by the contract should be declared `external` instead | 9 |
| [NC-20](#NC-20) | Variables need not be initialized to zero | 13 |

### <a name="NC-1"></a>[NC-1] Missing checks for `address(0)` when assigning values to address state variables

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

89:         depositToken = depositToken_;

109:         distributor = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

119:         chainLinkDataConsumer = value_;

127:         l1Sender = value_;

168:         rewardPool = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

67:         distributor = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

36:         router = router_;

37:         nonfungiblePositionManager = nonfungiblePositionManager_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="NC-2"></a>[NC-2] Array indices should be referenced via `enum`s rather than via numeric literals

*Instances (3)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

351:             _onlyExistedDepositPool(rewardPoolIndex_, depositPoolAddresses[rewardPoolIndex_][0]);

352:             distributedRewards[rewardPoolIndex_][depositPoolAddresses[rewardPoolIndex_][0]] += rewards_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

209:         TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-3"></a>[NC-3] Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked`

Solidity version 0.8.4 introduces `bytes.concat()` (vs `abi.encodePacked(<bytes>,<bytes>)`)

Solidity version 0.8.12 introduces `string.concat()` (vs `abi.encodePacked(<str>,<str>), which catches concatenation errors (in the event of a`bytes`data mixed in the concatenation)`)

*Instances (4)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

67:         return keccak256(abi.encodePacked(path_));

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

106:         bytes memory receiverAndSenderAddresses_ = abi.encodePacked(config.receiver, address(this));

214:             path_ = abi.encodePacked(path_, tokens_[i], poolsFee_[i]);

216:         path_ = abi.encodePacked(path_, tokens_[tokens_.length - 1]);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-4"></a>[NC-4] `constant`s should be defined rather than using magic numbers

Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39) can benefit from using readable constants instead of hex/numeric literals

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

71:         return 18;

106:         return res_.convert(baseDecimals_, 18);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

766:         return 7;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

205:         require(tokens_.length >= 2 && tokens_.length == poolsFee_.length + 1, "L1S: invalid array length");

239:         return 2;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

137:         return 2;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="NC-5"></a>[NC-5] Control structures do not follow the Solidity Style Guide

See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (4)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

346:         if (rewards_ == 0) return;

360:         if (block.timestamp <= lastCalculatedTimestamp_ + minRewardsDistributePeriod) return;

403:             if (yields_[i] == 0) continue;

483:         if (yield_ == 0) return;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="NC-6"></a>[NC-6] Default Visibility for constants

Some constants are using the default visibility. For readability, consider explicitly declaring them as `internal`.

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

22:     uint128 constant DECIMAL = 1e18;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="NC-7"></a>[NC-7] Consider disabling `renounceOwnership()`

If the plan for your project does not include eventually giving up all ownership control, consider overwriting OpenZeppelin's `Ownable`'s `renounceOwnership()` function in order to disable it.

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

16: contract ChainLinkDataConsumer is IChainLinkDataConsumer, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

17: contract DepositPool is IDepositPool, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

22: contract Distributor is IDistributor, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

19: contract L1SenderV2 is IL1SenderV2, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

14: contract L2TokenReceiverV2 is IL2TokenReceiverV2, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

11: contract RewardPool is IRewardPool, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="NC-8"></a>[NC-8] Duplicated `require()`/`revert()` Checks Should Be Refactored To A Modifier Or Function

*Instances (19)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

199:         require(users_.length == amounts_.length, "DS: invalid length");

200:         require(users_.length == claimLockEnds_.length, "DS: invalid length");

201:         require(users_.length == referrers_.length, "DS: invalid length");

291:             require(claimSender[rewardPoolIndex_][staker_][_msgSender()], "DS: invalid caller");

302:         require(claimSender[rewardPoolIndex_][referrer_][_msgSender()], "DS: invalid caller");

308:         require(isMigrationOver == true, "DS: migration isn't over");

321:         require(userData.deposited > 0, "DS: user isn't staked");

361:         require(isMigrationOver == true, "DS: migration isn't over");

435:         require(isMigrationOver == true, "DS: migration isn't over");

442:         require(deposited_ > 0, "DS: user isn't staked");

514:         require(isMigrationOver == true, "DS: migration isn't over");

524:         require(

577:         require(isMigrationOver == true, "DS: migration isn't over");

587:         require(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

290:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

309:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

314:         require(amount_ > 0, "DR: nothing to withdraw");

420:         require(depositPool.strategy != Strategy.NO_YIELD, "DR: invalid strategy for the deposit pool");

427:         require(undistributedRewards > 0, "DR: nothing to withdraw");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="NC-9"></a>[NC-9] Events that mark critical parameter changes should contain both the old and the new value

This should especially be done if the new value is not required to be different from the old value

*Instances (19)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

56:     function updateDataFeeds(string[] calldata paths_, address[][] calldata feeds_) external onlyOwner {
            require(paths_.length == feeds_.length, "CLDC: mismatched array lengths");
            for (uint256 i = 0; i < paths_.length; i++) {
                require(feeds_[i].length > 0, "CLDC: empty feed array");
                dataFeeds[getPathId(paths_[i])] = feeds_[i];
    
                emit DataFeedSet(paths_[i], feeds_[i]);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

101:     function setDistributor(address value_) public onlyOwner {
             require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "DR: invalid distributor address");
     
             if (distributor != address(0)) {
                 IERC20(depositToken).approve(distributor, 0);
             }
             IERC20(depositToken).approve(value_, type(uint256).max);
     
             distributor = value_;
     
             emit DistributorSet(value_);

114:     function setRewardPoolProtocolDetails(
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

231:     function setClaimSender(
             uint256 rewardPoolIndex_,
             address[] calldata senders_,
             bool[] calldata isAllowed_
         ) external {
             IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);
             require(senders_.length == isAllowed_.length, "DS: invalid array length");
     
             for (uint256 i = 0; i < senders_.length; ++i) {
                 claimSender[rewardPoolIndex_][_msgSender()][senders_[i]] = isAllowed_[i];
     
                 emit ClaimSenderSet(rewardPoolIndex_, _msgSender(), senders_[i], isAllowed_[i]);

246:     function setClaimReceiver(uint256 rewardPoolIndex_, address receiver_) external {
             IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);
     
             claimReceiver[rewardPoolIndex_][_msgSender()] = receiver_;
     
             emit ClaimReceiverSet(rewardPoolIndex_, _msgSender(), receiver_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

113:     function setChainLinkDataConsumer(address value_) public onlyOwner {
             require(
                 IERC165(value_).supportsInterface(type(IChainLinkDataConsumer).interfaceId),
                 "DR: invalid data consumer"
             );
     
             chainLinkDataConsumer = value_;
     
             emit ChainLinkDataConsumerSet(value_);

124:     function setL1Sender(address value_) public onlyOwner {
             require(IERC165(value_).supportsInterface(type(IL1SenderV2).interfaceId), "DR: invalid L1Sender address");
     
             l1Sender = value_;
     
             emit L1SenderSet(value_);

135:     function setAavePool(address value_) public onlyOwner {
             require(value_ != address(0), "DR: invalid Aave pool address");
     
             aavePool = value_;
     
             emit AavePoolSet(value_);

146:     function setAavePoolDataProvider(address value_) public onlyOwner {
             require(value_ != address(0), "DR: invalid Aave pool data provider address");
     
             aavePoolDataProvider = value_;
     
             emit AavePoolDataProviderSet(value_);

157:     function setAaveRewardsController(address value_) public onlyOwner {
             require(value_ != address(0), "DR: invalid Aave rewards controller address");
     
             aaveRewardsController = value_;
     
             emit AaveRewardsControllerSet(value_);

165:     function setRewardPool(address value_) public onlyOwner {
             require(IERC165(value_).supportsInterface(type(IRewardPool).interfaceId), "DR: invalid reward pool address");
     
             rewardPool = value_;
     
             emit RewardPoolSet(value_);

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {
             minRewardsDistributePeriod = value_;
     
             emit MinRewardsDistributePeriodSet(value_);

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {
             IRewardPool(rewardPool).onlyExistedRewardPool(rewardPoolIndex_);
             require(value_ <= block.timestamp, "DR: invalid last calculated timestamp");
     
             rewardPoolLastCalculatedTimestamp[rewardPoolIndex_] = value_;
     
             emit RewardPoolLastCalculatedTimestampSet(rewardPoolIndex_, value_);

258:     function updateDepositTokensPrices(uint256 rewardPoolIndex_) public {
             IRewardPool(rewardPool).onlyPublicRewardPool(rewardPoolIndex_);
     
             uint256 length_ = depositPoolAddresses[rewardPoolIndex_].length;
             IChainLinkDataConsumer chainLinkDataConsumer_ = IChainLinkDataConsumer(chainLinkDataConsumer);
     
             address[] storage addressesForIndex = depositPoolAddresses[rewardPoolIndex_];
             mapping(address => DepositPool) storage poolsForIndex = depositPools[rewardPoolIndex_];
     
             for (uint256 i = 0; i < length_; i++) {
                 address depositPoolAddress_ = addressesForIndex[i];
                 DepositPool storage depositPool = poolsForIndex[depositPoolAddress_];
     
                 bytes32 chainLinkPathId_ = chainLinkDataConsumer_.getPathId(depositPool.chainLinkPath);
                 uint256 price_ = chainLinkDataConsumer_.getChainLinkDataFeedLatestAnswer(chainLinkPathId_);
     
                 require(price_ > 0, "DR: price for pair is zero");
                 depositPool.tokenPrice = price_;
     
                 emit TokenPriceSet(depositPool.chainLinkPath, price_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

56:     function setStETh(address value_) external onlyOwner {
            require(value_ != address(0), "L1S: invalid stETH address");
    
            stETH = value_;
    
            emit stETHSet(value_);

64:     function setDistributor(address value_) external onlyOwner {
            require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "L1S: invalid distributor address");
    
            distributor = value_;
    
            emit DistributorSet(value_);

75:     function setUniswapSwapRouter(address value_) external onlyOwner {
            require(value_ != address(0), "L1S: invalid `uniswapSwapRouter` address");
    
            uniswapSwapRouter = value_;
    
            emit UniswapSwapRouterSet(value_);

95:     function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {
            layerZeroConfig = layerZeroConfig_;
    
            emit LayerZeroConfigSet(layerZeroConfig_);

132:     function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {
             require(stETH != address(0), "L1S: stETH is not set");
             require(newConfig_.receiver != address(0), "L1S: invalid receiver");
     
             ArbitrumBridgeConfig memory oldConfig_ = arbitrumBridgeConfig;
     
             if (oldConfig_.wstETH != address(0)) {
                 IERC20(stETH).approve(oldConfig_.wstETH, 0);
                 IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);
             }
     
             IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);
             IERC20(newConfig_.wstETH).approve(
                 IGatewayRouter(newConfig_.gateway).getGateway(newConfig_.wstETH),
                 type(uint256).max
             );
     
             arbitrumBridgeConfig = newConfig_;
     
             emit ArbitrumBridgeConfigSet(newConfig_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-10"></a>[NC-10] Function ordering does not follow the Solidity style guide

According to the [Solidity style guide](https://docs.soliditylang.org/en/v0.8.17/style-guide.html#order-of-functions), functions should be laid out in the following order :`constructor()`, `receive()`, `fallback()`, `external`, `public`, `internal`, `private`, but the cases below do not follow this pattern

*Instances (5)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

1: 
   Current order:
   external ChainLinkDataConsumer_init
   external supportsInterface
   external setAllowedPriceUpdateDelay
   external updateDataFeeds
   public getPathId
   public decimals
   external getChainLinkDataFeedLatestAnswer
   external version
   internal _authorizeUpgrade
   
   Suggested order:
   external ChainLinkDataConsumer_init
   external supportsInterface
   external setAllowedPriceUpdateDelay
   external updateDataFeeds
   external getChainLinkDataFeedLatestAnswer
   external version
   public getPathId
   public decimals
   internal _authorizeUpgrade

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

1: 
   Current order:
   external DepositPool_init
   external supportsInterface
   public setDistributor
   public setRewardPoolProtocolDetails
   external migrate
   external editReferrerTiers
   external manageUsersInPrivateRewardPool
   external setClaimSender
   external setClaimReceiver
   external stake
   external withdraw
   external claim
   external claimFor
   external claimReferrerTier
   external claimReferrerTierFor
   external lockClaim
   private _stake
   private _withdraw
   private _claim
   private _claimReferrerTier
   private _applyReferrerTier
   public getLatestUserReward
   public getLatestReferrerReward
   private _getCurrentUserReward
   private _getCurrentPoolRate
   public getCurrentUserMultiplier
   public getReferrerMultiplier
   internal _getUserTotalMultiplier
   external removeUpgradeability
   external version
   internal _authorizeUpgrade
   
   Suggested order:
   external DepositPool_init
   external supportsInterface
   external migrate
   external editReferrerTiers
   external manageUsersInPrivateRewardPool
   external setClaimSender
   external setClaimReceiver
   external stake
   external withdraw
   external claim
   external claimFor
   external claimReferrerTier
   external claimReferrerTierFor
   external lockClaim
   external removeUpgradeability
   external version
   public setDistributor
   public setRewardPoolProtocolDetails
   public getLatestUserReward
   public getLatestReferrerReward
   public getCurrentUserMultiplier
   public getReferrerMultiplier
   internal _getUserTotalMultiplier
   internal _authorizeUpgrade
   private _stake
   private _withdraw
   private _claim
   private _claimReferrerTier
   private _applyReferrerTier
   private _getCurrentUserReward
   private _getCurrentPoolRate

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

1: 
   Current order:
   external Distributor_init
   external supportsInterface
   public setChainLinkDataConsumer
   public setL1Sender
   public setAavePool
   public setAavePoolDataProvider
   public setAaveRewardsController
   public setRewardPool
   public setMinRewardsDistributePeriod
   public setRewardPoolLastCalculatedTimestamp
   external addDepositPool
   private _onlyExistedDepositPool
   public updateDepositTokensPrices
   external supply
   external withdraw
   public distributeRewards
   external withdrawYield
   external withdrawUndistributedRewards
   external claimAaveRewards
   external sendMintMessage
   private _withdrawYield
   external getDistributedRewards
   external version
   internal _authorizeUpgrade
   
   Suggested order:
   external Distributor_init
   external supportsInterface
   external addDepositPool
   external supply
   external withdraw
   external withdrawYield
   external withdrawUndistributedRewards
   external claimAaveRewards
   external sendMintMessage
   external getDistributedRewards
   external version
   public setChainLinkDataConsumer
   public setL1Sender
   public setAavePool
   public setAavePoolDataProvider
   public setAaveRewardsController
   public setRewardPool
   public setMinRewardsDistributePeriod
   public setRewardPoolLastCalculatedTimestamp
   public updateDepositTokensPrices
   public distributeRewards
   internal _authorizeUpgrade
   private _onlyExistedDepositPool
   private _withdrawYield

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

1: 
   Current order:
   external L2TokenReceiver__init
   external supportsInterface
   external editParams
   external withdrawToken
   external withdrawTokenId
   external swap
   external increaseLiquidityCurrentRange
   external collectFees
   external version
   external onERC721Received
   private _addAllowanceUpdateSwapParams
   internal _getSwapParams
   internal _authorizeUpgrade
   
   Suggested order:
   external L2TokenReceiver__init
   external supportsInterface
   external editParams
   external withdrawToken
   external withdrawTokenId
   external swap
   external increaseLiquidityCurrentRange
   external collectFees
   external version
   external onERC721Received
   internal _getSwapParams
   internal _authorizeUpgrade
   private _addAllowanceUpdateSwapParams

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

1: 
   Current order:
   external RewardPool_init
   external supportsInterface
   public addRewardPool
   public isRewardPoolExist
   public isRewardPoolPublic
   external onlyExistedRewardPool
   external onlyPublicRewardPool
   external onlyNotPublicRewardPool
   external getPeriodRewards
   external version
   internal _authorizeUpgrade
   
   Suggested order:
   external RewardPool_init
   external supportsInterface
   external onlyExistedRewardPool
   external onlyPublicRewardPool
   external onlyNotPublicRewardPool
   external getPeriodRewards
   external version
   public addRewardPool
   public isRewardPoolExist
   public isRewardPoolPublic
   internal _authorizeUpgrade

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="NC-11"></a>[NC-11] Functions should not be longer than 50 lines

Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability

*Instances (83)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

32:     function ChainLinkDataConsumer_init() external initializer {

37:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {

56:     function updateDataFeeds(string[] calldata paths_, address[][] calldata feeds_) external onlyOwner {

66:     function getPathId(string memory path_) public pure returns (bytes32) {

78:     function getChainLinkDataFeedLatestAnswer(bytes32 pathId_) external view returns (uint256) {

113:     function version() external pure returns (uint256) {

117:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

85:     function DepositPool_init(address depositToken_, address distributor_) external initializer {

93:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

101:     function setDistributor(address value_) public onlyOwner {

137:     function migrate(uint256 rewardPoolIndex_) external onlyOwner {

162:     function editReferrerTiers(uint256 rewardPoolIndex_, ReferrerTier[] calldata referrerTiers_) external onlyOwner {

246:     function setClaimReceiver(uint256 rewardPoolIndex_, address receiver_) external {

254:     function stake(uint256 rewardPoolIndex_, uint256 amount_, uint128 claimLockEnd_, address referrer_) external {

268:     function withdraw(uint256 rewardPoolIndex_, uint256 amount_) external {

283:     function claim(uint256 rewardPoolIndex_, address receiver_) external payable {

287:     function claimFor(uint256 rewardPoolIndex_, address staker_, address receiver_) external payable {

297:     function claimReferrerTier(uint256 rewardPoolIndex_, address receiver_) external payable {

301:     function claimReferrerTierFor(uint256 rewardPoolIndex_, address referrer_, address receiver_) external payable {

307:     function lockClaim(uint256 rewardPoolIndex_, uint128 claimLockEnd_) external {

434:     function _withdraw(address user_, uint256 rewardPoolIndex_, uint256 amount_, uint256 currentPoolRate_) private {

513:     function _claim(uint256 rewardPoolIndex_, address user_, address receiver_) private {

576:     function _claimReferrerTier(uint256 rewardPoolIndex_, address referrer_, address receiver_) private {

675:     function getLatestUserReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

686:     function getLatestReferrerReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

696:     function _getCurrentUserReward(uint256 currentPoolRate_, UserData memory userData_) private pure returns (uint256) {

704:     function _getCurrentPoolRate(uint256 rewardPoolIndex_) private view returns (uint256, uint256) {

723:     function getCurrentUserMultiplier(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

733:     function getReferrerMultiplier(uint256 rewardPoolIndex_, address referrer_) public view returns (uint256) {

761:     function removeUpgradeability() external onlyOwner {

765:     function version() external pure returns (uint256) {

769:     function _authorizeUpgrade(address) internal view override onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

105:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

113:     function setChainLinkDataConsumer(address value_) public onlyOwner {

124:     function setL1Sender(address value_) public onlyOwner {

135:     function setAavePool(address value_) public onlyOwner {

146:     function setAavePoolDataProvider(address value_) public onlyOwner {

157:     function setAaveRewardsController(address value_) public onlyOwner {

165:     function setRewardPool(address value_) public onlyOwner {

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {

250:     function _onlyExistedDepositPool(uint256 rewardPoolIndex_, address depositPoolAddress_) private view {

258:     function updateDepositTokensPrices(uint256 rewardPoolIndex_) public {

285:     function supply(uint256 rewardPoolIndex_, uint256 amount_) external {

304:     function withdraw(uint256 rewardPoolIndex_, uint256 amount_) external returns (uint256) {

330:     function distributeRewards(uint256 rewardPoolIndex_) public {

416:     function withdrawYield(uint256 rewardPoolIndex_, address depositPoolAddress_) external {

426:     function withdrawUndistributedRewards(address user_, address refundTo_) external payable onlyOwner {

479:     function _withdrawYield(uint256 rewardPoolIndex_, address depositPoolAddress_) private {

509:     function version() external pure returns (uint256) {

513:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

43:     function L1SenderV2__init() external initializer {

48:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

56:     function setStETh(address value_) external onlyOwner {

64:     function setDistributor(address value_) external onlyOwner {

75:     function setUniswapSwapRouter(address value_) external onlyOwner {

95:     function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {

101:     function sendMintMessage(address user_, uint256 amount_, address refundTo_) external payable {

132:     function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {

238:     function version() external pure returns (uint256) {

242:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

43:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

50:     function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {

65:     function withdrawToken(address recipient_, address token_, uint256 amount_) external onlyOwner {

69:     function withdrawTokenId(address recipient_, address token_, uint256 tokenId_) external onlyOwner {

123:     function collectFees(uint256 tokenId_) external returns (uint256 amount0_, uint256 amount1_) {

136:     function version() external pure returns (uint256) {

140:     function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {

144:     function _addAllowanceUpdateSwapParams(SwapParams memory newParams_, bool isEditFirstParams_) private {

160:     function _getSwapParams(bool isUseFirstSwapParams_) internal view returns (SwapParams memory) {

164:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

22:     function RewardPool_init(RewardPool[] calldata poolsInfo_) external initializer {

31:     function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {

39:     function addRewardPool(RewardPool calldata rewardPool_) public onlyOwner {

51:     function isRewardPoolExist(uint256 index_) public view returns (bool) {

55:     function isRewardPoolPublic(uint256 index_) public view returns (bool) {

59:     function onlyExistedRewardPool(uint256 index_) external view {

63:     function onlyPublicRewardPool(uint256 index_) external view {

67:     function onlyNotPublicRewardPool(uint256 index_) external view {

71:     function getPeriodRewards(uint256 index_, uint128 startTime_, uint128 endTime_) external view returns (uint256) {

93:     function version() external pure returns (uint256) {

97:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="NC-12"></a>[NC-12] Lack of checks in setters

Be it sanity checks (like checks against `0`-values) or initial setting checks: it's best for Setter functions to have them

*Instances (5)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {
            allowedPriceUpdateDelay = allowedPriceUpdateDelay_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

114:     function setRewardPoolProtocolDetails(
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

246:     function setClaimReceiver(uint256 rewardPoolIndex_, address receiver_) external {
             IRewardPool(IDistributor(distributor).rewardPool()).onlyExistedRewardPool(rewardPoolIndex_);
     
             claimReceiver[rewardPoolIndex_][_msgSender()] = receiver_;
     
             emit ClaimReceiverSet(rewardPoolIndex_, _msgSender(), receiver_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {
             minRewardsDistributePeriod = value_;
     
             emit MinRewardsDistributePeriodSet(value_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

95:     function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {
            layerZeroConfig = layerZeroConfig_;
    
            emit LayerZeroConfigSet(layerZeroConfig_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-13"></a>[NC-13] Missing Event for critical parameters change

Events help non-contract tools to track changes, and events prevent users from being surprised by changes.

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {
            allowedPriceUpdateDelay = allowedPriceUpdateDelay_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

### <a name="NC-14"></a>[NC-14] NatSpec is completely non-existent on functions that should have them

Public and external functions that aren't view or pure should have NatSpec comments

*Instances (45)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

32:     function ChainLinkDataConsumer_init() external initializer {

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

85:     function DepositPool_init(address depositToken_, address distributor_) external initializer {

101:     function setDistributor(address value_) public onlyOwner {

114:     function setRewardPoolProtocolDetails(

137:     function migrate(uint256 rewardPoolIndex_) external onlyOwner {

162:     function editReferrerTiers(uint256 rewardPoolIndex_, ReferrerTier[] calldata referrerTiers_) external onlyOwner {

188:     function manageUsersInPrivateRewardPool(

231:     function setClaimSender(

246:     function setClaimReceiver(uint256 rewardPoolIndex_, address receiver_) external {

254:     function stake(uint256 rewardPoolIndex_, uint256 amount_, uint128 claimLockEnd_, address referrer_) external {

268:     function withdraw(uint256 rewardPoolIndex_, uint256 amount_) external {

283:     function claim(uint256 rewardPoolIndex_, address receiver_) external payable {

287:     function claimFor(uint256 rewardPoolIndex_, address staker_, address receiver_) external payable {

297:     function claimReferrerTier(uint256 rewardPoolIndex_, address receiver_) external payable {

301:     function claimReferrerTierFor(uint256 rewardPoolIndex_, address referrer_, address receiver_) external payable {

307:     function lockClaim(uint256 rewardPoolIndex_, uint128 claimLockEnd_) external {

761:     function removeUpgradeability() external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

88:     function Distributor_init(

113:     function setChainLinkDataConsumer(address value_) public onlyOwner {

124:     function setL1Sender(address value_) public onlyOwner {

165:     function setRewardPool(address value_) public onlyOwner {

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {

192:     function addDepositPool(

258:     function updateDepositTokensPrices(uint256 rewardPoolIndex_) public {

285:     function supply(uint256 rewardPoolIndex_, uint256 amount_) external {

304:     function withdraw(uint256 rewardPoolIndex_, uint256 amount_) external returns (uint256) {

330:     function distributeRewards(uint256 rewardPoolIndex_) public {

416:     function withdrawYield(uint256 rewardPoolIndex_, address depositPoolAddress_) external {

426:     function withdrawUndistributedRewards(address user_, address refundTo_) external payable onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

43:     function L1SenderV2__init() external initializer {

56:     function setStETh(address value_) external onlyOwner {

64:     function setDistributor(address value_) external onlyOwner {

101:     function sendMintMessage(address user_, uint256 amount_, address refundTo_) external payable {

154:     function sendWstETH(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

27:     function L2TokenReceiver__init(

50:     function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {

65:     function withdrawToken(address recipient_, address token_, uint256 amount_) external onlyOwner {

69:     function withdrawTokenId(address recipient_, address token_, uint256 tokenId_) external onlyOwner {

73:     function swap(

99:     function increaseLiquidityCurrentRange(

123:     function collectFees(uint256 tokenId_) external returns (uint256 amount0_, uint256 amount1_) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

22:     function RewardPool_init(RewardPool[] calldata poolsInfo_) external initializer {

39:     function addRewardPool(RewardPool calldata rewardPool_) public onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="NC-15"></a>[NC-15] Incomplete NatSpec: `@param` is missing on actually documented functions

The following functions are missing `@param` NatSpec comments.

*Instances (9)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

53:     /**
         * @dev https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
         */
        function updateDataFeeds(string[] calldata paths_, address[][] calldata feeds_) external onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

132:     /**
          * @dev https://aave.com/docs/resources/addresses. See `Pool`.
          */
         function setAavePool(address value_) public onlyOwner {

143:     /**
          * @dev https://aave.com/docs/resources/addresses. See `AaveProtocolDataProvider`.
          */
         function setAavePoolDataProvider(address value_) public onlyOwner {

154:     /**
          * @dev https://aave.com/docs/resources/addresses. See `RewardsController`.
          */
         function setAaveRewardsController(address value_) public onlyOwner {

458:     /**
          * @dev Used as a universal proxy for all `DepositPool` so that the `msg.sender` of the message to the
          * reward mint is one.
          */
         function sendMintMessage(
             uint256 rewardPoolIndex_,
             address user_,
             uint256 amount_,
             address refundTo_

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

72:     /**
         * https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
         */
        function setUniswapSwapRouter(address value_) external onlyOwner {

87:     /**
         * @dev https://docs.layerzero.network/v1/deployments/deployed-contracts
         * Gateway - see `EndpointV1` at the link
         * Receiver - `L2MessageReceiver` address
         * Receiver Chain Id - see `EndpointId` at the link
         * Zro Payment Address - the address of the ZRO token holder who would pay for the transaction
         * Adapter Params - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
         */
        function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {

126:     /**
          * @dev https://docs.arbitrum.io/build-decentralized-apps/reference/contract-addresses
          * wstETH - the wstETH token address
          * Gateway - see `L1 Gateway Router` at the link
          * Receiver - `L2MessageReceiver` address
          */
         function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {

189:     /**
          * @dev https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps
          *
          * Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence
          * of token addresses and poolFees that define the pools used in the swaps.
          * The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where
          * tokenIn/tokenOut parameter is the shared token across the pools.
          * Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
          */
         function swapExactInputMultihop(
             address[] calldata tokens_,
             uint24[] calldata poolsFee_,
             uint256 amountIn_,
             uint256 amountOutMinimum_,
             uint256 deadline_

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-16"></a>[NC-16] Incomplete NatSpec: `@return` is missing on actually documented functions

The following functions are missing `@return` NatSpec comments.

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

189:     /**
          * @dev https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps
          *
          * Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence
          * of token addresses and poolFees that define the pools used in the swaps.
          * The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where
          * tokenIn/tokenOut parameter is the shared token across the pools.
          * Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
          */
         function swapExactInputMultihop(
             address[] calldata tokens_,
             uint24[] calldata poolsFee_,
             uint256 amountIn_,
             uint256 amountOutMinimum_,
             uint256 deadline_
         ) external onlyOwner returns (uint256) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-17"></a>[NC-17] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor

If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

102:         require(_msgSender() == distributor, "L1S: the `msg.sender` isn't `distributor`");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="NC-18"></a>[NC-18] Consider using named mappings

Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/questions/51629/how-to-name-the-arguments-in-mapping/145555#145555) to make it easier to understand the purpose of each mapping

*Instances (16)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

19:     mapping(bytes32 => address[]) public dataFeeds;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

42:     mapping(uint256 => RewardPoolData) public rewardPoolsData;

45:     mapping(address => mapping(uint256 => UserData)) public usersData;

54:     mapping(uint256 => RewardPoolLimits) public unusedStorage2;

57:     mapping(uint256 => ReferrerTier[]) public referrerTiers;

58:     mapping(address => mapping(uint256 => ReferrerData)) public referrersData;

62:     mapping(uint256 => mapping(address => mapping(address => bool))) public claimSender;

63:     mapping(uint256 => mapping(address => address)) public claimReceiver;

74:     mapping(uint256 => RewardPoolProtocolDetails) public rewardPoolsProtocolDetails;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

28:     mapping(uint256 => mapping(address => DepositPool)) public depositPools;

30:     mapping(address => bool) public isDepositTokenAdded;

33:     mapping(uint256 => mapping(address => uint256)) public distributedRewards;

36:     mapping(uint256 => address[]) public depositPoolAddresses;

38:     mapping(uint256 => uint128) public rewardPoolLastCalculatedTimestamp;

39:     mapping(uint256 => bool) public isPrivateDepositPoolAdded;

265:         mapping(address => DepositPool) storage poolsForIndex = depositPools[rewardPoolIndex_];

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="NC-19"></a>[NC-19] `public` functions not called by the contract should be declared `external` instead

*Instances (9)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

70:     function decimals() public pure returns (uint8) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

114:     function setRewardPoolProtocolDetails(

675:     function getLatestUserReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

686:     function getLatestReferrerReward(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

723:     function getCurrentUserMultiplier(uint256 rewardPoolIndex_, address user_) public view returns (uint256) {

733:     function getReferrerMultiplier(uint256 rewardPoolIndex_, address referrer_) public view returns (uint256) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

157:     function setAaveRewardsController(address value_) public onlyOwner {

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="NC-20"></a>[NC-20] Variables need not be initialized to zero

The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (13)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

58:         for (uint256 i = 0; i < paths_.length; i++) {

81:         uint256 res_ = 0;

82:         uint8 baseDecimals_ = 0;

83:         for (uint256 i = 0; i < dataFeeds_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

170:         for (uint256 i = 0; i < referrerTiers_.length; i++) {

239:         for (uint256 i = 0; i < senders_.length; ++i) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

228:         address aToken_ = address(0);

267:         for (uint256 i = 0; i < length_; i++) {

369:         uint256 totalYield_ = 0;

372:         for (uint256 i = 0; i < length_; i++) {

402:         for (uint256 i = 0; i < length_; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

213:         for (uint256 i = 0; i < poolsFee_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

26:         for (uint256 i = 0; i < poolsInfo_.length; i++) {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

## Low Issues

| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | `approve()`/`safeApprove()` may revert if the current approval is not zero | 15 |
| [L-2](#L-2) | Use a 2-step ownership transfer pattern | 6 |
| [L-3](#L-3) | Some tokens may revert when zero value transfers are made | 6 |
| [L-4](#L-4) | USDC stablecoin centralization risk | 8 |
| [L-5](#L-5) | Missing checks for `address(0)` when assigning values to address state variables | 8 |
| [L-6](#L-6) | `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()` | 3 |
| [L-7](#L-7) | `decimals()` is not a part of the ERC-20 standard | 3 |
| [L-8](#L-8) | Deprecated approve() function | 7 |
| [L-9](#L-9) | Do not use deprecated library functions | 8 |
| [L-10](#L-10) | `safeApprove()` is deprecated | 8 |
| [L-11](#L-11) | Division by zero not prevented | 3 |
| [L-12](#L-12) | Empty Function Body - Consider commenting why | 5 |
| [L-13](#L-13) | External calls in an un-bounded `for-`loop may result in a DOS | 1 |
| [L-14](#L-14) | Initializers could be front-run | 20 |
| [L-15](#L-15) | Signature use at deadlines should be allowed | 3 |
| [L-16](#L-16) | Possible rounding issue | 1 |
| [L-17](#L-17) | Loss of precision | 6 |
| [L-18](#L-18) | Solidity version 0.8.20+ may not work on other chains due to `PUSH0` | 6 |
| [L-19](#L-19) | Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership` | 6 |
| [L-20](#L-20) | Unsafe ERC20 operation(s) | 8 |
| [L-21](#L-21) | Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions | 27 |
| [L-22](#L-22) | Upgradeable contract not initialized | 47 |

### <a name="L-1"></a>[L-1] `approve()`/`safeApprove()` may revert if the current approval is not zero

- Some tokens (like the *very popular* USDT) do not work when changing the allowance from an existing non-zero allowance value (it will revert if the current approval is not zero to protect against front-running changes of approvals). These tokens must first be approved for zero and then the actual allowance can be approved.
- Furthermore, OZ's implementation of safeApprove would throw an error if an approve is attempted from a non-zero value (`"SafeERC20: approve from non-zero to non-zero allowance"`)

Set the allowance to zero immediately before each of the existing allowance calls

*Instances (15)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

105:             IERC20(depositToken).approve(distributor, 0);

107:         IERC20(depositToken).approve(value_, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

232:             IERC20(token_).safeApprove(aavePool, type(uint256).max);

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

139:             IERC20(stETH).approve(oldConfig_.wstETH, 0);

140:             IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

144:         IERC20(newConfig_.wstETH).approve(

209:         TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

54:             TransferHelper.safeApprove(params_.tokenIn, router, 0);

55:             TransferHelper.safeApprove(params_.tokenIn, nonfungiblePositionManager, 0);

59:             TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);

148:         TransferHelper.safeApprove(newParams_.tokenIn, router, type(uint256).max);

149:         TransferHelper.safeApprove(newParams_.tokenIn, nonfungiblePositionManager, type(uint256).max);

151:         TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="L-2"></a>[L-2] Use a 2-step ownership transfer pattern

Recommend considering implementing a two step process where the owner or admin nominates an account and the nominated account needs to call an `acceptOwnership()` function for the transfer of ownership to fully succeed. This ensures the nominated EOA account is a valid and active account. Lack of two-step procedure for critical operations leaves them error-prone. Consider adding two step procedure on the critical functions.

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

16: contract ChainLinkDataConsumer is IChainLinkDataConsumer, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

17: contract DepositPool is IDepositPool, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

22: contract Distributor is IDistributor, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

19: contract L1SenderV2 is IL1SenderV2, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

14: contract L2TokenReceiverV2 is IL2TokenReceiverV2, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

11: contract RewardPool is IRewardPool, OwnableUpgradeable, UUPSUpgradeable {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-3"></a>[L-3] Some tokens may revert when zero value transfers are made

Example: <https://github.com/d-xo/weird-erc20#revert-on-zero-value-transfers>.

In spite of the fact that EIP-20 [states](https://github.com/ethereum/EIPs/blob/46b9b698815abbfa628cd1097311deee77dd45c5/EIPS/eip-20.md?plain=1#L116) that zero-valued transfers must be accepted, some tokens, such as LEND will revert if this is attempted, which may cause transactions that involve other tokens (such as batch operations) to fully revert. Consider skipping the transfer if the amount is zero, which will also save gas.

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

153:         IERC20(depositToken).transfer(distributor, remainder_);

381:             IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

507:             IERC20(depositToken).safeTransfer(user_, amount_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

295:         IERC20(depositPool.token).safeTransferFrom(depositPoolAddress_, address(this), amount_);

324:             IERC20(depositPool.token).safeTransfer(depositPoolAddress_, amount_);

488:             IERC20(depositPool.token).safeTransfer(l1Sender, yield_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="L-4"></a>[L-4] USDC stablecoin centralization risk

USDC is a centralized stablecoin that can be controlled by operators outside of the protocol. For example, the USDC operator can call the blacklist function with the protocol's Proxy contract address or a user's address.

**Recommendation**
If possible, use a decentralized stablecoin as the lending token.

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

232:             IERC20(token_).safeApprove(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

209:         TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

54:             TransferHelper.safeApprove(params_.tokenIn, router, 0);

55:             TransferHelper.safeApprove(params_.tokenIn, nonfungiblePositionManager, 0);

59:             TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);

148:         TransferHelper.safeApprove(newParams_.tokenIn, router, type(uint256).max);

149:         TransferHelper.safeApprove(newParams_.tokenIn, nonfungiblePositionManager, type(uint256).max);

151:         TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="L-5"></a>[L-5] Missing checks for `address(0)` when assigning values to address state variables

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

89:         depositToken = depositToken_;

109:         distributor = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

119:         chainLinkDataConsumer = value_;

127:         l1Sender = value_;

168:         rewardPool = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

67:         distributor = value_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

36:         router = router_;

37:         nonfungiblePositionManager = nonfungiblePositionManager_;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="L-6"></a>[L-6] `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`

Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions](https://docs.soliditylang.org/en/v0.8.13/abi-spec.html#non-standard-packed-mode) (e.g. `abi.encodePacked(0x123,0x456)` => `0x123456` => `abi.encodePacked(0x1,0x23456)`, but `abi.encode(0x123,0x456)` => `0x0...1230...456`). "Unless there is a compelling reason, `abi.encode` should be preferred". If there is only one argument to `abi.encodePacked()` it can often be cast to `bytes()` or `bytes32()` [instead](https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity#answer-82739).
If all arguments are strings and or bytes, `bytes.concat()` should be used instead

*Instances (3)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

67:         return keccak256(abi.encodePacked(path_));

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

214:             path_ = abi.encodePacked(path_, tokens_[i], poolsFee_[i]);

216:         path_ = abi.encodePacked(path_, tokens_[tokens_.length - 1]);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="L-7"></a>[L-7] `decimals()` is not a part of the ERC-20 standard

The `decimals()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (3)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

97:                     baseDecimals_ = aggregator_.decimals();

99:                     res_ = (res_ * uint256(answer_)) / (10 ** aggregator_.decimals());

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

385:             uint256 decimals_ = IERC20Metadata(yieldToken_).decimals();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="L-8"></a>[L-8] Deprecated approve() function

Due to the inheritance of ERC20's approve function, there's a vulnerability to the ERC20 approve and double spend front running attack. Briefly, an authorized spender could spend both allowances by front running an allowance-changing transaction. Consider implementing OpenZeppelin's `.safeApprove()` function to help mitigate this.

*Instances (7)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

105:             IERC20(depositToken).approve(distributor, 0);

107:         IERC20(depositToken).approve(value_, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

139:             IERC20(stETH).approve(oldConfig_.wstETH, 0);

140:             IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

144:         IERC20(newConfig_.wstETH).approve(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="L-9"></a>[L-9] Do not use deprecated library functions

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

232:             IERC20(token_).safeApprove(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

209:         TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

54:             TransferHelper.safeApprove(params_.tokenIn, router, 0);

55:             TransferHelper.safeApprove(params_.tokenIn, nonfungiblePositionManager, 0);

59:             TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);

148:         TransferHelper.safeApprove(newParams_.tokenIn, router, type(uint256).max);

149:         TransferHelper.safeApprove(newParams_.tokenIn, nonfungiblePositionManager, type(uint256).max);

151:         TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="L-10"></a>[L-10] `safeApprove()` is deprecated

[Deprecated](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/bfff03c0d2a59bcd8e2ead1da9aed9edf0080d05/contracts/token/ERC20/utils/SafeERC20.sol#L38-L45) in favor of `safeIncreaseAllowance()` and `safeDecreaseAllowance()`. If only setting the initial allowance to the value that means infinite, `safeIncreaseAllowance()` can be used instead. The function may currently work, but if a bug is found in this version of OpenZeppelin, and the version that you're forced to upgrade to no longer has this function, you'll encounter unnecessary delays in porting and testing replacement contracts.

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/Distributor.sol

232:             IERC20(token_).safeApprove(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

209:         TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

54:             TransferHelper.safeApprove(params_.tokenIn, router, 0);

55:             TransferHelper.safeApprove(params_.tokenIn, nonfungiblePositionManager, 0);

59:             TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);

148:         TransferHelper.safeApprove(newParams_.tokenIn, router, type(uint256).max);

149:         TransferHelper.safeApprove(newParams_.tokenIn, nonfungiblePositionManager, type(uint256).max);

151:         TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

### <a name="L-11"></a>[L-11] Division by zero not prevented

The divisions below take an input parameter which does not have any zero-value checks, which may lead to the functions reverting when zero is passed.

*Instances (3)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

99:                     res_ = (res_ * uint256(answer_)) / (10 ** aggregator_.decimals());

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

714:         uint256 rate_ = rewardPoolData.rate + (rewards_ * PRECISION) / rewardPoolData.totalVirtualDeposited;

743:         return (referrerData.virtualAmountStaked * PRECISION) / referrerData.amountStaked;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="L-12"></a>[L-12] Empty Function Body - Consider commenting why

*Instances (5)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

117:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

513:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

242:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

164:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

97:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-13"></a>[L-13] External calls in an un-bounded `for-`loop may result in a DOS

Consider limiting the number of iterations in for-loops that make external calls

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

179:             referrerTiers[rewardPoolIndex_].push(referrerTiers_[i]);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="L-14"></a>[L-14] Initializers could be front-run

Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

*Instances (20)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

32:     function ChainLinkDataConsumer_init() external initializer {

33:         __Ownable_init();

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

85:     function DepositPool_init(address depositToken_, address distributor_) external initializer {

86:         __Ownable_init();

87:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

88:     function Distributor_init(

94:     ) external initializer {

95:         __Ownable_init();

96:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

43:     function L1SenderV2__init() external initializer {

44:         __Ownable_init();

45:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

27:     function L2TokenReceiver__init(

32:     ) external initializer {

33:         __Ownable_init();

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

22:     function RewardPool_init(RewardPool[] calldata poolsInfo_) external initializer {

23:         __Ownable_init();

24:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-15"></a>[L-15] Signature use at deadlines should be allowed

According to [EIP-2612](https://github.com/ethereum/EIPs/blob/71dc97318013bf2ac572ab63fab530ac9ef419ca/EIPS/eip-2612.md?plain=1#L58), signatures used on exactly the deadline timestamp are supposed to be allowed. While the signature may or may not be used for the exact EIP-2612 use case (transfer approvals), for consistency's sake, all deadlines should follow this semantic. If the timestamp is an expiration rather than a deadline, consider whether it makes more sense to include the expiration timestamp as a valid timestamp, as is done for deadlines.

*Instances (3)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

311:         require(claimLockEnd_ > block.timestamp, "DS: invalid lock end value (1)");

368:             claimLockEnd_ = userData.claimLockEnd > block.timestamp ? userData.claimLockEnd : uint128(block.timestamp);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

181:         require(value_ <= block.timestamp, "DR: invalid last calculated timestamp");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="L-16"></a>[L-16] Possible rounding issue

Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator. Also, there is indication of multiplication and division without the use of parenthesis which could result in issues.

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

714:         uint256 rate_ = rewardPoolData.rate + (rewards_ * PRECISION) / rewardPoolData.totalVirtualDeposited;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="L-17"></a>[L-17] Loss of precision

Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

328:         uint256 virtualDeposited_ = (userData.deposited * multiplier_) / PRECISION;

397:         uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;

473:         uint256 virtualDeposited_ = (newDeposited_ * multiplier_) / PRECISION;

540:         uint256 virtualDeposited_ = (deposited_ * multiplier_) / PRECISION;

699:         uint256 newRewards_ = ((currentPoolRate_ - userData_.rate) * deposited_) / PRECISION;

714:         uint256 rate_ = rewardPoolData.rate + (rewards_ * PRECISION) / rewardPoolData.totalVirtualDeposited;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="L-18"></a>[L-18] Solidity version 0.8.20+ may not work on other chains due to `PUSH0`

The compiler for Solidity 0.8.20 switches the default target EVM version to [Shanghai](https://blog.soliditylang.org/2023/05/10/solidity-0.8.20-release-announcement/#important-note), which includes the new `PUSH0` op code. This op code may not yet be implemented on all L2s, so deployment on these chains will fail. To work around this issue, use an earlier [EVM](https://docs.soliditylang.org/en/v0.8.20/using-the-compiler.html?ref=zaryabs.com#setting-the-evm-version-to-target) [version](https://book.getfoundry.sh/reference/config/solidity-compiler#evm_version). While the project itself may or may not compile with 0.8.20, other projects with which it integrates, or which extend this project may, and those projects will have problems deploying these contracts/libraries.

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

2: pragma solidity ^0.8.20;

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-19"></a>[L-19] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`

Use [Ownable2Step.transferOwnership](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol) which is safer. Use it as it is more secure due to 2-stage ownership transfer.

**Recommended Mitigation Steps**

Use <a href="https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol">Ownable2Step.sol</a>
  
  ```solidity
      function acceptOwnership() external {
          address sender = _msgSender();
          require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
          _transferOwnership(sender);
      }
```

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

7: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-20"></a>[L-20] Unsafe ERC20 operation(s)

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

105:             IERC20(depositToken).approve(distributor, 0);

107:         IERC20(depositToken).approve(value_, type(uint256).max);

153:         IERC20(depositToken).transfer(distributor, remainder_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

139:             IERC20(stETH).approve(oldConfig_.wstETH, 0);

140:             IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

144:         IERC20(newConfig_.wstETH).approve(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="L-21"></a>[L-21] Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions

See [this](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps) link for a description of this storage variable. While some contracts may not currently be sub-classed, adding the variable now protects against forgetting to add it in the future.

*Instances (27)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

16: contract ChainLinkDataConsumer is IChainLinkDataConsumer, OwnableUpgradeable, UUPSUpgradeable {

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

17: contract DepositPool is IDepositPool, OwnableUpgradeable, UUPSUpgradeable {

24:     bool public isNotUpgradeable;

87:         __UUPSUpgradeable_init();

762:         isNotUpgradeable = true;

770:         require(!isNotUpgradeable, "DS: upgrade isn't available");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

6: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

7: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

22: contract Distributor is IDistributor, OwnableUpgradeable, UUPSUpgradeable {

96:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

19: contract L1SenderV2 is IL1SenderV2, OwnableUpgradeable, UUPSUpgradeable {

45:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

14: contract L2TokenReceiverV2 is IL2TokenReceiverV2, OwnableUpgradeable, UUPSUpgradeable {

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

11: contract RewardPool is IRewardPool, OwnableUpgradeable, UUPSUpgradeable {

24:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="L-22"></a>[L-22] Upgradeable contract not initialized

Upgradeable contracts are initialized via an initializer function rather than by a constructor. Leaving such a contract uninitialized may lead to it being taken over by a malicious user

*Instances (47)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

16: contract ChainLinkDataConsumer is IChainLinkDataConsumer, OwnableUpgradeable, UUPSUpgradeable {

29:         _disableInitializers();

32:     function ChainLinkDataConsumer_init() external initializer {

33:         __Ownable_init();

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

17: contract DepositPool is IDepositPool, OwnableUpgradeable, UUPSUpgradeable {

24:     bool public isNotUpgradeable;

82:         _disableInitializers();

85:     function DepositPool_init(address depositToken_, address distributor_) external initializer {

86:         __Ownable_init();

87:         __UUPSUpgradeable_init();

762:         isNotUpgradeable = true;

770:         require(!isNotUpgradeable, "DS: upgrade isn't available");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

6: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

7: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

22: contract Distributor is IDistributor, OwnableUpgradeable, UUPSUpgradeable {

85:         _disableInitializers();

88:     function Distributor_init(

94:     ) external initializer {

95:         __Ownable_init();

96:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

19: contract L1SenderV2 is IL1SenderV2, OwnableUpgradeable, UUPSUpgradeable {

40:         _disableInitializers();

43:     function L1SenderV2__init() external initializer {

44:         __Ownable_init();

45:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

5: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

6: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

14: contract L2TokenReceiverV2 is IL2TokenReceiverV2, OwnableUpgradeable, UUPSUpgradeable {

24:         _disableInitializers();

27:     function L2TokenReceiver__init(

32:     ) external initializer {

33:         __Ownable_init();

34:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

4: import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

5: import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

11: contract RewardPool is IRewardPool, OwnableUpgradeable, UUPSUpgradeable {

19:         _disableInitializers();

22:     function RewardPool_init(RewardPool[] calldata poolsInfo_) external initializer {

23:         __Ownable_init();

24:         __UUPSUpgradeable_init();

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

## Medium Issues

| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Contracts are vulnerable to fee-on-transfer accounting-related issues | 2 |
| [M-2](#M-2) | Centralization Risk for trusted owners | 38 |
| [M-3](#M-3) | Direct `supportsInterface()` calls may cause caller to revert | 6 |
| [M-4](#M-4) | Return values of `transfer()`/`transferFrom()` not checked | 1 |
| [M-5](#M-5) | Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20` | 8 |

### <a name="M-1"></a>[M-1] Contracts are vulnerable to fee-on-transfer accounting-related issues

Consistently check account balance before and after transfers for Fee-On-Transfer discrepancies. As arbitrary ERC20 tokens can be used, the amount here should be calculated every time to take into consideration a possible fee-on-transfer or deflation.
Also, it's a good practice for the future of the solution.

Use the balance before and after the transfer to calculate the received amount instead of assuming that it would be equal to the amount passed as a parameter. Or explicitly document that such tokens shouldn't be used and won't be supported

*Instances (2)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

381:             IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), amount_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

295:         IERC20(depositPool.token).safeTransferFrom(depositPoolAddress_, address(this), amount_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

### <a name="M-2"></a>[M-2] Centralization Risk for trusted owners

#### Impact

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (38)*:

```solidity
File: ./contracts/capital-protocol/ChainLinkDataConsumer.sol

45:     function setAllowedPriceUpdateDelay(uint64 allowedPriceUpdateDelay_) external onlyOwner {

56:     function updateDataFeeds(string[] calldata paths_, address[][] calldata feeds_) external onlyOwner {

117:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/ChainLinkDataConsumer.sol)

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

101:     function setDistributor(address value_) public onlyOwner {

120:     ) public onlyOwner {

137:     function migrate(uint256 rewardPoolIndex_) external onlyOwner {

162:     function editReferrerTiers(uint256 rewardPoolIndex_, ReferrerTier[] calldata referrerTiers_) external onlyOwner {

194:     ) external onlyOwner {

761:     function removeUpgradeability() external onlyOwner {

769:     function _authorizeUpgrade(address) internal view override onlyOwner {

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

113:     function setChainLinkDataConsumer(address value_) public onlyOwner {

124:     function setL1Sender(address value_) public onlyOwner {

135:     function setAavePool(address value_) public onlyOwner {

146:     function setAavePoolDataProvider(address value_) public onlyOwner {

157:     function setAaveRewardsController(address value_) public onlyOwner {

165:     function setRewardPool(address value_) public onlyOwner {

173:     function setMinRewardsDistributePeriod(uint256 value_) public onlyOwner {

179:     function setRewardPoolLastCalculatedTimestamp(uint256 rewardPoolIndex_, uint128 value_) public onlyOwner {

198:     ) external onlyOwner {

426:     function withdrawUndistributedRewards(address user_, address refundTo_) external payable onlyOwner {

448:     ) external onlyOwner returns (uint256 claimedAmount) {

513:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

56:     function setStETh(address value_) external onlyOwner {

64:     function setDistributor(address value_) external onlyOwner {

75:     function setUniswapSwapRouter(address value_) external onlyOwner {

95:     function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {

132:     function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {

158:     ) external payable onlyOwner returns (bytes memory) {

204:     ) external onlyOwner returns (uint256) {

242:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

```solidity
File: ./contracts/capital-protocol/L2TokenReceiverV2.sol

50:     function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {

65:     function withdrawToken(address recipient_, address token_, uint256 amount_) external onlyOwner {

69:     function withdrawTokenId(address recipient_, address token_, uint256 tokenId_) external onlyOwner {

78:     ) external onlyOwner returns (uint256) {

105:     ) external onlyOwner returns (uint128 liquidity_, uint256 amount0_, uint256 amount1_) {

164:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L2TokenReceiverV2.sol)

```solidity
File: ./contracts/capital-protocol/RewardPool.sol

39:     function addRewardPool(RewardPool calldata rewardPool_) public onlyOwner {

97:     function _authorizeUpgrade(address) internal view override onlyOwner {}

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/RewardPool.sol)

### <a name="M-3"></a>[M-3] Direct `supportsInterface()` calls may cause caller to revert

Calling `supportsInterface()` on a contract that doesn't implement the ERC-165 standard will result in the call reverting. Even if the caller does support the function, the contract may be malicious and consume all of the transaction's available gas. Call it via a low-level [staticcall()](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f959d7e4e6ee0b022b41e5b644c79369869d8411/contracts/utils/introspection/ERC165Checker.sol#L119), with a fixed amount of gas, and check the return code, or use OpenZeppelin's [`ERC165Checker.supportsInterface()`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f959d7e4e6ee0b022b41e5b644c79369869d8411/contracts/utils/introspection/ERC165Checker.sol#L36-L39).

*Instances (6)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

102:         require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "DR: invalid distributor address");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

115:             IERC165(value_).supportsInterface(type(IChainLinkDataConsumer).interfaceId),

125:         require(IERC165(value_).supportsInterface(type(IL1SenderV2).interfaceId), "DR: invalid L1Sender address");

166:         require(IERC165(value_).supportsInterface(type(IRewardPool).interfaceId), "DR: invalid reward pool address");

203:             IERC165(depositPoolAddress_).supportsInterface(type(IDepositPool).interfaceId),

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

65:         require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "L1S: invalid distributor address");

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

### <a name="M-4"></a>[M-4] Return values of `transfer()`/`transferFrom()` not checked

Not all `IERC20` implementations `revert()` when there's a failure in `transfer()`/`transferFrom()`. The function signature has a `boolean` return value and they indicate errors that way instead. By not checking the return value, operations that should have marked as failed, may potentially go through without actually making a payment

*Instances (1)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

153:         IERC20(depositToken).transfer(distributor, remainder_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

### <a name="M-5"></a>[M-5] Unsafe use of `transfer()`/`transferFrom()`/`approve()`/ with `IERC20`

Some tokens do not implement the ERC20 standard properly but are still accepted by most code that accepts ERC20 tokens.  For example Tether (USDT)'s `transfer()` and `transferFrom()` functions on L1 do not return booleans as the specification requires, and instead have no return value. When these sorts of tokens are cast to `IERC20`, their [function signatures](https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca) do not match and therefore the calls made, revert (see [this](https://gist.github.com/IllIllI000/2b00a32e8f0559e8f386ea4f1800abc5) link for a test case). Use OpenZeppelin's `SafeERC20`'s `safeTransfer()`/`safeTransferFrom()` instead

*Instances (8)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

105:             IERC20(depositToken).approve(distributor, 0);

107:         IERC20(depositToken).approve(value_, type(uint256).max);

153:         IERC20(depositToken).transfer(distributor, remainder_);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

139:             IERC20(stETH).approve(oldConfig_.wstETH, 0);

140:             IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

144:         IERC20(newConfig_.wstETH).approve(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)

## High Issues

| |Issue|Instances|
|-|:-|:-:|
| [H-1](#H-1) | IERC20.approve() will revert for USDT | 7 |

### <a name="H-1"></a>[H-1] IERC20.approve() will revert for USDT

Use forceApprove() from SafeERC20

*Instances (7)*:

```solidity
File: ./contracts/capital-protocol/DepositPool.sol

105:             IERC20(depositToken).approve(distributor, 0);

107:         IERC20(depositToken).approve(value_, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/DepositPool.sol)

```solidity
File: ./contracts/capital-protocol/Distributor.sol

233:             IERC20(aToken_).approve(aavePool, type(uint256).max);

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/Distributor.sol)

```solidity
File: ./contracts/capital-protocol/L1SenderV2.sol

139:             IERC20(stETH).approve(oldConfig_.wstETH, 0);

140:             IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);

143:         IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);

144:         IERC20(newConfig_.wstETH).approve(

```

[Link to code](https://github.com/code-423n4/2025-08-morpheus/tree/main/./contracts/capital-protocol/L1SenderV2.sol)
