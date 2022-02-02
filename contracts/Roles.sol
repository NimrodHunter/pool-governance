pragma solidity 0.5.0;

import "./Authority.sol";

/**
 * @title Roles
 * @notice Facilitates access to lists of user roles and capabilities.
 * @author Anibal Catalán <anibalcatalanf@gmail.com>.
 *
 * Originally base on code by DappHub.
 * https://github.com/dapphub/ds-roles/blob/master/src/roles.sol
 *
*/

contract Roles is Auth {
    mapping(address => bytes32) public userRoles;
    mapping(address => mapping(bytes4 => bytes32)) public capabilityRoles;
    mapping(address => mapping(bytes4 => bool)) public publicCapabilities;
    
    event LogSetUserRole(address indexed who, bytes32 roles);
    event LogSetPublicCapability(address indexed code, bytes4 signature, bool enabled);
    event LogSetRoleCapability(address indexed code, bytes4 signature, bytes32 roles);

    constructor() public {
        setAuthority(address(this));
    }

    /**
     * @notice Define User rol.
     * @param who user address from which will be defined the role.
     * @param role it is the rol to be defined.
     * @param enabled boolean that represent the definition.
     */
    function setUserRole(address who, uint8 role, bool enabled) public onlyAuth {
        bytes32 lastRoles = userRoles[who];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if (enabled) {
            userRoles[who] = lastRoles | shifted;
        } else {
            userRoles[who] = lastRoles & bitNot(shifted);
        }
        emit LogSetUserRole(who, userRoles[who]);
    }
    
    /**
     * @notice Define public access to a function into a contract.
     * @param code address contract where the access to a function will be defined.
     * @param sig function signature where the access will be defined.
     * @param enabled boolean that represent the definition.
     */
    function setPublicCapability(address code, bytes4 sig, bool enabled) public onlyAuth {
        publicCapabilities[code][sig] = enabled;
        emit LogSetPublicCapability(code, sig, enabled);
    }

    /**
     * @notice Define the access capabilities of some role to some function into a contract.
     * @param role it is the role which will be defined the access capabilities.
     * @param code address contract where the access to a function will be defined.
     * @param sig function signature where the access will be defined.
     * @param enabled boolean that represent the definition.
     */
    function setRoleCapability(uint8 role, address code, bytes4 sig, bool enabled) public onlyAuth {
        bytes32 lastRoles = capabilityRoles[code][sig];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if (enabled) {
            capabilityRoles[code][sig] = lastRoles | shifted;
        } else {
            capabilityRoles[code][sig] = lastRoles & bitNot(shifted);
        }
        emit LogSetRoleCapability(code, sig, capabilityRoles[code][sig]);
    }
    
    /**
     * @notice Return the roles of some address.
     * @param who user address from which the roles are returned.
     */
    function getUserRoles(address who) public view returns(bytes32) {
        return userRoles[who];
    }
    
    /**
     * @notice Return roles capables to call a function inside a contract.
     * @param code address contract by which one asks.
     * @param sig function signature by which one asks.
     */
    function getCapabilityRoles(address code, bytes4 sig) public view returns(bytes32) {
        return capabilityRoles[code][sig];
    }
    
    /**
     * @notice Return if some function into  contract have public access.
     * @param code address contract by which one asks.
     * @param sig function signature by which one asks.
     */
    function isCapabilityPublic(address code, bytes4 sig) public view returns(bool) {
        return publicCapabilities[code][sig];
    }
        
    /**
     * @notice Check if and user have some role
     * @param who user address by which one asks.
     * @param role it is the role by which one asks.
     */
    function hasUserRole(address who, uint8 role) public view returns(bool) {
        bytes32 roles = getUserRoles(who);
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        return bytes32(0) != roles & shifted;
    }
    
    /**
     * @notice Verify if the caller can access to a function into a contract.
     * @param caller user address by which one asks.
     * @param code address contract by which one asks.
     * @param sig function signature by which one asks.
     */
    function canCall(address caller, address code, bytes4 sig) public view returns(bool) {
        if (isCapabilityPublic(code, sig)) {
            return true;
        } else {
            bytes32 hasRoles = getUserRoles(caller);
            bytes32 needsOneOf = getCapabilityRoles(code, sig);
            return bytes32(0) != hasRoles & needsOneOf;
        }
    
    }

    /**
     * @notice Negation btiwise operation.
     * @param input bytes to be negated.
     */
    function bitNot(bytes32 input) internal pure returns(bytes32) {
        return input ^ bytes32(uint256(-1));
    }
}
