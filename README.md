
## DePetition Project

Inspired by @ryanberckmans (twitter account): [deposit (stake) capital against a petition](https://twitter.com/ryanberckmans/status/1743675086144434402)

The goal is to build a canonical place for users to provide feedback to corporations and institutions by voting with their money. This project allows anyone to permissionlessly create petitions, and users can support the petitions by voting with their funds or without funds.

### Technical details

The DePetition project benefits from the [UUPS](https://docs.openzeppelin.com/contracts/5.x/api/proxy#UUPSUpgradeable) upgradeable pattern and contains three main contracts:

- **Proxy contract**
The proxy contract, which is 'DePetitionProxy.sol', is a home for strorage variables on the implementation contract and also handles the proxy logic.

- **Ledger contract**
Our upgradeable contract is 'PetitionLedgerImpl', which is responsible for managing the funds that people send to support a petition, as well as upgrade logic.
Notice that per upgrade, the 'VERSION' variable should be increased by one, and updating it with '2**64 - 1' will make the contract nonupgradeable forever.

- **Petition contract**
The petition contract, which is 'Petition.sol', will be deployed by the ledger contract through the 'deployNewPetition function' at the same deterministic address with the same given salt on every EVM compatible chain.
This contract has a third-party owner, which is the petition creator, which is different for each petition.
Funds will be managed by the PetitionLedgerImpl contract, which the third party (petition owner) has no influence over.

### Test instractions

1. Go to the proxy address [here](https://holesky.etherscan.io/address/0x38200de4b4920ccddf4ac749ce88a1410f33aecd#writeProxyContract) invoke the deployNewPetition function (the argument salt is an arbitrary number). If it succeeds, it will return the address for your petition. You are the petition creator!

2. The petition supporter can support the petition you've created by sending funds via 'the'signWithToken' and 'signWithETH' functions, or no funds by simply invoking 'signWithNoFund'.

3. for signWithToken: mint [TST1](https://holesky.etherscan.io/address/0xaeeff661d58941115c4eced629cd70afe6ce5206#writeContract) and [TST2](https://holesky.etherscan.io/address/0x146c3816d390f4d57a0447bf608ca9a1e517c111#writeContract) as test token and approve [proxy address](https://holesky.etherscan.io/address/0x38200de4b4920ccddf4ac749ce88a1410f33aecd) the amount you want to support.

4. You can withdraw your funds through 'withdrawETH' and 'withdrawToken' whenever you want.

### Conditions that the project should hold true eventually

- Users are able to deposit any token on any chain.

- Contract should be deployed on all chains at the same address.

- The frontend UI aggregates all petitions and token balances on any chain into a single petition system.

### Further ideas

- featuring the contract with an NFT that has three levels (gold, silver, and bronze) based on how long the supporter staked the coin or how many coins.
