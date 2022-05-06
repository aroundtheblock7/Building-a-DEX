// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

contract Dex is Wallet {
    using SafeMath for uint256;

    uint256 public nextOrderId = 0;

    enum Side {
        BUY,
        SELL
    }

    //the other option in place of the enum would have been bool buyOrder but enum was easier to use
    struct Order {
        uint256 id;
        address trader;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 price;
        uint256 filled;
    }

    //the uint here is either 0 or 1 as it correlates to the enum. 0 is buy and 1 is sell. And this points to the order struct
    //so now we have one order book for buy (0) and one for sell (1)
    mapping(bytes32 => mapping(uint256 => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side)
        public
        view
        returns (Order[] memory)
    {
        return orderBook[ticker][uint256(side)];
    }

    function createLimitOrder(
        Side side,
        bytes32 ticker,
        uint256 amount,
        uint256 price
    ) public {
        if (side == Side.BUY) {
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
            //with the sell below you need to have the actual balance you want to sell (amount) so we make a require...
        } else if (side == Side.SELL) {
            require(balances[msg.sender][ticker] >= amount);
        }
        //We do not save in memory here but rather make a reference to an array that is in storage
        //Remember you can't do mappings with enums so we need [uint(side)] which references 0 or 1 for the enum
        Order[] storage orders = orderBook[ticker][uint256(side)];
        //After we establish that it is a buy or sell order we can push the Order into the orders array
        //for the Id input we can't just use .length, because there are 2 sides (buy and sell) and the id needs to be unique
        //so we create the global variable nextOderId and use it as a counter.
        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
        );

        //Bubble Sort- traditional bubble sort does 2 iterations as the first iteration does not likely sort...
        //becuase it compares values next to each other. One more iteration through will then sort the list properly
        //Because our entries aren't totally random, they are in succession (nextOderId), we only need to take the...
        //last entry and place it properly in the list. This requires only one iteration to get it sorted. So we don't
        //need to do traditional bubble sort that has a loop within a loop, we just do one loop/iteration
        //On the buy side we need the largest order first [10, 7, 5, 4, 3]
        //When we do while loops we first need to define where we are starting so the
        //first line reads.... if orders.length is > 0, uint i = orders.length -1 (index of last element)...
        //if not, uint i is equal to 0. Meaning if the array is empty i = 0!
        //If we just did this... uint i = orders.length - 1,  i would start as -1 which we don't want.
        //Keep in mind real order books combine buys at same price and quantity into 1 larger buy order but we don't do that here
        //This just puts into order book array and sorts but does not execute and transfer tokens. Market order does that.
        uint256 i = orders.length > 0 ? orders.length - 1 : 0;
        if (side == Side.BUY) {
            while (i > 0) {
                //we first check if a sort is necessary because it may not be.
                //i is last element, i -1 is the second to last element! So we check is i -1 < i? If so we can break!
                if (orders[i - 1].price > orders[i].price) {
                    break;
                }
                //suppose we had [10, 5, 6] orderToMove will be 5. So we save 5 in memory
                Order memory orderToMove = orders[i - 1];
                //then we set it to orders[i], the very last number so we now have [10,6,6]
                orders[i - 1] = orders[i];
                //finally we set order[i] which is the 5 in memory and assign it to order to move so we get [10,6,5]
                orders[i] = orderToMove;
                //now we go we want to go i-- which brings us back two slots to the second postion [10,6,5] which is 6
                //and we can compare again from the top of the loop, is i (6) < than i - 1 (10). It is, so we break!
                //So as long as i > 0, this will continue to run/loop
                i--;
            }
        } else if (side == Side.SELL) {
            while (i > 0) {
                //remember here we are sorting in the opposite direction (smallest order first [6,8,12])
                //so if i - 1 < i [6,8], we can break as this is how we want it ordered
                if (orders[i - 1].price < orders[i].price) {
                    break;
                }
            }
            Order memory orderToMove = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = orderToMove;
            i--;
        }
        nextOrderId++;
    }

    //Here we iterate through the order book until the order is completely filled or the order book is empty
    //We must fill at each of the best prices and then move to next price to fill at the price
    //We must add a struct property "uint filled" for this. This keeps how much we have filled so far for the order
    function createMarketOrder(
        Side side,
        bytes32 ticker,
        uint256 amount
    ) public {
        //If this is a sell order we can verify the seller has enough tokens (ticker) to cover the amount he wants to sell
        //We can't do this require for the buyer yet becuase we don't know the final cost of the buy until later
        if (side == Side.SELL) {
            require(
                balances[msg.sender][ticker] >= amount,
                "Insufficient Funds"
            );
        }
        //A buy order is matched with the sell orders, so we need to pull the sell side  order book for a buy order & vice versa..
        uint256 orderBookSide;
        if (side == Side.BUY) {
            orderBookSide = 1; //if its a buy order we want the opposite which is sell, which is 1
        } else {
            orderBookSide = 0; //if its a sell order we want the opposite which is buy, which is 0
        }
        //now we can save each order in an array called orders
        Order[] storage orders = orderBook[ticker][uint256(orderBookSide)];
        //Once we have the orderbook side we can start by creating the loop
        //as long as i < orders.length (meaning we've gone through every order in the orderBook)...
        //&& totalFilled < amount (meaning order is not yet completely filled) we will continue to loop thru orderBook
        //So the way we exit this loop is either i becomes as large as order.length (meaning we looped thru entire oderBook) or...
        //total filled is as big as amount, which means we filled the entire order.
        uint256 totalFilled = 0;
        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            //We need to figure out much we can fill from order[i]
            //Need to update totalFilled
            //We will try to fill the entire "amount", on each iteration but whatever is left we need to track...
            //so we will need a var called unfilled to keep track of that so we create a uint leftToFill for that.
            //Rememeber leftToFill will be equal to the entire order amount before the first iteration.
            uint256 leftToFill = amount.sub(totalFilled); //amount - totalFilled
            //this gives us the current state of the order book and tells us how much us available for us to fill
            //order[i].filled is referring to the "filled" property in the Struct for a particular order but...
            //remember the "i" means we are basically looking through every order in the orderbook.
            //another way to look at it, is availableToFill is happening at the struct level (each order in orderbook)
            uint256 availableToFill = orders[i].amount.sub(orders[i].filled); //orders.amount - orders.filled
            uint256 filled = 0;
            //this part of the if statement will fill the entire market order
            if (availableToFill > leftToFill) {
                filled = leftToFill;
            }
            //the else is only filling as much as available, it can not fill the entire order
            else {
                //availableToFill <= left to fill
                filled = availableToFill;
            }
            //Now we know how much of this market order we can fill with this specific iteration and adjust totalFilled
            totalFilled = totalFilled.add(filled);
            //We also need to modify the order iself to reflect each iteration that has been filled
            orders[i].filled = orders[i].filled.add(filled);
            uint256 cost = filled.mul(orders[i].price);

            //Now we need to execute the trade and shift balances between buyer and seller
            if (side == Side.BUY) {
                //verify that the buyer has enough funds to cover the purchase (require)
                //here we mulitiply the amount filled by the price in each order iteration
                require(balances[msg.sender]["ETH"] >= cost);
                //buyer is msg.sender. Transfer ETH from buyer to seller. Add the ticker (filled) to balance. Deduct the ETH cost
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(
                    filled
                );
                balances[msg.sender]["ETH"] = balances[msg.sender][ticker].sub(
                    cost
                );

                //Adjust Trader balance by deducting the ticker (filled) and adding the ETH (cost)
                balances[orders[i].trader][ticker] = balances[orders[i].trader][
                    ticker
                ].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader][
                    "ETH"
                ].add(cost);
            } else if (side == Side.SELL) {
                //we already did require at the beginning of the function to ensure he has funds to sell the amount he specified
                //msg.sender is seller. Transfer tokens from seller to buyer. Transfer ETH from buyer to seller.
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(
                    filled
                );
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(
                    cost
                );

                //Adjust Trader balance by adding the ticker (filled) and subtracting the ETH (cost) from buying
                balances[orders[i].trader][ticker] = balances[orders[i].trader][
                    ticker
                ].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader][
                    "ETH"
                ].sub(cost);
            }
        }
        //We need to remove 100% filled order. Take the following example...
        //Order(amount=10, filled=10),
        //Order(amount=100, filled=100),
        //Order(amount=25, filled=10),
        //Order(amount=200, filled 0)
        //The goal is to remove the top 2 which are the ones filled.
        //Soon as we get to an order in the list that is not completely filled (3rd down) we can stop the loop because..
        //we know that every order beneath isn't filled (filled orders at top). So this means we will
        //only continue to loop "while" the order at the top [0] index is equal to the amount. That means it was filled.
        //We will continue to check the index 0 "while" we loop through each order in the order book
        while (orders.length > 0 && orders[0].filled == orders[0].amount) {
            //Now that we have the while loop we want to remove the top element in the order array by overwriting every element...
            //with the next elememt. Overwrite i with [i +1], i.e. order[0] will be overwritten as Order(amount =100,filled=100)
            //The reason we stop at orders.length -1 is because there is no i+1 to replace it with so we need to stop at...
            //the second to last one which is orders.length - 1. i.e. we'd stop at order(amount=25, filled=10) after its replaced
            //If we continue for loop we will end up with duplicate at the end of the list which is the one we have to pop off
            //We will continue to run the loop "until" we have removed all the filled orders. i.e. the top 2
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }
}
