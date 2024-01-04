<!-- ABOUT THE PROJECT -->

## About The Project

ERC5643 provides a base implementation of [EIP5643](https://eips.ethereum.org/EIPS/eip-5643) to make building subscription
NFTs easier and more standardized.

This is **experimental software** and is provided on an "as is" and "as available" basis.
We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

<!-- Installation -->

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install cygaar/ERC5643
```

To import the contract in a hardhat-like fashion, you can add the following line to your [remappings](https://book.getfoundry.sh/reference/forge/forge-remappings):

```
erc5643/=lib/ERC5643/
```

Then you can import ERC5643 like so:

```solidity
pragma solidity ^0.8.19;

import "erc5643/src/ERC5643.sol";

contract Contract is ERC5643 {
    constructor(string memory name_, string memory symbol_)
        ERC5643(name_, symbol_)
    {}
}
```

<!-- USAGE EXAMPLES -->

## Usage

A good starting point is the [ERC5643Mock contract](https://github.com/cygaar/ERC5643/blob/main/src/mocks/ERC5643Mock.sol)
which provides an example implementation of ERC5643.

<!-- ROADMAP -->

## Roadmap

- [ ] Add npm support
- [ ] Add auto-renewal support via ERC20 tokens
- [ ] Gas optimizations
- [ ] Maintain full test coverage

See the [open issues](https://github.com/cygaar/ERC5643/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- ROADMAP -->

### Running tests locally

1. `forge test -vv`

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

Project Link: [https://github.com/cygaar/ERC5643](https://github.com/cygaar/ERC5643)
