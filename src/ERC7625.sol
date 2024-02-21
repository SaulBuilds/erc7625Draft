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
import "./MetadataLib.sol"; 
import "./MetadataGenerator.sol";

/// @title ERC7625 Smart Contract Identification and Management
/// @notice Implements the IERC7625 interface for managing smart contracts with unique IDs, enabling functionalities such as locking and unlocking asset transfers, approving operators, and handling ownership and approvals of contracts securely within decentralized applications.
/// @dev Extends `ERC165` for interface detection, `Ownable` for ownership management, and `ReentrancyGuard` for preventing re-entrance attacks.
contract ERC7625 is IERC7625, ERC165, Ownable, ReentrancyGuard {
    /// @dev Instance of the MetadataGenerator contract used to generate metadata for contracts.
    MetadataGenerator public metadataGenerator;

    /// @dev Maps contract IDs to their respective owner addresses.
    mapping(uint256 => address) private _contractOwners;

    /// @dev Maps owner addresses to their list of owned contract IDs.
    mapping(address => uint256[]) private _ownedContracts;

    /// @dev Maps contract IDs to their lock status (true if locked).
    mapping(uint256 => bool) private _contractLocks;

    /// @dev Maps contract IDs to addresses approved for transferring them.
    mapping(uint256 => address) private _contractApprovals;

    /// @dev Maps contract IDs to their metadata URIs.
    mapping(uint256 => string) private _contractMetadataURIs;

    /// @notice Emitted when a contract is received by this contract.
    /// @param operator The address which called the function leading to this event.
    /// @param from The address from which the contract ID was transferred.
    /// @param contractId The ID of the contract being transferred.
    /// @param data Additional data sent with the transfer.
    event ContractReceived(
        address operator,
        address from,
        uint256 contractId,
        bytes data
    );

    /// @notice Emitted when a new contract instance is created.
    /// @param instance The address of the newly created contract instance.
    /// @param contractId The unique identifier of the contract.

    event ContractInstanceCreated(
        address indexed instance,
        uint256 indexed contractId
    );

    /// @notice Emitted when assets are locked or unlocked.
    /// @param owner The owner of the assets.
    /// @param contractId The ID of the contract whose assets are being locked or unlocked.
    /// @param locked The new lock status of the contract's assets.
    event AssetsLocked(address owner, uint256 contractId, bool locked);

    /// @dev Counter for generating unique contract IDs.
    uint256 private _currentContractId;

    /// @dev Fee required to create a new contract.
    uint256 public CONTRACT_CREATION_FEE = 1 ether;

    ///  @notice Initializes the contract by setting the deployer as the initial owner and configuring the metadata generator.
    ///  @param _metadataGenerator The address of the MetadataGenerator contract.
    constructor(address _metadataGenerator) Ownable(msg.sender) {
        metadataGenerator = MetadataGenerator(_metadataGenerator);
    }

    /// @notice Checks if the asset transfers for a given contract are locked.
    /// @param contractId The unique identifier of the contract.
    /// @return locked True if asset transfers for the contract are locked, false otherwise.
    function isContractLocked(
        uint256 contractId
    ) public view returns (bool locked) {
        return _contractLocks[contractId];
    }

    /// @notice Overrides `supportsInterface` to declare support for `IERC7625` and `ERC165` interfaces.
    /// @param interfaceId The interface identifier to check.
    /// @return True if the contract supports the given interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IERC7625).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Automatically locks asset transfers for the given contract ID.
    ///     Only callable by the owner of the contract ID. Emits an {AssetsLocked} event.
    /// @param contractId Unique identifier for the contract whose assets are to be locked.
    function autoLockAssetTransfers(uint256 contractId) internal {
        require(
            _contractOwners[contractId] == msg.sender,
            "ERC7625: Unauthorized"
        );
        _contractLocks[contractId] = true;
        emit AssetsLocked(msg.sender, true);
    }

    /// @dev Internally locks the transfers and withdrawals of a specific contract ID, preventing any changes.
    /// Emits an {AssetsLocked} event indicating the contract is locked.
    /// Requirements:
    ///   - The caller must be the owner of the contract ID.
    /// @param contractId The ID of the contract to lock.
    function _lockAssetTransfers(uint256 contractId) external onlyOwner {
        require(
            msg.sender == _contractOwners[contractId],
            "ERC7625: Unauthorized"
        );
        autoLockAssetTransfers(contractId);
    }

    /// @notice Unlocks asset transfers for a specific contract.
    /// @dev Only callable by the owner.
    /// @param contractId The unique identifier of the contract to unlock.
    function _unlockAssetTransfers(uint256 contractId) external onlyOwner {
        require(_contractLocks[contractId], "ERC7625: Contract is not locked");
        _contractLocks[contractId] = false;
        emit AssetsLocked(owner(), false);
    }

    /// @dev Returns the number of contracts owned by the specified address.
    /// @param owner Address to query the number of owned contracts.
    /// @return The number of owned contracts.
    function balanceOfContractId(
        address owner
    ) public view override returns (uint256) {
        return _ownedContracts[owner].length;
    }

    /// @dev See {IERC7625-ownerOfContractId}.
    function ownerOfContractId(
        uint256 contractId
    ) public view override returns (address) {
        return _contractOwners[contractId];
    }

    /// @notice Transfers a contract from one address to another with additional data.
    /// @dev Safely transfers the ownership of a given contract ID from one address to another address.
    ///        Before the transfer, the contract must be locked, ensuring no changes can occur during the process.
    ///        If the target address is a contract, it must implement `IERC7625Receiver` and return the
    ///        correct magic value upon successful receipt of the contract. The `data` parameter allows the
    ///        sender to pass arbitrary data to the receiver in the `onERC7625Received` call.
    ///        After the transfer, ownership is updated, and the new owner has the ability to unlock the contract.
    /// @param from The current owner of the contract.
    /// @param to The address to transfer the contract to. Must implement `IERC7625Receiver` if it is a contract.
    /// @param contractId The ID of the contract to transfer.
    /// @param data Additional data with no specified format, sent to the receiver.
    ///    require The caller must be the owner of the contract ID.
    ///    require The contract ID must be locked for transfer.
    ///    require `to` cannot be the zero address.
    ///    require If `to` is a contract, it must support the `IERC7625Receiver` interface.
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
        _contractOwners[contractId] = to;
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
        emit TransferContract(from, to, contractId);
    }

    /// @dev Approves an operator to transfer a specific contract ID on behalf of the msg.sender.
    ///     Automatically locks the asset transfers for the contract ID.
    /// @param approved Address to be approved for transferring the contract ID.
    /// @param contractId Contract ID for which the operator is approved.
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

    /// @dev Sets or revokes approval for an operator to manage all the sender's contracts, auto-locking them.
    /// @param operator The operator's address.
    /// @param approved Whether the approval is being set or revoked.
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
            }
        }
        emit ApprovalForTransferOfAll(msg.sender, operator, approved);
    }

    /// @notice Gets the approved address for a specific contract.
    /// @param contractId The unique identifier of the contract.
    /// @return The address approved to manage the contract.
    function getApproved(
        uint256 contractId
    ) public view override returns (address) {
        return _contractApprovals[contractId];
    }

    /// @notice Withdraws funds from the contract.
    /// @dev Only callable by the owner. Uses ReentrancyGuard to prevent reentrancy attacks.
    /// @param to The recipient address.
    /// @param amount The amount to withdraw.
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

    /**
     ///@dev Creates a new contract instance with the given properties and assigns it a unique contract ID.
     ///@param salt A unique salt to ensure the uniqueness of the deployed contract address.
     ///@return contractId The unique identifier assigned to the newly created contract.
     */
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
    ) external payable returns (uint256 contractId) {
        require(
            msg.value == CONTRACT_CREATION_FEE,
            "ERC7625: Creation fee is 1 ether"
        );
        string memory symbol = "SYMBOL"; // Define or replace with actual symbol

        bytes memory bytecode = abi.encodePacked(
            type(BasicNFT).creationCode,
            abi.encode(name, symbol)
        );

        address instance = Create2.deploy(0, salt, bytecode);
        require(instance != address(0), "Deployment failed");

        contractId = ++_currentContractId;
        _contractOwners[contractId] = msg.sender;
        metadataGenerator.createMetadata(
            instance,
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
     ///@dev Handles the receipt of an incoming contract. This function is called whenever the contract ID is transferred
     ///to this contract via `safeContractTransferFrom`. It can be used to enforce custom logic upon receiving the contract,
     ///such as verifying the transfer, updating internal state, or locking the transfer of the contract ID until further
     ///action is taken.
     *
     ///@param operator The address which initiated the transfer (typically the current owner).
     ///@param from The address from which the contract ID was transferred.
     ///@param contractId The ID of the contract being transferred.
     ///@param data Additional data sent with the transfer.
     ///@return bytes4 Magic value to signify the successful receipt of a contract ID.
     */
    function onContractReceived(
        address operator,
        address from,
        uint256 contractId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            _validateContractId(contractId),
            "ERC7625: Unexpected contract ID"
        );

        _contractOwners[contractId] = address(this); // Transfer ownership to this contract
        _ownedContracts[address(this)].push(contractId); // Record the contract as owned by this contract

        _contractLocks[contractId] = true;

        emit ContractReceived(operator, from, contractId, data);

        return this.onContractReceived.selector;
    }

    /// @dev Validates that a contract ID is both owned and currently locked, indicating it's prepared for a secure transfer.
    /// This ensures the integrity and controlled management of contract transfers.
    /// @param contractId The ID of the contract being validated.
    /// @return bool indicating whether the contractId is both owned and locked, ready for transfer.
    function _validateContractId(
        uint256 contractId
    ) internal view returns (bool) {
        bool isOwned = _contractOwners[contractId] != address(0);
        bool isLocked = _contractLocks[contractId];

        return isOwned && isLocked;
    }
}
