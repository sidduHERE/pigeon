// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {WormholeHelper} from "src/wormhole/WormholeHelper.sol";
import {IWormholeCore} from "src/wormhole/interfaces/IWormholeCore.sol";
import {Messages} from "src/wormhole/lib/Messages.sol";

contract Target is Messages{
    uint256 public value;
    IWormholeCore wormhole;

    function receiveMessage(bytes memory _vaa) public {
        // call the Wormhole core contract to parse and verify the encodedMessage
        (
            IWormholeCore.VM memory wormholeMessage,
            bool valid,
            string memory reason
        ) = wormhole.parseAndVerifyVM(_vaa);

        // confirm that the Wormhole core contract verified the message
        require(valid, reason);
        value = abi.decode(wormholeMessage.payload, (uint256));
    }
}

contract AnotherTarget is Messages{
    uint256 public value;
    address public kevin;
    bytes32 public bob;
    IWormholeCore wormhole;

    function receiveMessage(bytes memory _vaa) public {
        // call the Wormhole core contract to parse and verify the encodedMessage
        (
            IWormholeCore.VM memory wormholeMessage,
            bool valid,
            string memory reason
        ) = wormhole.parseAndVerifyVM(_vaa);

        // confirm that the Wormhole core contract verified the message
        require(valid, reason);
        (value, kevin, bob) = abi.decode(
            wormholeMessage.payload,
            (uint256, address, bytes32)
        );
    }
}

contract WormholeHelperTest is Test {
    WormholeHelper wormholeHelper;
    Target target;
    AnotherTarget anotherTarget;

    uint256 L1_FORK_ID;
    uint256 L2_FORK_ID;
    uint16 constant L1_ID = 101;
    uint16 constant L2_ID = 109;
    address constant L1_whCore = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B; // ethereum mainnet
    address constant L2_whCore = 0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7; // polygon mainnet

    string RPC_ETH_MAINNET = vm.envString("ETH_MAINNET_RPC_URL");
    string RPC_POLYGON_MAINNET = vm.envString("POLYGON_MAINNET_RPC_URL");

    function setUp() external {
        L1_FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET, 16400467);
        wormholeHelper = new WormholeHelper();

        L2_FORK_ID = vm.createSelectFork(RPC_POLYGON_MAINNET, 38063686);
        target = new Target();
        anotherTarget = new AnotherTarget();
    }

    function testSimpleLZ() external {
        vm.selectFork(L1_FORK_ID);

        // ||
        // ||
        // \/ This is the part of the code you could copy to use the LayerZeroHelper
        //    in your own tests.
        vm.recordLogs();
        _someCrossChainFunctionInYourContract();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        wormholeHelper.help(L2_whCore, 100000, L2_FORK_ID, logs);
        // /\
        // ||
        // ||

        vm.selectFork(L2_FORK_ID);
        assertEq(target.value(), 12);
    }

    // function testSimpleLZWithEstimates() external {
    //     vm.selectFork(L1_FORK_ID);

    //     vm.recordLogs();
    //     _someCrossChainFunctionInYourContract();
    //     Vm.Log[] memory logs = vm.getRecordedLogs();
    //     lzHelper.helpWithEstimates(L2_lzEndpoint, 100000, L2_FORK_ID, logs);

    //     vm.selectFork(L2_FORK_ID);
    //     assertEq(target.value(), 12);
    // }

    // function testFancyLZ() external {
    //     vm.selectFork(L1_FORK_ID);

    //     vm.recordLogs();
    //     _aMoreFancyCrossChainFunctionInYourContract();
    //     Vm.Log[] memory logs = vm.getRecordedLogs();
    //     lzHelper.help(L2_lzEndpoint, 100000, L2_FORK_ID, logs);

    //     vm.selectFork(L2_FORK_ID);
    //     assertEq(anotherTarget.value(), 12);
    //     assertEq(anotherTarget.kevin(), msg.sender);
    //     assertEq(anotherTarget.bob(), keccak256("bob"));
    // }

    // function testCustomOrderingLZ() external {
    //     vm.selectFork(L1_FORK_ID);

    //     vm.recordLogs();
    //     _someCrossChainFunctionInYourContract();
    //     _someOtherCrossChainFunctionInYourContract();
    //     Vm.Log[] memory logs = vm.getRecordedLogs();
    //     Vm.Log[] memory lzLogs = lzHelper.findLogs(logs, 2);
    //     Vm.Log[] memory reorderedLogs = new Vm.Log[](2);
    //     reorderedLogs[0] = lzLogs[1];
    //     reorderedLogs[1] = lzLogs[0];
    //     lzHelper.help(L2_lzEndpoint, 100000, L2_FORK_ID, reorderedLogs);

    //     vm.selectFork(L2_FORK_ID);
    //     assertEq(target.value(), 12);
    // }

    function _someCrossChainFunctionInYourContract() internal {
        IWormholeCore endpoint = IWormholeCore(L1_whCore);
        bytes memory message = abi.encode(uint256(12));
        require(
            abi.encodePacked(message).length < type(uint16).max,
            "message too large"
        );

        // encode the HelloWorldMessage struct into bytes
        // bytes memory encodedMessage = Messages.encodeMessage(message);

        endpoint.publishMessage(
            0, // not batch VAA
            abi.encodePacked(message),
            200 // instant finality
        );
        // bytes memory remoteAndLocalAddresses = abi.encodePacked(
        //     address(target),
        //     address(this)
        // );
        // endpoint.send{value: 1 ether}(
        //     L2_ID,
        //     remoteAndLocalAddresses,
        //     abi.encode(uint256(12)),
        //     payable(msg.sender),
        //     address(0),
        //     ""
        // );
    }

    // function _someOtherCrossChainFunctionInYourContract() internal {
    //     IWormholeCore endpoint = IWormholeCore(L1_whCore);
    //     bytes memory remoteAndLocalAddresses = abi.encodePacked(
    //         address(target),
    //         address(this)
    //     );
    //     endpoint.send{value: 1 ether}(
    //         L2_ID,
    //         remoteAndLocalAddresses,
    //         abi.encode(uint256(6)),
    //         payable(msg.sender),
    //         address(0),
    //         ""
    //     );
    // }

    // function _aMoreFancyCrossChainFunctionInYourContract() internal {
    //     IWormholeCore endpoint = IWormholeCore(L1_whCore);
    //     bytes memory remoteAndLocalAddresses = abi.encodePacked(
    //         address(anotherTarget),
    //         address(this)
    //     );
    //     endpoint.send{value: 1 ether}(
    //         L2_ID,
    //         remoteAndLocalAddresses,
    //         abi.encode(uint256(12), msg.sender, keccak256("bob")),
    //         payable(msg.sender),
    //         address(0),
    //         ""
    //     );
    // }
}
