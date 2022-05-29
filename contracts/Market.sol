// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Market is ERC721, ERC20 {
    // 替换地址
    address constant TOKEN_BUY = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;
    address constant TOKEN_POINT = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;

    /// @dev 合约创建者
    address immutable creator;

    mapping(address => uint8) items;

    constructor() ERC721("NFT-16group", "NFT-16") {
        creator = msg.sender;
    }

    event GetTokenBuy(address indexed user, uint amount);
    event BuyNFT(address indexed buyer, uint price, uint indexed id);
    event Refund(uint time);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint amountIn, uint amountOut);

    // 用户兑换 TokenBuy，兑换比：1:100
    function getTokenBuy() public payable {
        uint amount = msg.value / 1 ether;
        IERC20(TOKEN_BUY).transfer(msg.sender, amount * 10000);

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
        uint balanceOfBuy = IERC20(TOKEN_BUY).balanceOf(address(this));
        uint balanceOfPoint = IERC20(TOKEN_POINT).balanceOf(address(this));
        IERC20(TOKEN_BUY).transfer(creator, balanceOfBuy);
        IERC20(TOKEN_POINT).transfer(creator, balanceOfPoint);

        emit Refund(block.timestamp);
    }

    // TokenBuy 和 TokenPoint 建个池子
    function swap(address tokenIn, uint amountIn) public {
        uint BuyBeforeSwap = IERC20(TOKEN_BUY).balanceOf(address(this));
        uint PointBeforeSwap = IERC20(TOKEN_POINT).balanceOf(address(this));
        // uint total = BuyBeforeSwap * PointBeforeSwap;
        
        if(tokenIn == TOKEN_BUY) {
            // Buy 换 Point
            IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), amountIn);
            // uint BuyAfterSwap = IERC20(TOKEN_BUY).balanceOf(address(this));
            uint amountOutPoint = cal(BuyBeforeSwap, PointBeforeSwap, amountIn);
            IERC20(TOKEN_POINT).transfer(msg.sender, amountOutPoint);

            emit Swap(msg.sender, tokenIn, TOKEN_POINT, amountIn, amountOutPoint);
        } else {
            // Point 换 Buy
            IERC20(TOKEN_POINT).transferFrom(msg.sender, address(this), amountIn);
            // uint PointAfterSwap = IERC20(TOKEN_BUY).balanceOf(address(this));
            uint amountOutBuy = cal(PointBeforeSwap, BuyBeforeSwap, amountIn);
            IERC20(TOKEN_BUY).transfer(msg.sender, amountOutBuy);

            emit Swap(msg.sender, tokenIn, TOKEN_BUY, amountIn, amountOutBuy);
        }
    }

    /// @param x 原来 tokenA 的数量
    /// @param y 原来 tokenB 的数量
    /// @param i 这次交易要兑换的 token 数量
    /// @param out 可以兑换到的 token 数量
    function cal(uint x, uint y, uint i) pure internal returns (uint out) {
        uint temp = (x * y) / (x + i);
        out = y - temp;
    }
}