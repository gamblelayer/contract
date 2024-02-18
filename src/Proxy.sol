// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {GlobalStorage} from "./libraries/Global.sol";
import {Controller} from "./implements/Controller.sol";

contract Proxy {
    event ProxyInitialized(address indexed admin, address indexed controller);

    GlobalStorage private $;

    constructor(address admin) {
        $.admin = admin;
        address controller = address(new Controller());
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = Controller.addContract.selector;
        selectors[1] = Controller.delContract.selector;
        selectors[2] = Controller.pauseProxy.selector;
        selectors[3] = Controller.resumeProxy.selector;
        selectors[4] = Controller.changeProxyAdmin.selector;
        selectors[5] = Controller.getProxyAdmin.selector;
        (bool success,) = controller.delegatecall(
            abi.encodeWithSignature("addContract(address,bytes4[],bytes)", controller, selectors, "")
        );
        require(success, "initialize proxy fail");
        emit ProxyInitialized(admin, controller);
    }

    fallback() external payable {
        require($.paused == false, "proxy paused");
        address imp = $.addresses[msg.sig];
        require(imp != address(0), "function not found");
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), imp, ptr, calldatasize(), 0, 0)
            returndatacopy(ptr, 0, returndatasize())
            switch result
            case 0 { revert(ptr, returndatasize()) }
            default { return(ptr, returndatasize()) }
        }
    }

    receive() external payable {}
}
