// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TokenBuy is ERC20 {
    constructor() ERC20('TokenBuy', 'buy') {
        _mint(msg.sender, 1000000 * 100);
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }
}