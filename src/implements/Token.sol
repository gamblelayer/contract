// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Base} from "./Base.sol";
import {NFT} from "./NFT.sol";

contract Token is Base {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.dustTotalSupply;
    }

    function dustBalanceOf(address account) external view returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.dustBalances[account];
    }

    function dustTransfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function dustTransferFrom(address from, address to, uint256 value) external returns (bool) {
        LocalStorage storage $$ = getLocalStorage();
        require($$.dustAllowances[from][msg.sender] >= value, "insufficient allowance");
        _transfer(from, to, value);
        unchecked {
            $$.dustAllowances[from][msg.sender] -= value;
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        LocalStorage storage $$ = getLocalStorage();
        require($$.dustBalances[from] >= value, "insufficient balance");
        unchecked {
            $$.dustBalances[from] -= value;
            $$.dustBalances[to] += value;
        }
        _update(from);
        _update(to);
    }

    function dustAllowance(address owner, address spender) external view returns (uint256) {
        LocalStorage storage $$ = getLocalStorage();
        return $$.dustAllowances[owner][spender];
    }

    function dustApprove(address spender, uint256 value) external returns (bool) {
        LocalStorage storage $$ = getLocalStorage();
        $$.dustAllowances[msg.sender][spender] = value;
        return true;
    }

    function dustMint(address account, uint256 value) external onlyOperators {
        LocalStorage storage $$ = getLocalStorage();
        unchecked {
            $$.dustBalances[account] += value;
            $$.dustTotalSupply += value;
        }
        _update(account);
    }

    function dustBurn(address account, uint256 value) external onlyOperators {
        LocalStorage storage $$ = getLocalStorage();
        require($$.dustBalances[account] >= value, "insufficient balance");
        unchecked {
            $$.dustBalances[account] -= value;
            $$.dustTotalSupply -= value;
        }
        _update(account);
    }

    function _update(address account) private {
        LocalStorage storage $$ = getLocalStorage();
        uint256 boxBalance = $$.boxes[account];
        uint256 dustBalance = $$.dustBalances[account];
        uint256 quotient = dustBalance / 1 ether;
        if (quotient == boxBalance) return;
        quotient > boxBalance
            ? NFT(address(this)).GLBMint(account, quotient - boxBalance)
            : NFT(address(this)).GLBBurn(account, boxBalance - quotient);
    }
}
