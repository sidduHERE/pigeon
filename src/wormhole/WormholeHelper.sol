// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IWormholeCore} from "./interfaces/IWormholeCore.sol";
interface IWormholeReceiver {

    function receiveMessage(bytes memory _vaa) external;
        // (uint16 srcChainId, bytes memory srcAddress, address dstAddress, uint64 nonce, uint256 gasLimit, bytes memory payload) = abi.decode(_vaa, (uint16, bytes, address, uint64, uint256, bytes));
        // receivePayload(srcChainId, srcAddress, dstAddress, nonce, gasLimit, payload);


    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external returns (uint256 nativeFee, uint256 zroFee);
}

contract WormholeHelper is Test {
    bytes32 constant LOG_SELECTOR = 0x6eb224fb001ed210e379b335e35efe88672a8ce935d981a6896b27ffdf52a3b2;
    address constant DEFAULT_LIBRARY = 0x4D73AdB72bC3DD368966edD0f0b2148401A178E2;

    // hardcoded defaultLibrary on ETH and Packet event selector
    function help(address endpoint, uint256 gasToSend, uint256 forkId, Vm.Log[] calldata logs) external {
        _help(endpoint, DEFAULT_LIBRARY, gasToSend, LOG_SELECTOR, forkId, logs, false);
    }

    function help(
        address endpoint,
        address defaultLibrary,
        uint256 gasToSend,
        bytes32 eventSelector,
        uint256 forkId,
        Vm.Log[] calldata logs
    ) external {
        _help(endpoint, defaultLibrary, gasToSend, eventSelector, forkId, logs, false);
    }

    // hardcoded defaultLibrary on ETH and Packet event selector
    function helpWithEstimates(address endpoint, uint256 gasToSend, uint256 forkId, Vm.Log[] calldata logs) external {
        bool enableEstimates = vm.envOr("ENABLE_ESTIMATES", false);
        _help(endpoint, DEFAULT_LIBRARY, gasToSend, LOG_SELECTOR, forkId, logs, enableEstimates);
    }

    function helpWithEstimates(
        address endpoint,
        address defaultLibrary,
        uint256 gasToSend,
        bytes32 eventSelector,
        uint256 forkId,
        Vm.Log[] calldata logs
    ) external {
        bool enableEstimates = vm.envOr("ENABLE_ESTIMATES", false);
        _help(endpoint, defaultLibrary, gasToSend, eventSelector, forkId, logs, enableEstimates);
    }

    function findLogs(Vm.Log[] calldata logs, uint256 length) external pure returns (Vm.Log[] memory lzLogs) {
        return _findLogs(logs, LOG_SELECTOR, length);
    }

    function findLogs(Vm.Log[] calldata logs, bytes32 eventSelector, uint256 length)
        external
        pure
        returns (Vm.Log[] memory lzLogs)
    {
        return _findLogs(logs, eventSelector, length);
    }

    function _help(
        address endpoint,
        address defaultLibrary,
        uint256 gasToSend,
        bytes32 eventSelector,
        uint256 forkId,
        Vm.Log[] memory logs,
        bool enableEstimates
    ) internal {
        uint256 prevForkId = vm.activeFork();
        vm.selectFork(forkId);
        //IWormholeCore.GuardianSet memory gaurdians = IWormholeCore(endpoint).getGuardianSet(IWormholeCore(endpoint).getCurrentGuardianSetIndex());
        //vm.startBroadcast(gaurdians.keys[0]);
        // larps as default library
         vm.startBroadcast(defaultLibrary);
        for (uint256 i; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            // unsure if the default library always emits the event
            if ( /*log.emitter == defaultLibrary &&*/ log.topics[0] == eventSelector) {
                (,,bytes memory payload,) = abi.decode(log.data, ( uint64, uint32, bytes, uint8));
                console.logBytes(payload);
                _generateVAA(endpoint,payload);

                // LayerZeroPacket.Packet memory packet = LayerZeroPacket.getPacket(payload);

                // _receivePayload(endpoint, packet, gasToSend, enableEstimates);
            }
        }
        vm.stopBroadcast();
        vm.selectFork(prevForkId);
    }

    function _generateVAA(address endpoint, bytes memory payload) internal {

        // IWormholeCore.GuardianSet memory gaurdians = IWormholeCore(endpoint).getGuardianSet(IWormholeCore(endpoint).getCurrentGuardianSetIndex());

        // vm.startBroadcast(gaurdians.keys[0]);
        // bytes memory sig = vm.sign(payload);
        // bytes memory header = abi.encode(1, uint32(IWormholeCore(endpoint).getCurrentGuardianSetIndex()), uint8(gaurdians.keys.length));
        // // for (uint256 index = 0; index < array.length; index++) {
            
        // // }
        // IWormholeReceiver(endpoint).receiveMessage(payload);
    }

    // function _estimateGas(
    //     address endpoint,
    //     uint16 destination,
    //     address userApplication,
    //     bytes memory payload,
    //     bool payInZRO,
    //     bytes memory adapterParam
    // ) internal returns (uint256 gasEstimate) {
    //     (uint256 nativeGas,) =
    //         ILayerZeroEndpoint(endpoint).estimateFees(destination, userApplication, payload, payInZRO, adapterParam);
    //     return nativeGas;
    // }

    // function _receivePayload(
    //     address endpoint,
    //     LayerZeroPacket.Packet memory packet,
    //     uint256 gasToSend,
    //     bool enableEstimates
    // ) internal {
    //     bytes memory path = abi.encodePacked(packet.srcAddress, packet.dstAddress);
    //     vm.store(
    //         address(endpoint),
    //         keccak256(abi.encodePacked(path, keccak256(abi.encodePacked(uint256(packet.srcChainId), uint256(5))))),
    //         bytes32(uint256(packet.nonce))
    //     );

    //     ILayerZeroEndpoint(endpoint).receivePayload(
    //         packet.srcChainId, path, packet.dstAddress, packet.nonce + 1, gasToSend, packet.payload
    //     );

    //     if (enableEstimates) {
    //         uint256 gasEstimate =
    //             _estimateGas(endpoint, packet.dstChainId, packet.dstAddress, packet.payload, false, "");
    //         emit log_named_uint("gasEstimate", gasEstimate);
    //     }
    // }

    function _findLogs(Vm.Log[] memory logs, bytes32 eventSelector, uint256 length)
        internal
        pure
        returns (Vm.Log[] memory lzLogs)
    {
        lzLogs = new Vm.Log[](length);

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == eventSelector) {
                lzLogs[currentIndex] = logs[i];
                currentIndex++;

                if (currentIndex == length) {
                    break;
                }
            }
        }
    }
}
