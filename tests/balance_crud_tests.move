#[test_only]
module belajar_sui_move::balance_crud_tests {
    use belajar_sui_move::balance_crud::{Self, Balance};
    use sui::test_scenario::{Self, Scenario};

    const ALICE: address = @0xA;

    // ── helper: create a Balance and return it ──────────────────
    fun create(scenario: &mut Scenario, name: vector<u8>, amount: u64): Balance {
        test_scenario::next_tx(scenario, ALICE);
        balance_crud::create_balance(name, amount, test_scenario::ctx(scenario));
        test_scenario::next_tx(scenario, ALICE);
        test_scenario::take_from_sender<Balance>(scenario)
    }

    #[test]
    fun test_create_balance() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let balance = create(&mut scenario, b"dompet-eth", 500);
            assert!(balance_crud::amount(&balance) == 500);
            assert!(balance_crud::name(&balance) == b"dompet-eth");
            test_scenario::return_to_sender(&scenario, balance);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_amount() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let mut balance = create(&mut scenario, b"tabungan", 100);
            balance_crud::add_amount(&mut balance, 50);
            assert!(balance_crud::amount(&balance) == 150);
            test_scenario::return_to_sender(&scenario, balance);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_subtract_amount() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let mut balance = create(&mut scenario, b"tabungan", 200);
            balance_crud::subtract_amount(&mut balance, 75);
            assert!(balance_crud::amount(&balance) == 125);
            test_scenario::return_to_sender(&scenario, balance);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0x1)] // EInsufficientBalance
    fun test_subtract_insufficient_fails() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let mut balance = create(&mut scenario, b"kecil", 10);
            balance_crud::subtract_amount(&mut balance, 100); // 💥 should abort
            test_scenario::return_to_sender(&scenario, balance);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_amount() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let mut balance = create(&mut scenario, b"flex", 42);
            balance_crud::set_amount(&mut balance, 999);
            assert!(balance_crud::amount(&balance) == 999);
            test_scenario::return_to_sender(&scenario, balance);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_delete_balance() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let balance = create(&mut scenario, b"burn-me", 1);
            balance_crud::delete_balance(balance);
            // object is gone — nothing to return
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_full_crud_flow() {
        let mut scenario = test_scenario::begin(ALICE);
        {
            let mut balance = create(&mut scenario, b"full", 0);
            assert!(balance_crud::amount(&balance) == 0);

            balance_crud::add_amount(&mut balance, 100);
            assert!(balance_crud::amount(&balance) == 100);

            balance_crud::subtract_amount(&mut balance, 40);
            assert!(balance_crud::amount(&balance) == 60);

            balance_crud::set_amount(&mut balance, 777);
            assert!(balance_crud::amount(&balance) == 777);

            balance_crud::delete_balance(balance);
        };
        test_scenario::end(scenario);
    }
}
