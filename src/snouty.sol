// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract SnoutyCoin is ERC20, Ownable {

    constructor(uint256 initialSupply) ERC20("Snouty", "SNTY") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
}