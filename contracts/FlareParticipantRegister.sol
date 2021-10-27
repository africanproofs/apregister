//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title An implementation of the Flare Participant Register
 */

contract FlareParticipantRegister {
    
    struct Participant{
        address owner;
        string name;
        string url;
        uint status;
        uint index;
    }

    mapping(address => Participant) public participants;
    address[] private participantIndex;

    event ParticipantRegisteredEvent(address indexed owner, uint index, string name, string url, uint status);
    event ParticipantUnregisteredEvent(address indexed owner, uint index, uint status);

    // A helper function that check if sender or submitted address is in one of participants
    function _isParticipant(address _address) internal view returns (bool _isCorrect) {
        if(participantIndex.length == 0) return false;
        return (participantIndex[participants[_address].index] == _address);
    }

    /**
     * @notice Registers a new participant. If sender address already exists, an update is perfomed.
     * @param _name             The name of the participant
     * @param _url              The absolute http/https URL pointing to the standardized json file.
     * @notice Emits ParticipantRegisteredEvent event
     */
    function register(string memory _name, string memory _url) public returns(bool _registered) {
        if (_isParticipant(msg.sender)){
            
            participants[msg.sender].name = _name;
            participants[msg.sender].url = _url;
            participants[msg.sender].status = 1;
        } else{

            participantIndex.push(msg.sender);
            uint _index = participantIndex.length-1;
            participants[msg.sender] = Participant(msg.sender, _name, _url, 1, _index);
        }
        
        emit ParticipantRegisteredEvent(
            msg.sender,
            participants[msg.sender].index,
            _name,
            _url,
            1
        );

        return true;
    }

    /**
     * @notice Unregisters a registered participant. Sets the status field to zero. Does not remove the record.
     * @notice Emits ParticipantUnregisteredEvent event
     */
    function unregister() public returns(bool _unregistered){
        require(participantIndex.length > 0, "No participants exist. ");
        require(_isParticipant(msg.sender), "Signer is not a registered participant. ");

        participants[msg.sender].status = 0;

        emit ParticipantUnregisteredEvent(
            msg.sender,
            participants[msg.sender].index,
            participants[msg.sender].status
        );

        return true;   
    }

    /**
     * @notice Retrieves a single record based on submitted participant address.
     * @param _address          The address of the participant whose data is requested.
     * @notice Returns a Tuple in format (address, name, url, status)
     */
    function getParticipant(address _address) public view returns(address, string memory, string memory, uint status){
        require(participantIndex.length > 0, "No participants exist. ");
        require(_isParticipant(msg.sender), "Submitted address is not a registered participant. ");

        return (participants[_address].owner, 
                participants[_address].name, 
                participants[_address].url,
                participants[_address].status);
    }

    /**
     * @notice Returns a list containing all participant irrespective of status.
     */
    function getAllParticipants() public view returns(address[] memory) {
        return participantIndex;
    }

    // See https://github.com/fravoll/solidity-patterns
    function _compareName(string memory _first, string memory _second) internal pure returns (bool _matches) {
        if(bytes(_first).length != bytes(_second).length) {
            return false;
        } else {
            return keccak256(bytes(_first)) == keccak256(bytes(_second));
        }
    }
}