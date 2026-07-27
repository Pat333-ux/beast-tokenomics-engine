// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * LUCR = Growth of People → Growth of System → Growth of Value
 * Minting is gated by verified scores from the Beast Verification Layer.
 */
interface IVerificationOracle {
    function getContributionScore(address user) external view returns (uint256);
    function getGovernanceScore(address user) external view returns (uint256);
    function getWellbeingScore(address user) external view returns (uint256);
}

contract LUCRToken {
    string public name = "LUCR Utility Token";
    string public symbol = "LUCR";
    uint8 public decimals = 18;

    address public owner;
    IVerificationOracle public oracle;

    // weights set by governance (beast-core-governance)
    uint256 public weightContribution; // Wc
    uint256 public weightGovernance;   // Wg
    uint256 public weightWellbeing;    // Wh

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public minters; // allowed system contracts

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event WeightsUpdated(uint256 Wc, uint256 Wg, uint256 Wh);
    event MinterUpdated(address indexed minter, bool allowed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Not minter");
        _;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IVerificationOracle(_oracle);

        // sane defaults, can be updated by governance
        weightContribution = 1e18;
        weightGovernance   = 1e18;
        weightWellbeing    = 1e18;
    }

    function setWeights(
        uint256 _wc,
        uint256 _wg,
        uint256 _wh
    ) external onlyOwner {
        weightContribution = _wc;
        weightGovernance   = _wg;
        weightWellbeing    = _wh;
        emit WeightsUpdated(_wc, _wg, _wh);
    }

    function setMinter(address _minter, bool _allowed) external onlyOwner {
        minters[_minter] = _allowed;
        emit MinterUpdated(_minter, _allowed);
    }

    /**
     * Core LUCR minting function:
     * M = (C * Wc) + (G * Wg) + (H * Wh)
     * Called by a system minter (e.g., beast-tokenomics-engine service)
     */
    function mintFromScores(address _user) external onlyMinter {
        uint256 C = oracle.getContributionScore(_user);
        uint256 G = oracle.getGovernanceScore(_user);
        uint256 H = oracle.getWellbeingScore(_user);

        uint256 amount =
            (C * weightContribution) +
            (G * weightGovernance) +
            (H * weightWellbeing);

        require(amount > 0, "No LUCR to mint");

        _mint(_user, amount);
    }

    function _mint(address _to, uint256 _value) internal {
        balanceOf[_to] += _value;
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    // simple transfer (LUCR can later be restricted/activated by governance)
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
