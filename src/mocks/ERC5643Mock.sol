// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC5643.sol";

contract ERC5643Mock is Ownable, ERC5643 {
    // Roughly calculates to 0.1 ether per 30 days
    uint256 public pricePerSecond = 38580246913;

    bool renewable;

    constructor(string memory name_, string memory symbol_)
        ERC5643(name_, symbol_)
    {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function mintWithSubscription(address to, uint256 tokenId, uint64 duration)
        public
    {
        _mint(to, tokenId);
        _extendSubscription(tokenId, duration);
    }

    function _getRenewalPrice(uint256 tokenId, uint64 duration)
        internal
        view
        override
        returns (uint256)
    {
        return duration * pricePerSecond;
    }

    function _isRenewable(uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        return renewable;
    }

    function setRenewable(bool _renewable) external onlyOwner {
        renewable = _renewable;
    }

    function setMinimumRenewalDuration(uint64 duration) external onlyOwner {
        _setMinimumRenewalDuration(duration);
    }

    function setMaximumRenewalDuration(uint64 duration) external onlyOwner {
        _setMaximumRenewalDuration(duration);
    }

    /**
     * @dev This function is used soley for testing purposes and shouldn't be used
     * in a standalone fashion.
     */
    function extendSubscription(uint256 tokenId, uint64 duration) external {
        _extendSubscription(tokenId, duration);
    }
}
