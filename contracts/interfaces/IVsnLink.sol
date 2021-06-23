// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

interface IVsnLink {
    
    event NewLinkCancel(address indexed _createUser,address token1, address indexed link,bool result);

    event NewLinkRefuse(address indexed _createUser,address indexed _toUser,address token1, address indexed link,bool result);
    
    event NewLinkConfirm(address indexed _createUser,address indexed _toUser, address token1, address indexed link,bool result);

    event ConfirmLinkCancel(address indexed _createUser,address indexed _toUser, address token1, address indexed link,bool result);

    event ConfirmLinkRefuse(address indexed _createUser,address indexed _toUser, address token1, address indexed link,bool result);
    
    event CancelConfirm(address indexed _createUser,address indexed _toUser, address token1, address indexed link,bool result);

    event CloseLink(address indexed _createUser,address indexed _toUser, address token1, address indexed link,bool result);

    event Deduction(address indexed link,uint256 amountA,uint256 amountB);


    function initToken(address addr0,address addr1) external;
    
    /**
     *  init link contract value 
     */
    function initialize(address createUser,address reviceUser,address tokenContract,uint256 _amount,uint256 _percent,uint256 _lockTime) external  ;
    
     /**
     *  init link contract value 
     */
    function initialize(address createUser,address tokenContract,uint256 _amount,uint256 _percent,uint256 _lockTime) external  ;
    
    /**
     *  veriy the contract data 
     */
    function verify(address _addrA,address _addrB,uint256 _amount,address _token,uint256 _percent,uint _lockDays) external returns(bool);
    
    /**
     *  veriy the contract data without linkAddressB
     */
    function verify(address _addrA,uint256 _amount,address _token,uint256 _percent,uint _lockDays) external returns(bool);
    
    /**
     * user cancel new link 
     */
	function cancelNewlLink() external;

	/**
	 * user confirm link
	 */
	function confirmLink() external ;
	
    /**
	 * user confirm link with Target account
	 */
	function confirmLink(address _toUser) external ;

	/**
	 * user refuse link
	 */
	function refuseLink() external ;
	
	/**
	 * user send cancel request
	 */
	function cancelLink() external;
	
	/**
	 * user send cancel request
	 */
	function cancelRevoke() external;
	
	/**
	 * user refuse cancel confirm link 
	 */ 
	function cancelRefuseLink() external ;

    /**
	 * user cancel link
	 */
	function cancelConfirm() external ;
	
	/**
	 * user send cancel request
	 */
	function closeLink() external;
	
	/**
	 * deduction account token
	 */ 
	function deduction(uint256 _amountA,uint256 _amountB) external;
	
}