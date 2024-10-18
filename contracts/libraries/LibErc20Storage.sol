// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ERC20Storage {
    string name;
    string symbol;
    uint8 decimal;
    uint totalSupply;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    address _owner;
}