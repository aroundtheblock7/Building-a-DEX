// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    using SafeMath for uint256;
    //every address/trader will have a balance, but you can have a balance of all diff types of coins
    //because we have all diff coins we need a double mapping, that goes from address to the tokenId (token symbol)
    //we could in theory do strings but we can't compare strings, so if we convert string to bytes we can do comparisons
    mapping(address => mapping(bytes32 => uint256)) public balances;

    struct Token {
        bytes32 ticker;
        address tokenAddress; //we need this so we can do transfer calls, we need the address of the token to do it & interface
    }

    //here we used combined storage design of being able to iterate through an array and a mapping to update very quickly
    bytes32[] public tokenList;
    mapping(bytes32 => Token) public tokenMapping;

    modifier tokenExists(bytes32 ticker) {
        require(
            tokenMapping[ticker].tokenAddress != address(0),
            "Token does not exist"
        );
        _;
    }

    function addToken(bytes32 ticker, address tokenAddress) external onlyOwner {
        //can do a require here to make sure its not already a token.
        //we can assign mappings properties individually or all in one shot like we are doing here
        tokenMapping[ticker] = Token(ticker, tokenAddress);
    }

    //we need to be able to interact with the other token contracts when depositing
    //the two things we need are the 1.)interface and 2.)address of the token contract
    //for the interface we can import IERC20 open Zeppelin contract to make this easier
    function deposit(uint256 amount, bytes32 ticker)
        external
        tokenExists(ticker)
    {
        //checks effects interactions, so adjust balance before the transfer
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
        //remember when using transferFrom we will need the "approval" first otherwise this will fail
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function withdraw(uint256 amount, bytes32 ticker)
        external
        tokenExists(ticker)
    {
        //then we need to check that msg.sender actaully has the balance to withdraw
        require(balances[msg.sender][ticker] >= amount, "Insufficient Balance");
        //then we need to adjust the balances to reflect withdrawal
        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
        //finally we are transferring from us (this contract) to msg.sender who is the rightful owner, we are just holding the tokens
        //remember in IERC20 and ERC20 transfer takes 2 inputs, to "to" address and the "amount".
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    function depositEth() external payable {
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][
            bytes32("ETH")
        ].add(msg.value);
    }

    function withdrawEth(uint256 amount) external {
        require(
            balances[msg.sender][bytes32("ETH")] >= amount,
            "Insuffient balance"
        );
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][
            bytes32("ETH")
        ].sub(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
