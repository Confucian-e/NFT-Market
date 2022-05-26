# NFT Market

## 玩法

1. 用ether兑换平台自己的ERC20购买代币
2. 平台的ERC20代币按照一定的规则兑换相应的NFT



## 特点

- 每个人都能发布自己的NFT
- 用户购买NFT时加个时间锁，在买后一定时间内可以退货
- 根据交易金额，用户获得平台的积分代币
- 每笔成功的交易都要支付一定的手续费给开发者



## ERC20

- 平台发2种币，一个用于购买NFT，一个用于积分
- 2种代币设立一个动态的价格兑换机制，类似池子
- 购买代币可由以太和积分代币兑换，积分代币只能由购买代币兑换



## 合约文件

- ERC20
  - token_buy
  - token_point
- Market
  - Swap (以太换 token_buy)
  - Publish (发布自己的NFT)
  - Refund (退款)