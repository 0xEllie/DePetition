// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Petition.sol";
import "../src/Token.sol";
import "../src/PetitionLedgerImpl.sol";
import "../src/DePetitionProxy.sol";

contract DePetitionScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address _account = vm.addr(privateKey);

        console.log("Account", _account);

        vm.startBroadcast(privateKey);

        Token _token1 = new Token("Test token one", "TST1");
        Token _token2 = new Token("Test token two", "TST2");
        Petition _petition = new Petition("petition title", "petition description", _account);
        PetitionLedgerImpl _petitionLedgerImpl = new PetitionLedgerImpl();
        DePetitionProxy proxy = new DePetitionProxy(address(_petitionLedgerImpl), _account);

        vm.stopBroadcast();
    }
}
