// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import "./library/SafeMath.sol";
import "./interfaces/IVsnFactory.sol";
import "./VsnLink.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWLUCA.sol";

contract VsnFactory is IVsnFactory{
    
    using SafeMath for uint256;
    using SafeMath for uint128;
    
    address public luca;
    address public wluca;
    
    bool switchOn;
    // owner
    address public owner;
    // supports total token size   
    uint256 public socialTokensAll; 
    // all contract link array 
    address[] public allLinkAddress;
    // support token address mapping
    mapping(uint256 => address) public socialTokens; 
    mapping(address => SocialToken) public socialTokensSta;

    constructor(address _luca,address _wluca) {    
       owner = msg.sender;
       switchOn = true;
       luca = _luca;
       wluca = _wluca;
    }
    
    uint256 constant MIN_LOCK_DAYS = 1;   
    uint256 constant MAX_LOCK_DAYS = 1825;  
    
    struct SocialToken {
        address token;   // token contract address
        uint256 minAmount;   //min lock amount
        bool isActive;    
    }
    
    // valid user is owner
    modifier checkSwitch() {
        require(switchOn == true,'Vsn Network:only switchOn is off,pls check!');
        _;
    }
    
    // valid user is owner
    modifier onlyOwner() {
        require(msg.sender == owner,'Vsn Network:only owner can operate!');
        _;
    }
    
    // valid percentlimt is range of 1-100
    modifier onlyPercentLimit(uint256 _percent) {
        require(_percent>=0 && _percent<=100,'Vsn Network:The consensus percentage is not in the specified wreath');
        _;
    }

    // valid lockdays is range of 1-1825
    modifier lockTimeLimit(uint256 _lockTime) {
        require(_lockTime>=MIN_LOCK_DAYS && _lockTime<=MAX_LOCK_DAYS,'Vsn Network:The locktime is not in the specified range');
        _;
    }
    
    modifier validToken(address _tokenAddr,uint256 _amount,uint256 _percent) {
        SocialToken memory _socialLink = socialTokensSta[_tokenAddr];
        require(_socialLink.isActive,'Vsn Network:The token is not added to the consensus link');
        require(_amount.div(100).mul(_percent) >= _socialLink.minAmount,'Vsn Network:The token lock min amount is not allowed.');
        _;
    }
    
     /**
     * add token to factory then can create social link with another user account      * 
     */ 
    function addSocialToken(address _tokenAddr, uint256 _minAmount) external override onlyOwner{
        require(socialTokensSta[_tokenAddr].isActive==false,"Vsn Network:Token already exist");
        socialTokensAll++;
        SocialToken memory _socialToken;
        _socialToken.token = _tokenAddr;
        _socialToken.minAmount = _minAmount;
        _socialToken.isActive = true;
        socialTokens[socialTokensAll] = _tokenAddr;
        socialTokensSta[_tokenAddr] = _socialToken;
    }
    
    /**
     * get all VsnLink's number
     * 
     */ 
    function allLinksLength() external override view returns (uint) {
        return allLinkAddress.length;
    }
    
    /**
     * create social link with to user account
     * 
     */ 
    function createSocialLink(
        address _toUser,
        address _token,
        uint256 _amount,
        uint256 _percent,
        uint256 _lockTime
    )
        external 
        override
        onlyPercentLimit(_percent)
        validToken(_token,_amount,_percent)
        lockTimeLimit(_lockTime)
        checkSwitch()
    {
        address createUser = msg.sender;
        address toUser = _toUser;
        address token = _token;
        uint256 amount = _amount;
        uint256 percent = _percent;
        uint256 lockTime = _lockTime;
        
        //require
        require(toUser != address(0), 'Vsn Network:zero address!!!');
        require(toUser != msg.sender, 'Vsn Network:to account is self.');
        //create link and transfer token to link contract
        address link = _createSocilaLink(createUser,token,amount,percent);
        VsnLink(link).initToken(luca,wluca);
        //record link msg on blockchain
        VsnLink(link).initialize(createUser,toUser,token,amount,percent,lockTime);
        emit LinkCreated(createUser,token, link, allLinkAddress.length);
    }
    
    /**
     * create social link without to user account
     * 
     */ 
    function createSocialLink(
        address _token,
        uint256 _amount,
        uint256 _percent,
        uint256 _lockTime
    )
        external 
        override
        onlyPercentLimit(_percent)
        validToken(_token,_amount,_percent)
        lockTimeLimit(_lockTime)
        checkSwitch()
    {
        address createUser = msg.sender;
        address token = _token;
        uint256 amount = _amount;
        uint256 percent = _percent;
        uint256 lockTime = _lockTime;
        
        //require
        require(percent==100, 'Vsn Network:percent max equals 100!!!');
        //create link and transfer token to link contract
        address link = _createSocilaLink(createUser,token,amount,percent);
        VsnLink(link).initToken(luca,wluca);
        //record link msg on blockchain
        VsnLink(link).initialize(createUser,token,amount,percent,lockTime);
        emit LinkCreated(createUser,token, link, allLinkAddress.length);
    } 


    /**
     * 
     */ 
    function setSwitchOn(bool switchOn_) external override onlyOwner{
        switchOn = switchOn_;
    }

    /**
     * create vsn link
     */ 
    function _createSocilaLink(address createUser,address token,uint256 amount,uint256 percent) internal returns(address link){
        // verify create user token balance is > _amount*_percent 
        uint accBalance = IERC20(token).balanceOf(createUser);
        uint createUserAmount = amount.mul(percent).div(100);
        require(createUserAmount <= accBalance,'Vsn Network:address has no enough token coin');
        //create link
        bytes memory bytecode = type(VsnLink).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(createUser,  block.timestamp));
        assembly {
            link := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //push link address to array
        allLinkAddress.push(link);
        //transfer token to contract address
        uint256 accountAmountA = amount.mul(percent).div(100);
        if(token==luca){
            //transfer token to luca token contract          
            IERC20 tempToken = IERC20(token);
            tempToken.transferFrom(msg.sender,wluca,accountAmountA);
            IWLUCA(wluca).deposit(link,accountAmountA);
        }else{
            //transfer         
            IERC20 tempToken = IERC20(token);
            tempToken.transferFrom(msg.sender,link,accountAmountA);
        }
       
        return link;
    }
}