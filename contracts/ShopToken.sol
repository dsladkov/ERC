// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./ERC20.sol";
import "./ERC20Burnable.sol";
//import "./Ownable.sol";
import "./Errors.sol";

contract ShopToken is ERC20Burnable { //Ownable //ERC20, 
    address private _owner;

    error NotAnOwner(address addr);

    modifier onlyOwner() {
        require(_owner == _msgSender(), Errors.NotAnOwner(msg.sender));
        _;
    }

    constructor(address initialOwner) ERC20("ShopToken", "STK") { //Ownable(msg.sender)
        _owner = initialOwner;
        _mint(msg.sender, 10 * 10 ** decimals()); //10 * 10 ^ 18
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}