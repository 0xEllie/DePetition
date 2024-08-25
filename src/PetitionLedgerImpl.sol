// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Petition.sol";

/*
 * @title PetitionLedgerImpl
 * @author ellie.xyz1991@gmail.com
 *
 * This contract will manage the funds that people send in support of the petition they are endorsing.
 * 
 *
 * signWithToken function : if you want to support a petition by supported token, you only need to pass the token  
 * address and the amount you want to support along with the petition address to signWithToken function. this way you will
 * also sign the petition. 
 * Note : the token should be added by the owner of this contract via addToken function beforehand, if not 
 * then the token is not supported.
 *
 * withdrawToken function : if you want to withdraw your token after supporting a petition, you only need to pass   
 * the token address and the petition address to withdrawToken function. 
 * 
 * signWithETH function : if you want to support a petition with ETH, you only need to pass the petition address
 * and specify the amount you want to support to signWithETH function. this way you will also sign the petition.
 * Note : make sure your account address is payable and DO NOT use a contract account with no receive or fallback funcion.
 *
 * withdrawETH function : if you want to withdraw your token after supporting a petition, you  only need to pass  
 * the petition address you've supported earlier to withdrawETH function. 
 * Note : make sure the address is payable and DO NOT use a contract account with no receive or fallback function.
 * 
 *
 * deployNewPetition function : this function will deploy the petition contract by invoking create2 method. this way given the same salt 
 * the petition will be deployed at the same address on all EVM compatible chains.
 * Note : salt is an arbitrary number(bytes32).
 */

contract PetitionLedgerImpl is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    uint64 public immutable VERSION = 2; // this number should be increased by every upgrade

    uint256 public ETHBalance;

    mapping(address petition => mapping(address token => mapping(address user => uint256 amount))) public tokenDeposites;

    mapping(address petition => mapping(address user => uint256 amount)) public ETHDeposites;

    mapping(address token => string symbol) public tokens;

    mapping(address petition => address creator) public petitions;

    mapping(address petition => mapping(address signer => bool)) public hasSigned;

    event LogPetitionLedgerInitialized(address indexed _initialOwner);

    event LogTransfer(address indexed _from, address indexed _petition, uint256 indexed _amount);

    event LogDeposit_User_Petition(address indexed _token, address indexed _from, address indexed _petition);

    event LogWithdraw(address indexed _from, address indexed _to, uint256 _amount);

    event LogWithdraw_User_Petition(address indexed _token, address indexed _from, address indexed _petition);

    event LogTransferEth(address indexed _from, address indexed _petition, uint256 indexed _amount);

    event LogWithdrawETH(address indexed _petition, address indexed _to, uint256 indexed _amount);

    event LogTokenAdded(address indexed _token, string indexed _symbol);

    event LogTokenRemoved(address indexed _token);

    event LogDeploy(address indexed _petition, string indexed _title, string indexed _description);

    event LogUpgradeAuthorized(address indexed _newImpl, address indexed _caller);

    event LogSign(address indexed _petition, address indexed _signer);

    constructor() {
        _disableInitializers();
    }

    modifier inputCheck(address _token, string memory _symbol) {
        require(_token != address(0), "token address cannot be zero");

        require(bytes(_symbol).length != 0, "symbol should not be empty");
        _;
    }

    function signWithETH(address _petition) public payable nonReentrant whenNotPaused returns (bool) {
        require(msg.value > 0, "depisit amount should not be zero");

        require(msg.sender != address(0), "_signer cannot be zero");

        require(petitions[_petition] != address(0), "petition doesnt exist");

        ETHDeposites[_petition][msg.sender] += msg.value;

        ETHBalance += msg.value;

        emit LogTransferEth(msg.sender, _petition, msg.value);

        if (!hasSigned[_petition][msg.sender]) {
            sign(_petition);
        }

        return true;
    }

    function signWithToken(address _petition, address _token, uint256 _amount)
        public
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(_token != address(0), "token is not supported");

        require(_amount > 0, " amount should be > 0 ");

        require(petitions[_petition] != address(0), "petition doesnt exist");

        require(msg.sender != address(0), "_signer cannot be zero");

        tokenDeposites[_petition][_token][msg.sender] += _amount;

        emit LogTransfer(msg.sender, _petition, _amount);

        emit LogDeposit_User_Petition(_token, msg.sender, _petition);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (!hasSigned[_petition][msg.sender]) {
            sign(_petition);
        }

        return true;
    }

    function signWithNoFund(address _petition) public nonReentrant whenNotPaused {
        require(msg.sender != address(0), "_signer cannot be zero");

        require(petitions[_petition] != address(0), "petition doesnt exist");

        require(!hasSigned[_petition][msg.sender], "already signed");

        sign(_petition);
    }

    function withdrawToken(address _petition, address _token) public nonReentrant whenNotPaused returns (bool) {
        uint256 _amount = tokenDeposites[_petition][_token][msg.sender];

        require(_amount > 0, "you've no token deposited");

        tokenDeposites[_petition][_token][msg.sender] = 0;

        emit LogWithdraw(address(this), msg.sender, _amount);

        emit LogWithdraw_User_Petition(_token, msg.sender, _petition);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        return true;
    }

    function withdrawETH(address _petition) public nonReentrant whenNotPaused returns (bool) {
        require(petitions[_petition] != address(0), "petition doesnt exist");

        uint256 _amount = ETHDeposites[_petition][msg.sender];

        require(_amount > 0, "you've no ether deposited");

        ETHBalance -= _amount;

        ETHDeposites[_petition][msg.sender] = 0;

        emit LogWithdrawETH(_petition, msg.sender, _amount);

        (bool sent,) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send Ether");

        return true;
    }

    // Returns the address of the newly deployed petition which will be the same when passing the same salt for other chains
    function deployNewPetition(string memory _title, string memory _description, uint256 _salt)
        public
        returns (address)
    {
        address _petition = address(new Petition{salt: bytes32(_salt)}(_title, _description, msg.sender));

        uint256 size;

        assembly {
            size := extcodesize(_petition)
        }
        require(size > 0, "_petition already exists");

        petitions[_petition] = msg.sender;

        emit LogDeploy(_petition, _title, _description);

        return _petition;
    }

    function getPetitionCreator(address _petition) public view returns (address) {
        return petitions[_petition];
    }

    function tokenIsSupported(address _token) public view returns (bool) {
        return (bytes(tokens[_token]).length != 0);
    }

    function addToken(address _token, string memory _symbol) external onlyOwner inputCheck(_token, _symbol) {
        require(bytes(tokens[_token]).length == 0, "token is already added");

        tokens[_token] = _symbol;

        emit LogTokenAdded(_token, _symbol);
    }

    function removeToken(address _token) external onlyOwner {
        require(bytes(tokens[_token]).length == 0, "token is not added");

        delete tokens[_token];

        emit LogTokenRemoved(_token);
    }

    function initialize(address _initialOwner) public initializer {
        _initialize(_initialOwner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function upgrade(address _newImpl) public reinitializer(VERSION) onlyOwner {
        upgradeToAndCall(_newImpl, "");
    }

    function _initialize(address _initialOwner) internal {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        emit LogPetitionLedgerInitialized(_initialOwner);
    }

    function _authorizeUpgrade(address _newImpl) internal virtual override(UUPSUpgradeable) onlyOwner {
        emit LogUpgradeAuthorized(_newImpl, msg.sender);
    }

    function sign(address _petition) private {
        hasSigned[_petition][msg.sender] = true;

        emit LogSign(_petition, msg.sender);
    }
}
