use starknet::ContractAddress;

#[starknet::interface]
trait IOwnable<TContractState> {
    fn is_owner(self: @TContractState, address: ContractAddress) -> bool;
    fn change_owner(ref self: TContractState, new_owner: ContractAddress);
}

trait OwnableInternal<TContractState> {
    fn initialize_owner(
        ref self: ownable::ComponentState<TContractState>, new_owner: ContractAddress
    );
}

#[starknet::component]
mod ownable {
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner_address: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    impl OwnableInternalImpl<TContractState> of super::OwnableInternal<TContractState> {
        fn initialize_owner(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            self.owner_address.write(new_owner);
        }
    }

    #[embeddable_as(OwnableImpl)]
    impl Ownable<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        fn is_owner(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            address == self.owner_address.read()
        }

        fn change_owner(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            if get_caller_address() == self.owner_address.read() {
                self.owner_address.write(new_owner);
            }
        }
    }
}
