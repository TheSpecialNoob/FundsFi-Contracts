// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

// Heads or tails game contract
contract HeadsOrTails is Ownable{
    struct Game {
        address addr;
        uint amountBet;
        uint8 guess;
        bool winner;
        uint ethInJackpot;
    }

  Game[] public lastPlayedGames;

    ///@notice This returns the input user enters and the outcome.
    event GameResult(uint8 indexed side, bool indexed isWon);

  ///@notice Play the game!
  function lottery(uint8 guess) public payable{
    require(guess < 2, "Variable 'guess' should be either 0 ('heads') or 1 ('tails')");
    require(msg.value > 0, "Bet more than 0");
      require(isContract(_msgSender()) == true, "Contract call not allowed");
    require(msg.value <= address(this).balance - msg.value, "You cannot bet more than what is available in the jackpot");
    //address(this).balance is increased by msg.value even before code is executed. Thus "address(this).balance-msg.value"
    //Create a random number. Use the mining difficulty & the player's address, hash it, convert this hex to int, divide by modulo 2 which results in either 0 or 1 and return as uint8
    uint8 result = uint8(uint256(vrf())%2);
    bool won;
    if (guess == result) {
      //Won!
      payable(_msgSender()).transfer(msg.value * 2);
      won = true;
    }

    lastPlayedGames.push(Game(msg.sender, msg.value, guess, won, address(this).balance));
    emit GameResult(result, won);
  }

  //Get amount of games played so far
  function getGameCount() public view returns(uint) {
    return lastPlayedGames.length;
  }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

  // Contract destructor (Creator of contract can also destroy it and receives remaining ether of contract address).
  //Advantage compared to "withdraw": SELFDESTRUCT opcode uses negative gas because the operation frees up space on
  //the blockchain by clearing all of the contract's data
  function destroy() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  //Withdraw money from contract
  function withdraw(uint amount) external {
    require(amount < address(this).balance, "You cannot withdraw more than what is available in the contract");
    payable(owner()).transfer(amount);
  }

  function vrf() private view returns (bytes32 result) {
        uint256[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
        return result;
    }

  // Accept any incoming amount
  receive() external payable {}
}
