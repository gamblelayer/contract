// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
/*
    Gamble Layer
    Twitter : https://x.com/gamblelayer
    Github : https://github.com/gamblelayer
    Discord : https://discord.gg/HxDwrC9aWe
*/

import {Test, console} from "lib/forge-std/src/Test.sol";
import {VmSafe} from "lib/forge-std/src/Vm.sol";
import {Proxy} from "src/Proxy.sol";
import {Controller} from "src/implements/Controller.sol";
import {GambleLayer} from "src/implements/GambleLayer.sol";
import {Vault} from "src/implements/Vault.sol";
import {Token} from "src/implements/Token.sol";
import {NFT} from "src/implements/NFT.sol";
import {RNG} from "src/implements/RNG.sol";

interface IBlast {
    function configure(uint8 _yield, uint8 gasMode, address governor) external;
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);
}

contract Fallback {
    fallback(bytes calldata) external payable returns (bytes memory result) {
        return abi.encode(0);
    }
}

contract Initializer is Test {
    bytes4[][] public selectors;

    constructor() {
        bytes memory code = address(new Fallback()).code;
        vm.etch(0x4300000000000000000000000000000000000002, code);
        vm.etch(0x4200000000000000000000000000000000000022, code);
        vm.etch(0x4200000000000000000000000000000000000023, code);

        selectors.push(new bytes4[](0));
        selectors[0].push(GambleLayer.addWhiteContract.selector);
        selectors[0].push(GambleLayer.delWhiteContract.selector);
        selectors[0].push(GambleLayer.addOperator.selector);
        selectors[0].push(GambleLayer.delOperator.selector);
        selectors[0].push(GambleLayer.applyOperator.selector);
        selectors[0].push(GambleLayer.approveOperator.selector);
        selectors[0].push(GambleLayer.setRng.selector);
        selectors[0].push(GambleLayer.luckyDraw.selector);
        selectors[0].push(GambleLayer.luckyDraw2.selector);
        selectors[0].push(GambleLayer.openGLB.selector);
        selectors[0].push(GambleLayer.upgradeGLT.selector);
        selectors[0].push(GambleLayer.claimGLT.selector);
        selectors[0].push(GambleLayer.getStats.selector);

        selectors.push(new bytes4[](0));
        selectors[1].push(Token.decimals.selector);
        selectors[1].push(Token.totalSupply.selector);
        selectors[1].push(Token.dustBalanceOf.selector);
        selectors[1].push(Token.dustTransfer.selector);
        selectors[1].push(Token.dustTransferFrom.selector);
        selectors[1].push(Token.dustAllowance.selector);
        selectors[1].push(Token.dustApprove.selector);
        selectors[1].push(Token.dustMint.selector);
        selectors[1].push(Token.dustBurn.selector);

        selectors.push(new bytes4[](0));
        selectors[2].push(NFT.balanceOf.selector);
        selectors[2].push(NFT.GLBBalanceOf.selector);
        selectors[2].push(NFT.ownerOf.selector);
        selectors[2].push(NFT.getApproved.selector);
        selectors[2].push(NFT.name.selector);
        selectors[2].push(NFT.symbol.selector);
        selectors[2].push(NFT.tokenURI.selector);
        selectors[2].push(NFT.baseURI.selector);
        selectors[2].push(NFT.setBaseURI.selector);
        selectors[2].push(NFT.approve.selector);
        selectors[2].push(NFT.GLBMint.selector);
        selectors[2].push(NFT.GLBBurn.selector);
        selectors[2].push(NFT.GLTMint.selector);
        selectors[2].push(NFT.GLTBurn.selector);
        selectors[2].push(NFT.GLTList.selector);
        selectors[2].push(NFT.transfer.selector);
        selectors[2].push(NFT.transferFrom.selector);

        selectors.push(new bytes4[](0));
        selectors[3].push(Vault.claimIncome.selector);
        selectors[3].push(Vault.balances.selector);
        selectors[3].push(Vault.transferRatio.selector);
        selectors[3].push(Vault.transferDirect.selector);
    }

    function getSelectors(uint256 index) public view returns (bytes4[] memory) {
        return selectors[index];
    }
}

contract Tester is Test, Initializer {
    function test() public {
        address proxy = address(new Proxy(address(this)));
        Controller controller = Controller(proxy);
        controller.addContract(address(new GambleLayer()), getSelectors(0), abi.encode(1 ether, 3, 3e3));
        controller.addContract(address(new Token()), getSelectors(1), "");
        controller.addContract(address(new NFT()), getSelectors(2), "");
        controller.addContract(address(new Vault()), getSelectors(3), "init");

        GambleLayer gamble = GambleLayer(proxy);
        Token token = Token(proxy);
        NFT nft = NFT(proxy);
        RNG rng = new RNG(vulnerableRngSource());
        gamble.setRng(rng);

        console.log("run 10000 luckyDraw");
        for (uint256 i; i < 10000; i++) {
            gamble.luckyDraw(address(0));
        }
        console.log("dust collected : ", token.dustBalanceOf(address(this)));
        console.log("box balance : ", nft.GLBBalanceOf(address(this)));

        console.log("open all box");
        gamble.openGLB(nft.GLBBalanceOf(address(this)));

        NFT.Ticket[] memory tickets = nft.GLTList(address(this));
        console.log("ticket list : ", tickets.length);
        for (uint256 i; i < tickets.length; i++) {
            console.log("ticketId:%s value:%s", tickets[i].ticketId, tickets[i].value);
        }

        console.log("upgrade all ticket");
        for (uint256 i; i < tickets.length; i++) {
            gamble.upgradeGLT(tickets[i].ticketId);
        }

        NFT.Ticket[] memory tickets2 = nft.GLTList(address(this));
        console.log("ticket list : ", tickets2.length);
        for (uint256 i; i < tickets2.length; i++) {
            console.log("ticketId:%s value:%s", tickets2[i].ticketId, tickets2[i].value);
        }
    }

    function vulnerableRngSource() private returns (uint256 rand) {
        string[] memory args = new string[](1);
        args[0] = "date";
        bytes memory result = vm.ffi(args);
        VmSafe.Wallet memory wallet = vm.createWallet(string(result));
        rand = wallet.publicKeyX;
    }
}
