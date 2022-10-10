describe('Holograph Factory Contract', async function () {

    describe('init():', async function () {
        it('should successfully init once') // Validate hardcoded values are correct
        it('should fail to init if already initialized')
        it('should fail if data parameter is invalid ') // NOTE: check if the expected value is correct
    })

    describe(`bridgeIn()`, async function() {
        it('should return the expected selector from the input payload')
        it('should return bad data if payload data is invalid')
    })

    describe('bridgeOut()', async function() {
        it('should return selector and payload')
    })

    describe('deployHolographableContract()', async function() {
        it('should fail with invalid signature if config is incorrect')
        it('should fail with invalid signature if signature.r is incorrect')
        it('should fail with invalid signature if signature.s is incorrect')
        it('should fail with invalid signature if signature.v is incorrect')
        it('should fail with invalid signature if signer is incorrect')

        it('should fail contract was already deployed')

        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`getHolograph()`, async function() {
        it('Should return valid _holographSlot')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe('setHolograph()', async function() {
        it('should allow admin to alter _holographSlot')
        it('should fail to allow owner to alter _holographSlot')
        it('should fail to allow non-owner to alter _holographSlot')
    })

    describe(`getRegistry()`, async function() {
        it('Should return valid _registrySlot')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe('setRegistry()', async function() {
        it('should allow admin to alter _registrySlot')
        it('should fail to allow owner to alter _registrySlot')
        it('should fail to allow non-owner to alter _registrySlot')
    })

    describe('_isContract()', async function() {
        it('should not be callable')
    })

    describe('_verifySigner()', async function() {
        it('should not be callable')
    })
})
