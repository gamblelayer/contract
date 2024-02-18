// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Global} from "../libraries/Global.sol";
import {Base} from "./Base.sol";

interface IBlast {
    function configure(uint8 _yield, uint8 gasMode, address governor) external;
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);
}

interface IToken {
    // IERC20Rebasing
    function configure(uint8 _yield) external returns (uint256);
    function claim(address recipient, uint256 amount) external returns (uint256);
    function getClaimableAmount(address account) external view returns (uint256);
    // IERC20
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    // IWETH
    function deposit() external payable;
}

contract Vault is Base {
    IBlast constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    IToken constant USDB = IToken(0x4200000000000000000000000000000000000022);
    IToken constant WETH = IToken(0x4200000000000000000000000000000000000023);

    event ClaimIncome(uint256 gasAmount, uint256 wethAmount, uint256 usdbAmount);
    event TransferRatio(address to, uint256 wethAmount, uint256 usdbAmount);
    event TransferDirect(address token, address to, uint256 amount);

    modifier onlyProxyAdmin() {
        Global.onlyProxyAdmin();
        _;
    }

    function initialize(bytes calldata) external onlyProxyAdmin {
        if (block.chainid != 31337) {
            BLAST.configure(2, 1, address(this));
            USDB.configure(2);
            WETH.configure(2);
        }
    }

    function claimIncome() public {
        unchecked {
            LocalStorage storage $$ = getLocalStorage();
            BLAST.claimAllYield(address(this), address(this));
            BLAST.claimMaxGas(address(this), address(this));
            uint256 gasAmount = address(this).balance;
            uint256 wethAmount = WETH.claim(address(this), WETH.getClaimableAmount(address(this)));
            uint256 usdbAmount = USDB.claim(address(this), USDB.getClaimableAmount(address(this)));
            if (gasAmount > 0) {
                WETH.deposit{value: gasAmount}();
            }
            $$.stats[msg.sender].totalIncomeUsdb += usdbAmount;
            $$.stats[address(this)].totalIncomeUsdb += usdbAmount;
            $$.stats[msg.sender].totalIncomeWeth += wethAmount + gasAmount;
            $$.stats[address(this)].totalIncomeWeth += wethAmount + gasAmount;
            emit ClaimIncome(gasAmount, wethAmount, usdbAmount);
        }
    }

    function transferRatio(address to, uint256 ratio)
        external
        onlyOperators
        returns (uint256 wethAmount, uint256 usdbAmount)
    {
        claimIncome();
        wethAmount = WETH.balanceOf(address(this)) * ratio / 1e4;
        usdbAmount = USDB.balanceOf(address(this)) * ratio / 1e4;
        WETH.transfer(to, wethAmount);
        USDB.transfer(to, usdbAmount);
        emit TransferRatio(to, wethAmount, usdbAmount);
    }

    function transferDirect(address token, address to, uint256 amount) external onlyOperators {
        claimIncome();
        IToken(token).transfer(to, amount);
        emit TransferDirect(token, to, amount);
    }

    function balances() external view returns (uint256 wethBalance, uint256 usdbBalance) {
        wethBalance = WETH.balanceOf(address(this));
        usdbBalance = USDB.balanceOf(address(this));
    }
}
