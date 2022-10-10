describe('Holograph Registry Contract', async function () {

    describe('constructor', async function () {
        it('should successfully deploy')
    })

    describe('init()', async function() {
        it('should successfully be initialized once') // Validate hardcoded values are correct
        it('should fail if already initialized')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe('factoryDeployedHash', async function() {
        it('should successfully set values')
        it('should fail because sender is not a factory function')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getContractTypeAddress()`, async function() {
        it('Should return valid _contractTypeAddresses')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHolograph()`, async function() {
        it('Should return valid _holographSlot')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHolographableContracts`, async function() {
        it('Should return valid contracts')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHolographableContractsLength`, async function() {
        it('Should return valid _holographableContracts length')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHolographedHashAddress`, async function() {
        it('Should return valid _holographedContractsHashMap')
        it('should return 0x0 for invalid hash')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`setHolographedHashAddress`, async function() {
        it('Should return fail to add contract because it does not have a factory')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHToken`, async function() {
        it('Should return valid _hTokens')
        it('should return 0x0 for invalid chainId')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getUtilityToken`, async function() {
        it('Should return valid _hTokens')
        it('should return 0x0 for invalid chainId')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`isHolographedContract`, async function() {
        it('Should return true if smartContract is valid')
        it('should return false if smartContract is INVALID')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`isHolographedHashDeployed`, async function() {
        it('Should return true if hash is valid')
        it('should return false if hash is INVALID')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`referenceContractTypeAddress`, async function() {
        it('should return valid address')
        it('should fail if contract is empty')
        it('should fail if contract is already set')
        it('should fail if the address type is reserved already')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`setContractTypeAddress`, async function() {
        it('should return valid address')
        it('should fail if the address is the contract is not a reserve type')
        it('should allow admin to alter setContractTypeAddress')
        it('should fail to allow owner to alter setContractTypeAddress')
        it('should fail to allow non-owner to alter setContractTypeAddress')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe('setHolograph()', async function() {
        it('should allow admin to alter _holographSlot')
        it('should fail to allow owner to alter _holographSlot')
        it('should fail to allow non-owner to alter _holographSlot')
    })

    describe('setHToken()', async function() {
        it('should allow admin to alter _hTokens')
        it('should fail to allow owner to alter _hTokens')
        it('should fail to allow non-owner to alter _hTokens')
    })

    describe('getReservedContractTypeAddress()', async function() {
        it('should return expected contract type address')
    })

    describe('setReservedContractTypeAddress()', async function() {
        it('should allow admin to set contract type address')
        it('should fail to allow owner to alter contract type address')
        it('should fail to allow non-owner to alter contract type address')
    })

    describe('setReservedContractTypeAddresses()', async function() {
        it('should allow admin to set _reservedTypes')
        it('should fail to allow owner to alter _reservedTypes')
        it('should fail to allow non-owner to alter _reservedTypes')
    })

    describe('setUtilityToken()', async function() {
        it('should allow admin to alter _utilityTokenSlot')
        it('should fail to allow owner to alter _utilityTokenSlot')
        it('should fail to allow non-owner to alter _utilityTokenSlot')
    })

})
