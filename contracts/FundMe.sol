// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// to get latest conversion rate,  from https://www.npmjs.com/package/@chainlink/contracts
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; //in vsc, you have to import from github instead of npm
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

/*
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}*/

contract FundMe {
    using SafeMathChainlink for uint256;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //payable: this function can be used to pay for things. this buttons is red
    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10**18;
        // 1gwei < $50
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to  spend more ETH!"
        );
        /*
        if (msg.value < minimumUSD){
            revert ?;
        }*/

        addressToAmountFunded[msg.sender] += msg.value; //msg.sender: sender of the function call, msg.value: how much they sent
        // what the ETH -> USD conversion rate

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );*/
        return priceFeed.version();
    }

    // to read current eth to usd
    function getPrice() public view returns (uint256) {
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );*/
        //(,int256 answer,,,)
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10); // 18decimals
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount);
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // only for the owner of the eth to withdraw
        //require(msg.sender == owner);

        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
