// SPDX-License-Identifier: MIT
// GateBoard — Agent ID-gated bounty board
// Binance Agent ID Hackathon (Binance Wallet x BNB Chain)
// Submissions: 18 Nov - 9 Dec 2026 08:00 UTC
// Agent ID contract (BNB Chain): 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
//   SPACE ID Agent ID, ERC-721, non-transferable, name.ai
//   Check: balanceOf(address) > 0 means the address holds an Agent ID.
//
// What it does:
//   Only wallets holding an Agent ID can post a bounty or claim one.
//   Anyone can read the board. No funds are held by this contract.
//   No BNB is deposited, escrowed, or paid out on-chain in v1.
//   Payment for a completed bounty is arranged off-chain between
//   creator and claimer. This keeps the contract simple and avoids
//   any automatic or scheduled asset transfer.
//
// Safety / hackathon red lines (Binance rules):
//   - No web QR-code login for Agentic Wallet. This contract does
//     not log anyone in. The frontend connects to the user's own
//     injected wallet (Binance Wallet / MetaMask) and every
//     transaction is confirmed by the user in their own wallet.
//   - No bypass of user confirmation, no unauthorized transfers,
//     no collection of seed phrases / private keys / pairing codes.
//   - No owner, no admin, no mint, no pause, no fee, no upgrade.
//     There are no owner permissions to disclose because there is
//     no owner. Anyone can read, only Agent ID holders can write.
//   - No "Binance" / "BNB" branding impersonation in the name.
//     GateBoard is an independent entry, not affiliated with Binance.
//
// Deployment: BNB Chain mainnet (chainId 56), Solidity ^0.8.20
// Verify on BscScan with this exact source (MIT, no constructor args).
// Compiler: 0.8.20+ (use Remix default 0.8.20 or later, optimizer off
//   or 200 runs — note the exact settings when you verify).

pragma solidity ^0.8.20;

interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract GateBoard {
    IAgentID public immutable agentId;

    // 0 = Open, 1 = Claimed, 2 = Done, 3 = Cancelled
    struct Bounty {
        uint256 id;
        address creator;
        address claimer;
        string title;
        string description;
        uint8 status;
        uint256 createdAt;
    }

    uint256 public bountyCount;
    mapping(uint256 => Bounty) private _bounties;

    event BountyCreated(uint256 indexed id, address indexed creator, string title);
    event BountyClaimed(uint256 indexed id, address indexed claimer);
    event BountyCompleted(uint256 indexed id, address indexed creator);
    event BountyCancelled(uint256 indexed id, address indexed creator);

    error AgentIdRequired();
    error BountyNotFound();
    error BountyNotOpen();
    error BountyNotClaimed();
    error CannotClaimOwn();
    error NotCreator();
    error EmptyTitle();
    error TitleTooLong();
    error DescriptionTooLong();

    constructor(address agentIdAddress) {
        agentId = IAgentID(agentIdAddress);
    }

    function hasAgentId(address user) public view returns (bool) {
        return agentId.balanceOf(user) > 0;
    }

    modifier onlyAgentHolder() {
        if (!hasAgentId(msg.sender)) revert AgentIdRequired();
        _;
    }

    function createBounty(string calldata title, string calldata description)
        external
        onlyAgentHolder
        returns (uint256 id)
    {
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(title).length > 100) revert TitleTooLong();
        if (bytes(description).length > 500) revert DescriptionTooLong();

        id = bountyCount;
        _bounties[id] = Bounty({
            id: id,
            creator: msg.sender,
            claimer: address(0),
            title: title,
            description: description,
            status: 0,
            createdAt: block.timestamp
        });
        bountyCount = id + 1;

        emit BountyCreated(id, msg.sender, title);
    }

    function claimBounty(uint256 id) external onlyAgentHolder {
        Bounty storage b = _bounties[id];
        if (b.creator == address(0)) revert BountyNotFound();
        if (b.status != 0) revert BountyNotOpen();
        if (msg.sender == b.creator) revert CannotClaimOwn();

        b.claimer = msg.sender;
        b.status = 1;
        emit BountyClaimed(id, msg.sender);
    }

    function completeBounty(uint256 id) external {
        Bounty storage b = _bounties[id];
        if (b.creator == address(0)) revert BountyNotFound();
        if (b.status != 1) revert BountyNotClaimed();
        if (msg.sender != b.creator) revert NotCreator();

        b.status = 2;
        emit BountyCompleted(id, msg.sender);
    }

    function cancelBounty(uint256 id) external {
        Bounty storage b = _bounties[id];
        if (b.creator == address(0)) revert BountyNotFound();
        if (b.status != 0) revert BountyNotOpen();
        if (msg.sender != b.creator) revert NotCreator();

        b.status = 3;
        emit BountyCancelled(id, msg.sender);
    }

    function getBounty(uint256 id) external view returns (Bounty memory) {
        Bounty memory b = _bounties[id];
        if (b.creator == address(0)) revert BountyNotFound();
        return b;
    }

    function getBounties(uint256 start, uint256 count)
        external
        view
        returns (Bounty[] memory out)
    {
        if (start >= bountyCount) return new Bounty[](0);
        uint256 end = start + count;
        if (end > bountyCount) end = bountyCount;
        out = new Bounty[](end - start);
        for (uint256 i = start; i < end; i++) {
            out[i - start] = _bounties[i];
        }
    }
}
