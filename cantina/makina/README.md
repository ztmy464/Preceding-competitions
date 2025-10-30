# Contracts in Scope for the CTF
(In addition to the contracts below, any other contracts deployed by the listed factories are in scope, additionally any new contracts deployed on spoke chains at the addresses listed below for Base & Arbitrum are in scope) 

```
// Global Entities
"DAOContractAdmin": "0x2A919D575B96e7a5260d7Dc26d2f26D9f67Bc46F",
"SecurityCouncil": "0x0e8844Ff1e702948e086F1D234178f1c614fc008",
"StrategyMgmtSetupTimelock": "0xBad784b2b52E8FCF9AA3c5dB63db783555bD17b7",

// Strategy Specific Entities
"RiskManager": "0x05F9baEDD4aC67B3ce50371bFb2907AD02d3f7E0",
"RiskManagerTimelock": "0x6e0EE7d0ccd43E6E5193484A0b270F175534D10a",
"Mechanic/Operator": "0xf16fd67770daf14dcaa25711af9196dc290caca0",
"StrategyDeploymentTimelock": "0x9c693333e7404C062660496516692026435283CE",

// Strategy Specific Infra
"AccountingToken": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
"PreDepositToken": "0x9a8bC3B04b7f3D87cfC09ba407dCED575f2d61D8",
"PreDepositTokenOracle": "0x64287ab4d91c3eccec880b674361349f79859cb1",
"CTFWETH": "0xc3fede37bfe4563204b0417e9fa1808421881a97",
"PredepositVault": "0xfdbec10c751e1ef8738ef57c5eedf01517038f2d",
"DepositContract": "0xe7D7d68e8eA92Ec79979eAf5E2eb366f7C3678D0",
"RedeemerContract": "0x21Ded3FB74052896fc0238fCE59f39D02bbE9Eca",
"SecurityModule": "0xFd2bEBc08A41c6d5Bc8aC6C9ead2f23A5d365eb1",
"FeeManager": "0x76e53a349cd0ddff174a3e6076ce60bc9741366f",
"Machine": "0xe51638dad0ebaff103de9262f0c32796daa26d3d",
"Caliber": "0x4938cb1c765889a37112a39d910a8bbd7902252f"

// Infrastructure
  "Mainnet": {
	"Core": {
	  "AccessManager": "0x9cAF58819fBd7df3284e73d66461a7d6d3E3d3Ca",
	  "BridgeAdapterBeacons": {
	    "1": "0x394E09F4F7B22FcaE68f127E9Da06e0c803aBD8c"
	  },
	  "CaliberBeacon": "0x6C06140269Ee1858b8A0Eb54a7e84FCB1BD61067",
	  "ChainRegistry": "0x284Ea33406E0dF79709c52e30C426B66fA2E3A2F",
	  "HubCoreFactory": "0x72ff905685cFD3856CBc0f67C96042805748760F",
	  "HubCoreRegistry": "0xd456793D6688077Ac24bad3d391cFfecB8F08C27",
	  "MachineBeacon": "0xA3f42df673A77e1bbA9f421F2Ad67c7AddB00edD",
	  "OracleRegistry": "0x8073dbb4303F3615F5F43956a595AFa90E63b0f3",
	  "SwapModule": "0x4791DF672BA1a368181f84eA0A831c9E9B65A3C4",
	  "TokenRegistry": "0xb6f6FD97c47dA273b120ce6E8e632043BF4fdA2f"
	},
	"Periphery": {
	  "AsyncRedeemerBeacon": "0x68caAf4Aacb80FfB21EA3f617365347afAe2f1C3",
	  "DirectDepositorBeacon": "0x43C33287809E5C9C732dB481dbE7725CBeA70348",
	  "FlashloanAggregator": "0x97Fa9Ec53C734842a39916103D2c83e9DB6cd9e5",
	  "HubPeripheryFactory": "0x9030ba18c51E9281C17B78e912BC2D930FFfa5Dc",
	  "HubPeripheryRegistry": "0x18D8698797F3ebb343d95c2bC170E52F7CcCeAD6",
	  "MetaMorphoOracleFactory": "0xbBCeD8C9C94B3720cB4cCa8A850f5E6b6ce8bCe1",
	  "SecurityModuleBeacon": "0x0ABe58aAb6B0B6a7DD9694dfdF9752ceD677f89B",
	  "WatermarkFeeManagerBeacon": "0x581D2A50f7401611cd710c94dC6fEe4C8d3EEb6e"
	}
  }
   // Spoke Chain Contracts (addresses are the same on all spokes) 
  "Base/Arbitrum/OtherSpokeChain": {
	"Core": {
	  "AccessManager": "0x9cAF58819fBd7df3284e73d66461a7d6d3E3d3Ca",
	  "BridgeAdapterBeacons": {
	    "1": "0x394E09F4F7B22FcaE68f127E9Da06e0c803aBD8c"
	  },
	  "CaliberBeacon": "0x6C06140269Ee1858b8A0Eb54a7e84FCB1BD61067",
	  "CaliberMailboxBeacon": "0x081D75073FB10d38f5D812EC96f359562030D7f0",
	  "OracleRegistry": "0x8073dbb4303F3615F5F43956a595AFa90E63b0f3",
	  "SpokeCoreFactory": "0x72ff905685cFD3856CBc0f67C96042805748760F",
	  "SpokeCoreRegistry": "0xd456793D6688077Ac24bad3d391cFfecB8F08C27",
	  "SwapModule": "0x4791DF672BA1a368181f84eA0A831c9E9B65A3C4",
	  "TokenRegistry": "0xb6f6FD97c47dA273b120ce6E8e632043BF4fdA2f"
	  "Caliber": "TBD After Migration"
          "CaliberMailbox": "TBD After Migration"
	}
  }

```
