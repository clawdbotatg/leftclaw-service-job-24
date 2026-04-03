// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployHelpers.s.sol";
import "../contracts/TreasuryManagerV2.sol";

contract DeployTreasuryManagerV2 is ScaffoldETHDeploy {
    // IMPORTANT: This address is the job client / contract owner.
    // Must match the wallet that will manage the treasury.
    // Changing this address changes who controls all owner-only functions.
    address constant OWNER = 0x9ba58Eea1Ea9ABDEA25BA83603D54F6D9A01E506;

    function run() external ScaffoldEthDeployerRunner {
        new TreasuryManagerV2(OWNER);
    }
}
