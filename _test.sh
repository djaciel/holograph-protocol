#!/bin/sh

echo "\n\n###### TESTING DEPLOYMENT ######\n\n"

FILES=("0_fund_deployer" "1_deploy_holograph_genesis" "2_deploy_sources" "3_set_pa1d_type" "4_deploy_holograph_erc721" "5_test_holograph_erc721" "6_set_holograph_erc721_type" "7_deploy_sample_erc721" "8_test_sample_erc721" "9_mint_sample_token" "10_test_nft_functionality" "11_deploy_holograph_erc20" "12_test_holograph_erc20" "13_set_holograph_erc20_type" "14_deploy_mock_tokens" "15_deploy_hToken" "16_test_hToken" "17_mint_hToken" "18_test_hToken_functionality")

## we loop two times to cover networks 1 and 2
for network in 1 2
do

    export NETWORK_TYPE=$network;

    for FILE in ${FILES[@]}; do

        echo "\n### "$FILE"_network_"$NETWORK_TYPE"_start ###"
        node test/$FILE.js
        if [ $? != 0 ]; then
            exit
        fi
        echo "### "$FILE"_network_"$NETWORK_TYPE"_finish ###"

    done

done

export NETWORK_TYPE=1;

    echo ""
    echo ""


exit