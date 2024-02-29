// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Distribution is VRFConsumerBase {
    address public owner;
    uint256 public prizepool;
    uint256 public registrationFee;
    uint256 public taskReward;
    uint256 public playersCount;
    uint256 public randomWinnerIndex;
    bool public registrationClosed;
    bool public taskCompleted;
    bytes32 public requestId;
    uint256 public randomResult;
    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(address => bool) public registeredPlayers;
    address[] public players;

    event Registration(address indexed player);
    event TaskCompleted(address indexed player);
    event WinnerSelected(address indexed winner, uint256 randomIndex);


    constructor(
        address __vrfCoordinator,
        address _link,
        uint256 _registrationFee,
        uint256 _taskReward
    ) VRFConsumerBase(__vrfCoordinator, _link) {
        owner = msg.sender;
        registrationFee = _registrationFee;
        taskReward = _taskReward;
    }

      function registerPlayer() external payable {
        require(!registrationClosed, "Registration is closed");
        require(msg.value >= registrationFee, "Insufficient registration fee");

        if (!registeredPlayers[msg.sender]) {
            registeredPlayers[msg.sender] = true;
            players.push(msg.sender);
            playersCount++;
            emit Registration(msg.sender);
        }
    }

     function completeTask() external {
        require(registeredPlayers[msg.sender], "Participant not registered");
        require(!taskCompleted, "Task already completed");

        taskCompleted = true;
        emit TaskCompleted(msg.sender);
    }

      function closeRegistration() external {
        require(msg.sender == owner, "Only owner can close registration");
        registrationClosed = true;
    }

     function selectWinner() external {
        require(msg.sender == owner, "Only owner can select winner");
        require(taskCompleted, "Task not completed yet");

        requestId = requestRandomness(keyHash, fee);
    }

      function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(_requestId == requestId, "Invalid request ID");
        randomResult = _randomness;
        randomWinnerIndex = _randomness % playersCount;
        payable(players[randomWinnerIndex]).transfer(taskReward);
        emit WinnerSelected(players[randomWinnerIndex], randomWinnerIndex);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

}