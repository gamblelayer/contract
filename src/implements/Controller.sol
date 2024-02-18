// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Global, GlobalStorage} from "../libraries/Global.sol";

contract Controller {
    GlobalStorage private $;

    event ChangeProxyAdmin(address indexed oldAdmin, address indexed newAdmin);
    event AddContract(address indexed addr, uint256 indexed selectors);
    event DelContract(address indexed addr, uint256 indexed selectors);

    modifier onlyProxyAdmin() {
        Global.onlyProxyAdmin();
        _;
    }

    function changeProxyAdmin(address admin) external onlyProxyAdmin {
        emit ChangeProxyAdmin($.admin, admin);
        $.admin = admin;
    }

    function addContract(address addr, bytes4[] calldata selectors, bytes calldata args) external onlyProxyAdmin {
        require($.selectors[addr].length == 0, "contract already exists");

        for (uint256 index; index < selectors.length; index++) {
            bytes4 selector = selectors[index];
            require($.addresses[selector] == address(0), "selector already exists");
            require(selector != bytes4(0), "invalid selector");
            $.selectors[addr].push(selector);
            $.addresses[selector] = addr;
        }

        if (args.length > 0) {
            (bool success,) = addr.delegatecall(abi.encodeWithSignature("initialize(bytes)", args));
            require(success, "initialize contract fail");
        }

        emit AddContract(addr, selectors.length);
    }

    function delContract(address addr) external onlyProxyAdmin {
        require($.selectors[addr].length != 0, "contract not found");

        bytes4[] storage selectors = $.selectors[addr];
        for (uint256 index; index < selectors.length; index++) {
            require($.addresses[selectors[index]] == addr, "selector not found");
            delete $.addresses[selectors[index]];
        }

        emit DelContract(addr, selectors.length);
        delete $.selectors[addr];
    }

    function pauseProxy() external onlyProxyAdmin {
        $.paused = true;
    }

    function resumeProxy() external onlyProxyAdmin {
        $.paused = false;
    }

    function getProxyAdmin() external view returns (address) {
        return $.admin;
    }
}
