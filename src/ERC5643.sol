// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5643.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();
error InvalidTokenId();
error CallerNotOwnerNorApproved();

contract ERC5643 is ERC721, IERC5643 {
    mapping(uint256 => uint64) private _expirations;

    uint64 private minimumRenewalDuration;
    uint64 private maximumRenewalDuration;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev See {IERC5643-renewSubscription}.
     */
    function renewSubscription(uint256 tokenId, uint64 duration)
        external
        payable
        virtual
    {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            assembly {
                // revert CallerNotOwnerNorApproved()
                mstore(0, 0x4fb505aa)
                revert(0x1c, 0x04)
            }
        }

        uint64 _minRenewalDuration;
        uint64 _maxRenewalDuration;

        assembly {

            // Compiler performs a single SLOAD as values are packed in the same slot.

            // Load `minimumRenewalDuration` at offset 0.
            _minRenewalDuration := and(sload(minimumRenewalDuration.slot), 0xffffffffffffffff)
            // Load `maximumRenewalDuration` at offset 8.
            _maxRenewalDuration := and(shr(64, sload(maximumRenewalDuration.slot)), 0xffffffffffffffff)

            // Equivalent to `duration < minimumRenewalDuration`
            if lt(duration, _minRenewalDuration) {
                // revert RenewalTooShort()
                mstore(0, 0xe3061ca9)
                revert(0x1c, 0x04)
            }

            // Equivalent to `maximumRenewalDuration != 0 && duration > maximumRenewalDuration`
            if iszero(iszero(_maxRenewalDuration)) {
                if gt(duration, _maxRenewalDuration) {
                    // revert RenewalTooLong()
                    mstore(0, 0x3b44021f)
                    revert(0x1c, 0x04)
                }
            }
        }

        if (msg.value < _getRenewalPrice(tokenId, duration)) {
            assembly {
                // revert InsufficientPayment()
                mstore(0, 0xcd1c8867)
                revert(0x1c, 0x04)
            }
        }

        _extendSubscription(tokenId, duration);
    }

    /**
     * @dev Extends the subscription for `tokenId` for `duration` seconds.
     * If the `tokenId` does not exist, an error will be thrown.
     * If a token is not renewable, an error will be thrown.
     * Emits a {SubscriptionUpdate} event after the subscription is extended.
     */
    function _extendSubscription(uint256 tokenId, uint64 duration)
        internal
        virtual
    {
        if (!_exists(tokenId)) {
            assembly {
                // revert InvalidTokenId()
                mstore(0, 0x3f6cc768)
                revert(0x1c, 0x04)
            }
        }

        uint64 currentExpiration;

        // Equivalent to `_currentExpiration = _expirations[tokenId]`
        assembly {
            mstore(0, tokenId)
            mstore(0x20, _expirations.slot)
            currentExpiration := and(sload(keccak256(0, 0x40)), 0xffffffffffffffff)
        }

        uint64 newExpiration;
        if ((currentExpiration == 0) || (currentExpiration < block.timestamp)) {
            newExpiration = uint64(block.timestamp) + duration;
        } else {
            if (!_isRenewable(tokenId)) {
                assembly {
                    // revert SubscriptionNotRenewable()
                    mstore(0, 0x8b9bff45)
                    revert(0x1c, 0x04)
                }
            }
            newExpiration = currentExpiration + duration;
        }

        assembly {
            // Equivalent to `_expirations[tokenId] = newExpiration`
            mstore(0, tokenId)
            mstore(0x20, _expirations.slot)
            sstore(keccak256(0, 0x40), newExpiration)

            // Store expiration in memory
            mstore(0, newExpiration)

            // Equivalent to `emit SubscriptionUpdate(tokenId, newExpiration)`
            log2(
                0, 0x20,
                // SubscriptionUpdate(uint256,uint64)
                0x2ec2be2c4b90c2cf13ecb6751a24daed6bb741ae5ed3f7371aabf9402f6d62e8,
                tokenId
            )
        }
    }

    /**
     * @dev Gets the price to renew a subscription for `duration` seconds for
     * a given tokenId. This value is defaulted to 0, but should be overridden in
     * implementing contracts.
     */
    function _getRenewalPrice(uint256 tokenId, uint64 duration)
        internal
        view
        virtual
        returns (uint256)
    {
        return 0;
    }

    /**
     * @dev See {IERC5643-cancelSubscription}.
     */
    function cancelSubscription(uint256 tokenId) external payable virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            assembly {
                // revert CallerNotOwnerNorApproved()
                mstore(0, 0x4fb505aa)
                revert(0x1c, 0x04)
            }
        }

        assembly {
            // Equivalent to `delete _expirations[tokenId]`
            mstore(0, tokenId)
            mstore(0x20, _expirations.slot)
            sstore(keccak256(0, 0x40), 0)

            // Expiration is always zero on cancellations
            mstore(0, 0)

            // Equivalent to `emit SubscriptionUpdate(tokenId, 0)`
            log2(
                0, 0x20,
                // SubscriptionUpdate(uint256,uint64)
                0x2ec2be2c4b90c2cf13ecb6751a24daed6bb741ae5ed3f7371aabf9402f6d62e8,
                tokenId
            )
        }
    }

    /**
     * @dev See {IERC5643-expiresAt}.
     */
    function expiresAt(uint256 tokenId)
        external
        view
        virtual
        returns (uint64)
    {
        if (!_exists(tokenId)) {
            assembly {
                // revert InvalidTokenId()
                mstore(0, 0x3f6cc768)
                revert(0x1c, 0x04)
            }
        }

        // Equivalent to `return _expirations[tokenId]`
        assembly {
            mstore(0, tokenId)
            mstore(0x20, _expirations.slot)
            mstore(0, sload(keccak256(0, 0x40)))
            return (0, 0x20)
        }
    }

    /**
     * @dev See {IERC5643-isRenewable}.
     */
    function isRenewable(uint256 tokenId)
        external
        view
        virtual
        returns (bool)
    {
        if (!_exists(tokenId)) {
            assembly {
                // revert InvalidTokenId()
                mstore(0, 0x3f6cc768)
                revert(0x1c, 0x04)
            }
        }
        return _isRenewable(tokenId);
    }

    /**
     * @dev Internal function to determine renewability. Implementing contracts
     * should override this function if renewabilty should be disabled for all or
     * some tokens.
     */
    function _isRenewable(uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }

    /**
     * @dev Internal function to set the minimum renewal duration.
     */
    function _setMinimumRenewalDuration(uint64 duration) internal virtual {
        // Equivalent to `minimumRenewalDuration = duration`
        assembly {
            sstore(
                minimumRenewalDuration.slot,
                or(
                    and(
                        sload(minimumRenewalDuration.slot),
                        not(0xffffffffffffffff)
                    ),
                    duration
                )
            )
        }
    }

    /**
     * @dev Internal function to set the maximum renewal duration.
     */
    function _setMaximumRenewalDuration(uint64 duration) internal virtual {
        // Equivalent to `maximumRenewalDuration = duration`
        assembly {
            sstore(
                maximumRenewalDuration.slot,
                or(
                    and(
                        sload(maximumRenewalDuration.slot),
                        not(0xffffffffffffffff)
                    ),
                    // Skip to offset 8
                    shl(64, duration)
                )
            )
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
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
