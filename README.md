Crowdfunding
Crowdfunding is a decentralized fundraising contract built on the Stacks blockchain using Clarity.
It allows project creators to launch campaigns, collect STX contributions from supporters,
and automatically release or refund funds based on whether the campaign reaches its funding goal before the deadline.

Features
Create and manage fundraising campaigns
Support contributions from multiple participants
Automatic goal and deadline verification
Claim funds if the goal is reached
Refund contributors if the campaign fails
Transparent tracking through on-chain events

Technical Overview
Language: Clarity
Data Structures:
campaigns → campaign-id → {creator, goal, deadline, total-funded, is-claimed}
contributions → {campaign-id, contributor} → amount
next-id → sequential counter for campaign indexing
Core Functions:
create-campaign(goal, deadline) – create new funding campaign
contribute(campaign-id, amount) – fund a campaign
claim-funds(campaign-id) – creator withdraws after success
refund(campaign-id) – contributor refunds if campaign fails
get-campaign(campaign-id) – retrieve campaign data

Security
Prevents double refunds or double claims
Enforces deadline validation
Safe STX transfers via stx-transfer?
Emits events for traceability and audits
