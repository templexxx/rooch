/// Module which defines hash functions. Note that Sha-256 and Sha3-256 is available in the std::hash module in the
/// standard library.
/// Conflict with the standard library, change the name for hash
module rooch_framework::rooch_hash {
   /// @param data: Arbitrary binary data to hash
   /// Hash the input bytes using Blake2b-256 and returns 32 bytes.
   native public fun blake2b256(data: &vector<u8>): vector<u8>;

   /// @param data: Arbitrary binary data to hash
   /// Hash the input bytes using keccak256 and returns 32 bytes.
   native public fun keccak256(data: &vector<u8>): vector<u8>;

   #[test]
   fun test_keccak256_hash() {
      let msg = b"hello world!";
      let hashed_msg_bytes = x"57caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd6";
      let hashed_msg = keccak256(&msg);
      assert!(hashed_msg == hashed_msg_bytes, 0);

      let empty_msg = b"";
      let _ = keccak256(&empty_msg);
      let long_msg = b"57caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd6";
      let _ = keccak256(&long_msg);
   }

   #[test]
   fun test_blake2b256_hash() {
      let msg = b"hello world!";
      let hashed_msg_bytes = x"4fccfb4d98d069558aa93e9565f997d81c33b080364efd586e77a433ddffc5e2";
      let hashed_msg = blake2b256(&msg);
      assert!(hashed_msg == hashed_msg_bytes, 0);

      let empty_msg = b"";
      let _ = blake2b256(&empty_msg);
      let long_msg = b"57caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd657caa176af1ac0433c5df30e8dabcd2ec1af1e92a26eced5f719b88458777cd6";
      let _ = blake2b256(&long_msg);
   }
}