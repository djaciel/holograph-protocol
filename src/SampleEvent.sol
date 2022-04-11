HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

contract SampleEvent {

    event Packet (uint16 chainId, bytes payload);

    constructor() {
    }

    function sample(bytes memory data) external {
        emit Packet(1, data);
    }

}
