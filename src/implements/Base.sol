// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {RNG} from "./RNG.sol";

struct Stats {
    uint256 totalDraw;
    uint256 totalBoxOpen;
    uint256 totalMintedTicket;
    uint256 totalPayoutWeth;
    uint256 totalPayoutUsdb;
    uint256 totalIncomeWeth;
    uint256 totalIncomeUsdb;
}

struct WhiteContract {
    address addr;
    string desc;
}

struct Operator {
    address addr;
    string desc;
}

contract Base {
    modifier onlyOperators() {
        LocalStorage storage $$ = getLocalStorage();
        require($$.isOperator[msg.sender] != 0, "only operator");
        _;
    }

    struct LocalStorage {
        // for nft
        string baseURI;
        uint256 ticketId;
        uint256 boxTotalSupply;
        uint256 ticketTotalSupply;
        uint256 gameOptions;
        mapping(uint256 ticketId => address owner) owners;
        mapping(address owner => uint256) boxes;
        mapping(address owner => uint256[] ticketIds) tickets;
        mapping(uint256 ticketId => address spender) approvals;
        mapping(uint256 ticketId => uint256 value) values;
        // for token
        mapping(address account => uint256) dustBalances;
        mapping(address account => mapping(address spender => uint256)) dustAllowances;
        uint256 dustTotalSupply;
        // for gamble layer
        Operator[] operators;
        WhiteContract[] whiteContracts;
        mapping(address addr => uint256 index) isOperator;
        mapping(address addr => uint256 index) isWhiteContract;
        uint256 drawRate;
        uint256 openRate;
        uint256 gasCost;
        uint256 totalUsers;
        mapping(address account => Stats) stats;
        RNG rng; // only for testnet
    }

    // keccak256(bytes("GambleLayer"))
    bytes32 private constant SLOT = 0xc848ec71f380117534c038d0dcbc35fb8fc9f09e4f4238c815e43a25bc3a7b20;

    function getLocalStorage() internal pure returns (LocalStorage storage $$) {
        assembly {
            $$.slot := SLOT
        }
    }
}
