#!/bin/sh

node deploy/0_deploy_bridge_registry.js
node deploy/1_deploy_secure_storage.js
node deploy/2_deploy_bridge_factory.js
node deploy/3_bridge_factory_tests.js
# node deploy/

exit