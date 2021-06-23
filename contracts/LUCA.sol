// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import './library/SafeMath.sol';
import './interfaces/IERC20.sol';

contract LUCA is IERC20{
                
    /// @notice EIP-20 token name for this token
    string public constant name = "VSN";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "LUCA";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;

    mapping (address => mapping (address => uint96)) internal allowances;

    address public creator;

    /// @notice Address which may mint new tokens
    address public minter;

    /// @notice Address which can recive burn coin
    address public recycler;
    
    /// @notice Address which can recive mint coin
    address public burse;

    /// @notice The timestamp after which minting may occur
    uint public mintingAllowedAfter;

    /// @notice Minimum time between mints
    uint32 public constant minimumTimeBetweenMints = 1 days;

    mapping (address => uint96) internal balances;

    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    /// @notice An event thats emitted when the Recycler address is changed
    event RecyclerChanged(address recycler, address newRecycler);

    /// @notice An event thats emitted when the Burse address is changed
    event BurseChanged(address burse, address newBurse);
    
    /**
     * @notice Construct a new lvr token
     * @param minter_ The account with minting ability
     * @param burse_ The account with receive mint token
     * @param recycler_ The account with recycle token
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor (address minter_,address burse_,address recycler_, uint mintingAllowedAfter_)  {
        require(mintingAllowedAfter_ >= block.timestamp, "Vsn Network:: constructor: minting can only begin after deployment");
        minter = minter_;
        recycler = recycler_;
        burse = burse_;
        creator = msg.sender;
        emit MinterChanged(address(0), minter);
        emit RecyclerChanged(address(0), recycler);
        mintingAllowedAfter = mintingAllowedAfter_;
    }

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
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == creator, "Vsn Network:: setMinter: only the creator can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }


    /**
     * @notice Mint new tokens
     * @param amount The address of the destination account
     */
    function mint(uint256 amount) external {
        require(msg.sender == minter, "Vsn Network:: mint: only the minter can mint");
        //require(block.timestamp >= mintingAllowedAfter, "Vsn Network:: mint: minting not allowed yet");
        // record the mint time
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);
        // incre the amount
        uint96 _amount = safe96(amount,"Vsn Network:: mint: increAmount exceeds 96 bits");
        totalSupply = safe96(SafeMath.add(totalSupply, _amount), "Vsn Network:: mint: totalSupply exceeds 96 bits");
        // transfer the amount to the recipient
        balances[burse] = add96(balances[burse], _amount, "Vsn Network:: mint: transfer amount overflows");
        emit Transfer(address(0), burse, amount);
    }


    function burn(address account, uint256 amount) external{
        require(msg.sender == minter, "Vsn Network:: mint: only the minter can do it.");
        require(account != address(0), "Vsn Network:: burn: from the zero address");
        uint96 recAmount = safe96(amount, "Vsn Network:: burn: amount exceeds 96 bits");
        _transferTokens(account, address(0), recAmount);
        totalSupply = safe96(SafeMath.sub(totalSupply, amount), "Vsn Network:: burn: totalSupply exceeds 96 bits");
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Change the burse address
     * @param burse_ The address of the new burse
     */
    function setBurse(address burse_) external {
        require(msg.sender == creator, "Vsn Network:: setBurse: only the creator can change the burse address");
        emit BurseChanged(burse, burse_);
        burse = burse_;
    }

    /**
     * @notice Change the recycler address
     * @param recycler_ The address of the new recycler
     */
    function setRecycler(address recycler_) external {
        require(msg.sender == creator, "Vsn Network:: setMinter: only the creator can change the recycler address");
        emit RecyclerChanged(recycler, recycler_);
        recycler = recycler_;
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
