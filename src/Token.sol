    // SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * @title Token
 * @author ellie.xyz1991@gmail.com
 *
 * The intention of this contract is to create dummy tokens for internal testing needs on public testnets.
 */

contract Token is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 value) external {
        _mint(account, value);
    }
}
