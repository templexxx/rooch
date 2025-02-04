#[test_only]
/// This test module is used to test the coin logic in coin and account module.
module rooch_framework::coin_test{
    use std::signer;
    use std::string;
    use moveos_std::account_storage;
    use moveos_std::storage_context::{Self, StorageContext};
    use rooch_framework::account;
    use rooch_framework::coin;
    use rooch_framework::coin::{BurnCapability, FreezeCapability, MintCapability, mint, initialize,
        supply, name, symbol, decimals, balance, value, burn, freeze_coin_store, unfreeze_coin_store,
        is_coin_store_frozen, burn_from, zero, destroy_zero, is_coin_initialized, extract, deposit, transfer, withdraw,
        is_account_accept_coin, do_accept_coin, set_auto_accept_coin
    };

    #[test_only]
    struct FakeCoin {}

    #[test_only]
    struct FakeCoinCapabilities has key {
        burn_cap: BurnCapability<FakeCoin>,
        freeze_cap: FreezeCapability<FakeCoin>,
        mint_cap: MintCapability<FakeCoin>,
    }

    #[test_only]
    fun initialize_fake_coin(
        ctx: &mut StorageContext,
        account: &signer,
        decimals: u8,
    ): (BurnCapability<FakeCoin>, FreezeCapability<FakeCoin>, MintCapability<FakeCoin>) {
        coin::init_for_test(ctx);
        coin::initialize<FakeCoin>(
            ctx,
            account,
            string::utf8(b"Fake coin"),
            string::utf8(b"FCD"),
            decimals,
        )
    }

    #[test_only]
    fun initialize_and_init_coin_store(
        ctx: &mut StorageContext,
        account: &signer,
        decimals: u8,
    ): (BurnCapability<FakeCoin>, FreezeCapability<FakeCoin>, MintCapability<FakeCoin>) {
        let (burn_cap, freeze_cap, mint_cap) = initialize_fake_coin(
            ctx,
            account,
            decimals,
        );
        account::init_account_for_test(ctx, account);
        (burn_cap, freeze_cap, mint_cap)
    }

    #[test_only]
    fun create_fake_coin(
        source: &signer,
        destination: &signer,
        amount: u256
    ) {
        let source_ctx = storage_context::new_test_context(signer::address_of(source));
        let destination_ctx = storage_context::new_test_context_random(signer::address_of(destination), b"test_tx1");

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, source, 9);

        let coins_minted = mint<FakeCoin>(&mut source_ctx, amount, &mint_cap);
        deposit(&mut source_ctx, signer::address_of(source), coins_minted);
        account_storage::global_move_to(&mut source_ctx, source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
        moveos_std::storage_context::drop_test_context(destination_ctx);
    }

    #[test(source = @rooch_framework, destination = @0x55)]
    fun test_end_to_end(
        source: signer,
        destination: signer,
    ) {
        let source_addr = signer::address_of(&source);
        let destination_addr = signer::address_of(&destination);
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));
        let destination_ctx = storage_context::new_test_context_random(signer::address_of(&destination), b"test_tx1");

        let name = string::utf8(b"Fake coin");
        let symbol = string::utf8(b"FCD");
        let decimals = 9u8;

        coin::init_for_test(&mut source_ctx);
        let (burn_cap, freeze_cap, mint_cap) = initialize<FakeCoin>(
            &mut source_ctx,
            &source,
            name,
            symbol,
            decimals,
        );
        account::init_account_for_test(&mut source_ctx, &source);
        account::init_account_for_test(&mut destination_ctx, &destination);
        assert!(supply<FakeCoin>(&source_ctx) == 0, 0);

        assert!(name<FakeCoin>(&source_ctx) == name, 1);
        assert!(symbol<FakeCoin>(&source_ctx) == symbol, 2);
        assert!(decimals<FakeCoin>(&source_ctx) == decimals, 3);

        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);
        deposit(&mut source_ctx, source_addr, coins_minted);
        transfer<FakeCoin>(&mut source_ctx, &source, destination_addr, 50);

        assert!(balance<FakeCoin>(&source_ctx, source_addr) == 50, 4);
        assert!(balance<FakeCoin>(&destination_ctx, destination_addr) == 50, 5);
        assert!(supply<FakeCoin>(&source_ctx) == 100, 6);

        let coin = withdraw<FakeCoin>(&mut source_ctx, &source, 10);
        assert!(value(&coin) == 10, 7);
        burn(&mut source_ctx, coin, &burn_cap);
        assert!(supply<FakeCoin>(&source_ctx, ) == 90, 8);
        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
        moveos_std::storage_context::drop_test_context(destination_ctx);
    }

    #[test(source = @rooch_framework, destination = @0x55)]
    fun test_end_to_end_no_supply(
        source: signer,
        destination: signer,
    ) {
        let source_addr = signer::address_of(&source);
        let destination_addr = signer::address_of(&destination);
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));
        let destination_ctx = storage_context::new_test_context_random(signer::address_of(&destination), b"test_tx1");

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, &source, 9);

        account::init_account_for_test(&mut destination_ctx, &destination);
        assert!(supply<FakeCoin>(&source_ctx) == 0, 0);

        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);
        deposit<FakeCoin>(&mut source_ctx, source_addr, coins_minted);
        transfer<FakeCoin>(&mut source_ctx, &source, destination_addr, 50);

        assert!(balance<FakeCoin>(&source_ctx, source_addr) == 50, 1);
        assert!(balance<FakeCoin>(&destination_ctx, destination_addr) == 50, 2);
        assert!(supply<FakeCoin>(&source_ctx) > 0, 3);

        let coin = withdraw<FakeCoin>(&mut source_ctx, &source, 10);
        burn(&mut source_ctx, coin, &burn_cap);
        assert!(supply<FakeCoin>(&source_ctx) > 0, 4);

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
        moveos_std::storage_context::drop_test_context(destination_ctx);
    }

    #[test(source = @0x55, framework = @rooch_framework)]
    #[expected_failure(abort_code = 65537, location = rooch_framework::coin)]
    public fun fail_initialize(source: signer, framework: signer) {
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));
        let framework_ctx = storage_context::new_test_context_random(signer::address_of(&framework), b"test_tx1");

        // coin::init_for_test(&mut source_ctx, &source);
        let (burn_cap, freeze_cap, mint_cap) = initialize<FakeCoin>(
            &mut source_ctx,
            &source,
            string::utf8(b"Fake coin"),
            string::utf8(b"FCD"),
            9,
        );

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
        moveos_std::storage_context::drop_test_context(framework_ctx);
    }

    #[test(source = @rooch_framework, destination = @0x55)]
    #[expected_failure(abort_code = 393218, location = moveos_std::raw_table)]
    fun test_fail_transfer(
        source: signer,
        destination: signer,
    ) {
        let source_addr = signer::address_of(&source);
        let destination_addr = signer::address_of(&destination);
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));
        let destination_ctx = storage_context::new_test_context_random(signer::address_of(&destination), b"test_tx1");

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, &source, 9);
        assert!(supply<FakeCoin>(&source_ctx) == 0, 0);

        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);
        deposit(&mut source_ctx, source_addr, coins_minted);
        transfer<FakeCoin>(&mut source_ctx, &source, destination_addr, 50);

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
        moveos_std::storage_context::drop_test_context(destination_ctx);
    }

    #[test(source = @rooch_framework)]
    fun test_burn_from_with_capability(
        source: signer,
    ) {
        let source_addr = signer::address_of(&source);
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, &source, 9);

        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);
        deposit(&mut source_ctx, source_addr, coins_minted);
        assert!(balance<FakeCoin>(&source_ctx, source_addr) == 100, 0);
        assert!(supply<FakeCoin>(&source_ctx) == 100, 1);

        burn_from<FakeCoin>(&mut source_ctx, source_addr, 10, &burn_cap);
        assert!(balance<FakeCoin>(&source_ctx, source_addr) == 90, 2);
        assert!(supply<FakeCoin>(&source_ctx) == 90, 3);

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
    }

    #[test(source = @rooch_framework)]
    #[expected_failure(abort_code = 65540, location = rooch_framework::coin)]
    public fun test_destroy_non_zero(
        source: signer,
    ) {
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, &source, 9);
        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);
        destroy_zero(coins_minted);

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
    }


    #[test(source = @rooch_framework)]
    fun test_test_extract(
        source: signer,
    ) {
        let source_addr = signer::address_of(&source);
        let source_ctx = storage_context::new_test_context(signer::address_of(&source));
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut source_ctx, &source, 9);
        let coins_minted = mint<FakeCoin>(&mut source_ctx, 100, &mint_cap);

        let extracted = extract(&mut coins_minted, 25);
        assert!(value(&coins_minted) == 75, 0);
        assert!(value(&extracted) == 25, 1);

        deposit(&mut source_ctx, source_addr, coins_minted);
        deposit(&mut source_ctx, source_addr, extracted);

        assert!(balance<FakeCoin>(&source_ctx, source_addr) == 100, 2);

        account_storage::global_move_to(&mut source_ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(source_ctx);
    }


    #[test(source = @rooch_framework)]
    public fun test_is_coin_initialized(source: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&source));
        assert!(!is_coin_initialized<FakeCoin>(&ctx), 0);

        let (burn_cap, freeze_cap, mint_cap) = initialize_fake_coin(&mut ctx, &source, 9);
        assert!(is_coin_initialized<FakeCoin>(&ctx), 1);

        account_storage::global_move_to(&mut ctx, &source, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test(account = @rooch_framework)]
    public fun test_is_coin_store_frozen(account: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&account));
        let addr = signer::address_of(&account);
        // An non do_accept_coined account is has a frozen coin store by default
        assert!(!is_coin_store_frozen<FakeCoin>(&ctx, addr), 1);

        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &account, 9);

        assert!(!is_coin_store_frozen<FakeCoin>(&ctx, addr), 1);
        // freeze account
        freeze_coin_store(&mut ctx, addr, &freeze_cap);
        assert!(is_coin_store_frozen<FakeCoin>(&ctx, addr), 1);

        // unfreeze account
        unfreeze_coin_store(&mut ctx, addr, &freeze_cap);
        assert!(!is_coin_store_frozen<FakeCoin>(&ctx, addr), 1);

        account_storage::global_move_to(&mut ctx, &account, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test]
    fun test_zero() {
        let zero = zero<FakeCoin>();
        assert!(value(&zero) == 0, 1);
        destroy_zero(zero);
    }

    #[test(account = @rooch_framework)]
    fun test_burn_frozen(account: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&account));
        let account_addr = signer::address_of(&account);
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &account, 9);

        let coins_minted = mint<FakeCoin>(&mut ctx, 100, &mint_cap);
        deposit(&mut ctx, account_addr, coins_minted);

        freeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        burn_from(&mut ctx, account_addr, 100, &burn_cap);

        account_storage::global_move_to(&mut ctx, &account, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test(account = @rooch_framework)]
    #[expected_failure(abort_code = 327688, location = rooch_framework::coin)]
    fun test_withdraw_frozen(account: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&account));
        let account_addr = signer::address_of(&account);
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &account, 9);

        freeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        let coin = withdraw<FakeCoin>(&mut ctx, &account, 10);
        burn(&mut ctx, coin, &burn_cap);

        account_storage::global_move_to(&mut ctx, &account, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test(account = @rooch_framework)]
    #[expected_failure(abort_code = 327688, location = rooch_framework::coin)]
    fun test_deposit_frozen(account: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&account));
        let account_addr = signer::address_of(&account);
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &account, 9);

        let coins_minted = mint<FakeCoin>(&mut ctx, 100, &mint_cap);
        freeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        deposit(&mut ctx, account_addr, coins_minted);

        account_storage::global_move_to(&mut ctx, &account, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test(account = @rooch_framework)]
    fun test_deposit_widthdraw_unfrozen(account: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&account));
        let account_addr = signer::address_of(&account);
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &account, 9);

        let coins_minted = mint<FakeCoin>(&mut ctx, 100, &mint_cap);
        freeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        unfreeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        deposit(&mut ctx, account_addr, coins_minted);

        freeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        unfreeze_coin_store(&mut ctx, account_addr, &freeze_cap);
        let coin = withdraw<FakeCoin>(&mut ctx, &account, 10);
        burn(&mut ctx, coin, &burn_cap);

        account_storage::global_move_to(&mut ctx, &account, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }


    #[test(framework = @rooch_framework)]
    fun test_accept_twice_should_not_fail(framework: signer) {
        let ctx = storage_context::new_test_context(signer::address_of(&framework));
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &framework, 9);

        // Registering twice should not fail.
        do_accept_coin<FakeCoin>(&mut ctx, &framework);
        do_accept_coin<FakeCoin>(&mut ctx, &framework);
        assert!(is_account_accept_coin<FakeCoin>(&ctx, @rooch_framework), 1);

        account_storage::global_move_to(&mut ctx, &framework, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
    }

    #[test(framework = @rooch_framework, source1 = @0x33, source2 = @0x66)]
    #[expected_failure(abort_code = 393225, location = rooch_framework::coin)]
    fun test_deposit_coin_after_turnoff_auto_accept_coin_flag_should_fail(framework: signer, source1: signer, source2: signer,) {
        let ctx = storage_context::new_test_context(signer::address_of(&framework));

        let source1_addr = signer::address_of(&source1);
        let source2_addr = signer::address_of(&source2);
        let source1_ctx = storage_context::new_test_context_random(source1_addr, b"test_tx2");
        let source2_ctx = storage_context::new_test_context_random(source2_addr, b"test_tx3");
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &framework, 9);

        let mint_coins1 = mint(&mut ctx, 10, &mint_cap);
        let mint_coins2 = mint(&mut ctx, 20, &mint_cap);

        account::init_account_for_test(&mut source1_ctx, &source1);
        account::init_account_for_test(&mut source2_ctx, &source2);

        // source1 default deposit should succ
        deposit(&mut source1_ctx, source1_addr, mint_coins1);

        // source2 turnoff auto accept coin flag, deposit should fail
        set_auto_accept_coin(&mut source2_ctx, &source2, false);
        deposit(&mut source2_ctx, source2_addr, mint_coins2);

        account_storage::global_move_to(&mut ctx, &framework, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
        moveos_std::storage_context::drop_test_context(source1_ctx);
        moveos_std::storage_context::drop_test_context(source2_ctx);
    }

    #[test(framework = @rooch_framework, source1 = @0x33, source2 = @0x66)]
    fun test_deposit_coin_after_turnoff_auto_accept_coin_flag_and_accept_coin_should_succ(framework: signer, source1: signer, source2: signer,) {
        let ctx = storage_context::new_test_context(signer::address_of(&framework));

        let source1_addr = signer::address_of(&source1);
        let source2_addr = signer::address_of(&source2);
        let source1_ctx = storage_context::new_test_context_random(source1_addr, b"test_tx2");
        let source2_ctx = storage_context::new_test_context_random(source2_addr, b"test_tx3");
        let (burn_cap, freeze_cap, mint_cap) = initialize_and_init_coin_store(&mut ctx, &framework, 9);

        let mint_coins1 = mint(&mut ctx, 10, &mint_cap);
        let mint_coins2 = mint(&mut ctx, 20, &mint_cap);

        account::init_account_for_test(&mut source1_ctx, &source1);
        account::init_account_for_test(&mut source2_ctx, &source2);

        // source1 default deposit should succ
        deposit(&mut source1_ctx, source1_addr, mint_coins1);

        // source2 turnoff auto accept coin flag, deposit should fail
        set_auto_accept_coin(&mut source2_ctx, &source2, false);

        // source2 accept coin, deposit should succ
        do_accept_coin<FakeCoin>(&mut source2_ctx, &source2);
        deposit(&mut source2_ctx, source2_addr, mint_coins2);

        account_storage::global_move_to(&mut ctx, &framework, FakeCoinCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        moveos_std::storage_context::drop_test_context(ctx);
        moveos_std::storage_context::drop_test_context(source1_ctx);
        moveos_std::storage_context::drop_test_context(source2_ctx);
    }
}