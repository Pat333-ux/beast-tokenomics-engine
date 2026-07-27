// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * New World Order Health & Wellbeing Token
 * Symbol: WELL
 *
 * Purpose:
 * - Represents verified wellbeing improvements
 * - Minted from health, service, and community metrics
 * - Non-transferable (soulbound)
 * - Used for wellbeing rewards, access rights, and stability metrics
 */

interface IWellbeingOracle {
    function getHealthScore(address user) external view returns (uint256);
    function getServiceScore(address user) external view returns (uint256);
    function getCommunityScore(address user) external view returns (uint256);
}

contract WellbeingToken {
    string public name = "New World Order Wellbeing Token";
    string public symbol = "WELL";
    uint8 public decimals = 18;

    address public owner;
    IWellbeingOracle public oracle;

    // governance-controlled weights
    uint256 public weightHealth;     // Wh
    uint256 public weightService;    // Ws
    uint256 public weightCommunity;  // Wc

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public authorizedMinters;

    event Mint(address indexed to, uint256 value);
    event WeightsUpdated(uint256 Wh, uint256 Ws, uint256 Wc);
    event MinterUpdated(address indexed minter, bool allowed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMinter() {
        require(authorizedMinters[msg.sender], "Not authorized minter");
        _;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IWellbeingOracle(_oracle);

        // default weights (governance can update)
        weightHealth = 2e18;     // health improvements weighted highest
        weightService = 1e18;    // community service
        weightCommunity = 1e18;  // social contribution
    }

    // governance updates wellbeing weights
    function setWeights(
        uint256 _wh,
        uint256 _ws,
        uint256 _wc
    ) external onlyOwner {
        weightHealth = _wh;
        weightService = _ws;
        weightCommunity = _wc;
        emit WeightsUpdated(_wh, _ws, _wc);
    }

    // owner assigns minters (verification layer, tokenomics engine)
    function setMinter(address _minter, bool _allowed) external onlyOwner {
        authorizedMinters[_minter] = _allowed;
        emit MinterUpdated(_minter, _allowed);
    }

    /**
     * Minting logic:
     * WELL = (HealthScore * Wh) + (ServiceScore * Ws) + (CommunityScore * Wc)
     *
     * This ensures wellbeing improvements directly increase WELL supply.
     */
    function mintFromWellbeing(address _user) external onlyMinter {
        uint256 H = oracle.getHealthScore(_user);
        uint256 S = oracle.getServiceScore(_user);
        uint256 C = oracle.getCommunityScore(_user);

        uint256 amount =
            (H * weightHealth) +
            (S * weightService) +
            (C * weightCommunity);

        require(amount > 0, "No WELL to mint");

        _mint(_user, amount);
    }

    // soulbound mint
    function _mint(address _to, uint256 _value) internal {
        balanceOf[_to] += _value;
        emit Mint(_to, _value);
    }

    // soulbound: cannot transfer
    function transfer(address, uint256) external pure returns (bool) {
        revert("WELL is soulbound and non-transferable");
    }
}
