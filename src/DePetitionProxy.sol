// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Petition.sol";
import "./PetitionLedgerImpl.sol";

/*
 * @title DePetitionProxy
 * @author ellie.xyz1991@gmail.com
 *
 * This contract act as the proxy for PetitionLedgerImpl contract.
 * We benefit from UUPS proxy pattern.
 * 
 */
contract DePetitionProxy is ERC1967Proxy {
    constructor(address _implementation, address _initialOwner)
        ERC1967Proxy(_implementation, abi.encodeWithSelector(PetitionLedgerImpl.initialize.selector, _initialOwner))
    {}
}
