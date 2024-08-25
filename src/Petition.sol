// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*
 * @title Petition
 * @author ellie.xyz1991@gmail.com
 *
 * This contract is a part of DePetition project which is a place for users to provide feedback to corporations
 * and institutions by voting with their asset.
 *
 * Petition contract mainly contains the petition title and description for each petition.
 * 
 * Note : you can support this petition via PetitionLedgerImpl contract.
 * 
 * Note : this contract has a third party owner which is the petition creator that is different for each petition.
 * funds will be managed by the PetitionLedgerImpl contract, which the third party(petition owner) has no influence over.
 *
 */

contract Petition {
    string public title;

    string public description;

    address public creator;

    event LogPetitionInit(address indexed _creator, string indexed _title, string indexed _description);

    constructor(string memory _title, string memory _description, address _creator) {
        title = _title;

        description = _description;

        creator = _creator;

        emit LogPetitionInit(_creator, _title, _description);
    }
}
