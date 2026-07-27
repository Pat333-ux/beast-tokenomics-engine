// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Beast System 3.0 — Governance Token
 * Symbol: GOVNWO
 *
 * Purpose:
 * - Represents authority inside New World Order DAO
 * - Controls voting, upgrades, treasury allocation
 * - Minting restricted to governance-approved roles
 */

interface IVerificationOracle {
    function getGovernanceScore(address user) external view returns (uint256);
}

contract GovernanceToken {
    string public name = "New World Order Governance Token";
    string public symbol = "GOVNWO";
    uint8 public decimals = 18;

    address public owner;
    IVerificationOracle public oracle;

    // governance-controlled parameters
    uint256 public baseVotingPower;     // baseline voting weight
    uint256 public governanceMultiplier; // multiplier applied to oracle score

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public authorizedMinters;
    mapping(address => bool) public governanceCouncil; // elevated authority

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event MinterUpdated(address indexed minter, bool allowed);
    event CouncilUpdated(address indexed member, bool allowed);
    event VotingParamsUpdated(uint256 basePower, uint256 multiplier);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMinter() {
        require(authorizedMinters[msg.sender], "Not authorized minter");
        _;
    }

    modifier onlyCouncil() {
        require(governanceCouncil[msg.sender], "Not council member");
        _;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IVerificationOracle(_oracle);

        // default governance parameters
        baseVotingPower = 1e18;
        governanceMultiplier = 2e18; // governance score is weighted heavily
    }

    // governance council controls voting parameters
    function updateVotingParams(
        uint256 _basePower,
        uint256 _multiplier
    ) external onlyCouncil {
        baseVotingPower = _basePower;
        governanceMultiplier = _multiplier;
        emit VotingParamsUpdated(_basePower, _multiplier);
    }

    // owner assigns minters (tokenomics engine, treasury vault, etc.)
    function setMinter(address _minter, bool _allowed) external onlyOwner {
        authorizedMinters[_minter] = _allowed;
        emit MinterUpdated(_minter, _allowed);
    }

    // owner assigns governance council members
    function setCouncil(address _member, bool _allowed) external onlyOwner {
        governanceCouncil[_member] = _allowed;
        emit CouncilUpdated(_member, _allowed);
    }

    /**
     * Minting logic:
     * Governance tokens are minted based on governance score:
     *
     * M = baseVotingPower + (governanceScore * governanceMultiplier)
     *
     * This ensures governance authority grows with verified contributions.
     */
    function mintFromGovernanceScore(address _user) external onlyMinter {
        uint256 score = oracle.getGovernanceScore(_user);
        uint256 amount = baseVotingPower + (score * governanceMultiplier);

        require(amount > 0, "No governance tokens to mint");

        _mint(_user, amount);
    }

    function _mint(address _to, uint256 _value) internal {
        balanceOf[_to] += _value;
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    // standard transfer
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Voting power calculation:
     * VP = balance + (governanceScore * governanceMultiplier)
     */
    function votingPower(address _user) external view returns (uint256) {
        uint256 score = oracle.getGovernanceScore(_user);
        return balanceOf[_user] + (score * governanceMultiplier);
    }
}
