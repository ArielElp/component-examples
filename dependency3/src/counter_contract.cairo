#[starknet::interface]
trait ICounterContract<TContractState> {
    fn increase_counter(ref self: TContractState, amount: u128);
    fn decrease_counter(ref self: TContractState, amount: u128);
    fn get_counter(self: @TContractState) -> u128;
}

#[starknet::contract]
mod counter_contract {
    use starknet::get_caller_address;
    use dependency3::upgradable::upgradable as upgradable_component;
    use dependency3::ownable::ownable as ownable_component;
    use ownable_component::OwnableInternalImpl;

    component!(path: upgradable_component, storage: upgradable, event: UpgradableEvent);
    component!(path: ownable_component, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl Upgradable = upgradable_component::UpgradableImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u128,
        #[substorage(v0)]
        upgradable: upgradable_component::Storage,
        #[substorage(v0)]
        ownable: ownable_component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        UpgradableEvent: upgradable_component::Event,
        OwnableEvent: ownable_component::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct CounterDecreased {
        amount: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u128) {
        self.counter.write(initial_counter);
    }

    #[external(v0)]
    impl CounterContract of super::ICounterContract<ContractState> {
        fn get_counter(self: @ContractState) -> u128 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState, amount: u128) {
            // now is_owner comes from OwnableInternalImpl
            if self.ownable.is_owner(get_caller_address()) {
                let current = self.counter.read();
                self.counter.write(current + amount);
                self.emit(CounterIncreased { amount });
            }
        }

        fn decrease_counter(ref self: ContractState, amount: u128) {
            // now is_owner comes from OwnableInternalImpl
            if self.ownable.is_owner(get_caller_address()) {
                let current = self.counter.read();
                self.counter.write(current - amount);
                self.emit(CounterDecreased { amount });
            }
        }
    }
}
