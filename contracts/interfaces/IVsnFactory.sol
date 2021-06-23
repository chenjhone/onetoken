// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

interface IVsnFactory {
    
    event LinkCreated(address indexed _createUser, address indexed _token1, address _link, uint _length);

    function setSwitchOn(bool _switchOn) external;

    function allLinksLength() external  returns (uint);

    function createSocialLink(address _toUser,address _token,uint256 _amount,uint256 _percent,uint256 _lockTime) external;
    
    function createSocialLink(address _token,uint256 _amount,uint256 _percent,uint256 _lockTime) external;
    
    function addSocialToken(address _tokenAddr, uint256 _minAmount) external;

}