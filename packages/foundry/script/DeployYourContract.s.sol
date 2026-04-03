// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployHelpers.s.sol";
import "../contracts/TreasuryManagerV2.sol";

contract DeployTreasuryManagerV2 is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        // Owner must be job.client = 0x9ba58Eea1Ea9ABDEA25BA83603D54F6D9A01E506
        new TreasuryManagerV2(0x9ba58Eea1Ea9ABDEA25BA83603D54F6D9A01E506);
    }
}
