
const PlsBurnDrop = artifacts.require('PlsBurnDrop');
const ERC20Burnable = artifacts.require('ERC20Burnable');
const pify = require('pify')



contract('PlsBurnDrop', (accounts) => {
  let plsBurnDrop;

  const waitNBlocks = async n => {
    const sendAsync = pify(web3.currentProvider.send);
    await Promise.all(
      [...Array(n).keys()].map(i =>
        sendAsync({
          jsonrpc: '2.0',
          method: 'evm_mine',
          id: i
        })
      )
    );
  };

  before(async () => {
    let ring = await ERC20Burnable.new('RING');
    let pls = await ERC20Burnable.new('PLS');
    plsBurnDrop = await PlsBurnDrop.new(100000, 10000, 1596612273, 1596615872, ring.address, pls.address);
  });

  describe('TestExchange', async () => {
    before(async () => {

    });
  });
});
