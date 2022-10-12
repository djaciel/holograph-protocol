describe('Holograph Treasury Contract', async function () {
  describe('constructor', async function () {});

  describe('init()', async function () {
    it('should successfully be initialized once'); // Validate hardcoded values are correct
    it('should fail if already initialized');
    it('Should allow external contract to call fn');
    it('should fail to allow inherited contract to call fn');
  });

  describe(`_bridge()`, async function () {
    it('should successfully get _bridgeSlot');
    it('is private function');
  });

  describe(`_holograph()`, async function () {
    it('should successfully get _holographSlot');
    it('is private function');
  });

  describe(`_operator()`, async function () {
    it('should successfully get _operatorSlot');
    it('is private function');
  });

  describe(`_registry()`, async function () {
    it('should successfully get _registrySlot');
    it('is private function');
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
});
