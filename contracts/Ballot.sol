pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import "./Roles.sol";
import "./Pool.sol";
import "./DLL.sol";
import "./configuration/BallotConfiguration.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Ballot  {
    using SafeMath for uint256;
    using DLL for DLL.Data;

    uint256 constant public INITIAL_POLL_NONCE = 0;
    uint256 public pollNonce;

    // Poll params
    mapping(uint256 => Poll) public pollMap; // maps pollID to Poll struct.
    DLL.Data public dllPolls; // list of active polls.

    BallotConfiguration configuration;

    struct Poll {
        uint256 endDate; // poll expiration.
        uint256 winningOption; // result of the poll.
        uint256 executedTimestamp; // timestamp when the winning option was executed.
        mapping(uint256 => uint256) votesTally; //tally of votes of different options.
        mapping(address => uint256) voteOptions; // stores the voteOption of an address.
        address code; // smart contract to be called.
        bytes4 sig; // function signature to be triggered.
        bytes[] datas; // different options to be use as parameter.
    }

    event LogPollCreated(uint256 endDate, bytes[] datas, uint256 indexed pollID, address indexed creator);
    event LogVote(address indexed voter, uint256 indexed pollID, uint256 option, uint256 votes);
    event LogPollEnded(uint256 indexed pollID, uint256 winningOption, uint256 winningPercentage, bool executed);

    constructor(address _configuration) public {
        require(_configuration != address(0), "address 0 not valid"); 
        configuration = BallotConfiguration(_configuration);
        pollNonce = INITIAL_POLL_NONCE;
    }

    modifier onlyAuth {
        require(Roles(configuration.getRoles()).isAuthorized(msg.sender, address(this), msg.sig), "unauthorized function call");
        _;
    }

    modifier finishPoll {
        endPoll();
        _;
    }

    /**
     * @notice Start a new poll, the poll will determine which call will be done by the voting contract, only can be one poll active at once.
     * @param _code It is the smart contract address to be called.
     * @param _sig It is the smart contract function signature, related with the function to be executed.
     * @param _datas It is the data option to be chosen in the poll, this data will be the msg.data of next call to be executed.
                                 
     * @return pollID  poll identifier.                                                       
     */      
    function startPoll(address _code, bytes4 _sig, bytes[] memory _datas)
        public
        onlyAuth
	finishPoll
        returns (uint256 pollID) {
            require(_code != address(0), "address 0 not valid");
			require(_datas.length > 0, "at least should be one option");
            require(isValidPoll(_code, _sig, _datas), "invalid poll");
            
            uint256 pollDuration = Pool(configuration.getPool()).getPollDuration(msg.sender, _code, _sig, _datas);
			
			pollNonce = pollNonce + 1;
			uint256 _endDate = block.timestamp.add(pollDuration);

			pollMap[pollNonce] = Poll({
				endDate: _endDate,
				winningOption: 0,
				executedTimestamp: 0,
				code: _code,
                sig: _sig,
				datas: _datas
			});

			insertPoll(pollNonce);

			emit LogPollCreated(_endDate, _datas, pollNonce, msg.sender);
			return pollNonce;
        }

	/**
     * @notice vote for the current poll.
     * @param pollID poll identifier.
     * @param option poll option chosen by the user.
     */  
    function vote(uint256 pollID, uint256 option)
	public
	onlyAuth
	finishPoll {
	    Poll storage poll = pollMap[pollID];
		
	    require(pollExists(pollID) && !pollExpired(pollID), "invalid poll");
	    require(option <= poll.datas.length, "option out of range");
	    require(poll.voteOptions[msg.sender] == 0, "user already voted");
		 
	    uint256 voteCount = Pool(configuration.getPool()).getVoteWeight(msg.sender, poll.code, poll.sig, poll.datas);
	    poll.voteOptions[msg.sender] = option;
	    poll.votesTally[option] = poll.votesTally[option].add(voteCount);
	    emit LogVote(msg.sender, pollID, option, voteCount);
    }

	/**
	 * @notice Ends the poll with the first end date and execute the transaction chosen.
	 */
	function endPoll() public {
		uint256 pollID = dllPolls.first;
		if (pollExpired(pollID)) {
			Poll storage poll = pollMap[pollID];
			uint256 temporalWinning;
			uint256 total;
			for (uint256 i = 0; i <= poll.datas.length; i++) {
				if (poll.votesTally[i] > temporalWinning) {
					temporalWinning = poll.votesTally[i];
					poll.winningOption = i;
				}
				total = total.add(poll.votesTally[i]);
			}
			uint256 winingPercentage = temporalWinning.mul(10000).div(total);
			if (winingPercentage > Pool(configuration.getPool()).getQuorum(poll.code, poll.sig, poll.datas) && poll.winningOption != 0) {
				require(executeResult(pollID, gasleft()), "call execution fail");
				poll.executedTimestamp = block.timestamp;
			}
			dllPolls.remove(pollID);
			emit LogPollEnded(pollID, poll.winningOption, winingPercentage, poll.executedTimestamp != 0);
		}
	} 

    /**
     * @notice Verify if the poll exists.
     * @param pollID identifier of the poll.
     * @return true if the poll exist.
     */
    function pollExists(uint256 pollID) public view returns (bool) {
		return (pollID != 0 && pollID <= pollNonce);
	}

	/**
	 * @notice Verify if the poll expired.
	 * @param pollID identifier of the poll.
	 * @return true if the poll expired.
	 */
	function pollExpired(uint256 pollID) public view returns (bool) {
		return (pollExists(pollID) && pollMap[pollID].endDate < block.timestamp);
	}

	/**
	 * @notice Verify if the poll winning option was executed.
	 * @param pollID identifier of the poll.
	 * @return true if the poll was executed.
	 */
	function pollExecuted(uint256 pollID) public view returns (bool) {
		return (pollMap[pollID].executedTimestamp != 0);
	}

	/**
	 * @notice Insert a poll to the active polls list, it is ordered by its duration.                     
     * @param pollID poll identifier.                                                                     
     */
	function insertPoll(uint256 pollID) internal {
		uint256 maxActivePolls = configuration.getMaxActivePolls();
		if (maxActivePolls > 0) {
			require(dllPolls.count < maxActivePolls, "too many polls");
		}

		Poll memory newPoll = pollMap[pollID];
		uint256 currentPoll = dllPolls.last;
		
		if (dllPolls.count == 0) {
			dllPolls.insert(0, pollID, 0);
		} else if (newPoll.endDate < pollMap[dllPolls.first].endDate) {
			dllPolls.insert(0, pollID, dllPolls.first);
		} else {
			for (uint256 i = dllPolls.count; i > 0; i--) {
				if (newPoll.endDate >= pollMap[currentPoll].endDate) {
					uint256 next = dllPolls.getNext(currentPoll);
					dllPolls.insert(currentPoll, pollID, next);
					break;
				}
				currentPoll = dllPolls.getPrev(currentPoll);
			}
		}
	}

	/**
	 * @notice Execute the poll results.
	 * @param pollID poll identifier.
	 * @param txGas transaction gas needed to execute the transaction chosen.
	 * @return success true winning poll call was executed.
	 */
	function executeResult(uint256 pollID, uint256 txGas) internal returns (bool success) {
		Poll memory poll = pollMap[pollID];
		address code = poll.code;
		uint256 winningOption = poll.winningOption.sub(1);
		bytes memory data = poll.datas[winningOption];
		/* solhint-disable indent */
		assembly {
			success := call
			(
				txGas,
				code,
				0,
				add(data, 0x20),
				mload(data),
				0,
				0
			)
		}
	}

    function isValidPoll(address _code, bytes4 _sig, bytes[] memory _datas) internal view returns (bool) {
        require(Pool(configuration.getPool()).isValidPoll(msg.sender, _code, _sig, _datas), "invalid poll");   
        return true;
    }

}
