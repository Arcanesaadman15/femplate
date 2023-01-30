// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "@zodiac/contracts/core/Module.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Safe } from "@safe-contracts/contracts/Safe.sol";


contract MyModule is Module {
    using ECDSA for bytes32;

    address public token;
    Safe public safe;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    uint256 internal immutable _CHAIN_ID;

    mapping(bytes32 => bool) public executed;

    constructor(address _owner, address _token) {
        bytes memory initializeParams = abi.encode(_owner, _token);
        setUp(initializeParams);
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
        _CHAIN_ID = block.chainid;
    }

    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (address _owner, address _token) = abi.decode(initializeParams, (address, address));

        token = _token;
        setAvatar(_owner);
        setTarget(_owner);
        transferOwnership(_owner);
        safe = Safe(payable(_owner));
    }

    function withdrawWithSignature(address _to, uint amount, uint nonce, bytes memory _sigs,bytes32 digest) external {
        bytes32 txHash = getTxHash(_to, amount, nonce);

        require(!executed[txHash], "tx executed");
        require(_checkSigs(_sigs,digest), "invalid sig");

        bytes memory data = abi.encodeWithSelector(0xa9059cbb, _to, amount);
        exec(token, 0,data , Enum.Operation.Call);
    }

    function _checkSigs(bytes memory _sigs,bytes32 digest) private view returns (bool) {
        address signatory = ECDSA.recover(digest, _sigs);
        bool valid = safe.isOwner(signatory);
        return valid;
    }

    function getTxHash(address _to, uint _amount,uint _nonce) public view returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256("transfer(address to, uint256 amount)"),_to, _amount,_nonce));
    }

    function _deriveEIP712Digest(bytes32 hash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_DOMAIN_SEPARATOR, hash);
    }


    /// @dev Returns the domain separator tied to the contract.
    /// @return 256-bit domain separator tied to this contract.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    /// @dev Generates an EIP-712 domain separator.
    /// @return A 256-bit domain separator tied to this contract.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("name")),
                keccak256(bytes("v1")),
                block.chainid,
                address(this)
            )
        );
    }

}