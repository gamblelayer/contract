// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Initializer} from "../test/Tester.sol";
import {Proxy} from "../src/Proxy.sol";
import {Controller} from "../src/implements/Controller.sol";
import {GambleLayer} from "../src/implements/GambleLayer.sol";
import {Token} from "../src/implements/Token.sol";
import {NFT} from "../src/implements/NFT.sol";
import {Vault} from "../src/implements/Vault.sol";
import {RNG} from "../src/implements/RNG.sol";

contract Deploy is Script, Initializer {
    function run() public {
        address admin = vm.envAddress("ACCOUNT");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address proxy = address(new Proxy(admin));
        Controller controller = Controller(proxy);
        address gamblelayer = address(new GambleLayer());
        address token = address(new Token());
        address nft = address(new NFT());
        address vault = address(new Vault());
        RNG rng = new RNG(31337);
        controller.addContract(gamblelayer, getSelectors(0), abi.encode(0.5 ether, 3, 3e3));
        controller.addContract(token, getSelectors(1), "");
        controller.addContract(nft, getSelectors(2), "");
        controller.addContract(vault, getSelectors(3), "init");
        GambleLayer(proxy).setRng(rng);
        vm.stopBroadcast();
    }
}
