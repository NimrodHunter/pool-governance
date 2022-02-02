pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import "./Roles.sol";

/**
 * @title Pool.
 * @notice Dummy Pool.
 * @author Anibal Catalán <anibalcatalanf@gmail.com>.
 */

contract Pool {
    address public roles;
    uint256 public interest;

    constructor(address _roles) public {
	require(_roles != address(0), "invalid _roles address");
	roles = _roles;
        interest = 3;
    }

    function isValidPoll(address sender, address _code, bytes4 _sig, bytes[] memory _datas) public view returns (bool) {
	return true;
    }

    function getPollDuration(address sender, address _code, bytes4 _sig, bytes[] memory _datas) public view returns (uint256) {
	return 3 hours;
    }

    function getVoteWeight(address sender, address _code, bytes4 _sig, bytes[] memory _datas) public view returns (uint256) {
	return 1000;
    }

    function getQuorum(address _code, bytes4 _sig, bytes[] memory _datas) public view returns (uint256) {
	return 50; 
    }

    function setInterest (uint256 newInterest) public onlyAuth {
	interest = newInterest;
    }

    modifier onlyAuth {
        require(Roles(roles).isAuthorized(msg.sender, address(this), msg.sig), "unauthorized function call");
	_;
    } 
}
