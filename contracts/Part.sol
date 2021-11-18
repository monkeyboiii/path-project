// SPDX-License-Identifier: MIT

pragma solidity ^0.5.1;

import "./interface/IERC721.sol";
import "./lib/oraclizeAPI_0.5.sol";

/**
 * @dev Modified implementation of
 * https://eips.ethereum.org/EIPS/eip-721[ Non-Fungible Token Standard,
 * including the Metadata extension, but not including the Enumerable
 * extension, which is available separately as {numerable}.
 * This is the actual instance of commodity.
 */
contract Part is IERC721 {
    // contract name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token symbol
    uint256 public total;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping owner address to token
    mapping(address => uint256[]) private _collections;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // part dependency graph
    mapping(uint256 => uint256[]) public _dependency;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _owners[0] = address(0);
        _dependency[0] = new uint256[](0);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "Part: balance query for the zero address"
        );
        return _balances[owner];
    }

    function collectionOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(
            owner != address(0),
            "Part: collection query for the zero address"
        );
        return _collections[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Part: owner query for nonexistent token");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function getTotal() public view returns (uint256) {
        return total;
    }

    function mint(address to) external payable returns (uint256) {
        _safeMint(to, total);
        total++;
        return total;
    }

    function trace(uint256 tokenId) external view returns (string memory) {
        string memory ans = "";
        for (uint256 i = 0; i < _dependency[tokenId].length; i++) {
            // TODO: serical library for concatenation
        }
        return ans;
    }

    // function tokenURI(uint256 tokenId) public view returns (string memory) {
    //     require(_exists(tokenId), "Part: URI query for nonexistent token");

    //     string memory baseURI = _baseURI();
    //     return
    //         bytes(baseURI).length > 0
    //             ? string(abi.encodePacked(baseURI, tokenId.toString()))
    //             : "";
    // }

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    //  * by default, can be overriden in child contracts.
    //  */
    // function _baseURI() internal view returns (string memory) {
    //     return "";
    // }

    function approve(address to, uint256 tokenId) public payable {
        address owner = this.ownerOf(tokenId);
        require(to != owner, "Part: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Part: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Part: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Part: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Part: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Part: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {Ieceiver-oneceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        // require(
        //     _checkOneceived(from, to, tokenId, _data),
        //     "Part: transfer to non eceiver implementer"
        // );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(tokenId), "Part: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {Ieceiver-oneceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {Ieceiver-oneceived} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        // require(
        //     _checkOneceived(address(0), to, tokenId, _data),
        //     "Part: transfer to non eceiver implementer"
        // );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Part: mint to the zero address");
        require(!_exists(tokenId), "Part: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "Part: transfer of token that is not own"
        );
        require(to != address(0), "Part: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}
}
