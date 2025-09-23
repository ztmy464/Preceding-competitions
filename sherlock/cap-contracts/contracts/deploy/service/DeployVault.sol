// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { AccessControl } from "../../access/AccessControl.sol";

import { Delegation } from "../../delegation/Delegation.sol";

import { FeeAuction } from "../../feeAuction/FeeAuction.sol";

import { ILender } from "../../interfaces/ILender.sol";
import { IMinter } from "../../interfaces/IMinter.sol";

import { Lender } from "../../lendingPool/Lender.sol";
import { DebtToken } from "../../lendingPool/tokens/DebtToken.sol";
import { FractionalReserve } from "../../vault/FractionalReserve.sol";
import { Minter } from "../../vault/Minter.sol";

import { FeeReceiver } from "../../feeReceiver/FeeReceiver.sol";
import { CapToken } from "../../token/CapToken.sol";
import { OFTLockbox } from "../../token/OFTLockbox.sol";
import { StakedCap } from "../../token/StakedCap.sol";
import { Vault } from "../../vault/Vault.sol";
import { ZapOFTComposer } from "../../zap/ZapOFTComposer.sol";
import {
    FeeConfig,
    ImplementationsConfig,
    InfraConfig,
    UsersConfig,
    VaultConfig,
    VaultLzPeriphery
} from "../interfaces/DeployConfigs.sol";

import { LzAddressbook } from "../utils/LzUtils.sol";
import { ProxyUtils } from "../utils/ProxyUtils.sol";
import { ZapAddressbook } from "../utils/ZapUtils.sol";

contract DeployVault is ProxyUtils {
    function _deployVault(
        ImplementationsConfig memory implementations,
        InfraConfig memory infra,
        string memory name,
        string memory symbol,
        address[] memory assets,
        address insuranceFund
    ) internal returns (VaultConfig memory d) {
        // deploy and init cap instances
        d.capToken = _proxy(implementations.capToken);
        d.stakedCapToken = _proxy(implementations.stakedCap);
        d.feeReceiver = _proxy(implementations.feeReceiver);
        d.feeAuction = _proxy(implementations.feeAuction);

        FeeReceiver(d.feeReceiver).initialize(infra.accessControl, d.capToken, d.stakedCapToken);
        FeeAuction(d.feeAuction).initialize(
            infra.accessControl,
            d.capToken, // payment token is the vault's cap token
            d.feeReceiver, // payment recipient is the staked cap token
            24 hours, // 3 hour auctions
            1e18 // min price of 1 token
        );
        CapToken(d.capToken).initialize(
            name, symbol, infra.accessControl, d.feeAuction, infra.oracle, assets, insuranceFund
        );
        StakedCap(d.stakedCapToken).initialize(infra.accessControl, d.capToken, 24 hours);

        // deploy and init debt tokens
        d.assets = assets;
        d.debtTokens = new address[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            d.debtTokens[i] = _proxy(implementations.debtToken);
            DebtToken(d.debtTokens[i]).initialize(infra.accessControl, assets[i], infra.oracle);
        }
    }

    function _deployVaultLzPeriphery(
        LzAddressbook memory lzAddressbook,
        ZapAddressbook memory zapAddressbook,
        VaultConfig memory vault,
        UsersConfig memory users
    ) internal returns (VaultLzPeriphery memory d) {
        // deploy the lockboxes
        d.capOFTLockbox =
            address(new OFTLockbox(vault.capToken, address(lzAddressbook.endpointV2), users.vault_config_admin));

        d.stakedCapOFTLockbox =
            address(new OFTLockbox(vault.stakedCapToken, address(lzAddressbook.endpointV2), users.vault_config_admin));

        // deploy the zap composers
        d.capZapComposer = address(
            new ZapOFTComposer(
                address(lzAddressbook.endpointV2),
                d.capOFTLockbox,
                zapAddressbook.zapRouter,
                zapAddressbook.tokenManager
            )
        );
        d.stakedCapZapComposer = address(
            new ZapOFTComposer(
                address(lzAddressbook.endpointV2),
                d.stakedCapOFTLockbox,
                zapAddressbook.zapRouter,
                zapAddressbook.tokenManager
            )
        );
    }

    function _initVaultAccessControl(InfraConfig memory infra, VaultConfig memory vault, UsersConfig memory users)
        internal
    {
        AccessControl accessControl = AccessControl(infra.accessControl);
        accessControl.grantAccess(Vault.borrow.selector, vault.capToken, infra.lender);
        accessControl.grantAccess(Vault.repay.selector, vault.capToken, infra.lender);
        accessControl.grantAccess(Minter.setFeeData.selector, vault.capToken, users.lender_admin);
        accessControl.grantAccess(Minter.setRedeemFee.selector, vault.capToken, users.lender_admin);
        accessControl.grantAccess(Vault.pauseProtocol.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(Vault.unpauseProtocol.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(Vault.pauseAsset.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(Vault.unpauseAsset.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(bytes4(0), vault.capToken, users.access_control_admin);

        accessControl.grantAccess(FractionalReserve.setReserve.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(
            FractionalReserve.setFractionalReserveVault.selector, vault.capToken, users.vault_config_admin
        );
        accessControl.grantAccess(FractionalReserve.investAll.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(FractionalReserve.divestAll.selector, vault.capToken, users.vault_config_admin);
        accessControl.grantAccess(FractionalReserve.realizeInterest.selector, vault.capToken, users.vault_config_admin);

        // Configure FeeAuction access control
        accessControl.grantAccess(FeeAuction.setStartPrice.selector, vault.feeAuction, infra.lender);
        accessControl.grantAccess(FeeAuction.setDuration.selector, vault.feeAuction, infra.lender);
        accessControl.grantAccess(FeeAuction.setMinStartPrice.selector, vault.feeAuction, infra.lender);
        accessControl.grantAccess(bytes4(0), vault.feeAuction, users.access_control_admin);

        for (uint256 i = 0; i < vault.assets.length; i++) {
            accessControl.grantAccess(DebtToken.mint.selector, vault.debtTokens[i], infra.lender);
            accessControl.grantAccess(DebtToken.burn.selector, vault.debtTokens[i], infra.lender);
            accessControl.grantAccess(bytes4(0), vault.debtTokens[i], users.access_control_admin);
        }

        accessControl.grantAccess(FeeAuction.setMinStartPrice.selector, vault.feeAuction, users.fee_auction_admin);
        accessControl.grantAccess(FeeAuction.setDuration.selector, vault.feeAuction, users.fee_auction_admin);
        accessControl.grantAccess(FeeAuction.setStartPrice.selector, vault.feeAuction, users.fee_auction_admin);

        accessControl.grantAccess(
            FeeReceiver.setProtocolFeePercentage.selector, vault.feeReceiver, users.vault_config_admin
        );
        accessControl.grantAccess(
            FeeReceiver.setProtocolFeeReceiver.selector, vault.feeReceiver, users.vault_config_admin
        );

        AccessControl(infra.accessControl).grantAccess(bytes4(0), vault.stakedCapToken, users.access_control_admin);
    }

    function _initVaultLender(VaultConfig memory d, InfraConfig memory infra, FeeConfig memory fee) internal {
        for (uint256 i = 0; i < d.assets.length; i++) {
            Lender(infra.lender).addAsset(
                ILender.AddAssetParams({
                    asset: d.assets[i],
                    vault: d.capToken,
                    debtToken: d.debtTokens[i],
                    interestReceiver: d.feeAuction,
                    bonusCap: 0.1e27,
                    minBorrow: 100e6
                })
            );

            Lender(infra.lender).pauseAsset(d.assets[i], false);

            Minter(d.capToken).setFeeData(
                d.assets[i],
                IMinter.FeeData({
                    minMintFee: fee.minMintFee,
                    slope0: fee.slope0,
                    slope1: fee.slope1,
                    mintKinkRatio: fee.mintKinkRatio,
                    burnKinkRatio: fee.burnKinkRatio,
                    optimalRatio: fee.optimalRatio
                })
            );
        }
    }
}
