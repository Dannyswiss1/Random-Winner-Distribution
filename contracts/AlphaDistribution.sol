// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAlphaToken {
    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function decimals() external view returns (uint8);
    // function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    // function approve(address _spender, uint256 _value) external returns (bool success);
    // function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
interface IAlphaVRFv2 {
   function requestRandomWords() external returns (uint256 requestId);
   function setNum(uint32 _num) external ;
   function Winners() external view returns(uint [] memory _winners);   
    
}

contract AlphaDistribution{

    struct Participant{
        uint id;
        uint points;
        uint gamesParticipatedCount;
        uint reward;
        uint raffelNumber;
    }

        uint[] public winnigNumber;

    uint participantsCount;
    mapping (address => Participant) public participants;
    mapping (address => uint)  guessGameScore;
    mapping (address => bool)  followTwitter;
    mapping (address => bool)  hasRegistered;
    mapping (address => bool)  connectlink;
    mapping (address => bool)  guessGame;
    mapping (address => uint)  airDropRaffelNumber;
     mapping (address => bool)  gottenRaffelnum;
    mapping (uint => Participant)  airDropRaffelParticipant;
    uint public deadline = block.timestamp  + 3600;
    
    event rewardClaimed(address, string, uint, string);

    uint rewardCount;

    address alphaToken = 0xd9145CCE52D386f254917e481eB44e9943F39138;//Address for ERC20 token to be given as reward
    address chainLink = 0xf8e81D47203A594245E36C48e151709F0C19fBe8; //Address of chainlink contract that would generate random Numbers

    Participant[] public participantsArray;
    address owner = msg.sender;

    


    function register() external {
        require(deadline > block.timestamp, "TIME UP CAN NO LONGER GET REWARDS");

        Participant storage newParticipant = participants[msg.sender];

        require(!hasRegistered[msg.sender], "Registered already");

        uint _id = participantsCount + 1;

        newParticipant.id = _id;

        newParticipant.points = 0;

        hasRegistered[msg.sender] = true;

        guessGameScore[msg.sender] = 5;  //setting user score in the game to be 5 and would be reduced for every turn he fails till he wins or lose

    }

    function guessTheNumber(uint _guess) external  returns(string memory answer)  {
        require(deadline > block.timestamp, "TIME UP CAN NO LONGER GET REWARDS");
        require(hasRegistered[msg.sender], "Only Registered accounts can play");

        Participant storage newParticipant = participants[msg.sender];

        participantsArray.push(newParticipant);   
        participantsCount++;
        require(!guessGame[msg.sender], "You have played already");
        
        
        string memory lost = "You Have Lost The game";
        uint number = 2;  // Answer to the game

        // if user score is zero he fails the game but gets 100 points for trying
        if ( guessGameScore[msg.sender] < 1){
            guessGame[msg.sender] = true;
            newParticipant.gamesParticipatedCount +=1;
            newParticipant.points += 100;
            return (lost);
        }

        // if user wins he gets 300points multiply by the amount of turns he needed to win
        else if(_guess == number){
            guessGame[msg.sender] = true;
            newParticipant.gamesParticipatedCount +=1;
            uint points = 300;
            newParticipant.points += newParticipant.points + (points *  guessGameScore[msg.sender]);
            return("Congratulations you Won");
        }
        else if(_guess > number){
             guessGameScore[msg.sender]--;
            return("Too High");
        }
         else if(_guess < number){
             guessGameScore[msg.sender]--;
            return("Too Low");
        }
        
    }

    function followUsOnTwitter() external {
        require(deadline > block.timestamp, "TIME UP CAN NO LONGER GET REWARDS");
        require(hasRegistered[msg.sender], "Only Registered accounts can apply");
        require(!followTwitter[msg.sender], "Already following");
        // 100points for a follow on twitter
        Participant storage newParticipant = participants[msg.sender];
        newParticipant.gamesParticipatedCount +=1;
        followTwitter[msg.sender] =true;
        newParticipant.points += 100;
    }

       function connectLinkdin() external {
        require(deadline > block.timestamp, "TIME UP CAN NO LONGER GET REWARDS");
        require(hasRegistered[msg.sender], "Only Registered accounts can apply");
        require(!connectlink[msg.sender], "Already following");

        // 200 points for following on linkdin
        Participant storage newParticipant = participants[msg.sender];
        newParticipant.gamesParticipatedCount +=1;
        connectlink[msg.sender] =true;
        newParticipant.points += 200;
    }

    function getAirdropRaffelNumber() external returns (uint Raffel_ID) {
        require(deadline > block.timestamp, "TIME UP CAN NO LONGER GET REWARDS");
        require(!gottenRaffelnum[msg.sender], "Already have Raffel Number");


        Participant storage newParticipant = participants[msg.sender];
        // rewards starts after 10 people participates in the activites
        if(rewardCount <=10){
         // User needs to be involved in 2 activites to be eligible   
            require(newParticipant.gamesParticipatedCount >= 2, "Not yet Eligible");
            rewardCount++;
            //set users raffel number 
            airDropRaffelNumber[msg.sender] = rewardCount;
            newParticipant.raffelNumber = rewardCount;
            gottenRaffelnum[msg.sender] = true;

            airDropRaffelParticipant[rewardCount] = newParticipant;
            return (rewardCount);

        }
    }

    function getPoints() external view returns(uint){
        Participant storage newParticipant = participants[msg.sender];
        return(newParticipant.points);
    }

    //function uses interface to get random number from chainlink
    function randomWinners() external  returns(uint [] memory){
        uint[] memory arr = IAlphaVRFv2(chainLink).Winners();
        for(uint i = 0; i < arr.length; i++){
           uint a = arr[i];
           uint b = a % 10;
            winnigNumber.push(b);
            }
        //winning number is an array that will hold all the random numbers returned
        return (winnigNumber);
     }


    // Calculating the airdrop by multiplying users points by 100000
    function airdropRewardCalculation() external  returns(uint){
        Participant storage newParticipant = participants[msg.sender];
        require(gottenRaffelnum[msg.sender], "You do not qualify for reward");

        uint reward = newParticipant.points * 100000;
        newParticipant.points = 0;
        newParticipant.reward += reward;
        return(reward) ;          
    }


    //Users claim their rewards
   function claimReward() external returns (string memory status) {

    Participant storage newParticipant = participants[msg.sender];

    require(gottenRaffelnum[msg.sender], "You do not qualify for reward");
    require(newParticipant.reward > 0, "Reward Claimed");

    // Checks if users raffel number is in the luck winners array if it is user is rewarded else try again
    for (uint i = 0; i < winnigNumber.length; i++) {
        if (winnigNumber[i] == airDropRaffelNumber[msg.sender]) {
            uint amount = newParticipant.reward;
            newParticipant.reward = 0;

            // Check if the contract has enough tokens to transfer
            require(IAlphaToken(alphaToken).balanceOf(address(this)) >= amount, "Contract does not have enough tokens");

            // Update the participant's reward before transferring to reduce gas costs
            IAlphaToken(alphaToken).transfer(msg.sender, amount);

            emit rewardClaimed(msg.sender, "claimed", amount, "successfully");
            return "CONGRATULATIONS";
        }
    }

    // No winning number matched, participant did not win
    revert("No reward won, try again next time");
}


    function timeLeft() external  view returns(uint TimeLeftIs){
        require(deadline > block.timestamp, "TIME UP");
        uint tL = deadline - block.timestamp;
        return tL;
    }

    function generateRandomNumbers(uint32 _numword) external {
   // user specifies how many random numbers he want and calls the function to generate the numbers from the chainlink contract
        IAlphaVRFv2(chainLink).setNum(_numword);
        IAlphaVRFv2(chainLink).requestRandomWords();
    }
}