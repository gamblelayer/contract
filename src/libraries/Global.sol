// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Controller} from "../implements/Controller.sol";
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

struct GlobalStorage {
    bool paused;
    address admin;
    mapping(address => bytes4[]) selectors;
    mapping(bytes4 => address) addresses;
}

library Global {
    function onlyProxyAdmin() internal view {
        GlobalStorage storage $ = getGlobalStorage();
        require(msg.sender == $.admin, "not admin");
    }

    function getGlobalStorage() private pure returns (GlobalStorage storage $) {
        assembly {
            $.slot := 0
        }
    }
}
