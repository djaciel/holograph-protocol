#!/bin/sh

export NETWORK_TYPE=1;
node deploy/0_fund_deployer.js &&
node deploy/1_deploy_holograph_genesis.js &&
node deploy/2_deploy_sources.js &&
node deploy/3_set_pa1d_type.js &&
node deploy/4_deploy_holograph_erc721.js &&
node deploy/5_test_holograph_erc721.js &&
node deploy/6_set_holograph_erc721_type.js &&
node deploy/7_deploy_sample_erc721.js &&
node deploy/8_test_sample_erc721.js &&
node deploy/9_mint_sample_token.js &&
node deploy/10_test_nft_functionality.js &&

export NETWORK_TYPE=2;
node deploy/0_fund_deployer.js &&
node deploy/1_deploy_holograph_genesis.js &&
node deploy/2_deploy_sources.js &&
node deploy/3_set_pa1d_type.js &&
node deploy/4_deploy_holograph_erc721.js &&
node deploy/5_test_holograph_erc721.js &&
node deploy/6_set_holograph_erc721_type.js &&
node deploy/7_deploy_sample_erc721.js &&
node deploy/8_test_sample_erc721.js &&
node deploy/9_mint_sample_token.js &&
node deploy/10_test_nft_functionality.js &&

export NETWORK_TYPE=1;
# node deploy/.js &&
# node deploy/.js &&
# node deploy/.js &&
# node deploy/.js &&

echo ""
echo ""

exit