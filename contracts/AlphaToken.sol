// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlphaToken is ERC20, Ownable {
    
    constructor(address initialOwner)
        ERC20("AlphaToken", "APH")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 51 * 10 ** 15);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}