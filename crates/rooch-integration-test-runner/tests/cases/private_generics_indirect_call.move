//# init --addresses creator=0x42

//# publish
module creator::test0 {
    struct KeyStruct has key {
        x: u64,
    }
}

//# publish
module creator::test {
    use std::string;
    use std::debug;
    use creator::test0::KeyStruct;
    use moveos_std::account_storage;
    use moveos_std::storage_context::{Self, StorageContext};
    use moveos_std::object;
    use moveos_std::object_id::ObjectID;
    use moveos_std::object_storage;

    struct Foo has key {
        x: u64,
    }

    #[private_generics(T1)]
    public fun publish_foo<T1>(ctx: &mut StorageContext, s: &signer) {
        account_storage::global_move_to<Foo>(ctx, s, Foo { x: 500 })
    }

    public fun run(ctx: &mut StorageContext, s: &signer) {
        let _ = string::utf8(b"account_storage");
        publish_foo<KeyStruct>(ctx, s)
    }

    public fun call_moveos_std<T:store>(ctx: &mut StorageContext, sender: &signer, object_id: ObjectID) {
        let object_storage = storage_context::object_storage_mut(ctx);
        debug::print(&object_id);
        let obj = object_storage::remove<KeyStruct>(object_storage, object_id);
        debug::print(&obj);
        let (_id,_owner,value) = object::unpack(obj);
        account_storage::global_move_to(ctx, sender, value);
    }
}
