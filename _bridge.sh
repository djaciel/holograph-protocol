#!/bin/sh

node deploy/bridge_1_deploy_sample_erc721.js &&
node deploy/bridge_2_mint_multichain_nfts.js &&
# node deploy/.js &&
# node deploy/.js &&

echo ""
echo ""

exit