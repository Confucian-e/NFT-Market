// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract Market {
    // 替换地址
    address constant TOKEN_BUY = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;
    address constant TOKEN_POINT = 0xCFf94b4606c1e3D73510A80d9868D9B07825D692;

    struct Item {
        address owner;
        address nft;
        uint price;
    }

    Item[] public items;

    event SwapETH(address user, uint amount);
    event BuyNFT(address buyer, uint price, uint id);
    event PublishNFT(address seller, uint nftId, uint price);

    function swap() external payable {
        payable(address(this)).transfer(msg.value);
        uint _amount = msg.value / 1 ether;
        IERC20(TOKEN_BUY).transfer(msg.sender, 1000);
        emit SwapETH(msg.sender, _amount);
    }

    // 买家购买NFT
    function buyNFT(uint _id) external {
        require(IERC20(TOKEN_BUY).balanceOf(msg.sender) >= items[_id].price, "money not enough");
        IERC20(TOKEN_BUY).transferFrom(msg.sender, address(this), items[_id].price);
        // 时间锁
        IERC20(TOKEN_BUY).transfer(items[_id].owner, items[_id].price * 99 / 100);
        getPoint(items[_id].price);
        items[_id].owner = msg.sender;
        emit BuyNFT(msg.sender, items[_id].price, _id);
    }

    // 卖家挂售NFT
    function publishNFT(address _nft, uint _tokenId, uint _price) external {
        Item memory item = Item(msg.sender ,_nft, _price);
        items.push(item);
        IERC721(_nft).approve(address(this), _tokenId);
        emit PublishNFT(msg.sender, _tokenId, _price);
    }

    // 每次购买成功都获得积分代币
    function getPoint(uint _price) internal {
        uint amount = _price / 2;
        IERC20(TOKEN_POINT).transfer(tx.origin, amount);
    }
}