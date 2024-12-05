// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import "./Errors.sol";

contract TokenExchange {
    IERC20 token;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, Errors.NotAnOwner(msg.sender));
        _;
    }

    constructor(address _token) {
        _owner = msg.sender;
        token = IERC20(_token); // экипируем адрес в интерфейс IERC20
    }

    function buy() public payable {
        uint amount = msg.value; // wei

        require(amount > 0, "amount should be more 0");
        uint currentBalance = token.balanceOf(address(this));

        require(currentBalance >= amount, Errors.InsufficientBalanceExchange(currentBalance, amount));

        token.transfer(msg.sender, amount);
    }

    function sell(uint _amount) public {
        require(address(this).balance >= _amount); //enough ETH on balance exchange
        require(token.allowance(msg.sender, address(this)) >=_amount);
        token.transferFrom(msg.sender, address(this), _amount);
        //payable(msg.sender).transfer(_amount); // 
        //(bool ok) = payable(msg.sender).send(_amount); // 
        (bool sent, bytes memory data) = msg.sender.call{value:_amount}(""); // call in combination with re-entrancy guard is the recommended method to use after December 2019
        require(sent, "Failed to send Ether");
    }

    receive() external payable { 
        buy();
    }

    //Only owner can send ETH for this exchange platform
    function topUp() external  payable  onlyOwner{}
}