
// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.4/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://raw.githubusercontent.com/moniquebaumann/freedom-cash/v0.0.1/freedom-cash-interface.sol



pragma solidity 0.8.19;

interface IFreedomCash {
    function getBuyPrice(uint256 ethBalance, uint256 underway) external pure returns(uint256);
    function getSellPrice(uint256 ethBalance, uint256 underway) external pure returns(uint256);
    function buyFreedomCash(address receiver, uint256 requestAmount) external payable;
    function sellFreedomCash(uint256 amount) external;
    function getAmountOfETHForFC(uint256 fCPrice, uint256 fCAmount) external view returns(uint256);
    function getUnderway() external view returns(uint256);
}

// File: freedom-playgrounds.sol



// This smart contract provides Freedom Playgrounds like 
// Freedom Treasuries, Freedom Exchanges and Freedom Enterprises
// Freedom Playgrounds leverage Freedom Cash as decentralized currency 

// We will be free

pragma solidity 0.8.19;



contract FreedomPlaygrounds {

    uint256 public freedomTreasuryCounter;
    uint256 public freedomExchangeCounter;
    uint256 public taskCounter = 0;
    uint256 public fundingCounter = 0;
    uint256 public solutionCounter = 0;
    mapping(uint256 => FreedomTreasury) public freedomTreasuries;
    mapping(uint256 => FreedomExchange) public freedomExchanges;
    mapping(uint256 => Funding) public fundings;
    mapping(uint256 => Solution) public solutions;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => uint256) public fundingsToTask;
    mapping(uint256 => uint256) public solutionsToTask;
    address public nativeFreedomCash = 0x1Dc4E031e7737455318C77f7515F8Ea8bE280a93;

    struct FreedomTreasury {
        address from;
        bytes32 location;
        bytes32 guestBookEntry;
    }
    struct FreedomExchange {
        address from;
        bytes32 location;
        string description;
    }
    struct Task {
        address from;
        string text;
    }
    struct Funding {
        address from;
        uint256 amount;
        uint256 assignedAmount;
    }
    struct Solution {
        address from;
        string evidence;
        uint256 score;
        uint256 claimed;
    }

    error TaskIDNotAvailableYet();
    error NonSense();
    error OnlyTheCreatorOfTheTaskCanDoThat();
    error NothingToClaimATM();
    error HundredPercentIsEnough();
    error yourAppreciationAmountCannotBeHigherThanYourFundingsForThisTask();

    function addFreedomTreasury(bytes32 location, bytes32 guestBookEntry) public {
        freedomTreasuryCounter++;
        freedomTreasuries[freedomTreasuryCounter] = FreedomTreasury(msg.sender, location, guestBookEntry);
    }
    function addFreedomExchange(bytes32 location, string memory description) public {
        freedomExchangeCounter++;
        freedomExchanges[freedomExchangeCounter] = FreedomExchange(msg.sender, location, description);
    }
    function createTask(string memory text) public {
        taskCounter++;
        tasks[taskCounter] = Task(msg.sender, text);
    }
    function fundTask(uint256 taskID,uint256 fundingAmountFC) public payable {
        if (taskID > taskCounter) { revert TaskIDNotAvailableYet(); }
        fundingCounter++;
        IFreedomCash(nativeFreedomCash).buyFreedomCash{value: msg.value}(address(this), fundingAmountFC);
        fundings[fundingCounter] = Funding(msg.sender, fundingAmountFC, 0);
        fundingsToTask[fundingCounter] = taskID;
    }
    function provideSolution(uint256 taskID, string memory evidence) public {
        if (taskID > taskCounter) { revert TaskIDNotAvailableYet(); }
        solutionCounter++;
        Solution memory solution = Solution(msg.sender, evidence, 0, 0);
        solutions[solutionCounter] = solution;
        solutionsToTask[solutionCounter] = taskID;
    }
    function getMaxAppreciationPotential(uint256 taskID, address supporter) public view returns (uint256) {
        if (taskID > taskCounter) { revert TaskIDNotAvailableYet(); }
        uint256 maxAppreciationPotential = 0;
        for (uint256 i = 1; i <= fundingCounter; i++) {
            if (fundingsToTask[i] == taskID && fundings[i].from == supporter) {
                maxAppreciationPotential += (fundings[i].amount -
                    fundings[i].assignedAmount);
            }
        }
        return maxAppreciationPotential;
    }
    function appreciateSolution(uint256 solutionID, uint256 amount) public {
        uint256 taskID = solutionsToTask[solutionID];
        if (taskID == 0) { revert NonSense(); }
        if (amount > getMaxAppreciationPotential(taskID, msg.sender)) {
            revert yourAppreciationAmountCannotBeHigherThanYourFundingsForThisTask();
        }
        uint256 appreciationPot = 0;
        for (uint256 i = 1; i <= fundingCounter; i++) {
            if (fundingsToTask[i] == taskID && fundings[i].from == msg.sender) {
                if (appreciationPot < amount) {
                    uint256 diff = amount - appreciationPot;
                    uint256 assignable = fundings[i].amount -
                        fundings[i].assignedAmount;
                    uint256 toBeAssigned = 0;
                    if (diff > assignable) {
                        toBeAssigned = assignable;
                    } else {
                        toBeAssigned = diff;
                    }
                    appreciationPot += toBeAssigned;
                    fundings[i].assignedAmount += toBeAssigned;
                }
            }
        }
        solutions[solutionID].score += amount;
    }
    function claimRewards() public {
        uint256 claimable = getClaimableReward(msg.sender);
        if (claimable > 0) {
            for (uint256 i = 1; i <= solutionCounter; i++) {
                if (solutions[i].from == msg.sender && solutions[i].score > 0) {
                    solutions[i].claimed = solutions[i].score;
                }
            }
            IERC20(nativeFreedomCash).transfer(msg.sender, claimable);
        } else {
            revert NothingToClaimATM();
        }
    }
    function getFundingAmountOf(uint256 taskID) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= fundingCounter; i++) {
            if (fundingsToTask[i] == taskID) {
                total += fundings[i].amount;
            }
        }
        return total;
    }
    function getClaimableReward(address receiver) public view returns (uint256) {
        uint256 claimable = 0;
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutions[i].from == receiver && solutions[i].score > 0) {
                claimable += (solutions[i].score - solutions[i].claimed);
            }
        }
        return claimable;
    }
    function getSolutionProposalIDs(uint256 taskID) external view returns (uint[] memory) {
        uint256 counter;
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutionsToTask[i] == taskID) {
                counter++;
            }
        }
        uint[] memory result = new uint[](counter);
        counter = 0;
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutionsToTask[i] == taskID) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function getTaskIDsCreatedBySender() external view returns (uint[] memory) {
        uint256 counter;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].from == msg.sender) {
                counter++;
            }
        }
        uint[] memory result = new uint[](counter);
        counter = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].from == msg.sender) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function getFundingIDsFundedBySender() external view returns (uint[] memory ){
        uint256 counter;
        for (uint256 i = 1; i <= fundingCounter; i++) {
            if (fundings[i].from == msg.sender) {
                counter++;
            }
        }
        uint[] memory result = new uint[](counter);
        counter = 0;
        for (uint256 i = 1; i <= fundingCounter; i++) {
            if (fundings[i].from == msg.sender) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function getSolutionIDsProvidedBySender() external view returns (uint[] memory) {
        uint256 counter;
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutions[i].from == msg.sender) {
                counter++;
            }
        }
        uint[] memory result = new uint[](counter);
        counter = 0;
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutions[i].from == msg.sender) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}