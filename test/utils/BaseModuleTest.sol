// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";
import { Safe } from "@safe-contracts/contracts/Safe.sol";
import { MyModule } from "../../src/MyModule.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import {SigUtils} from "./SigUtils.sol";
contract BaseModuleTest is BaseTest { 

    Safe internal mockSafe;
    MyModule internal module;
    MockERC20 internal unicorn;
    SigUtils internal sigUtils;

    uint256 internal alicePk = 0xa11ce;
    uint256 internal bobPk = 0xb0b;
    uint256 internal calPk = 0xca1;

    address internal alice = vm.addr(alicePk);
    address internal bob = vm.addr(bobPk);
    address internal cal = vm.addr(calPk);
    address internal mockContract = vm.addr(4);

    function _deployTestContracts() internal {
        mockSafe = new Safe();
        unicorn = new MockERC20();
        module = new MyModule(address(mockSafe),address(unicorn));
        sigUtils = new SigUtils(module.DOMAIN_SEPARATOR());

        bytes memory mockdata = abi.encode(
            address(mockSafe),address(mockSafe),address(mockSafe)
        );

        address[] memory owners = new address[](1);
        owners[0] = alice;
        mockSafe.setup(owners,1,mockContract,mockdata,address(0),mockContract,1, payable(mockContract));
        

    }

    function _getSignatureFrom(address _to, uint _amount, uint256 Pk) internal returns (bytes memory,bytes32){
        SigUtils.Transfer memory transfer = SigUtils.Transfer({
            to: _to,
            amount: _amount
        });
        bytes32 digest = sigUtils.getTypedDataHash(transfer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(Pk, digest);
        bytes memory signature = abi.encodePacked(r,s,v);
        return (signature, digest);
    }

    function _isOwnerofSafe(address owner) internal returns (bool){
        return mockSafe.isOwner(owner);
    }

    

}
