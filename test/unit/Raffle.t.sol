//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    // Events
    event EnterRaffle(address indexed _player);

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public Player = makeAddr("Azan");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(Player, STARTING_BALANCE);
    }

    function testEnterRaffle() public {
        vm.prank(Player);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSend.selector);
        raffle.enterRaffle{value: 0}();
    }

    function testRaffleState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.Open);
    }

    function testRaffleRecordWhenPlayerEnters() public {
        vm.prank(Player);

        raffle.enterRaffle{value: entranceFee}();
        address Playeraddress = raffle.getPlayer(0);
        assert(Playeraddress == Player);
    }

    function testEmitsEventOnEnternace() public {
        vm.prank(Player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(Player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(Player);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_NotOpened.selector);
        vm.prank(Player);
        raffle.enterRaffle{value: entranceFee}();
    }
}
