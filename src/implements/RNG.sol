// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

///  @title RNG
///  @notice This is 100% exploitable random number generator.
///  @dev It will be replaced by a properly secured RNG in the near future.
contract RNG {
    uint256 private seed;

    constructor(uint256 seed_) {
        seed = seed_;
    }

    function gen() external returns (uint256) {
        seed = uint256(keccak256(abi.encodePacked(block.timestamp, seed)));
        return seed;
    }
}
