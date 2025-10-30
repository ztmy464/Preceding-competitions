// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC677Receiver} from "./interfaces/IERC677Receiver.sol";
import {IMerge} from "./interfaces/IMerge.sol";

contract MergeTgt is IMerge, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable tgt;
    IERC20 public immutable titn;

    uint256 public constant TGT_TO_EXCHANGE = 579_000_000 * 10 ** 18; // 57.9% of MAX_TGT
    uint256 public constant TITN_ARB = 173_700_000 * 10 ** 18; // 17.37% of MAX_TITN
    uint256 public launchTime;

    mapping(address => uint256) public claimedTitnPerUser;
    mapping(address => uint256) public claimableTitnPerUser;
    uint256 public totalTitnClaimed;
    uint256 public totalTitnClaimable;
    uint256 public remainingTitnAfter1Year;
    uint256 public initialTotalClaimable; // store the initial claimable TITN after 1 year

    LockedStatus public lockedStatus;

    // Events
    event Deposit(address indexed token, uint256 amount);
    event Withdraw(address indexed token, uint256 amount, address indexed to);
    event LaunchTimeSet(uint256 timestamp);
    event LockedStatusUpdated(LockedStatus newStatus);
    event ClaimTitn(address indexed user, uint256 amount);
    event ClaimableTitnUpdated(address indexed user, uint256 titnOut);
    event WithdrawRemainingTitn(address indexed user, uint256 amount);

    constructor(address _tgt, address _titn, address initialOwner) Ownable(initialOwner) {
        tgt = IERC20(_tgt);
        titn = IERC20(_titn);
    }

    function deposit(IERC20 token, uint256 amount) external onlyOwner {
        if (token != titn) {
            revert InvalidTokenReceived();
        }
        //~ @audit [QA-01] Dust Amount Loss in Cross-Chain TITN Token Transfers
        //~ 源链和目标链可能 代币精度（decimals）不同
        //~ 你跨链 1.000000000000000001 个 token（带 18 位小数），目标链可能只支持 6 位小数, 被 dust removal 

        //~ mitigation: Add tolerance for deposit amounts.
        
        // enforce that the deposited amount is 12_500_000 * 10**18
        if (amount != TITN_ARB) {    //~ 必须精确相等
            revert InvalidAmountReceived();
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(address(token), amount);
    }

    /// @notice Withdraw any locked contracts in Merge contract
    function withdraw(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(owner(), amount);
        emit Withdraw(address(token), amount, owner());
    }

    //~ ERC677 在 ERC20 的 transfer 基础上，加了一个新函数：
    /*     
        function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success);

        if (isContract(to)) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        }
    */
    //~ 实现了 ERC677 的回调接口
    /// @notice tgt token transferAndCall ERC677-like
    function onTokenTransfer(address from, uint256 amount, bytes calldata extraData) external nonReentrant {
        if (msg.sender != address(tgt)) {
            revert InvalidTokenReceived();
        }
        if (lockedStatus == LockedStatus.Locked || launchTime == 0) {
            revert MergeLocked();
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (block.timestamp - launchTime > 360 days) {
            revert MergeEnded();
        }

        //~ @audit-H MergeTgt has no handling if TGT is exceeded TGT_TO_EXCHANGE
        //~ mitigation：跟踪已存入的 TGT 数量来限制 TGT 的总存款量 或 将 totalTitnClaimable 限制为 TITN_ARB 值
        // tgt in, titn out
        uint256 titnOut = quoteTitn(amount);
        claimableTitnPerUser[from] += titnOut;
        totalTitnClaimable += titnOut;

        emit ClaimableTitnUpdated(from, titnOut);
    }

    function tgtBalance() external view returns (uint256) {
        return tgt.balanceOf(address(this));
    }

    function titnBalance() external view returns (uint256) {
        return titn.balanceOf(address(this));
    }

    function claimTitn(uint256 amount) external nonReentrant {
        require(amount <= claimableTitnPerUser[msg.sender], "Not enough claimable titn");

        if (block.timestamp - launchTime >= 360 days) {
            revert TooLateToClaimRemainingTitn();
        }

        claimedTitnPerUser[msg.sender] += amount;
        claimableTitnPerUser[msg.sender] -= amount;

        totalTitnClaimed += amount;
        totalTitnClaimable -= amount;

        titn.safeTransfer(msg.sender, amount);

        emit ClaimTitn(msg.sender, amount);
    }

    function withdrawRemainingTitn() external nonReentrant {
        require(launchTime > 0, "Launch time not set");

        if (block.timestamp - launchTime < 360 days) {
            revert TooEarlyToClaimRemainingTitn();
        }

        uint256 currentRemainingTitn = titn.balanceOf(address(this));

        if (remainingTitnAfter1Year == 0) {
            // Initialize remainingTitnAfter1Year to the current balance of TITN
            remainingTitnAfter1Year = currentRemainingTitn;

            // Capture the total claimable TITN at the time of the first claim
            initialTotalClaimable = totalTitnClaimable;
        }

        uint256 claimableTitn = claimableTitnPerUser[msg.sender];
        require(claimableTitn > 0, "No claimable TITN");

        // Calculate proportional remaining TITN for the user
        uint256 unclaimedTitn = remainingTitnAfter1Year - initialTotalClaimable;
        //~ q 都不claimTitn想等着最后分怎么办
        uint256 userProportionalShare = (claimableTitn * unclaimedTitn) / initialTotalClaimable;

        uint256 titnOut = claimableTitn + userProportionalShare;

        // Update state variables
        claimableTitnPerUser[msg.sender] = 0; // each user can only claim once
        totalTitnClaimed += titnOut;

        claimedTitnPerUser[msg.sender] += titnOut;
        totalTitnClaimable -= claimableTitn;

        // Transfer TITN to the user
        titn.safeTransfer(msg.sender, titnOut);

        emit WithdrawRemainingTitn(msg.sender, titnOut);
    }
    //~ 计算可兑换 TITN Amount

    //~ 0–90 天：兑换比例固定（线性），用户能拿到 (TGT * TITN_ARB) / TGT_TO_EXCHANGE。
    //~ 90–360 天：兑换比例逐渐递减，越晚兑换 TITN 越少。
    function quoteTitn(uint256 tgtAmount) public view returns (uint256 titnAmount) {
        require(launchTime > 0, "Launch time not set");

        uint256 timeSinceLaunch = (block.timestamp - launchTime);
        if (timeSinceLaunch < 90 days) {
            titnAmount = (tgtAmount * TITN_ARB) / TGT_TO_EXCHANGE;
        } else if (timeSinceLaunch < 360 days) {
            uint256 remainingtime = 360 days - timeSinceLaunch;
            titnAmount = (tgtAmount * TITN_ARB * remainingtime) / (TGT_TO_EXCHANGE * 270 days); //270 days = 9 months
        } else {
            titnAmount = 0;
        }
    }

    //~ [QA-04] Setter Functions Don’t Check for Value Changes
    //~ 值没变时出现不必要的事件排放
    function setLockedStatus(LockedStatus newStatus) external onlyOwner {
        lockedStatus = newStatus;
        emit LockedStatusUpdated(newStatus);
    }

    function setLaunchTime() external onlyOwner {
        require(launchTime == 0, "Launch time already set");
        launchTime = block.timestamp;
        emit LaunchTimeSet(block.timestamp);
    }

    function gettotalClaimedTitnPerUser(address user) external view returns (uint256) {
        return claimedTitnPerUser[user];
    }

    function getClaimableTitnPerUser(address user) external view returns (uint256) {
        return claimableTitnPerUser[user];
    }
}