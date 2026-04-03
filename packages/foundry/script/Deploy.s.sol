//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployHelpers.s.sol";
import { DeployTreasuryManagerV2 } from "./DeployYourContract.s.sol";

contract DeployScript is ScaffoldETHDeploy {
  function run() external {
    DeployTreasuryManagerV2 deployTreasury = new DeployTreasuryManagerV2();
    deployTreasury.run();
  }
}
