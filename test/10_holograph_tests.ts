describe('Holograph Contract', async function () {
  describe('init():', async function () {
    it('should successfully init once'); // Validate hardcoded values are correct
    it('should fail to init if already initialized');
    it('should fail if holographChainId is value larger than uint32'); // NOTE: check if the expected value is correct
  });

  describe(`getBridge()`, async function () {
    it('Should return valid _bridgeSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(' setBridge()', async function () {
    it('should allow admin to alter _bridgeSlot');
    it('should fail to allow owner to alter _bridgeSlot');
    it('should fail to allow non-owner to alter _bridgeSlot');
  });

  describe(`getChainId()`, async function () {
    it('Should return valid _chainIdSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setChainId()', async function () {
    it('should allow admin to alter _chainIdSlot');
    it('should fail to allow owner to alter _chainIdSlot');
    it('should fail to allow non-owner to alter _chainIdSlot');
  });

  describe(`getFactory()`, async function () {
    it('Should return valid _factorySlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setFactory()', async function () {
    it('should allow admin to alter _factorySlot');
    it('should fail to allow owner to alter _factorySlot');
    it('should fail to allow non-owner to alter _factorySlot');
  });

  describe(`getHolographChainId()`, async function () {
    it('Should return valid _holographChainIdSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setHolographChainId()', async function () {
    it('should allow admin to alter _holographChainIdSlot');
    it('should fail to allow owner to alter _holographChainIdSlot');
    it('should fail to allow non-owner to alter _holographChainIdSlot');
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

  describe(`getOperator()`, async function () {
    it('Should return valid _operatorSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setOperator()', async function () {
    it('should allow admin to alter _operatorSlot');
    it('should fail to allow owner to alter _operatorSlot');
    it('should fail to allow non-owner to alter _operatorSlot');
  });

  describe(`getRegistry()`, async function () {
    it('Should return valid _registrySlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setRegistry()', async function () {
    it('should allow admin to alter _registrySlot');
    it('should fail to allow owner to alter _registrySlot');
    it('should fail to allow non-owner to alter _registrySlot');
  });

  describe(`getTreasury()`, async function () {
    it('Should return valid _treasurySlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(' setTreasury()', async function () {
    it('should allow admin to alter _treasurySlot');
    it('should fail to allow owner to alter _treasurySlot');
    it('should fail to allow non-owner to alter _treasurySlot');
  });

  describe(`getUtilityToken()`, async function () {
    it('Should return valid _utilityTokenSlot');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe('setUtilityToken()', async function () {
    it('should allow admin to alter _utilityTokenSlot');
    it('should fail to allow owner to alter _utilityTokenSlot');
    it('should fail to allow non-owner to alter _utilityTokenSlot');
  });

  describe(`receive()`, async function () {
    it('should revert');
  });

  describe(`fallback()`, async function () {
    it('should revert');
  });
});
