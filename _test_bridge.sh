#!/bin/sh

echo "\n\n###### TESTING BRIDGING ######\n\n"

FILES=("bridge_1_deploy_sample_erc721" "bridge_2_mint_multichain_nfts" "bridge_3_transfer_multichain_nfts")

export NETWORK_TYPE=1;

for FILE in ${FILES[@]}; do

    echo "\n### "$FILE"_start ###"
    node test/$FILE.js
    if [ $? != 0 ]; then
        exit
    fi
    echo "### "$FILE"_finish ###"

done

export NETWORK_TYPE=1;

    echo ""
    echo ""


exit