//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";



/**
 * @title Interface for ERC7625 Smart Contract Identification and Management
 * @dev Extends ERC165. Defines an interface for managing unique smart contract IDs and integrates with ERC20 and ERC721 for asset tracking.
 */
interface IERC7625 is IERC165 {
    /**
     * @dev Emitted when a contract's asset transfers are locked or unlocked.
     * @param owner Address of the contract owner.
     * @param locked Status of the asset lock (true if locked).
     */
    event AssetsLocked(address indexed owner, bool locked);

    /**
     * @dev Emitted upon the transfer of a contract from one address to another.
     * @param from Address of the current owner.
     * @param to Address of the new owner.
     * @param contractId Unique identifier of the contract being transferred.
     */
    event TransferContract(address indexed from, address indexed to, uint256 indexed contractId);

    /**
     * @dev Emitted when a new operator is approved to manage a specific contract ID.
     * @param owner Address of the contract owner.
     * @param approved Address of the approved operator.
     * @param contractId Unique identifier of the contract.
     */
    event ApprovalForTransfer(address indexed owner, address indexed approved, uint256 indexed contractId);

    /**
     * @dev Emitted when an operator is granted or revoked permission to manage all contracts of an owner.
     * @param owner Address of the contract owner.
     * @param operator Address of the operator.
     * @param approved True if the operator is approved, false otherwise.
     */
    event ApprovalForTransferOfAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Emitted upon withdrawal of funds, specifying the beneficiary and the amount withdrawn.
     * @param to Beneficiary address.
     * @param amount Amount of funds withdrawn.
     */
    event Withdraw(address indexed to, uint256 amount);

    /**
     * @notice Locks all asset transfers and withdrawals for a given contract ID.
     * @param contractId Unique identifier of the contract.
     */
    function _lockAssetTransfers(uint256 contractId) external;
    
    /**
     * @notice Unlocks all asset transfers and withdrawals for a given contract ID.
     * @param contractId Unique identifier of the contract.
     */
    function _unlockAssetTransfers(uint256 contractId) external;
    
    /**
     * @notice Returns the number of contracts owned by a given address.
     * @param owner Address to query the balance for.
     * @return Number of contracts owned.
     */
    function balanceOfContractId(address owner) external view returns (uint256);

    /**
     * @notice Returns the owner of a specified contract ID.
     * @param contractId Unique identifier of the contract.
     * @return Address of the owner.
     */
    function ownerOfContractId(uint256 contractId) external view returns (address);

    /**
     * @notice Transfers a contract to another address along with additional data.
     * @param from Current owner of the contract.
     * @param to Recipient address.
     * @param contractId Unique identifier of the contract.
     * @param data Additional transfer data.
     */
    function safeContractTransferFrom(address from, address to, uint256 contractId, bytes calldata data) external payable;

    /**
     * @notice Approves another address to manage the specified contract.
     * @param approved Address to be approved.
     * @param contractId Unique identifier of the contract.
     */
    function approveOperatorToTransfer(address approved, uint256 contractId) external payable;

    /**
     * @notice Sets or revokes approval for an operator to manage all contracts of the sender.
     * @param operator Address of the operator.
     * @param approved Approval status.
     */
    function setApprovalForAllContracts(address operator, bool approved) external;

    /**
     * @notice Returns the approved address for a specified contract ID.
     * @param contractId Unique identifier of the contract.
     * @return Address currently approved.
     */
    function getApproved(uint256 contractId) external view returns (address);

    /**
     * @notice Withdraws funds from the contract to a specified beneficiary.
     * @param to Beneficiary address.
     * @param amount Amount to withdraw.
     */
    function withdraw(address to, uint256 amount) external;

    /**
     * @notice Creates a new contract instance and returns its unique ID.
     * @return Unique ID of the newly created contract instance.
     */
    function createContract(bytes32 salt,
        string memory name,
        string memory description,
        string memory image,
        string memory externalLink,
        string memory contractType,
        string memory creator,
        string memory network,
        string memory sourceCodeLink,
        string memory license,
        string memory attributesJSON,
        string memory functionsJSON,
        string memory eventsJSON,
        string memory mappingsJSON) external returns (uint256);

    /**
     * @notice Handles the receipt of an ERC7625 contract.
     * @param operator Address that initiated the transfer.
     * @param from Previous owner of the contract.
     * @param contractId Unique identifier of the contract being transferred.
     * @param data Additional data with no specific format.
     * @return Indicator for successful receipt.
     */
    function onContractReceived(address operator, address from, uint256 contractId, bytes calldata data) external returns(bytes4);
}

/**
 * @title Receiver Interface for ERC7625 Smart Contract Identification and Management
 * @dev Interface for contracts wishing to support safe transfers of ERC7625 contract IDs.
 */
interface IERC7625Receiver {
    /**
     * @notice Handles the receipt of a contract ID.
     * @param operator Address that initiated the transfer.
     * @param from Previous owner of the contract.
     * @param contractId Unique identifier of the contract being transferred.
     * @param data Additional data sent along with the transfer.
     * @return bytes4 Returns `bytes4(keccak256("onERC7625Received(address,address,uint256,bytes)"))` when the transfer is accepted.
     */
    function onERC7625Received(address operator, address from, uint256 contractId, bytes calldata data) external returns (bytes4);
}