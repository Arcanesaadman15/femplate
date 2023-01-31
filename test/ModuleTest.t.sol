pragma solidity ^0.8.17;

import { BaseModuleTest } from "./utils/BaseModuleTest.sol";
import "../lib/forge-std/src/console.sol";

contract ModuleTest is BaseModuleTest {
    function setUp() public {
        _deployTestContracts();
    }

    function testTokenName() public {
         assertEq(unicorn.symbol(), "Unicorn");
    }

//Test if module can be enabled by safe
    function testEnableModule() public subtest{
        mockSafe.enableModule(address(module));
        assert(mockSafe.isModuleEnabled(address(module)));
    }

//Test if unicorn can be transfered from the safe using sig of an owner
    function testTransfeUsingSignature() public subtest {
        mockSafe.enableModule(address(module));
        assert(mockSafe.isModuleEnabled(address(module)));
        unicorn.mintTo(alice);

        vm.prank(alice);
        unicorn.transfer(address(mockSafe),(100000));
        vm.stopPrank();

        assert(unicorn.balanceOf(address(mockSafe))==100000);
        assert(unicorn.balanceOf(bob)==0);
        assert(_isOwnerofSafe(alice));
        (bytes memory signature, bytes32 digest) = _getSignatureFrom(bob, 100, alicePk);

        vm.prank(bob);
        module.withdrawWithSignature(bob,100,1,signature,digest);
        assert(unicorn.balanceOf(bob)==100);
        vm.stopPrank();
    }

//Test signature does not work from accounts that are not owners of the safe
    function testFailTransfeUsingSignature() public subtest {
        mockSafe.enableModule(address(module));
        assert(mockSafe.isModuleEnabled(address(module)));
        unicorn.mintTo(alice);

        vm.prank(alice);
        unicorn.transfer(address(mockSafe),(100000));
        vm.stopPrank();

        assert(unicorn.balanceOf(address(mockSafe))==100000);
        assert(unicorn.balanceOf(bob)==0);
        assert(_isOwnerofSafe(alice));
        (bytes memory signature, bytes32 digest) = _getSignatureFrom(bob, 100, bobPk);

        vm.prank(bob);
        module.withdrawWithSignature(bob,100,1,signature,digest);
        assert(unicorn.balanceOf(bob)==100);
        vm.stopPrank();
    }
}