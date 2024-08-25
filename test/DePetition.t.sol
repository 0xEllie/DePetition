// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Petition.sol";
import "../src/Token.sol";
import "../src/PetitionLedgerImpl.sol";
import "../src/DePetitionProxy.sol";
import "./v3PetitionLedger.sol";
import "./v4PetitionLedger.sol";

contract DePetitionTest is Test {
    DePetitionProxy public proxy;
    PetitionLedgerImpl public petitionLedgerImpl;
    PetitionLedgerImpl public petitionUpgradeable;
    Token token1;
    Token token2;
    address petition1;
    address constant INITIAL_OWNER = address(10);
    address constant Alice = address(1);
    address constant Bob = address(2);
    uint256 petitionCount;

    function setUp() public {
        petitionLedgerImpl = new PetitionLedgerImpl();
        proxy = new DePetitionProxy(address(petitionLedgerImpl), INITIAL_OWNER);
        petitionUpgradeable = PetitionLedgerImpl(address(proxy));

        token1 = new Token("Test1", "TST1");
        vm.prank(Alice);
        token1.mint(Alice, 1000);

        token2 = new Token("Test2", "TST2");
        vm.prank(Bob);
        token2.mint(Bob, 1000);

        deal(Alice, 100 * 1e18);

        test_DeployNewPetition();

        console.log("implimentation owner address", petitionUpgradeable.owner());
    }

    function test_AddToken() private {
        vm.prank(INITIAL_OWNER);
        petitionUpgradeable.addToken(address(token1), "TST1");
        assertEq(petitionUpgradeable.tokens(address(token1)), "TST1");
        console.log("VERSiON : ", petitionUpgradeable.VERSION());
    }

    function test_DeployNewPetition() public {
        petitionCount += 1;
        petition1 =
            petitionUpgradeable.deployNewPetition("new petition", "this petition is about Ethereum", petitionCount);
        assertEq(petitionUpgradeable.petitions(petition1), address(this));
        console.log("VERSiON : ", petitionUpgradeable.VERSION());
    }

    function test_SignWithToken() public {
        vm.startPrank(Alice);
        token1.approve(address(petitionUpgradeable), type(uint256).max);
        console.log("tst1 balance for alice : ", token1.balanceOf(Alice));
        console.log("petitionProxy : ", address(petitionUpgradeable));
        petitionUpgradeable.signWithToken(petition1, address(token1), 30);

        vm.stopPrank();
        assertGe(
            token1.balanceOf(address(petitionUpgradeable)),
            petitionUpgradeable.tokenDeposites(petition1, address(token1), Alice)
        );
        console.log("VERSiON inside test_SignWithToken: ", petitionUpgradeable.VERSION());
    }

    function test_WithdrawToken() public {
        test_SignWithToken();
        vm.startPrank(Alice);
        token1.approve(address(petitionUpgradeable), type(uint256).max);
        petitionUpgradeable.withdrawToken(petition1, address(token1));
        vm.stopPrank();
        assertEq(token1.balanceOf(address(petitionUpgradeable)), 0);
        assertGe(token1.balanceOf(Alice), 30);
        assertEq(petitionUpgradeable.tokenDeposites(petition1, address(token1), Alice), 0);
        console.log("VERSiON : ", petitionUpgradeable.VERSION());
    }

    function test_SignWithETH() public {
        uint256 _balance_before = Alice.balance;
        vm.startPrank(Alice);
        petitionUpgradeable.signWithETH{value: 1 ether}(petition1);
        vm.stopPrank();
        uint256 _balance_after = _balance_before - 1 ether;
        assertEq(Alice.balance, _balance_after);
        assertEq(petitionUpgradeable.ETHDeposites(petition1, Alice), 1 ether);
        console.log("_alice_balance : ", _balance_after);
    }

    function test_WithdrawETH() public {
        test_SignWithETH();
        uint256 _balance_before = Alice.balance;
        console.log("_alice_balance : ", Alice.balance);
        vm.startPrank(Alice);
        petitionUpgradeable.withdrawETH(petition1);
        vm.stopPrank();
        uint256 _balance_after = _balance_before + 1 ether;
        assertEq(Alice.balance, _balance_after);
        assertEq(petitionUpgradeable.ETHDeposites(petition1, Alice), 0);
        console.log("_alice_balance : ", _balance_after);
    }

    function test_SignWithNoFunds() public {
        uint256 _balance_before = Alice.balance;
        vm.startPrank(Alice);
        petitionUpgradeable.signWithNoFund(petition1);

        assert(petitionUpgradeable.hasSigned(petition1, Alice));

        assertEq(Alice.balance, _balance_before);

        vm.stopPrank();
    }

    function test_Version() public {
        assertEq(petitionUpgradeable.VERSION(), 2);
    }

    function test_SequenceOfFunctions() public {
        test_AddToken();
        test_DeployNewPetition();
        test_SignWithToken();
        test_WithdrawToken();
        test_UpgradeV3();
    }

    function test_SequenceOfFunctionsAfterV3() public {
        test_AddToken();
        test_DeployNewPetition();
        test_SignWithToken();
        console.log("VERSiON  sequence: ", petitionUpgradeable.VERSION());
        test_UpgradeV3();
        test_WithdrawToken();
        test_SignWithToken();
        console.log("VERSiON  sequence: ", petitionUpgradeable.VERSION());
        test_UpgradeV4();
        test_SignWithToken();
        test_WithdrawToken();
        console.log("VERSiON  sequence: ", petitionUpgradeable.VERSION());
    }

    // through the setup() function, the initializer modifier on initialize function(inside petitionLedgerImpl)
    // will be invoked.
    // this modifire has set the  $._initialized = 1
    // upgrade function(inside petitionLedgerImpl) invoke reInitializer(version) modifire and this modifire
    // checks if $._initialized  > version then otherwise reverts. So that the value that you set for
    // version(inside the petitionLedgerImpl contract as an immutable variable) should be biger than 1
    function test_UpgradeV3() public {
        V3_PetitionLedgerImpl v3Impl = new V3_PetitionLedgerImpl();
        vm.prank(INITIAL_OWNER);
        petitionUpgradeable.upgrade(address(v3Impl));
        assertEq(petitionUpgradeable.owner(), INITIAL_OWNER);
        assertEq(petitionUpgradeable.VERSION(), 3);
    }

    function test_UpgradeV4() public {
        V4_PetitionLedgerImpl v4Impl = new V4_PetitionLedgerImpl();
        vm.prank(INITIAL_OWNER);
        petitionUpgradeable.upgrade(address(v4Impl));
        assertEq(petitionUpgradeable.owner(), INITIAL_OWNER);
        assertEq(petitionUpgradeable.VERSION(), 4);
    }
}
