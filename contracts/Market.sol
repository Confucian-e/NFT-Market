// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Market is ERC721 {
    // 替换地址
    address constant TOKEN_BUY = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;
    address constant TOKEN_POINT = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;

    /// @dev 合约创建者
    address immutable creator;

    mapping(address => uint8) items;

    constructor() ERC721("NFT-16group", "NFT-16") {
        creator = msg.sender;
    }

    uint balanceOfBuy = IERC20(TOKEN_BUY).balanceOf(address(this));
    uint balanceOfPoint = IERC20(TOKEN_POINT).balanceOf(address(this));

    event GetTokenBuy(address indexed user, uint amount);
    event BuyNFT(address indexed buyer, uint price, uint indexed id);
    event Refund(uint time);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint amountIn, uint amountOut);

    // 用户兑换 TokenBuy
    function getTokenBuy() public payable {
        uint amount = msg.value / 1 ether;
        IERC20(TOKEN_BUY).transfer(msg.sender, amount * 100);

        emit GetTokenBuy(msg.sender, amount);
    }

    // 买家购买NFT（铸造）
    function buyNFT(uint tokenId, uint price) public {
        IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), price);
        _safeMint(msg.sender, tokenId);

        emit BuyNFT(msg.sender, price / 100, tokenId);

        getPoint(price);
    }

    // 每次购买成功都获得积分代币
    function getPoint(uint price) internal {
        uint amount = price / 2;
        IERC20(TOKEN_POINT).transfer(tx.origin, amount);
    }

    // 查看合约内以太余额
    function showEtherBalance() view public returns (uint) {
        return address(this).balance;
    }

    // 创建者提取合约内 ERC20 代币
    function refund() external {
        require(msg.sender == creator, "Only creator can refund!");
        IERC20(TOKEN_BUY).transfer(creator, balanceOfBuy);
        IERC20(TOKEN_POINT).transfer(creator, balanceOfPoint);

        emit Refund(block.timestamp);
    }

    // TokenBuy 和 TokenPoint 建个池子
    function swap(address tokenIn, uint amountIn) public {
        uint total = balanceOfBuy * balanceOfPoint;
        
        if(tokenIn == TOKEN_BUY) {
            // Buy 换 Point
            IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), amountIn);
            uint amountOutPoint = total / balanceOfBuy;
            IERC20(TOKEN_POINT).transfer(msg.sender, amountOutPoint);

            emit Swap(msg.sender, tokenIn, TOKEN_POINT, amountIn, amountOutPoint);
        } else {
            // Point 换 Buy
            IERC20(TOKEN_POINT).transferFrom(msg.sender, address(this), amountIn);
            uint amountOutBuy = total / balanceOfPoint;
            IERC20(TOKEN_BUY).transfer(msg.sender, amountOutBuy);

            emit Swap(msg.sender, tokenIn, TOKEN_BUY, amountIn, amountOutBuy);
        }
    }
}