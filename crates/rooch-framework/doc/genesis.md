
<a name="0x3_genesis"></a>

# Module `0x3::genesis`



-  [Struct `GenesisContext`](#0x3_genesis_GenesisContext)
-  [Constants](#@Constants_0)


<pre><code><b>use</b> <a href="../../moveos/moveos-stdlib/move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../moveos/moveos-stdlib/move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="../../moveos/moveos-stdlib/move-stdlib/doc/signer.md#0x2_signer">0x2::signer</a>;
<b>use</b> <a href="../../moveos/moveos-stdlib/moveos-stdlib/doc/storage_context.md#0x2_storage_context">0x2::storage_context</a>;
<b>use</b> <a href="auth_validator_registry.md#0x3_auth_validator_registry">0x3::auth_validator_registry</a>;
<b>use</b> <a href="builtin_validators.md#0x3_builtin_validators">0x3::builtin_validators</a>;
<b>use</b> <a href="chain_id.md#0x3_chain_id">0x3::chain_id</a>;
</code></pre>



<a name="0x3_genesis_GenesisContext"></a>

## Struct `GenesisContext`

GenesisContext is a genesis init parameters in the TxContext.


<pre><code><b>struct</b> <a href="genesis.md#0x3_genesis_GenesisContext">GenesisContext</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="chain_id.md#0x3_chain_id">chain_id</a>: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x3_genesis_ErrorGenesisInit"></a>



<pre><code><b>const</b> <a href="genesis.md#0x3_genesis_ErrorGenesisInit">ErrorGenesisInit</a>: u64 = 1;
</code></pre>
