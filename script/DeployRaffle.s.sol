// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "./../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./../script/Interaction.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        return deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription subscriptionContract = new CreateSubscription();
            (config.subscriptionId, ) = subscriptionContract.createSubscription(
                config.vrfCoordinator
            );

            FundSubscription fundSubContract = new FundSubscription();
            fundSubContract.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.linkToken,
                config.useNativePayment
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.useNativePayment
        );
        vm.stopBroadcast();

        AddConsumer addConsumerContract = new AddConsumer();
        addConsumerContract.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId
        );

        return (raffle, helperConfig);
    }
}
