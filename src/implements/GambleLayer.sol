// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Global} from "../libraries/Global.sol";
import {Base, Stats, WhiteContract, Operator} from "./Base.sol";
import {RNG} from "./RNG.sol";
import {NFT} from "./NFT.sol";
import {Token} from "./Token.sol";
import {Vault} from "./Vault.sol";

contract GambleLayer is Base {
    event GLTMinted(address indexed receiver, uint256 indexed value);
    event GLDMinted(address indexed receiver, uint256 indexed amount, bool indexed fever);
    event UpgradeSuccess(address indexed owner, uint256 indexed ticketId, uint256 indexed value);
    event UpgradeFail(address indexed owner, uint256 indexed ticketId, uint256 indexed value);
    event GLTClaimed(address indexed owner, uint256 indexed ticketId, uint256 wethAmount, uint256 usdbAmount);

    modifier onlyProxyAdmin() {
        Global.onlyProxyAdmin();
        _;
    }

    modifier onlyEoa() {
        require(tx.origin == msg.sender || block.chainid == 31337, "Not EOA");
        _;
    }

    modifier onlyWhiteContract() {
        LocalStorage storage $$ = getLocalStorage();
        require($$.isWhiteContract[msg.sender] != 0, "only white contract");
        _;
    }

    function initialize(bytes calldata args) external onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        addOperator(address(0), "");
        addOperator(address(this), "GambleLayer");
        addWhiteContract(address(0), "");
        addWhiteContract(address(this), "GambleLayer");
        (uint256 drawRate, uint256 openRate, uint256 gasCost) = abi.decode(args, (uint256, uint256, uint256));
        $$.drawRate = drawRate;
        $$.openRate = openRate;
        $$.gasCost = gasCost;
    }

    function addWhiteContract(address addr, string memory desc) public onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        require($$.isWhiteContract[addr] == 0, "contract already exists");
        WhiteContract memory whiteContract = WhiteContract(addr, desc);
        $$.isWhiteContract[addr] = $$.whiteContracts.length;
        $$.whiteContracts.push(whiteContract);
    }

    function delWhiteContract(address addr) external onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        uint256 index = $$.isWhiteContract[addr];
        require(index != 0, "contract not found");
        WhiteContract[] storage whiteContracts = $$.whiteContracts;
        whiteContracts[index] = whiteContracts[whiteContracts.length - 1];
        $$.isWhiteContract[whiteContracts[index].addr] = index;
        $$.isWhiteContract[addr] = 0;
        whiteContracts.pop();
    }

    function addOperator(address addr, string memory desc) public onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        require($$.isOperator[addr] == 0, "operator already exists");
        Operator memory operator = Operator(addr, desc);
        $$.isOperator[addr] = $$.operators.length;
        $$.operators.push(operator);
    }

    function delOperator(address addr) external onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        uint256 index = $$.isOperator[addr];
        require(index != 0, "operator not found");
        Operator[] storage operators = $$.operators;
        operators[index] = operators[operators.length - 1];
        $$.isOperator[operators[index].addr] = index;
        $$.isOperator[addr] = 0;
        operators.pop();
    }

    function applyOperator(address operator) external view onlyProxyAdmin {
        operator;
    }

    function approveOperator(address operator) external view onlyProxyAdmin {
        operator;
    }

    function setRng(RNG rng) external onlyProxyAdmin {
        LocalStorage storage $$ = getLocalStorage();
        $$.rng = RNG(rng);
    }

    function luckyDraw(address receiver) public onlyEoa {
        LocalStorage storage $$ = getLocalStorage();
        for (uint256 index; index < $$.gasCost; index++) {
            $$.gasCost++;
            $$.gasCost--;
        }
        bool fever = random() % 10 == 0;
        uint256 drawRate = $$.drawRate;
        if (receiver == address(0)) receiver = msg.sender;
        Token token = Token(address(this));
        if (fever) drawRate *= 2;
        token.dustMint(receiver, drawRate);
        uint256 burnAmount = random() % drawRate;
        if (fever) burnAmount /= 2;
        token.dustBurn(receiver, burnAmount);
        emit GLDMinted(receiver, drawRate - burnAmount, fever);
        $$.stats[receiver].totalDraw++;
        $$.stats[address(this)].totalDraw++;
    }

    function luckyDraw2(address receiver) external onlyWhiteContract {
        luckyDraw(receiver);
    }

    function openGLB(uint256 count) external onlyEoa {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            require($$.boxes[msg.sender] >= count, "insufficient box");
            for (uint256 index; index < count; index++) {
                _openGLB();
            }
        }
    }

    function _openGLB() private {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            Token(address(this)).dustBurn(msg.sender, 1 ether);
            NFT nft = NFT(address(this));
            uint256 openRate = $$.openRate;
            uint256 lucky = random();
            if (lucky % openRate == openRate / 2) {
                nft.GLTMint(msg.sender, 1);
                emit GLTMinted(msg.sender, 1);
            } else if (lucky % (openRate * 1e1) == (openRate * 5)) {
                nft.GLTMint(msg.sender, 1e1);
                emit GLTMinted(msg.sender, 1e1);
            } else if (lucky % (openRate * 1e2) == (openRate * 50)) {
                nft.GLTMint(msg.sender, 1e2);
                emit GLTMinted(msg.sender, 1e2);
            } else if (lucky % (openRate * 1e3) == (openRate * 500)) {
                nft.GLTMint(msg.sender, 1e3);
                emit GLTMinted(msg.sender, 1e3);
            }
            if ($$.stats[msg.sender] == 0) $$.totalUsers++;
            $$.stats[msg.sender].totalBoxOpen++;
            $$.stats[address(this)].totalBoxOpen++;
        }
    }

    function upgradeGLT(uint256 ticketId) external onlyEoa {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            require($$.owners[ticketId] == msg.sender, "not owner");
            uint256 value = $$.values[ticketId];
            uint256 rand = random() % 10000;
            if (rand + value * 2 > 5000) {
                NFT(address(this)).GLTBurn(msg.sender, ticketId);
                emit UpgradeFail(msg.sender, ticketId, value);
            } else {
                $$.values[ticketId] *= 2;
                emit UpgradeSuccess(msg.sender, ticketId, value);
            }
        }
    }

    function claimGLT(uint256 ticketId) external {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            require($$.owners[ticketId] == msg.sender, "not owner");
            require(NFT(address(this)).GLTBurn(msg.sender, ticketId), "ticket burn fail");
            (uint256 wethBalance, uint256 usdbBalance) =
                Vault(address(this)).transferRatio(msg.sender, $$.values[ticketId]);
            $$.stats[msg.sender].totalPayoutWeth += wethBalance;
            $$.stats[address(this)].totalPayoutWeth += wethBalance;
            $$.stats[msg.sender].totalPayoutUsdb += usdbBalance;
            $$.stats[address(this)].totalPayoutUsdb += usdbBalance;
            emit GLTClaimed(msg.sender, ticketId, wethBalance, usdbBalance);
        }
    }

    function getStats(address account) public view returns (Stats memory stats) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.stats[account];
    }

    function random() private returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.rng.gen();
    }
}
