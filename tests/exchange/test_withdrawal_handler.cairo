use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::exchange::withdrawal_handler::{
    IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait
};
use satoru::withdrawal::withdrawal_vault::{
    IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait
};
use satoru::fee::fee_handler::{IFeeHandlerDispatcher, IFeeHandlerDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::oracle::oracle_utils::{SetPricesParams, SimulatePricesParams};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::withdrawal::withdrawal_utils::CreateWithdrawalParams;
use satoru::withdrawal::withdrawal::Withdrawal;
use traits::Default;

// TODO: Add more tests after withdraw_utils implementation done.
#[test]
fn given_normal_conditions_when_create_withdrawal_then_works() {
    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();

    let account: ContractAddress = 0x123.try_into().unwrap();
    let receiver: ContractAddress = 0x234.try_into().unwrap();
    let ui_fee_receiver: ContractAddress = 0x345.try_into().unwrap();
    let market: ContractAddress = 0x456.try_into().unwrap();

    start_prank(withdrawal_handler.contract_address, caller_address);

    let params: CreateWithdrawalParams = CreateWithdrawalParams {
        receiver,
        callback_contract: receiver,
        ui_fee_receiver,
        market,
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        min_long_token_amount: Default::default(),
        min_short_token_amount: Default::default(),
        execution_fee: Default::default(),
        callback_gas_limit: Default::default(),
    };

    withdrawal_handler.create_withdrawal(account, params);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_create_withdrawal_then_fails() {
    // Should revert, call from anyone else then controller.
    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    let caller: ContractAddress = 0x847.try_into().unwrap();
    start_prank(withdrawal_handler.contract_address, caller);

    let params: CreateWithdrawalParams = CreateWithdrawalParams {
        receiver: 0x785.try_into().unwrap(),
        callback_contract: 0x786.try_into().unwrap(),
        ui_fee_receiver: 0x345.try_into().unwrap(),
        market: 0x346.try_into().unwrap(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        min_long_token_amount: Default::default(),
        min_short_token_amount: Default::default(),
        execution_fee: Default::default(),
        callback_gas_limit: Default::default(),
    };

    withdrawal_handler.create_withdrawal(caller, params);
}

#[test]
fn given_normal_conditions_when_cancel_withdrawal_then_works() {
    let withdrawal = Withdrawal {
        key: Default::default(),
        account: 0x785.try_into().unwrap(),
        receiver: 0x787.try_into().unwrap(),
        callback_contract: 0x348.try_into().unwrap(),
        ui_fee_receiver: 0x345.try_into().unwrap(),
        market: 0x346.try_into().unwrap(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: Default::default(),
        min_long_token_amount: Default::default(),
        min_short_token_amount: Default::default(),
        updated_at_block: Default::default(),
        execution_fee: Default::default(),
        callback_gas_limit: Default::default(),
    };

    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    start_prank(withdrawal_handler.contract_address, caller_address);

    let withdrawal_key = 'SAMPLE_WITHDRAW';
    data_store.set_withdrawal(withdrawal_key, withdrawal);

    // Key cleaning should be done in withdrawal_utils. We only check call here.
    withdrawal_handler.cancel_withdrawal(withdrawal_key);
}

#[test]
#[should_panic(expected: ('get_withdrawal failed',))]
fn given_unexisting_key_when_cancel_withdrawal_then_fails() {
    let withdrawal = Withdrawal {
        key: Default::default(),
        account: 0x785.try_into().unwrap(),
        receiver: 0x787.try_into().unwrap(),
        callback_contract: 0x348.try_into().unwrap(),
        ui_fee_receiver: 0x345.try_into().unwrap(),
        market: 0x346.try_into().unwrap(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: Default::default(),
        min_long_token_amount: Default::default(),
        min_short_token_amount: Default::default(),
        updated_at_block: Default::default(),
        execution_fee: Default::default(),
        callback_gas_limit: Default::default(),
    };

    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    start_prank(withdrawal_handler.contract_address, caller_address);

    let withdrawal_key = 'SAMPLE_WITHDRAW';

    // Key cleaning should be done in withdrawal_utils. We only check call here.
    withdrawal_handler.cancel_withdrawal(withdrawal_key);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_execute_withdrawal_then_fails() {
    let oracle_params = SetPricesParams {
        signer_info: Default::default(),
        tokens: Default::default(),
        compacted_min_oracle_block_numbers: Default::default(),
        compacted_max_oracle_block_numbers: Default::default(),
        compacted_oracle_timestamps: Default::default(),
        compacted_decimals: Default::default(),
        compacted_min_prices: Default::default(),
        compacted_min_prices_indexes: Default::default(),
        compacted_max_prices: Default::default(),
        compacted_max_prices_indexes: Default::default(),
        signatures: Default::default(),
        price_feed_tokens: Default::default(),
    };

    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();

    let withdrawal_key = 'SAMPLE_WITHDRAW';

    withdrawal_handler.execute_withdrawal(withdrawal_key, oracle_params);
}

// Panics due to the absence of a mocked withdrawal, resulting in Option::None being returned.
#[test]
#[should_panic(expected: ('invalid withdrawal key', 'SAMPLE_WITHDRAW'))]
fn given_invalid_withdrawal_key_when_execute_withdrawal_then_fails() {
    let oracle_params = SetPricesParams {
        signer_info: Default::default(),
        tokens: Default::default(),
        compacted_min_oracle_block_numbers: Default::default(),
        compacted_max_oracle_block_numbers: Default::default(),
        compacted_oracle_timestamps: Default::default(),
        compacted_decimals: Default::default(),
        compacted_min_prices: Default::default(),
        compacted_min_prices_indexes: Default::default(),
        compacted_max_prices: Default::default(),
        compacted_max_prices_indexes: Default::default(),
        signatures: Default::default(),
        price_feed_tokens: Default::default(),
    };

    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    let order_keeper = contract_address_const::<0x2233>();
    start_prank(withdrawal_handler.contract_address, order_keeper);

    let withdrawal_key = 'SAMPLE_WITHDRAW';

    withdrawal_handler.execute_withdrawal(withdrawal_key, oracle_params);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_simulate_execute_withdrawal_then_fails() {
    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    let caller: ContractAddress = contract_address_const::<0x847>();
    start_prank(withdrawal_handler.contract_address, caller);

    let oracle_params = SimulatePricesParams {
        primary_tokens: Default::default(), primary_prices: Default::default(),
    };

    let withdrawal_key = 'SAMPLE_WITHDRAW';

    withdrawal_handler.simulate_execute_withdrawal(withdrawal_key, oracle_params);
}

// Panics due to the absence of a mocked withdrawal, resulting in Option::None being returned.
#[test]
#[should_panic(expected: ('invalid withdrawal key', 'SAMPLE_WITHDRAW'))]
fn given_invalid_withdrawal_key_when_simulate_execute_withdrawal_then_fails() {
    let (caller_address, data_store, event_emitter, withdrawal_handler) = setup();
    let oracle_params = SimulatePricesParams {
        primary_tokens: Default::default(), primary_prices: Default::default(),
    };

    start_prank(withdrawal_handler.contract_address, caller_address);

    let withdrawal_key = 'SAMPLE_WITHDRAW';

    withdrawal_handler.simulate_execute_withdrawal(withdrawal_key, oracle_params);
}


fn deploy_withdrawal_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    withdrawal_vault_address: ContractAddress,
    oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('WithdrawalHandler');
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        withdrawal_vault_address.into(),
        oracle_address.into()
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_oracle(
    oracle_store_address: ContractAddress,
    role_store_address: ContractAddress,
    pragma_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let constructor_calldata = array![
        role_store_address.into(), oracle_store_address.into(), pragma_address.into()
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress
) -> ContractAddress {
    let contract = declare('OracleStore');
    let constructor_calldata = array![role_store_address.into(), event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_withdrawal_vault(strict_bank_address: ContractAddress) -> ContractAddress {
    let contract = declare('WithdrawalVault');
    let constructor_calldata = array![strict_bank_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_strict_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('StrictBank');
    let constructor_calldata = array![data_store_address.into(), role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

fn setup() -> (
    ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IWithdrawalHandlerDispatcher
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let order_keeper: ContractAddress = 0x2233.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let strict_bank_address = deploy_strict_bank(data_store_address, role_store_address);
    let withdrawal_vault_address = deploy_withdrawal_vault(strict_bank_address);
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(
        oracle_store_address, role_store_address, contract_address_const::<'pragma'>()
    );
    let withdrawal_handler_address = deploy_withdrawal_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        withdrawal_vault_address,
        oracle_address
    );

    let withdrawal_handler = IWithdrawalHandlerDispatcher {
        contract_address: withdrawal_handler_address
    };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(order_keeper, role::ORDER_KEEPER);
    role_store.grant_role(withdrawal_handler_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, data_store, event_emitter, withdrawal_handler)
}
