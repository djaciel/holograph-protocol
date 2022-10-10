describe('Holograph Genesis Contract', async function () {

    describe('constructor', async function () {
        it('should successfully deploy') // Validate hardcoded values are correct
    })

    describe('deploy()', async function() {
        it('should fail if chainId is not this blockchains chainId')
        it('should fail if contract was already deployed')
        it('should fail if the deployment failed')
        it('should fail if contract init code does not match the init selector')
    })

    describe(`approveDeployer()`, async function() {
        it('Should allow deployer wallet to add to approved deployers')
        it('should fail non-deployer wallet to add approved deployers')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe(`isApprovedDeployer()`, async function() {
        it('Should return true to approved deployer wallet')
        it('Should return false non-deployer wallet')
        it('Should allow external contract to call fn')
        it('should fail to allow inherited contract to call fn')
    })

    describe('_isContract()', async function() {
        it('should not be callable from an external contract')
    })

})
