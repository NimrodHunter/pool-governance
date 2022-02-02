pragma solidity 0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Configurable smart contract.
 * @notice The configuration holds two different type of attributes - providers and parameters. Providers are addresses of other contracts that are being called as services, parameters are specific configuration parameters stored as uint256.
 * @author Aave
 */

contract Configurable is Ownable {


    mapping(bytes4 => address) public providers;
    mapping(bytes4 => uint256) public parameters;


    function getProvider(string memory _key) public view returns (address) {
        return providers[bytes4(keccak256(abi.encodePacked(_key)))];
    }

    function setProvider(string memory _key, address _addr) public onlyOwner {
        providers[bytes4(keccak256(abi.encodePacked(_key)))] = _addr;
    }

    function getParameter(string memory _key) public view returns (uint256) {
        return parameters[bytes4(keccak256(abi.encodePacked(_key)))];
    }

    function setParameter(string memory _key, uint _param) public onlyOwner {
        parameters[bytes4(keccak256(abi.encodePacked(_key)))] = _param;
    }


}
