import { ethers } from 'ethers';
import increaseTime, { duration } from './helpers/increaseTime';

const RolesContract = artifacts.require('Roles');
const PoolContract = artifacts.require('Pool');

const ConfigurationContract = artifacts.require('BallotConfiguration');
const BallotContract = artifacts.require('Ballot');

contract('Ballot contract expected flow', (accounts, prov) => {
    let roles;
    let pool;
    let ballot;
    let ballotABI;
    let poolABI;	
    
    const LiquidityProviderRole = 1;
    const GovernanceRole = 2;
    
    before(async () => {
	roles = await RolesContract.new();
	
	await roles.setUserRole(accounts[1], LiquidityProviderRole, true);
        await roles.setUserRole(accounts[2], LiquidityProviderRole, true);
        await roles.setUserRole(accounts[3], LiquidityProviderRole, true);

	pool = await PoolContract.new(roles.address);
	poolABI = new ethers.utils.Interface(pool.abi);

	const configuration = await ConfigurationContract.new();
	await configuration.setProvider("pool", pool.address);
	await configuration.setProvider("roles", roles.address);
	await configuration.setParameter("maxActivePolls", 3);
	
        ballot = await BallotContract.new(configuration.address);
        ballotABI = new ethers.utils.Interface(ballot.abi);

	await roles.setRoleCapability(LiquidityProviderRole, ballot.address, ballotABI.functions.startPoll.sighash, true);
        await roles.setRoleCapability(LiquidityProviderRole, ballot.address, ballotABI.functions.vote.sighash, true);
	await roles.setUserRole(ballot.address, GovernanceRole, true);
	await roles.setRoleCapability(GovernanceRole, pool.address, poolABI.functions.setInterest.sighash, true);
    });

    it('should create a new poll', async () => {
        let values = [5];
        const optionOne = poolABI.functions.setInterest.encode(values);
        values = [2];
        const optionTwo = poolABI.functions.setInterest.encode(values);
        const options = [optionOne, optionTwo];
        await ballot.startPoll(pool.address, poolABI.functions.setInterest.sighash, options, { from: accounts[1] });
        const pollNonce = await ballot.pollNonce();
        assert.equal(pollNonce, 1, 'should be 1');
        const dllPolls = await ballot.dllPolls();
        assert.equal(dllPolls.last.valueOf(), 1, 'should be 1');
        assert.equal(dllPolls.last.valueOf(), 1, 'should be 1');
        assert.equal(dllPolls.count.valueOf(), 1, 'should be 1');
	const exists = await ballot.pollExists(pollNonce);
        assert.equal(exists, true, 'should be true');
    });

    it('should vote properly', async () => {
        const pollNonce = await ballot.pollNonce();
        await ballot.vote(pollNonce.valueOf(), 1, { from: accounts[1] });
        await ballot.vote(pollNonce.valueOf(), 1, { from: accounts[2] });
        await ballot.vote(pollNonce.valueOf(), 2, { from: accounts[3] });
    });

    it('should end ballot properly', async () => {
	let interest = await pool.interest();
	assert.equal(interest, 3, 'should be 3');
        const pollNonce = await ballot.pollNonce();
        await increaseTime(duration.hours(6));
        await ballot.endPoll();
        const expired = await ballot.pollExpired(pollNonce);
        assert.equal(expired, true, 'should be true');
        const executed = await ballot.pollExecuted(pollNonce);
        assert.equal(executed, true, 'should be true');
	interest = await pool.interest();
	assert.equal(interest, 5, 'should be 5');
    });
/*

    it('should not have tokens locked', async () => {
        const isLocked = await ballot.areTokensLocked(accounts[1]);
        assert.equal(isLocked, false, 'should be false');
    });

    it('should create three polls', async () => {
        let values = [25, 25, 6, 2, 30, 35, 7];
        let optionOne = ballotABI.functions.setBallotParams.encode(values);
        values = [5, 5, 2, 1, 10, 25, 4];
        let optionTwo = ballotABI.functions.setBallotParams.encode(values);
        let options = [optionOne, optionTwo];
        await ballot.startPoll(4, options, ballot.address);

        values = [22, 23, 4, 1, 27, 32, 8];
        optionOne = ballotABI.functions.setBallotParams.encode(values);
        values = [40, 40, 3, 2, 22, 28, 5];
        optionTwo = ballotABI.functions.setBallotParams.encode(values);
        options = [optionOne, optionTwo];
        await ballot.startPoll(1, options, ballot.address);

        values = [22, 23, 4, 1, 27, 32, 8];
        optionOne = ballotABI.functions.setBallotParams.encode(values);
        values = [40, 40, 3, 2, 22, 28, 5];
        optionTwo = ballotABI.functions.setBallotParams.encode(values);
        options = [optionOne, optionTwo];
        await ballot.startPoll(2, options, ballot.address);

        const dllPolls = await ballot.dllPolls();
        assert.equal(dllPolls.count.valueOf(), 3, 'should be 3');
    });

    it('should be locked the tokens', async () => {
        const pollNonce = await ballot.pollNonce();
        await ballot.vote(pollNonce.valueOf(), 1, { from: accounts[1] });
        const isLocked = await ballot.areTokensLocked(accounts[1]);
        assert.equal(isLocked, true, 'should be true');
    });
*/
});
