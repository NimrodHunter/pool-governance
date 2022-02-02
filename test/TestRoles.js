import expectThrow from './helpers/expectThrow';

const RoleContract = artifacts.require('Roles');

contract('Roles contract expected flow', (accounts) => {
    let roles;
    const owner = accounts[0];
    const zeroRoles = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const zeroAddress = '0x0000000000000000000000000000000000000000';
    const directorRole = 0;
    const dummyRole = 16;
    const director = accounts[2];
 
    before(async () => {
        roles = await RoleContract.new();
    });

    it('should set owner properly', async () => {
        let _owner = await roles.owner();
        assert.equal(_owner, owner, 'should be the same account[0]');
    });

    it('should set authority properly', async () => {
        let authority = await roles.authority();
        assert.equal(authority, roles.address, 'should be the same that roles contract address');
        
        const ninjaAddress = accounts[5];
        expectThrow(roles.setOwner(ninjaAddress, { from: ninjaAddress }));

        await roles.setAuthority(ninjaAddress);
        authority = await roles.authority();
        assert.equal(authority, ninjaAddress, 'should be the same that ninja address');
	await roles.setAuthority(roles.address);
    });

    it('should set role properly', async () => {
        await roles.setUserRole(director, directorRole, true);
        let isDirectorRole = await roles.hasUserRole(director, directorRole);
        assert.equal(isDirectorRole, true, 'should be true');
        const userRole = await roles.getUserRoles(director);
        assert.equal(userRole, '0x0000000000000000000000000000000000000000000000000000000000000001', 'should be 0x1');

        await roles.setUserRole(director, directorRole, false);
        isDirectorRole = await roles.hasUserRole(director, directorRole);
        assert.equal(isDirectorRole, false, 'should be false');
    });

    it('should set public capabilities properly', async () => {
        const setUserRoleSignature = roles.abi.find(fun => fun.name === 'setUserRole').signature;
        await roles.setPublicCapability(roles.address, setUserRoleSignature, true);
        const isPublicCapability = await roles.isCapabilityPublic(roles.address, setUserRoleSignature);
        assert.equal(isPublicCapability, true, 'should be true');
        const ninjaAccount = accounts[8];
        await roles.setUserRole(ninjaAccount, dummyRole, true, { from: ninjaAccount });
        const isDummyRoleRole = await roles.hasUserRole(ninjaAccount, dummyRole);
        assert.equal(isDummyRoleRole, true, 'should be true');
    });

    it('should set role capabilities properly', async () => {
        await roles.setUserRole(director, directorRole, true);
        const setOwnerSignature = roles.abi.find(fun => fun.name === 'setOwner').signature;
        
        await roles.setRoleCapability(directorRole, roles.address, setOwnerSignature, true);
        const userRoles = await roles.getUserRoles(director);
        
        let capabilityRoles = await roles.getCapabilityRoles(roles.address, setOwnerSignature);
        assert.equal(userRoles, capabilityRoles, 'should be the same');
        
        const newOwner = accounts[7];
        await roles.setOwner(newOwner, { from: director });
        
        const _newOwner = await roles.owner();
        assert.equal(newOwner, _newOwner, 'should be accounts[7]');
        
        await roles.setRoleCapability(directorRole, roles.address, setOwnerSignature, false, { from: newOwner });
        capabilityRoles = await roles.getCapabilityRoles(roles.address, setOwnerSignature);
        assert.equal(capabilityRoles, zeroRoles, 'should be the same');
    });
    
});
