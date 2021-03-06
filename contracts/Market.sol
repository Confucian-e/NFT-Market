// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract Market is ERC721 {
    using Counters for Counters.Counter;
    // 替换地址
    address constant TOKEN_BUY = 0x8713dB4e36573Fa319f56833c2cE4560D1391996;
    address constant TOKEN_POINT = 0x0a814cA41263Bfb79E46771188B0c1E85ac878B5;

    /// @dev 合约创建者
    address immutable creator;

    /// @dev 记录NFT的序号
    Counters.Counter private _tokenIds;

    constructor() ERC721("NFT-16group", "NFT-16") {
        creator = msg.sender;
    }

    event GetTokenBuy(address indexed user, uint amount);
    event BuyNFT(address indexed buyer, uint price, uint indexed id);
    event Refund(uint time, uint amount);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint amountIn, uint amountOut);

    // 用户兑换 TokenBuy，兑换比：1 finney : 1000 Buy
    function getTokenBuy() public payable {
        uint amount = 1000 * (msg.value / 1000000 gwei);
        IERC20(TOKEN_BUY).transfer(msg.sender, amount * 100);

        emit GetTokenBuy(msg.sender, amount);
    }

    // 买家购买NFT（铸造）
    function buyNFT(uint price) public {
        IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), price);
        uint newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        emit BuyNFT(msg.sender, price / 100, newItemId);

        _tokenIds.increment();
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

    // 创建者提取合约内的以太币
    function refund() external {
        require(msg.sender == creator, "Only creator can refund!");
        uint balanceETH = address(this).balance;
        payable(creator).transfer(balanceETH);

        emit Refund(block.timestamp, balanceETH);
    }

    // TokenBuy 和 TokenPoint 建个池子来兑换
    function swap(address tokenIn, uint amountIn) public {
        uint BuyBeforeSwap = IERC20(TOKEN_BUY).balanceOf(address(this));
        uint PointBeforeSwap = IERC20(TOKEN_POINT).balanceOf(address(this));
        
        if(tokenIn == TOKEN_BUY) {
            // Buy 换 Point
            IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), amountIn);
            uint amountOutPoint = cal(BuyBeforeSwap, PointBeforeSwap, amountIn);
            IERC20(TOKEN_POINT).transfer(msg.sender, amountOutPoint);

            emit Swap(msg.sender, tokenIn, TOKEN_POINT, amountIn, amountOutPoint);
        } else {
            // Point 换 Buy
            IERC20(TOKEN_POINT).transferFrom(msg.sender, address(this), amountIn);
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
