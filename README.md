# component-examples

This repo contains a few examples of the potential interaction between components. For a review on components, see the [community forum post](https://community.starknet.io/t/cairo-components/101136). Build with `scarb build --workspace`, or a specific package via `scarb build --package dependency3`.

## Examples in the repo

### basic_component 

An example of a basic upgradability component with no dependency

### dependency1

Upgradable depends on an `OwnableTrait` implementation to limit access to the `upgrade` function. The contract which uses the component directly implements `OwnableTrait` in order to use the upgradability component.

### dependency2

We now have two components, `Ownable` and `Upgradable`. `Ownable` has the internal function `initialize_owner`, and two external functions that are defined in the `IOwnable` interface. `Upgradable` depends on the contract implementing `IOwnable` to limit to the `upgrade` function. The contract uses both components. By using `Ownable`, we create an impl of `IOwnable<ContractState>`, which is need to use `Upgradable`.

### dependency3

Same as above, but now the `is_owner` function is moved to the internal trait `OwnableInternal`. This means that we need to access "internal" functions (i.e. functions in a none embeddable impl) of component A inside component B. 

Since both `upgrade` and `is_owner` are now functions that expect `upgradable::ComponentState` and `ownable:ComponentState` respectively, we need a way to move from one to the other. To do this, we add a dependency on an implementation of `ownable::HasComponent<TContractState>` to `UpgradableImpl`. This allows us to do the following transition: `upgradable::ComponentState<TContractState>` &rarr; `TcontractState` &rarr; `ownable::ComponentState<TContractState>`.

In order to keep the `upgrade` function brief, we placed this transition logic inside a new impl called `GetOwnable`.