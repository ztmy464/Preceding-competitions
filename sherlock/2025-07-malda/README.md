# Malda contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the **Issues** page in your private contest repo (label issues as **Medium** or **High**)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum, Base, Linea, Optimism, Unichain, Arbitrum. 
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of [weird tokens](https://github.com/d-xo/weird-erc20) you want to integrate?
Tokens at launch: 

Stables: USDC, USDT, USDS

Bluechips: wBTC, wETH

LSTs: wstETH, weETH, ezETH, wrsETH/rsETH on mainnet

Post-launch: 

Stables: USDe, sUSDe

Others: Lombard BTC, fiammaBTC, ARB, OP, LINEA, GMX, ZKC (Boundless Token), AERO
___

### Q: Are there any limitations on values set by admins (or other roles) in the codebase, including restrictions on array lengths?
Owner is trusted
Sequnecer is semi-trusted - It is trusted to maintain volume control and monitor the underlying chains for security. It can only execute UserOps based on zkProofs
Rebalancer is semi-trusted - Rebalancer only has DDOS abilities for the protocol via constant rebalancing. It cannot transfer user funds
Pauser is trusted

If the Sequencer or Rebalancer can use access-restricted functions they shouldn't be able to (based on the role explanation above), it may be considered a valid issue if it has Medium or High impact.
___

### Q: Are there any limitations on values set by admins (or other roles) in protocols you integrate with, including restrictions on array lengths?
No
___

### Q: Is the codebase expected to comply with any specific EIPs?
No
___

### Q: Are there any off-chain mechanisms involved in the protocol (e.g., keeper bots, arbitrage bots, etc.)? We assume these mechanisms will not misbehave, delay, or go offline unless otherwise specified.
Liquidators - Expected to liquidate positions like in other lending protocols
Sequencer (Centralized) - Expected to deliver proofs and execute UserOps via those proofs for all multichain interactions
Rebalancer (Centralized) - Expected to maintain liquidity across all deployments by rebalancing liquidity predicted by demand

___

### Q: What properties/invariants do you want to hold even if breaking them has a low/unknown impact?
No
___

### Q: Please discuss any design choices you made.
Sequencer - We chose to implement a centralized sequencer design that executes cross-chain actions without waiting for full L1 finality for rollups. This design choice was implemented to provide the users lower latency, while maintaining additional security checks that are not feasible with current ZK technology to be programmed into a zk-proof. 
___

### Q: Please provide links to previous audits (if any) and all the known issues or acceptable risks.
https://docs.malda.xyz/malda-protocol/audit-reports
___

### Q: Please list any relevant protocol resources.
https://docs.malda.xyz/

___

### Q: Additional audit information.
Here's the config for testing on testnet:
```
{
  "Core Contracts": {
    "linea_sepolia": {
      "Deployer contract": "0x7aFcD811e32a9F221B72502bd645d4bAa56a375a",
      "Roles(Rbac)": "0x3dc52279175EE96b6A60f6870ec4DfA417c916E3",
      "ZkVerifier": "0xF3CA3C7018eA139E8B3969FF64DafDa8DF946B31",
      "BatchSubmitter": "0xC03155E29276841Bc5D27653c57fb85FA6043C65",
      "GasHelper": "0x3aE44aC156557D30f58E38a6796336E7eD0A3fC1",
      "RewardDistributor implementation": "0x5D88bbd2c635277C39cAcC773dd2cdFbA7890f2c",
      "RewardDistributor": "0x837D67e10C0E91B58568582154222EDF4357D58E",
      "MixedPriceOracleV4": "0xAc028838DaF18FAD0F69a1a1e143Eb8a29b04904",
      "Operator implementation": "0x0B6d9A4FEd6516FFe871dbB9BF9166420f92b3E9",
      "Operator proxy": "0x389cc3D08305C3DaAf19B2Bf2EC7dD7f66D68dA8",
      "Pauser": "0x4EC99a994cC51c03d67531cdD932f231385f9618"
    },
    "op_sepolia": {
      "Deployer contract": "0x7aFcD811e32a9F221B72502bd645d4bAa56a375a",
      "Roles(Rbac)": "0x3dc52279175EE96b6A60f6870ec4DfA417c916E3",
      "ZkVerifier": "0xF3CA3C7018eA139E8B3969FF64DafDa8DF946B31",
      "BatchSubmitter": "0xC03155E29276841Bc5D27653c57fb85FA6043C65",
      "GasHelper": "0x3aE44aC156557D30f58E38a6796336E7eD0A3fC1",
      "Pauser": "0x4EC99a994cC51c03d67531cdD932f231385f9618"
    },
    "sepolia": {
      "Deployer contract": "0x7aFcD811e32a9F221B72502bd645d4bAa56a375a",
      "Roles(Rbac)": "0x3dc52279175EE96b6A60f6870ec4DfA417c916E3",
      "ZkVerifier": "0xF3CA3C7018eA139E8B3969FF64DafDa8DF946B31",
      "BatchSubmitter": "0xC03155E29276841Bc5D27653c57fb85FA6043C65",
      "GasHelper": "0x3aE44aC156557D30f58E38a6796336E7eD0A3fC1",
      "Pauser": "0x4EC99a994cC51c03d67531cdD932f231385f9618"
    }
  },
  "Market Contracts": {
    "linea_sepolia": {
      "mUSDCMock": {
        "HostImplementation": "0xC0878EB12e0712031fD1961970f7Cc65546792E4",
        "HostProxy": "0x76daf584Cbf152c85EB2c7Fe7a3d50DaF3f5B6e6"
      },
      "mwstETHMock": {
        "HostImplementation": "0xB5e829DBE2DF8aC2ee7e6A50Cbc2105960BadE00",
        "HostProxy": "0xD4286cc562b906589f8232335413f79d9aD42f7E"
      }
    },
    "op_sepolia": {
      "mUSDCMock": {
        "ExtensionImplementation": "0x0842B40d66F6cA95Fc3b512B71Bb2267Ee89d851",
        "ExtensionProxy": "0x76daf584Cbf152c85EB2c7Fe7a3d50DaF3f5B6e6"
      },
      "mwstETHMock": {
        "ExtensionImplementation": "0x1C2E16780760256e247F228Ea43C9E44fE43cAEd",
        "ExtensionProxy": "0xD4286cc562b906589f8232335413f79d9aD42f7E"
      }
    },
    "sepolia": {
      "mUSDCMock": {
        "ExtensionImplementation": "0x0842B40d66F6cA95Fc3b512B71Bb2267Ee89d851",
        "ExtensionProxy": "0x76daf584Cbf152c85EB2c7Fe7a3d50DaF3f5B6e6"
      },
      "mwstETHMock": {
        "ExtensionImplementation": "0x1C2E16780760256e247F228Ea43C9E44fE43cAEd",
        "ExtensionProxy": "0xD4286cc562b906589f8232335413f79d9aD42f7E"
      }
    }
```


# Audit scope

[malda-lending @ ab4fa9b2da94bc7f5b0e6d4c52f61e28b0820a54](https://github.com/malda-protocol/malda-lending/tree/ab4fa9b2da94bc7f5b0e6d4c52f61e28b0820a54)
- [malda-lending/src/blacklister/Blacklister.sol](malda-lending/src/blacklister/Blacklister.sol)
- [malda-lending/src/interest/JumpRateModelV4.sol](malda-lending/src/interest/JumpRateModelV4.sol)
- [malda-lending/src/migration/IMigrator.sol](malda-lending/src/migration/IMigrator.sol)
- [malda-lending/src/migration/Migrator.sol](malda-lending/src/migration/Migrator.sol)
- [malda-lending/src/mToken/BatchSubmitter.sol](malda-lending/src/mToken/BatchSubmitter.sol)
- [malda-lending/src/mToken/extension/mTokenGateway.sol](malda-lending/src/mToken/extension/mTokenGateway.sol)
- [malda-lending/src/mToken/host/mErc20Host.sol](malda-lending/src/mToken/host/mErc20Host.sol)
- [malda-lending/src/mToken/mErc20Immutable.sol](malda-lending/src/mToken/mErc20Immutable.sol)
- [malda-lending/src/mToken/mErc20.sol](malda-lending/src/mToken/mErc20.sol)
- [malda-lending/src/mToken/mErc20Upgradable.sol](malda-lending/src/mToken/mErc20Upgradable.sol)
- [malda-lending/src/mToken/mTokenConfiguration.sol](malda-lending/src/mToken/mTokenConfiguration.sol)
- [malda-lending/src/mToken/mToken.sol](malda-lending/src/mToken/mToken.sol)
- [malda-lending/src/mToken/mTokenStorage.sol](malda-lending/src/mToken/mTokenStorage.sol)
- [malda-lending/src/Operator/Operator.sol](malda-lending/src/Operator/Operator.sol)
- [malda-lending/src/Operator/OperatorStorage.sol](malda-lending/src/Operator/OperatorStorage.sol)
- [malda-lending/src/oracles/gas/DefaultGasHelper.sol](malda-lending/src/oracles/gas/DefaultGasHelper.sol)
- [malda-lending/src/oracles/MixedPriceOracleV3.sol](malda-lending/src/oracles/MixedPriceOracleV3.sol)
- [malda-lending/src/oracles/MixedPriceOracleV4.sol](malda-lending/src/oracles/MixedPriceOracleV4.sol)
- [malda-lending/src/pauser/Pauser.sol](malda-lending/src/pauser/Pauser.sol)
- [malda-lending/src/rebalancer/bridges/AcrossBridge.sol](malda-lending/src/rebalancer/bridges/AcrossBridge.sol)
- [malda-lending/src/rebalancer/bridges/BaseBridge.sol](malda-lending/src/rebalancer/bridges/BaseBridge.sol)
- [malda-lending/src/rebalancer/bridges/EverclearBridge.sol](malda-lending/src/rebalancer/bridges/EverclearBridge.sol)
- [malda-lending/src/rebalancer/Rebalancer.sol](malda-lending/src/rebalancer/Rebalancer.sol)
- [malda-lending/src/Roles.sol](malda-lending/src/Roles.sol)
- [malda-lending/src/utils/WrapAndSupply.sol](malda-lending/src/utils/WrapAndSupply.sol)
- [malda-lending/src/verifier/ZkVerifier.sol](malda-lending/src/verifier/ZkVerifier.sol)

[malda-zk-coprocessor @ 813060dd27ad8658a2e6009260b05e69bafaab8d](https://github.com/malda-protocol/malda-zk-coprocessor/tree/813060dd27ad8658a2e6009260b05e69bafaab8d)
- [malda-zk-coprocessor/malda_rs/src/constants.rs](malda-zk-coprocessor/malda_rs/src/constants.rs)
- [malda-zk-coprocessor/malda_rs/src/elfs_ids.rs](malda-zk-coprocessor/malda_rs/src/elfs_ids.rs)
- [malda-zk-coprocessor/malda_rs/src/lib.rs](malda-zk-coprocessor/malda_rs/src/lib.rs)
- [malda-zk-coprocessor/malda_rs/src/viewcalls.rs](malda-zk-coprocessor/malda_rs/src/viewcalls.rs)
- [malda-zk-coprocessor/malda_utils/src/constants.rs](malda-zk-coprocessor/malda_utils/src/constants.rs)
- [malda-zk-coprocessor/malda_utils/src/cryptography.rs](malda-zk-coprocessor/malda_utils/src/cryptography.rs)
- [malda-zk-coprocessor/malda_utils/src/lib.rs](malda-zk-coprocessor/malda_utils/src/lib.rs)
- [malda-zk-coprocessor/malda_utils/src/types.rs](malda-zk-coprocessor/malda_utils/src/types.rs)
- [malda-zk-coprocessor/malda_utils/src/validators.rs](malda-zk-coprocessor/malda_utils/src/validators.rs)
- [malda-zk-coprocessor/methods/build.rs](malda-zk-coprocessor/methods/build.rs)
- [malda-zk-coprocessor/methods/guest/src/bin/get_proof_data.rs](malda-zk-coprocessor/methods/guest/src/bin/get_proof_data.rs)
- [malda-zk-coprocessor/methods/src/lib.rs](malda-zk-coprocessor/methods/src/lib.rs)


