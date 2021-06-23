// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import './interfaces/IVsnLink.sol';
import './library/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IVsnFactory.sol';
import './LUCA.sol';
import './WLUCA.sol';

contract VsnLink is IVsnLink {
    
    
    address private luca;
    address private wluca;

    
    using SafeMath for uint256;
    using SafeMath for uint128;
    
    address private factory;
    address public cancelAccount;
    // create link amount
    uint256 public totalAmount;  
    // create user A address
    address public linkAddressA;
    // confirm user B address
    address public linkAddressB;
    // create user A lock token amount
    uint256 public linkAmountA;  
    // confirm user B lock token amount
    uint256 public linkAmountB; 
    // the user A deduction token amount which is cancel
    uint256 public deductAmountA;  
    // the user B deduction token amount which is cancel
    uint256 public deductAmountB;
    // token contract address
    address public tokenAddr;
    // create User A send percent of totalAmount
    uint256 public percent;   
    // link start day which is activel
    uint256 public startDay;  
    // link lock the days
    uint256 public lockDays;    
    // link exprire day
    uint256 public expiredDay;  
    // link close day 
    uint256 public closeDay; 
    // link status   [0-New,1-Confirm,2-Cancel,3-Close]
    LinkStatus public status;
    
    // link status
    enum LinkStatus{
        New,        // New link. Waitting confirm
        Confirm,    // confirm link
        Cancel,     // confirm link user send cancel
        Close       // link close
    }
    
    constructor() {
        factory = msg.sender;
    }
  
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Vsn Network: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    
    function initToken(address addr0,address addr1) external override{
        require(msg.sender == factory, 'Vsn Network: FORBIDDEN');
        luca = addr0;
        wluca = addr1;
    }
    
    /**
     *  init link data
     */
    function initialize(address createUser,address reviceUser,address tokenContract,uint256 _amount,uint256 _percent,uint256 _lockTime)  external override  {
        require(msg.sender == factory, 'Vsn Network: FORBIDDEN');
        // init link value 
        linkAddressA = createUser;
        linkAddressB = reviceUser;
        totalAmount = _amount;
        linkAmountA = _amount.mul(_percent).div(100);
        linkAmountB = SafeMath.sub(_amount,linkAmountA);
        tokenAddr = tokenContract;
        percent = _percent;
        lockDays = _lockTime;
        if(_percent==100){
            startDay = block.timestamp;
            closeDay =  SafeMath.add(startDay, lockDays * 1 days);
            expiredDay = SafeMath.add(startDay, lockDays * 1 days);
            status = LinkStatus.Confirm;
            emit NewLinkConfirm(linkAddressA, linkAddressB, tokenAddr, address(this),true);
        }else{
           status = LinkStatus.New;
        }
    }
    
    /**
     *  init link data
     */
    function initialize(address createUser,address tokenContract,uint256 _amount,uint256 _percent,uint256 _lockTime)  external override  {
        require(msg.sender == factory, 'Vsn Network: FORBIDDEN');
        // init link value 
        linkAddressA = createUser;
        totalAmount = _amount;
        linkAmountA = _amount.mul(_percent).div(100);
        linkAmountB = SafeMath.sub(_amount,linkAmountA);
        tokenAddr = tokenContract;
        percent = _percent;
        lockDays = _lockTime;
        status = LinkStatus.New;
    }
    
    /**
     * verify link contract data 
     */
    function verify(address _addrA,address _addrB,uint256 _amount,address _token,uint256 _percent,uint256 _lockDays) external override  view  returns(bool){
        //require(msg.sender == linkAddressA, 'Vsn Network: FORBIDDEN');
        if(_addrA!=linkAddressA){
            return false;
        }
        if(_addrB!=linkAddressB){
            return false;
        }
        if(_amount!=totalAmount){
            return false;
        }
        if(_token!=tokenAddr){
            return false;
        }
        if(_percent!=percent){
            return false;
        }
        if(_lockDays!=lockDays){
            return false;
        }
        
        return true;
    }
    
    /**
     * verify link contract data  without linkAddressB 
     */
    function verify(address _addrA,uint256 _amount,address _token,uint256 _percent,uint256 _lockDays) external override  view  returns(bool){
        //require(msg.sender == linkAddressA, 'Vsn Network: FORBIDDEN');
        if(_addrA!=linkAddressA){
            return false;
        }
        if(_amount!=totalAmount){
            return false;
        }
        if(_token!=tokenAddr){
            return false;
        }
        if(_percent!=percent){
            return false;
        }
        if(_lockDays!=lockDays){
            return false;
        }
        
        return true;
    }
    
    /**
     * user cancel New link
     */
    function cancelNewlLink() external override lock {
        require(status==LinkStatus.New,'Vsn Network: must be new status can do it.');      
        // valid sender is revice user address
        require(msg.sender == linkAddressA,'Vsn Network: must be link account can do it.');
        //give back account coin to address
        IERC20 tempToken = IERC20(tokenAddr);
        if(tokenAddr==luca){
            IWLUCA wtoken = IWLUCA(wluca);
            wtoken.burn(address(this),linkAmountA);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressA,linkAmountA);
        }else{
            tempToken.transfer(linkAddressA,linkAmountA);
        }
        //user send cancel request to another user
        status = LinkStatus.Close;
        //event
        emit NewLinkCancel(msg.sender,tokenAddr, address(this),true);
    }
    
    /**
     * user refuse link
     */
    function refuseLink() external override lock{
        require(status==LinkStatus.New,'Vsn Network: must be new status can do it.');
        // valid sender is revice user address
        require(msg.sender == linkAddressB,'Vsn Network: must be confirm account can do it.');
        //give back account coin to address
        IERC20 tempToken = IERC20(tokenAddr);
        if(tokenAddr==luca){
            IWLUCA wtoken = IWLUCA(wluca);
            wtoken.burn(address(this),linkAmountA);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressA,linkAmountA);
        }else{
            tempToken.transfer(linkAddressA,linkAmountA);
        }
        
        //update link status
        status = LinkStatus.Close;
        //event
        emit NewLinkRefuse(linkAddressA, linkAddressB, tokenAddr, address(this), true);
    }
    
    /**
     * user confirm New link
     */
    function confirmLink() external override lock{
        require(status==LinkStatus.New,'Vsn Network: must be new status can do it.');      
        require(msg.sender == linkAddressB,'Vsn Network: must be confirm account can do it.');
        uint256 balance = IERC20(tokenAddr).balanceOf(msg.sender);
        require(linkAmountB <= balance,'Vsn Network:user has no enough token coin to confirm link.');
        
        // update link data
        startDay = block.timestamp;
        closeDay =  SafeMath.add(startDay, lockDays * 1 days);
        expiredDay = SafeMath.add(startDay, lockDays * 1 days);
        status = LinkStatus.Confirm;
        
        IERC20 tempToken = IERC20(tokenAddr);
        if(tokenAddr==luca){
            IWLUCA wtoken = IWLUCA(wluca);
            //transfer lunca to wluca token address
            tempToken.transferFrom(msg.sender,wluca,linkAmountB);
            //transfer wluca to link address==> deposit
            wtoken.deposit(address(this),linkAmountB);
        }else{
            tempToken.transferFrom(msg.sender,address(this),linkAmountB);
        }
        
        emit NewLinkConfirm(linkAddressA, linkAddressB, tokenAddr, address(this),true);
    }
    
    /**
     * user confirm New link with target user account
     */
    function confirmLink(address _toUser) external override lock{
        require(status==LinkStatus.New,'Vsn Network: must be new status can do it.');      
        require(msg.sender == linkAddressA,'Vsn Network: must be confirm account can do it.');
        require(percent==100,'Vsn Network: percent must be 100.');
        linkAddressB = _toUser;
        startDay = block.timestamp;
        closeDay =  SafeMath.add(startDay, lockDays * 1 days);
        expiredDay = SafeMath.add(startDay, lockDays * 1 days);
        status = LinkStatus.Confirm;
    }

    /**
     * user cancel confirm link
     */
    function cancelLink() external override lock{
        require(status==LinkStatus.Confirm,'Vsn Network: must be confirm status can do it.');
        // valid sender is revice user address
        require(msg.sender == linkAddressA || msg.sender == linkAddressB,'Vsn Network: must be link account can do it.');
        cancelAccount = msg.sender;
        //user send cancel request to another user
        status = LinkStatus.Cancel;
        //event
        emit ConfirmLinkCancel(linkAddressA, linkAddressB, tokenAddr, address(this), true);
    }
    
    /**
     * cancel account revoke cancel link request
     */ 
    function cancelRevoke() external override lock{
        require(status==LinkStatus.Cancel,'Vsn Network: must be cancel status can do it.');
        // valid sender is revice user address
        require(msg.sender == cancelAccount,'Vsn Network: must be cancel account can do it.');
        //user send cancel request to another user
        status = LinkStatus.Confirm;
    }
    
    
    /**
     * account refuse cancel request
     */
    function cancelRefuseLink() external override lock{
        require(status==LinkStatus.Cancel,'Vsn Network: must be cancel status can do it.');
         // if cancel request is account A,so valid link address B is msg.sender 
        if(cancelAccount == linkAddressA){
            require(msg.sender == linkAddressB,'Vsn Network: must be cancel confirm account can do it.');
        }
        // if cancel request is account B,so valid link address A is msg.sender 
        if(cancelAccount == linkAddressB){
            require(msg.sender == linkAddressA,'Vsn Network: must be cancel confirm account can do it.');
        }
        
        //user send cancel request to another user
        status = LinkStatus.Confirm;
        //event
        emit ConfirmLinkRefuse(linkAddressA, linkAddressB, tokenAddr, address(this), true);
    }
    
    /**
     * user confirm cancel link 
     */
    function cancelConfirm() external override lock{
        require(status==LinkStatus.Cancel,'Vsn Network: must be cancel status can do it.');
        // if cancel request is account A,so valid link address B is msg.sender 
        if(cancelAccount == linkAddressA){
            require(msg.sender == linkAddressB,'Vsn Network: must be cancel confirm account can do it.');
        }
        // if cancel request is account B,so valid link address A is msg.sender 
        if(cancelAccount == linkAddressB){
            require(msg.sender == linkAddressA,'Vsn Network: must be cancel confirm account can do it.');
        }
        
        //calculate the coin of account punish。 total percentage is 20%
        (uint256 _backAmountA, uint256 _backAmountB) = _calculateDeductionAmount();
        
        IERC20 tempToken = IERC20(tokenAddr);
        if(tokenAddr==luca){
            
            IWLUCA wtoken = IWLUCA(wluca);
            wtoken.burn(address(this),_backAmountA);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressA,_backAmountA);
            
            //transfer remain token to A Account
             wtoken.burn(address(this),_backAmountB);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressB,_backAmountB);
        }else{
            tempToken.transferFrom(address(this),linkAddressA,_backAmountA);
            //transfer remain token to B Account
            tempToken.transferFrom(address(this),linkAddressB,_backAmountB);
        }
        
        status = LinkStatus.Close;
        closeDay = block.timestamp;
         //event
        emit CancelConfirm(linkAddressA, linkAddressB, tokenAddr, address(this), true);
    }
    
    /**
     * user send cancel request
     */
    function closeLink() external override lock{
        // require status is confirm
        require(status==LinkStatus.Confirm,'Vsn Network: must be confirm status can do it.');
        // require send user is A or B 
        require(msg.sender == linkAddressA || msg.sender == linkAddressB,'Vsn Network: must be link account can do it.');
        // require time >= expiredDay
        require(expiredDay <= block.timestamp,'Vsn Network: FORBIDDEN');
        
        IERC20 tempToken = IERC20(tokenAddr);
        if(tokenAddr==luca){
            IWLUCA wtoken = IWLUCA(wluca);
            wtoken.burn(address(this),linkAmountA);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressA,linkAmountA);
            
            wtoken.burn(address(this),linkAmountB);
            //transfer tokenAddr token from wluca to linkAddressA account
            wtoken.withdraw(luca,linkAddressB,linkAmountB);
        }else{
            //send A amount to A address
            tempToken.transferFrom(address(this),linkAddressA,linkAmountA);
            //send B amount to B address
            tempToken.transferFrom(address(this),linkAddressB,linkAmountB);
        }
        status = LinkStatus.Close;
        //event
        emit CloseLink(linkAddressA, linkAddressB, tokenAddr, address(this), true);
    }
    

    /**
     * deduction account lock lvr token
     */ 
    function deduction(uint256 _amountA,uint256 _amountB) external override lock{
        // require status is confirm
        require(status==LinkStatus.Confirm,'Vsn Network: must be confirm status can do it.');
        //require(tokenAddr=="",'Vsn Network: tokenAddr must be lvr token contract address.');
        
        LUCA lvr = LUCA(tokenAddr);
        address _recycler = lvr.recycler();
        address _minter = lvr.minter();
        require(msg.sender == _minter ,'Vsn Network: msg.sender must be minter account address.');
        
        //update lvr lock value
        linkAmountA = SafeMath.sub(linkAmountA,_amountA);
        linkAmountB = SafeMath.sub(linkAmountB,_amountB);
        totalAmount = SafeMath.add(linkAmountA,linkAmountB);
        
        //send A amount to A address
        lvr.transferFrom(address(this),_recycler,_amountA);
        //send B amount to B address
        lvr.transferFrom(address(this),_recycler,_amountB);
        //event
        emit Deduction(address(this), _amountA, _amountB);
    }
    
    /**
     * calculate the amount of account give back
     */ 
    function _calculateDeductionAmount() private returns (uint256 backAmountA,uint256 backAmountB){
        uint256 fee = 100;
        if(expiredDay > block.timestamp){
            uint256 t = SafeMath.sub(expiredDay, block.timestamp);
            // less of a day. subtract 20% of account lock token value
            if(t > 1 days){
                // remaminDay/lockDays * 20%. min is 1%
                fee = t.mul(100).div(lockDays*1 days);
                // if fee equal zero, fee is 1;
                fee = fee<=5?5:fee;
                fee = fee>100?100:fee;
            }
        }else{
           fee = 5; 
        }
        // *20%. see see next divide 1000
        fee = fee.mul(20).div(10);
        deductAmountA = linkAmountA.mul(fee).div(1000);
        deductAmountB = linkAmountB.mul(fee).div(1000);
        backAmountA = SafeMath.sub(linkAmountA,deductAmountA);
        backAmountB = SafeMath.sub(linkAmountB,deductAmountB);
    }
 
}
