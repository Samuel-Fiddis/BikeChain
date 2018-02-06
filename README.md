# BikeChain

This project aims to create an ethereum based platform for the registration,
reporting of theft and transfer of bikes as a non-fungible asset between ethereum addresses.

# Development

To start development, download truffle and all dependencies. Then in one terminal run:

> truffle develop
> comiple
> migrate

Then in another run:

> npm run dev

# Deployment to Rinkeby Testnet

To deploy to the Rinkeby Testnet open one terminal to run geth with the command:

> geth --rinkeby --rpc --rpcapi db,eth,net,web3,personal --unlock=<Rinkeby Account> --password <file storing password>

Then another and run:

> truffle develop
> comiple
> migrate --network rinkeby
