// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import './IERC20.sol';


interface IWLUCA is IERC20{
    function deposit(uint256 amount) external;
}