use starknet::ClassHash;

#[starknet::interface]
trait IUpgradable<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

#[starknet::component]
mod upgradable {
    use starknet::ClassHash;
    use starknet::syscalls::replace_class_syscall;

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
        TContractState, +HasComponent<TContractState>
    > of super::IUpgradable<ComponentState<TContractState>> {
        fn upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            replace_class_syscall(new_class_hash).unwrap();
            let old_class_hash = self.current_implementation.read();
            self.emit(ContractUpgraded { old_class_hash, new_class_hash });
            self.current_implementation.write(new_class_hash);
        }
    }
}
