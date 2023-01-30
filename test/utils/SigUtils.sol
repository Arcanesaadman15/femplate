// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("transfer(address to, uint256 amount)");
    bytes32 public constant TRANSFER_TYPEHASH = 
        keccak256("transfer(address to, uint256 amount)");

    struct Transfer {
        address to;
        uint256 amount;
    }

    // computes the hash of a permit
    function getStructHash(Transfer memory _transfer)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TRANSFER_TYPEHASH,
                    _transfer.to,
                    _transfer.amount
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Transfer memory _transfer)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_transfer)
                )
            );
    }
}
