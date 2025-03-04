use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::tests_lib::{setup, teardown};
use satoru::utils::span32::{Span32, Array32Trait};

use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

#[test]
fn given_normal_conditions_when_set_order_new_and_override_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    // Test logic

    // Test set_order function with a new key.
    data_store.set_order(key, order);

    let order_by_key = data_store.get_order(key).unwrap();
    assert(order_by_key == order, 'Invalid order by key');

    let order_count = data_store.get_order_count();
    assert(order_count == 1, 'Invalid key order count');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 1, 'Invalid account order count');

    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 1, 'Acc order # should be 1');

    // Update the order using the set_order function and then retrieve it to check the update was successful
    let receiver = 'receiver'.try_into().unwrap();
    order.receiver = receiver;
    data_store.set_order(key, order);

    let order_by_key = data_store.get_order(key).unwrap();
    assert(order_by_key == order, 'Invalid order by key');
    assert(order_by_key.receiver == receiver, 'Invalid order value');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 1, 'Invalid account withdrawl count');

    let order_count = data_store.get_order_count();
    assert(order_count == 1, 'Invalid key order count');

    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 1, 'Acc order # should be 1');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('order account cant be 0',))]
fn given_order_account_0_when_set_order_then_fails() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = contract_address_const::<0>();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    // Test logic

    // Test set_order function with account 0
    data_store.set_order(key, order);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_set_order_then_fails() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    // Test logic

    // Test set_order function without permission
    data_store.set_order(key, order);

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_get_order_keys_then_fails() {
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    data_store.set_order(key, order);

    // Given
    data_store.remove_order(key, account);

    // Then
    let order_by_key = data_store.get_order(key);
    assert(order_by_key.is_none(), 'order should be removed');

    let order_count = data_store.get_order_count();
    assert(order_count == 0, 'Invalid key order count');
    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 0, 'Acc order # should be 0');
    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_remove_only_order_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    data_store.set_order(key, order);

    // Given
    data_store.remove_order(key, account);

    // Then
    let order_by_key = data_store.get_order(key);
    assert(order_by_key.is_none(), 'order should be removed');

    let order_count = data_store.get_order_count();
    assert(order_count == 0, 'Invalid key order count');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 0, 'Acc order # should be 0');

    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_remove_1_of_n_order_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order_1: Order = create_new_order(
        key_1,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    let key_2: felt252 = 22222222222;

    let mut order_2: Order = create_new_order(
        key_2,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    data_store.set_order(key_1, order_1);
    data_store.set_order(key_2, order_2);

    let order_count = data_store.get_order_count();
    assert(order_count == 2, 'Invalid key order count');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 2, 'Acc order # should be 2');
    // Given
    data_store.remove_order(key_1, account);

    // Then
    let order_1_by_key = data_store.get_order(key_1);
    assert(order_1_by_key.is_none(), 'order1 shouldnt be removed');

    let order_2_by_key = data_store.get_order(key_2);
    assert(order_2_by_key.is_some(), 'order2 shouldnt be removed');

    let order_count = data_store.get_order_count();
    assert(order_count == 1, 'order # should be 1');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 1, 'Acc order # should be 1');

    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 1, 'Acc withdraw # not 1');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_remove_order_then_fails() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order: Order = create_new_order(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    data_store.set_order(key, order);

    // Given
    data_store.remove_order(key, account);

    // Then
    let order_by_key = data_store.get_order(key);
    assert(order_by_key.is_none(), 'order should be removed');
    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 0, 'Acc order # should be 0');
    let account_order_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_order_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_multiple_account_keys_then_works() {
    // Setup

    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut order_1: Order = create_new_order(
        key_1,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    let key_2: felt252 = 22222222222;
    let account_2 = 'account2222'.try_into().unwrap();
    let mut order_2: Order = create_new_order(
        key_2,
        account_2,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 2
    );
    let key_3: felt252 = 3333344455667;
    let mut order_3: Order = create_new_order(
        key_3,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );
    let key_4: felt252 = 444445556777889;
    let mut order_4: Order = create_new_order(
        key_4,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        is_frozen: false,
        order_no: 1
    );

    data_store.set_order(key_1, order_1);
    data_store.set_order(key_2, order_2);
    data_store.set_order(key_3, order_3);
    data_store.set_order(key_4, order_4);

    let order_by_key3 = data_store.get_order(key_3).unwrap();
    assert(order_by_key3 == order_3, 'Invalid order by key3');

    let order_by_key4 = data_store.get_order(key_4).unwrap();
    assert(order_by_key4 == order_4, 'Invalid order by key4');

    let order_count = data_store.get_order_count();
    assert(order_count == 4, 'Invalid key order count');

    let account_order_count = data_store.get_account_order_count(account);
    assert(account_order_count == 3, 'Acc order # should be 3');

    let account_order_count2 = data_store.get_account_order_count(account_2);
    assert(account_order_count2 == 1, 'Acc2 order # should be 1');

    let order_keys = data_store.get_order_keys(0, 10);
    assert(order_keys.len() == 4, 'invalid key len');
    assert(order_keys.at(0) == @key_1, 'invalid key1');
    assert(order_keys.at(1) == @key_2, 'invalid key2');
    assert(order_keys.at(2) == @key_3, 'invalid key3');
    assert(order_keys.at(3) == @key_4, 'invalid key4');

    let order_keys2 = data_store.get_order_keys(1, 3);
    assert(order_keys2.len() == 2, '2:invalid key len');
    assert(order_keys2.at(0) == @key_2, '2:invalid key2');
    assert(order_keys2.at(1) == @key_3, '2:invalid key3');

    let account_keys = data_store.get_account_order_keys(account, 0, 10);
    assert(account_keys.len() == 3, '3:invalid key len');
    assert(account_keys.at(0) == @key_1, '3:invalid key1');
    assert(account_keys.at(1) == @key_3, '3:invalid key3');
    assert(account_keys.at(2) == @key_4, '3:invalid key4');

    let account_keys2 = data_store.get_account_order_keys(account_2, 0, 10);
    assert(account_keys2.len() == 1, '4:invalid key len');
    assert(account_keys2.at(0) == @key_2, '4:invalid key2');

    // Given
    data_store.remove_order(key_1, account);

    teardown(data_store.contract_address);
}

/// Utility function to create new Order  struct
///
/// # Arguments
///
/// * `account` - The account of the order.
/// * `receiver` - The receiver for any token transfers.
/// * `market` - The trading market.
/// * `initial_collateral_token` - The initial collateral token for increase orders.
/// * `is_long` - Whether the order is for a long or short.
/// * `is_frozen` - Whether the order is frozen.
/// * `order_no` - Random number to change values
fn create_new_order(
    key: felt252,
    account: ContractAddress,
    receiver: ContractAddress,
    market: ContractAddress,
    initial_collateral_token: ContractAddress,
    is_long: bool,
    is_frozen: bool,
    order_no: u128
) -> Order {
    let order_type = OrderType::StopLossDecrease;
    let decrease_position_swap_type = DecreasePositionSwapType::NoSwap(());
    let callback_contract = contract_address_const::<'callback_contract'>();
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();
    let swap_path: Span32<ContractAddress> = array![
        contract_address_const::<'swap_path_0'>(), contract_address_const::<'swap_path_1'>()
    ]
        .span32();
    let size_delta_usd = 1000 * order_no;
    let initial_collateral_delta_amount = 1000 * order_no;
    let trigger_price = 11111 * order_no;
    let acceptable_price = 11111 * order_no;
    let execution_fee: u128 = 10 * order_no.into();
    let min_output_amount = 10 * order_no;
    let updated_at_block = 1;

    let callback_gas_limit = 300000;

    // Create an order.
    Order {
        key,
        order_type,
        decrease_position_swap_type,
        account,
        receiver,
        callback_contract,
        ui_fee_receiver,
        market,
        initial_collateral_token,
        swap_path,
        size_delta_usd,
        initial_collateral_delta_amount,
        trigger_price,
        acceptable_price,
        execution_fee,
        callback_gas_limit,
        min_output_amount,
        updated_at_block,
        is_long,
        is_frozen,
    }
}
