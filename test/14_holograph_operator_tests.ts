describe('Holograph Operator Contract', async function () {
  describe('constructor', async function () {
    it('should successfully deploy');
  });

  describe('init()', async function () {
    it('should successfully be initialized once'); // Validate hardcoded values are correct
    it('should fail if already initialized');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('executeJob()', async function () {
    it('Should fail if job hash is not in in _operatorJobs');
    it('Should fail non-operator address tries to execute job'); // NOTE: "HOLOGRAPH: operator has time" error
    it('Should fail if there has been a gas spike');
    it('Should fail if fallback is invalid'); // NOTE: "HOLOGRAPH: invalid fallback"
    it('Should fail if there is not enough gas');
  });

  describe(`crossChainMessage()`, async function () {
    it('Should successfully allow messaging address to call fn');
    it('Should fail to allow deployer address to call fn');
    it('Should fail to allow owner address to call fn');
    it('Should fail to allow non-owner address to call fn');
  });

  describe('jobEstimator()', async function () {
    it('should return expected estimated value');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
    it('should be payable');
  });

  describe('send()', async function () {
    it('should fail if `toChainId` provided a string');
    it('should fail if `toChainId` provided a value larger than uint32');
  });

  describe('getJobDetails()', async function () {
    it('should return expected operatorJob from valid jobHash');
    it('should return expected operatorJob from INVALID jobHash');
  });

  describe('getTotalPods()', async function () {
    it('should return expected number of pods');
  });

  describe('getPodOperatorsLength()', async function () {
    it('should fail if pod does not exist');
    it('should return expected pod length');
  });

  describe('getPodOperators(pod)', async function () {
    it('should return expected operators for a valid pod');
    it('should fail to return operators for an INVALID pod');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('getPodOperators(pod, index, length)', async function () {
    it('should return expected operators for a valid pod');
    it('should fail to return operators for an INVALID pod');
    it('should fail if index out of bounds');
    it('should fail if length is out of bounds');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('getPodBondAmounts()', async function () {
    it('should return expected base and current value');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('getBondedPod()', async function () {
    it('should return expected _bondedOperators');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('topupUtilityToken()', async function () {
    it('should fail if operator is bonded');
    it('successfully top up utility tokens');
  });

  describe('bondUtilityToken()', async function () {
    it('should fail if the operator is already bonded');
    it('Should fail if the provided bond amount is too low');
    it('should fail if the pod operator limit has been reached');
    it('should fail if the token transfer failed');
    it('should successfully allow bonding');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('unbondUtilityToken()', async function () {
    it('should fail if the operator has not bonded');
    it('Should fail if operator address is a contract');
    it('should fail if sender is not the owner');
    it('should fail if the token transfer failed');
    it('should successfully allow unbonding');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`getMessagingModule()`, async function () {
    it('Should return valid _messagingModuleSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setMessagingModule()', async function () {
    it('should allow admin to alter _messagingModuleSlot');
    it('should fail to allow owner to alter _messagingModuleSlot');
    it('should fail to allow non-owner to alter _messagingModuleSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`getBridge()`, async function () {
    it('Should return valid _bridgeSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setBridge()', async function () {
    it('should allow admin to alter _bridgeSlot');
    it('should fail to allow owner to alter _bridgeSlot');
    it('should fail to allow non-owner to alter _bridgeSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`getHolograph()`, async function () {
    it('Should return valid _holographSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setHolograph()', async function () {
    it('should allow admin to alter _holographSlot');
    it('should fail to allow owner to alter _holographSlot');
    it('should fail to allow non-owner to alter _holographSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`getInterfaces()`, async function () {
    it('Should return valid _interfacesSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setInterfaces()', async function () {
    it('should allow admin to alter _interfacesSlot');
    it('should fail to allow owner to alter _interfacesSlot');
    it('should fail to allow non-owner to alter _interfacesSlot');
  });

  describe(`getRegistry()`, async function () {
    it('Should return valid _registrySlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setRegistry()', async function () {
    it('should allow admin to alter _registrySlot');
    it('should fail to allow owner to alter _registrySlot');
    it('should fail to allow non-owner to alter _registrySlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`getUtilityToken()`, async function () {
    it('Should return valid _utilityTokenSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setUtilityToken()', async function () {
    it('should allow admin to alter _utilityTokenSlot');
    it('should fail to allow owner to alter _utilityTokenSlot');
    it('should fail to allow non-owner to alter _utilityTokenSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('_bridge()', async function () {
    it('is private function');
  });

  describe('_holograph()', async function () {
    it('is private function');
  });

  describe('_interfaces()', async function () {
    it('is private function');
  });

  describe('_messagingModule()', async function () {
    it('is private function');
  });

  describe('_registry()', async function () {
    it('is private function');
  });

  describe('_utilityToken()', async function () {
    it('is private function');
  });

  describe('_jobNonce()', async function () {
    it('is private function');
  });

  describe('_popOperator()', async function () {
    it('is private function');
  });

  describe('_getBaseBondAmount()', async function () {
    it('is private function');
  });

  describe('_getCurrentBondAmount()', async function () {
    it('is private function');
  });

  describe('_randomBlockHash()', async function () {
    it('is private function');
  });

  describe('_isContract()', async function () {
    it('should not be callable from an external contract');
  });
});
