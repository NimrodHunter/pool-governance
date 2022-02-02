pragma solidity 0.5.0;

import "./base/Configurable.sol";

/**
 * @title configuration contract
 * @author Aave
 */

contract BallotConfiguration is Configurable {

    //providers
    function getRoles() public view returns(address) { return getProvider("roles");}
    function getPool() public view returns(address) { return getProvider("pool");}
    

    //parameters
    function getMaxActivePolls() public view returns(uint256) { return getParameter("maxActivePolls");}
    
}
