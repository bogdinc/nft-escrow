// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}



library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal initializer {
        _setOwner(initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}


interface MyNFT  {

    function getRoyaltyWallet() external view returns (address);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}


contract EscrowUpgradable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using Address for address;

    uint256 public _tokenId;

    uint256 public _price;

    uint256 public _ownerRoyalty;

    uint256 public _authorRoyalty;

    address payable public _authorWallet;

    MyNFT private _mainContract;

    event msgSender(address indexed account);
    event msgValue(uint256 amount);
    event Change(uint256 amount);
    event Amount(uint256 amount);
    event Tokens(uint256 amount);


    function initialize(
        uint256 tokenId,
        address cOwner,
        uint256 price,
        address _contract,
        uint256 oRoyalty,
        uint256 aRoyalty,
        address author
    ) public virtual initializer {
        __EscrowUpgradable_init(tokenId, cOwner, price, _contract, oRoyalty, aRoyalty, author);
    }

    function __EscrowUpgradable_init (
        uint256 tokenId,
        address cOwner,
        uint256 price,
        address _contract,
        uint256 oRoyalty,
        uint256 aRoyalty,
        address author
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(cOwner);
        __EscrowUpgradable_init_unchained(tokenId, price, _contract, oRoyalty, aRoyalty, author);
    }

    function __EscrowUpgradable_init_unchained (
        uint256 tokenId,
        uint256 price,
        address _contract,
        uint256 oRoyalty,
        uint256 aRoyalty,
        address author
    ) internal initializer {
        _tokenId = tokenId;
        _price = price;
        _ownerRoyalty = oRoyalty;
        _authorRoyalty = aRoyalty;
        _authorWallet = payable(author);
        _mainContract = MyNFT(_contract);
    }


    function getSupply() public view returns (uint256) {
        uint256 balance = _mainContract.balanceOf(address(this), _tokenId);
        return balance;
    }

    function withdraw(uint256 _amount) public onlyOwner  {
        uint256 supply = getSupply();
        require(_amount <= supply, "Insufficient amount to withdraw.");
        _mainContract.safeTransferFrom(address(this), owner(), _tokenId, _amount, "");
    }


    receive() external payable {
        require(msg.sender != owner(), "Seller cannot buy own NFT tokens.");
        uint256 tokenAmount = msg.value / _price;

        if (tokenAmount > getSupply()) {
            tokenAmount = getSupply();
        }
        uint256 change = msg.value - (tokenAmount * _price);
        uint256 _oRoyalty;
        uint256 _aRoyalty;
        address payable royaltyWallet;
        if (tokenAmount > 0) {
            _oRoyalty = tokenAmount * _price * _ownerRoyalty / 100;
            _aRoyalty = tokenAmount * _price * _authorRoyalty / 100;
            royaltyWallet = payable(_mainContract.getRoyaltyWallet());
            _mainContract.safeTransferFrom(address(this), _msgSender(), _tokenId, tokenAmount, "");
            royaltyWallet.transfer(_oRoyalty);
            _authorWallet.transfer(_aRoyalty);
            payable(owner()).transfer(msg.value - change - _oRoyalty - _aRoyalty);
            emit msgSender(_msgSender());
            emit msgValue(msg.value);
            emit Change(change);
            emit Tokens(tokenAmount);
        }
        if (change > 0) {
            payable(_msgSender()).transfer(change);
        }

    }

    uint256[50] private __gap;
}



interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);


    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}


interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}



library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}



contract AVONFT is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    mapping (uint256 => uint256) public tokenSupply;

    mapping (uint256 => address) public authors;

    mapping (uint256 => uint256) public _ownerRoyalty;

    mapping (uint256 => uint256) public _authorRoyalty;


    mapping (address => bool) private escrows;

    event EscrowCreated(address indexed account);

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;


    constructor(string memory baseuri,  address cOwner) Ownable (cOwner)  {
        _setURI(baseuri);
    }


    function setURI(string memory _newuri) public onlyOwner {
        _uri = _newuri;
    }


    function setTransferAllowance(address _account, bool b) public onlyOwner {
        require(_account != address(0), "Zero address not allowed.");
        escrows[_account] = b;
    }


    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }


    function getRoyaltyWallet() public view returns (address) {
        return owner();
    }



    function create (
        uint256 _id,
        uint256 _initialSupply,
        uint256 _oRoyalty,
        uint256 _aRoyalty,
        address _author,
        bytes calldata _data
      ) external onlyOwner returns (uint256) {
        require(_author != address(0), "Zero address for author is prohibited");
        require(_initialSupply > 0, "Cannot create zero amount of tokens");
        require(_oRoyalty + _aRoyalty < 100, "Total royalty cannot exceed 100%");
        require(tokenSupply[_id] == 0, "Token already exists");
        _mint(owner(), _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        _ownerRoyalty[_id] = _oRoyalty;
        _authorRoyalty[_id] = _aRoyalty;
        authors[_id] = _author;
        return _id;
      }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(_id), ".json"));
    }


    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }



    function balanceOfBatch(address account, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(ids.length > 0, "ERC1155: No ids provided");

        uint256[] memory batchBalances = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = balanceOf(account, ids[i]);
        }

        return batchBalances;
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public  override {
        require((from == owner() || to == owner() || escrows[from] || escrows[to]),
                "ERC1155: transfers allowed only to contract owner address or to escrow address.");

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require((from == owner() || to == owner() || escrows[from] || escrows[to]),
                "ERC1155: transfers allowed only to contract owner address or to escrow address.");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }


    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }


    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }


    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }


    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }


    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(amount > 0, "ERC1155: amount must exceed zero");
        require(amount <= tokenSupply[id], "ERC1155: amount cannot exceed total supply");
        _burn(account, id, amount);
        tokenSupply[id] = tokenSupply[id] - amount;
    }



    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }


    function createEscrow(
        uint256 tokenId,
        uint256 price,
        uint256 amount
    ) external {
        require(_balances[tokenId][msg.sender] >= amount, "Insufficient amount to sell.");
        require(price > 0, "Price cannot be zero.");
        EscrowUpgradable escrow = new EscrowUpgradable();
        escrow.initialize(tokenId, msg.sender, price, address(this), _ownerRoyalty[tokenId], _authorRoyalty[tokenId], authors[tokenId]);
        uint256 fromBalance = _balances[tokenId][msg.sender];
        _balances[tokenId][msg.sender] = fromBalance - amount;
        _balances[tokenId][address(escrow)] = _balances[tokenId][address(escrow)] + amount;
        escrows[address(escrow)] = true;
        emit TransferSingle(msg.sender, msg.sender, address(escrow), tokenId, amount);
        emit EscrowCreated(address(escrow));
    }

}