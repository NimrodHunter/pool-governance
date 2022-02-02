pragma solidity 0.5.0;

/**
 * @title Authority
 * @notice Flexible and updatable auth pattern which is completely separate from application logic.
 * @author Anibal Catalán <anibalcatalanf@gmail.com>.
 *
 * Originally base on code by DappHub.
 * https://github.com/dapphub/ds-auth/blob/master/src/auth.sol
 * 
*/

contract Authority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}


contract Auth is Authority {
    address public authority;
    address public owner;
    
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(owner);
    }
    
    /**
     * @notice Change the owner of this contract.
     * @param _owner Contract owner address.
     */
    function setOwner(address _owner) public onlyAuth {
        owner = _owner;
        emit LogSetOwner(owner);
    }

    /**
     * @notice Change the contract that act as authority.
     * @param _authority address contract to be changed.
     */
    function setAuthority(address _authority) public onlyAuth {
        authority = _authority;
        emit LogSetAuthority(authority);
    }
    
    /**
     * @notice Authorization verifier.
     */
    modifier onlyAuth {
        require(isAuthorized(msg.sender, address(this), msg.sig), "unauthorized function call");
        _;
    }
    
    /**
     * @notice Verify if a call is authorized.
     * @param src address where the call come from.
     * @param sig signature of the function called.
     */
    function isAuthorized(address src, address dst, bytes4 sig) public view returns (bool) {
 	if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return Authority(authority).canCall(src, dst, sig);
        }
    }
}
