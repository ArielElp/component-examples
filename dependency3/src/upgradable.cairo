use starknet::ClassHash;

#[starknet::interface]
trait IUpgradable<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

#[starknet::component]
mod upgradable {
    use starknet::{ClassHash, get_caller_address};
    use starknet::syscalls::replace_class_syscall;
    use dependency3::ownable::ownable as ownable_component;

    use ownable_component::OwnableInternalImpl;

    // this (or something similar) will potentially be generated in the next RC
    #[generate_trait]
    impl GetOwnable<
        TContractState,
        +HasComponent<TContractState>,
        +ownable_component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetOwnableTrait<TContractState> {
        fn get_ownable(
            self: @ComponentState<TContractState>
        ) -> @ownable_component::ComponentState<TContractState> {
            let contract = self.get_contract();
            ownable_component::HasComponent::<TContractState>::get_component(contract)
        }

        fn get_ownable_mut(
            ref self: ComponentState<TContractState>
        ) -> ownable_component::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            ownable_component::HasComponent::<TContractState>::get_component_mut(ref contract)
        }
    }

    #[storage]
    struct Storage {
        current_implementation: ClassHash
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ContractUpgraded: ContractUpgraded
    }

    #[derive(Drop, starknet::Event)]
    struct ContractUpgraded {
        old_class_hash: ClassHash,
        new_class_hash: ClassHash
    }

    #[embeddable_as(UpgradableImpl)]
    impl Upgradable<
        TContractState,
        +HasComponent<TContractState>,
        +ownable_component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of super::IUpgradable<ComponentState<TContractState>> {
        fn upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            if self.get_ownable_mut().is_owner(get_caller_address()) {
                replace_class_syscall(new_class_hash).unwrap();
                let old_class_hash = self.current_implementation.read();
                self.emit(ContractUpgraded { old_class_hash, new_class_hash });
                self.current_implementation.write(new_class_hash);
            }
        }
    }
}