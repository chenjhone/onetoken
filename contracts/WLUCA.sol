// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import './library/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWLUCA.sol';

contract WLUCA is IWLUCA{
                
    /// @notice EIP-20 token name for this token
    string public constant name = "VSN";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "WLUCA";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    //uint public totalSupply = 0;

    mapping (address => mapping (address => uint96)) internal allowances;


    mapping (address => uint96) internal balances;

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external override view returns (uint) {
        return allowances[account][spender];
    }


    /**
     * @notice Mint new tokens
     * @param amount The address of the destination account
     */
    function deposit(address account,uint256 amount) external override {
        // incre the amount
        uint96 _amount = safe96(amount,"Vsn Network:: mint: increAmount exceeds 96 bits");
        //totalSupply = safe96(SafeMath.add(totalSupply, _amount), "Vsn Network:: mint: totalSupply exceeds 96 bits");
        // transfer the amount to the recipient
        balances[account] = add96(balances[account], _amount, "Vsn Network:: mint: transfer amount overflows");
    }
    
    /**
     * @notice Mint new tokens
     * @param amount The address of the destination account
     */
    function burn(address account,uint256 amount) external override{
        // incre the amount
        uint96 _amount = safe96(amount,"Vsn Network:: mint: increAmount exceeds 96 bits");
        //totalSupply = safe96(SafeMath.sub(totalSupply, _amount), "Vsn Network:: mint: totalSupply exceeds 96 bits");
        balances[account] = sub96(balances[account], _amount, "Vsn Network:: mint: transfer amount overflows");
    }


    function withdraw(address token,address to,uint256 amount) external override{
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external override view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external override returns (bool) {
        uint96 amount = safe96(rawAmount, "Vsn Network:: transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }
    
    function transferFrom(address from,address to, uint rawAmount) external override returns (bool) {
        uint96 amount = safe96(rawAmount, "Vsn Network:: transfer: amount exceeds 96 bits");
        _transferTokens(from, to, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external override returns (bool) {
        uint96 amount = safe96(rawAmount, "Vsn Network:: approve: amount exceeds 96 bits");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }


    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Vsn Network:: _transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Vsn Network:: _transferTokens: cannot transfer to the zero address");
        balances[src] = sub96(balances[src], amount, "Vsn Network:: _transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Vsn Network:: _transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

}
