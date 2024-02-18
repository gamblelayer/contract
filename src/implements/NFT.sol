// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Base} from "./Base.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract NFT is Base {
    using Strings for uint256;

    event GLBMinted(address indexed owner, uint256 indexed count);
    event GLBBurned(address indexed owner, uint256 indexed count);
    event GLTMinted(address indexed owner, uint256 indexed ticketId, uint256 indexed value);
    event GLTBurned(address indexed owner, uint256 indexed ticketId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    struct Ticket {
        uint256 ticketId;
        uint256 value;
    }

    function balanceOf(address owner) external view returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.tickets[owner].length;
    }

    function GLBBalanceOf(address owner) external view returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.boxes[owner];
    }

    function ownerOf(uint256 ticketId) external view returns (address) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.owners[ticketId];
    }

    function getApproved(uint256 ticketId) external view returns (address) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.approvals[ticketId];
    }

    function name() external pure returns (string memory) {
        return "GLTicket";
    }

    function symbol() external pure returns (string memory) {
        return "GLT";
    }

    function tokenURI(uint256 ticketId) external view virtual returns (string memory) {
        return string.concat(baseURI(), ticketId.toString());
    }

    function baseURI() public view returns (string memory) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOperators {
        LocalStorage storage $$ = getLocalStorage();
        $$.baseURI = baseURI_;
    }

    function approve(address to, uint256 ticketId) external {
        LocalStorage storage $$ = getLocalStorage();
        require($$.owners[ticketId] == msg.sender, "not owner");
        $$.approvals[ticketId] = to;
        emit Approval($$.owners[ticketId], to, ticketId);
    }

    function GLBMint(address to, uint256 count) external onlyOperators {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            $$.boxTotalSupply += count;
            $$.boxes[to] += count;
            emit GLBMinted(to, count);
        }
    }

    function GLBBurn(address from, uint256 count) external onlyOperators {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            require($$.boxes[from] >= count, "insufficient balance");
            $$.boxTotalSupply -= count;
            $$.boxes[from] -= count;
            emit GLBBurned(from, count);
        }
    }

    function GLTMint(address to, uint256 value) external onlyOperators {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            uint256 ticketId = ++$$.ticketId;
            emit GLTMinted(to, ticketId, value);
            $$.ticketTotalSupply++;
            $$.owners[ticketId] = to;
            $$.values[ticketId] = value;
            $$.tickets[to].push(ticketId);
            $$.stats[to].totalMintedTicket++;
            $$.stats[address(this)].totalMintedTicket++;
        }
    }

    function GLTBurn(address from, uint256 ticketId) external onlyOperators returns (bool) {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            emit GLTBurned(from, ticketId);
            uint256[] storage tickets = $$.tickets[from];
            $$.ticketTotalSupply--;
            $$.owners[ticketId] = address(0);
            $$.values[ticketId] = 0;
            for (uint256 index; index < tickets.length; index++) {
                if (tickets[index] == ticketId) {
                    tickets[index] = tickets[tickets.length - 1];
                    tickets.pop();
                    return true;
                }
            }
            return false;
        }
    }

    function GLTList(address owner) external view returns (Ticket[] memory tickets) {
        LocalStorage storage $$ = getLocalStorage();
        tickets = new Ticket[]($$.tickets[owner].length);
        for (uint256 index; index < $$.tickets[owner].length; index++) {
            uint256 ticketId = $$.tickets[owner][index];
            tickets[index] = Ticket(ticketId, $$.values[ticketId]);
        }
    }

    function transfer(address from, address to, uint256 ticketId) external {
        LocalStorage storage $$ = getLocalStorage();
        require(msg.sender == $$.owners[ticketId], "not owner");
        $$.owners[ticketId] = to;
        emit Transfer(from, to, ticketId);
    }

    function transferFrom(address from, address to, uint256 ticketId) external returns (bool) {
        LocalStorage storage $$ = getLocalStorage();
        require(msg.sender == $$.approvals[ticketId] && from == $$.owners[ticketId], "not approved");
        $$.owners[ticketId] = to;
        emit Transfer($$.owners[ticketId], to, ticketId);
        return true;
    }
}
