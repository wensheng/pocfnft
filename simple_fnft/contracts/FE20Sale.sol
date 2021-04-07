// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

//import '@openzeppelin/contracts/utils/context.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import './NFT2E20.sol';

contract FE20Sale is IERC721Receiver, IERC1155Receiver, Context, ReentrancyGuard {
    enum NftType {E721, E1155}
    NFT2E20 private _token;
    //IERC165 private _nft;
    NftType private _nftType;
    uint public nftId;
    address public admin;
    address public nftAddress;
    address payable private _wallet;
    address payable private _nftOwner;
    uint public tokenPrice;
    uint public tokenSupply;
    uint public offerEndTime;
    uint public saleDuration;  // in hours
    bool private _nftReceived;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;


    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param _nftAddress address of NFT to be acquired later by admin
     */
    constructor (address _nftAddress, uint _nftId) {
        require(_nftAddress != address(0), "NFT Address is the zero address");
        _wallet = payable(msg.sender);
        admin = msg.sender;
        nftAddress = _nftAddress;
        IERC165 nft = IERC165(_nftAddress);
        // TODO: reduce gas
        if(nft.supportsInterface(0x80ac58cd)){
            _nftType = NftType.E721;
        }else{
            _nftType = NftType.E1155;
        }
        nftId = _nftId;
        _nftReceived = false;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external override returns (bytes4){
        _nftReceived = true;
        return 0x150b7a02;
    }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
    external override returns(bytes4){
        _nftReceived = true;
        return 0xf23a6e61;
    }
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4){
        _nftReceived = true;
        return 0xbc197c81;
    }
    function supportsInterface(bytes4 interfaceId) external override view returns (bool){
        if (interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId){
            return true;
        }
    }


    receive() external payable {
        buyTokens(msg.sender);
    }
    fallback() external payable {
        buyTokens(msg.sender);
    }

    function nftype() public view returns (NftType) {
        return _nftType;
    }

    function transferNFT() public {
        // TODO: must be owner of nft, or approved
        if(_nftType == NftType.E721){
            IERC721 nft = IERC721(nftAddress);
            nft.safeTransferFrom(msg.sender, address(this), nftId);
        }else{
            IERC1155 nft = IERC1155(nftAddress);
            nft.safeTransferFrom(msg.sender, address(this), nftId, 1, bytes(""));
        }
        _nftOwner = payable(msg.sender);
    }

    function startSelling(uint _supply, uint _price, uint _duration) external {
        require(msg.sender == admin, 'only admin');
        tokenSupply = _supply;
        tokenPrice = _price;
        saleDuration = _duration;
        offerEndTime = block.timestamp + saleDuration * 3600;
        _token = new NFT2E20("name", "symbol", nftId, tokenSupply);
    }

    function concludeSale() external {
        require(msg.sender == admin, 'only admin');
        // owner get 99.5% of fund, platform get remaining 0.5
        uint totalBalance = address(this).balance;
        uint nftOwnerGet = totalBalance * 995 / 1000;
        uint platformGet = totalBalance - nftOwnerGet;
        _nftOwner.transfer(nftOwnerGet);
        _wallet.transfer(platformGet);
        uint unsold = tokenSupply - _token.totalSupply();
        if(unsold > 0) {
            _token.transfer(_nftOwner, unsold);
        }
    }


    /**
     * @return the token being sold.
     */
    function token() public view returns (NFT2E20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        require(offerEndTime > 0, 'Sale of token not started');
        require(block.timestamp <= offerEndTime, 'Sale of token finished');
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        require(_token.totalSupply() + tokens <= tokenSupply, 'not enough shares left');

        // update state
        _weiRaised = _weiRaised + weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        //_forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

}
