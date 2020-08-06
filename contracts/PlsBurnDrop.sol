pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./IBurnableERC20.sol";

contract PlsBurnDrop is Ownable {
    event ClaimedTokens(
        address indexed token,
        address indexed owner,
        uint256 amount
    );

    event BurnDrop(
        address sender,
        uint256 ringAmount,
        uint256 plsAmount
    );

    using SafeMath for uint256;
    uint256 public startRatio = 0;
    uint256 public endRatio = 0;
    uint256 public startTime = 0;
    uint256 public endTime = 0;
    uint256 public denominator = 1000000;
    address public RING_TOKEN;
    address public PLS_TOKEN;
    bool public paused = false;

    constructor(
        uint256 _startRatio,
        uint256 _endRatio,
        uint256 _startTime,
        uint256 _endTime,
        address _ring,
        address _pls
    ) public {
        require(
            _startRatio > 0 && _startRatio < denominator,
            "_startRatio error"
        );
        require(_endRatio > 0 && _endRatio < denominator, "_endRatio error");
        require(_startTime > 0 && _startTime < _endTime, "_startTime error");
        require(_endTime > 0, "_endTime error");
        require(_ring != address(0) && _pls != address(0), "_ring _pls error");

        startRatio = _startRatio;
        endRatio = _endRatio;
        startTime = _startTime;
        endTime = _endTime;
        RING_TOKEN = _ring;
        PLS_TOKEN = _pls;
    }

    modifier isWork() {
        require(!paused, "Not started");
        _;
    }

    /**
     * @dev ERC223 fallback function, make sure to check the msg.sender is from target token contracts
     * @param _from - person who transfer token in for deposits or claim deposit with penalty KTON.
     * @param _amount - amount of token.
     * @param _data - data which indicate the operations.
     */
    function tokenFallback(
        address _from,
        uint256 _amount,
        bytes memory _data
    ) public isWork {
        require(msg.sender == PLS_TOKEN, "Just allow pls tokens.");
        require(_amount > 0, "Transfer token must gt 0.");

        uint256 amountOut = convertFor(_amount);
        IBurnableERC20 ring = IBurnableERC20(RING_TOKEN);
        IBurnableERC20 pls = IBurnableERC20(PLS_TOKEN);

        pls.transfer(address(0), _amount);
        ring.transfer(_from, amountOut);
        emit BurnDrop(_from, amountOut, _amount);
    }

    function convertFor(uint256 _amountIn) public view returns (uint256) {
        if (now > endTime) {
            return _amountIn.mul(endRatio).div(denominator);
        }

        if (now < startTime) {
            return _amountIn.mul(startRatio).div(denominator);
        }

        uint256 timePercent = now.sub(startTime).mul(denominator).div(
            endTime.sub(startTime)
        );

        if (startRatio > endRatio) {
            uint256 gap = startRatio - endRatio;
            return
                _amountIn
                    .mul(startRatio.sub(timePercent.mul(gap).div(denominator)))
                    .div(denominator);
        } else {
            uint256 gap = endRatio - startRatio;
            return
                _amountIn
                    .mul(startRatio.add(timePercent.mul(gap).div(denominator)))
                    .div(denominator);
        }
    }

    function setRatio(uint256 _startRatio, uint256 _endRatio) public onlyOwner {
        require(
            _startRatio > 0 && _startRatio < denominator,
            "Start ratio error."
        );
        require(_endRatio > 0 && _endRatio < denominator, "End ratio error.");
        startRatio = _startRatio;
        endRatio = _endRatio;
    }

    function setTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_startTime > 0 && _startTime < _endTime, "Start time error.");
        require(_endTime > 0, "End time error.");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setRingContract(address _address) public onlyOwner {
        require(_address != address(0), "address error");
        RING_TOKEN = _address;
    }

    function setPlsContract(address _address) public onlyOwner {
        require(_address != address(0), "address error");
        PLS_TOKEN = _address;
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
            return;
        }
        IBurnableERC20 token = IBurnableERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);

        emit ClaimedTokens(_token, msg.sender, balance);
    }

    function setPaused(bool _status) public onlyOwner {
        paused = _status;
    }
}
