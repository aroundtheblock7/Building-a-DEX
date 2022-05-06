# Building-a-DEX

## This is a custom built Dex deployed to Rospten Network
```truffle console --network ropsten```
```truffle migrate```

## Deployment to Rospten
```
2_dex_migrations.js
===================

   Replacing 'Dex'
   ---------------
   > transaction hash:    0xb7f69f2233b6e355eb911698657a154a31e24fdc9330a2589c7895973941ac92
   > Blocks: 1            Seconds: 8
   > contract address:    0xFCA3D348e44BA2C038c659e00E44868eBE092557
   > block number:        12242846
   > block timestamp:     1651850756
   > account:             0xFF985509Aa523FE9cd3d0A6891fCB9f2A4134feE
   > balance:             0.300279580962394938
   > gas used:            3596653 (0x36e16d)
   > gas price:           2.500001026 gwei
   > value sent:          0 ETH
   > total cost:          0.008991636190165978 ETH

   Pausing for 2 confirmations...

   -------------------------------
   > confirmation number: 1 (block: 12242847)
   > confirmation number: 2 (block: 12242848)
   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:     0.008991636190165978 ETH


3_token_migrations.js
=====================

   Replacing 'Link'
   ----------------
   > transaction hash:    0x97493f063575f842114f4375e92b5f636382e74abae0140b145f301e34e017fe
   > Blocks: 1            Seconds: 88
   > contract address:    0x28634019a10E1640B7e0C19C3265c70108615d12
   > block number:        12242850
   > block timestamp:     1651850869
   > account:             0xFF985509Aa523FE9cd3d0A6891fCB9f2A4134feE
   > balance:             0.297330249991675592
   > gas used:            1150919 (0x118fc7)
   > gas price:           2.500000822 gwei
   > value sent:          0 ETH
   > total cost:          0.002877298446055418 ETH

   Pausing for 2 confirmations...

   -------------------------------
   > confirmation number: 1 (block: 12242851)
   > confirmation number: 2 (block: 12242852)
   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:     0.002877298446055418 ETH

Summary
=======
> Total deployments:   3
> Final cost:          0.012482934934625396 ETH
```
