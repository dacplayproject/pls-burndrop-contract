pragma solidity ^0.6.0;

interface IBurnableERC20 {
    function burn(address _from, uint _value) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}