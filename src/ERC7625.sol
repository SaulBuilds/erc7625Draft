// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "./IERC7625.sol";
import "./sampleContract.sol";
import "./MetadataLib.sol"; // Import the Metadata library
import "./MetadataGenerator.sol"; 
/**
 * @title ERC7625 Smart Contract Identification and Management
 * @dev Implements the IERC7625 interface to manage smart contracts with unique IDs. This contract provides
 * functionality to create unique contract IDs, lock and unlock asset transfers, approve operators for transfers,
 * and manage ownership and approvals of contract IDs. It's designed for managing assets and their ownership
 * securely within a decentralized application.
 */
contract ERC7625 is IERC7625, ERC165, Ownable, ReentrancyGuard {
    MetadataGenerator public metadataGenerator; // Instance of the MetadataGenerator contract

    /// @notice Mapping from contract ID to owner address
    mapping(uint256 => address) private _contractOwners;

    /// @notice Mapping from owner address to list of owned contract IDs
    mapping(address => uint256[]) private _ownedContracts;

    /// @notice  Mapping from contract ID to its lock status (true if locked)
    mapping(uint256 => bool) private _contractLocks;

    /// @notice Mapping from contract ID to approved address for transfer
    mapping(uint256 => address) private _contractApprovals;

    /// @notice New mapping for contract metadata URIs
    mapping(uint256 => string) private _contractMetadataURIs;

    event ContractReceived(
        address operator,
        address from,
        uint256 contractId,
        bytes data
    );
    event ContractInstanceCreated(
        address indexed instance,
        uint256 indexed contractId
    );
    event AssetsLocked(address owner, uint256 contractId, bool locked);

    /// @notice Counter to generate unique contract IDs
    uint256 private _currentContractId;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _metadataGenerator) Ownable(msg.sender) {
        metadataGenerator = MetadataGenerator(_metadataGenerator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IERC7625).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function autoLockAssetTransfers(uint256 contractId) internal {
        require(
            _contractOwners[contractId] == msg.sender,
            "ERC7625: Unauthorized"
        );
        _contractLocks[contractId] = true;
        emit AssetsLocked(msg.sender, true);
    }

    /**
     * @dev Internally locks the transfers and withdrawals of a specific contract ID, preventing any changes.
     * Emits an {AssetsLocked} event indicating the contract is locked.
     *
     * Requirements:
     * - The caller must be the owner of the contract ID.
     *
     * @param contractId The ID of the contract to lock.
     */
    function _lockAssetTransfers(uint256 contractId) external onlyOwner {
        require(
            msg.sender == _contractOwners[contractId],
            "ERC7625: Unauthorized"
        );
        autoLockAssetTransfers(contractId);
    }

    /**
     * @notice Unlocks asset transfers for a specific contract.
     * @dev Only callable by the owner.
     * @param contractId The unique identifier of the contract to unlock.
     */
    function _unlockAssetTransfers(uint256 contractId) external onlyOwner {
        require(_contractLocks[contractId], "ERC7625: Contract is not locked");
        _contractLocks[contractId] = false;
        emit AssetsLocked(owner(), false);
    }

    /**
     * @dev See {IERC7625-balanceOfContractId}.
     */
    function balanceOfContractId(
        address owner
    ) public view override returns (uint256) {
        return _ownedContracts[owner].length;
    }

    /**
     * @dev See {IERC7625-ownerOfContractId}.
     */
    function ownerOfContractId(
        uint256 contractId
    ) public view override returns (address) {
        return _contractOwners[contractId];
    }

    /**
     * @notice Transfers a contract from one address to another with additional data.
     * @dev Safely transfers the ownership of a given contract ID from one address to another address.
     *
     * Before the transfer, the contract must be locked, ensuring no changes can occur during the process.
     * If the target address is a contract, it must implement `IERC7625Receiver` and return the
     * correct magic value upon successful receipt of the contract. The `data` parameter allows the
     * sender to pass arbitrary data to the receiver in the `onERC7625Received` call.
     * After the transfer, ownership is updated, and the new owner has the ability to unlock the contract.
     *
     * @param from The current owner of the contract.
     * @param to The address to transfer the contract to. Must implement `IERC7625Receiver` if it is a contract.
     * @param contractId The ID of the contract to transfer.
     * @param data Additional data with no specified format, sent to the receiver.
     *
     * require The caller must be the owner of the contract ID.
     * require The contract ID must be locked for transfer.
     * require `to` cannot be the zero address.
     * require If `to` is a contract, it must support the `IERC7625Receiver` interface.
     */
    function safeContractTransferFrom(
        address from,
        address to,
        uint256 contractId,
        bytes calldata data
    ) public payable override nonReentrant {
        require(
            _contractOwners[contractId] == from,
            "ERC7625: Caller is not owner"
        );
        require(
            _contractLocks[contractId],
            "ERC7625: Contract is not locked for transfer"
        );
        require(to != address(0), "ERC7625: Transfer to the zero address");

        // Update ownership to the new owner
        _contractOwners[contractId] = to;

        // If 'to' is a contract, try calling onERC7625Received
        if (to.code.length > 0) {
            require(
                IERC7625Receiver(to).onERC7625Received(
                    msg.sender,
                    from,
                    contractId,
                    data
                ) == IERC7625Receiver.onERC7625Received.selector,
                "ERC7625: Transfer to non IERC7625Receiver implementer"
            );
        }

        // Keep the contract locked, leaving it to the new owner to unlock
        emit TransferContract(from, to, contractId);
    }

    function approveOperatorToTransfer(
        address approved,
        uint256 contractId
    ) public payable override {
        require(
            _contractOwners[contractId] == msg.sender,
            "ERC7625: Caller is not owner"
        );
        _contractApprovals[contractId] = approved;
        autoLockAssetTransfers(contractId);
        emit ApprovalForTransfer(msg.sender, approved, contractId);
    }

    /**
     * @dev Sets or revokes approval for an operator to manage all the sender's contracts, auto-locking them.
     * @param operator The operator's address.
     * @param approved Whether the approval is being set or revoked.
     */
    function setApprovalForAllContracts(
        address operator,
        bool approved
    ) public onlyOwner {
        uint256[] storage ownerContracts = _ownedContracts[msg.sender];
        for (uint256 i = 0; i < ownerContracts.length; i++) {
            uint256 contractId = ownerContracts[i];
            _contractApprovals[contractId] = approved ? operator : address(0);
            if (approved) {
                autoLockAssetTransfers(contractId);
            } // Consider implementing autoUnlockAssetTransfers if you want to unlock when revoking approval
        }
        emit ApprovalForTransferOfAll(msg.sender, operator, approved);
    }

    /**
     * @notice Gets the approved address for a specific contract.
     * @param contractId The unique identifier of the contract.
     * @return The address approved to manage the contract.
     */
    function getApproved(
        uint256 contractId
    ) public view override returns (address) {
        return _contractApprovals[contractId];
    }

    /**
     * @notice Withdraws funds from the contract.
     * @dev Only callable by the owner. Uses ReentrancyGuard to prevent reentrancy attacks.
     * @param to The recipient address.
     * @param amount The amount to withdraw.
     */

    function withdraw(
        address to,
        uint256 amount
    ) public onlyOwner nonReentrant {
        require(
            address(this).balance >= amount,
            "ERC7625: Insufficient balance"
        );
        payable(to).transfer(amount);
        emit Withdraw(to, amount);
    }

    function createContract(
        bytes32 salt,
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
        string memory mappingsJSON
    ) external onlyOwner returns (uint256 contractId) {
        // Assuming 'name' and a previously undeclared 'symbol' variable are meant for BasicNFT
        string memory symbol = "SYMBOL"; // Define or replace with actual symbol

        bytes memory bytecode = abi.encodePacked(
            type(BasicNFT).creationCode,
            abi.encode(name, symbol)
        );

        address instance = Create2.deploy(0, salt, bytecode);
        require(instance != address(0), "Deployment failed");

        contractId = ++_currentContractId;
        _contractOwners[contractId] = msg.sender;
        // This line had an error due to 'metadata' being undeclared
        // _contractMetadataURIs[contractId] = string(metadata);
        // Correct approach: Store metadata URI or use MetadataGenerator to handle metadata

        // Example of creating metadata using MetadataGenerator (ensure parameters match your method signature in MetadataGenerator)
        metadataGenerator.createMetadata(
            instance, // Address of the newly created contract instance
            contractId,
            name,
            description,
            image,
            externalLink,
            contractType,
            creator,
            network,
            sourceCodeLink,
            license,
            attributesJSON,
            functionsJSON,
            eventsJSON,
            mappingsJSON
        );

        emit ContractInstanceCreated(instance, contractId);
    }

    /**
     * @dev Handles the receipt of an incoming contract. This function is called whenever the contract ID is transferred
     * to this contract via `safeContractTransferFrom`. It can be used to enforce custom logic upon receiving the contract,
     * such as verifying the transfer, updating internal state, or locking the transfer of the contract ID until further
     * action is taken.
     *
     * @param operator The address which initiated the transfer (typically the current owner).
     * @param from The address from which the contract ID was transferred.
     * @param contractId The ID of the contract being transferred.
     * @param data Additional data sent with the transfer.
     * @return bytes4 Magic value to signify the successful receipt of a contract ID.
     */
    function onContractReceived(
        address operator,
        address from,
        uint256 contractId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Example validation or action. Real implementation would depend on specific requirements.
        // Verify that the contractId is expected or conforms to certain criteria
        require(
            _validateContractId(contractId),
            "ERC7625: Unexpected contract ID"
        );

        // Update internal state to reflect the receipt of the contractId
        _contractOwners[contractId] = address(this); // Transfer ownership to this contract
        _ownedContracts[address(this)].push(contractId); // Record the contract as owned by this contract

        // Optionally, lock the contractId to prevent further transfers until explicitly unlocked
        _contractLocks[contractId] = true;

        emit ContractReceived(operator, from, contractId, data);

        return this.onContractReceived.selector;
    }

    /**
     * @dev Validates that a contract ID is both owned and currently locked, indicating it's prepared for a secure transfer.
     * This ensures the integrity and controlled management of contract transfers.
     *
     * @param contractId The ID of the contract being validated.
     * @return bool indicating whether the contractId is both owned and locked, ready for transfer.
     */
    function _validateContractId(
        uint256 contractId
    ) internal view returns (bool) {
        // Check that the contract ID is owned, indicating it's not a new or unassigned ID.
        bool isOwned = _contractOwners[contractId] != address(0);

        // Check that the contract ID is currently locked, indicating it's in a secure state for transfer.
        bool isLocked = _contractLocks[contractId];

        // The contract ID is valid for transfer if it's both owned and locked.
        return isOwned && isLocked;
    }
}
