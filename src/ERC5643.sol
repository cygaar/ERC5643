// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5643.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();

contract ERC5643 is ERC721, IERC5643 {
    mapping(uint256 => uint64) private _expirations;

    uint64 _minimumRenewalDuration;
    uint64 _maximumRenewalDuration;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function renewSubscription(uint256 tokenId, uint64 duration)
        external
        payable
        virtual
    {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Caller is not owner nor approved"
        );

        if (duration < _minimumRenewalDuration) {
            revert RenewalTooShort();
        } else if (
            _maximumRenewalDuration > 0 && duration > _maximumRenewalDuration
        ) {
            revert RenewalTooLong();
        }

        if (msg.value < _getRenewalPrice(duration)) {
            revert InsufficientPayment();
        }

        _updateSubscription(tokenId, duration);
    }

    function _updateSubscription(uint256 tokenId, uint64 duration)
        internal
        virtual
    {
        uint64 currentExpiration = _expirations[tokenId];
        uint64 newExpiration;
        if (currentExpiration == 0) {
            newExpiration = uint64(block.timestamp) + duration;
        } else {
            if (!_isRenewable(tokenId)) {
                revert SubscriptionNotRenewable();
            }
            newExpiration = currentExpiration + duration;
        }

        _expirations[tokenId] = newExpiration;

        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    function _getRenewalPrice(uint64 duration)
        internal
        view
        virtual
        returns (uint256)
    {
        return 0;
    }

    function cancelSubscription(uint256 tokenId) external payable virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Caller is not owner nor approved"
        );

        delete _expirations[tokenId];

        emit SubscriptionUpdate(tokenId, 0);
    }

    function expiresAt(uint256 tokenId)
        external
        view
        virtual
        returns (uint64)
    {
        return _expirations[tokenId];
    }

    function isRenewable(uint256 tokenId)
        external
        view
        virtual
        returns (bool)
    {
        return _isRenewable(tokenId);
    }

    function _isRenewable(uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }

    function _setMinimumRenewalDuration(uint64 duration) internal virtual {
        _minimumRenewalDuration = duration;
    }

    function _setMaximumRenewalDuration(uint64 duration) internal virtual {
        _maximumRenewalDuration = duration;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC5643).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
