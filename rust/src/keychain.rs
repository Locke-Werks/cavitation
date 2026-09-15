//! Keystore setup for Windows.
//!
//! rustpush keeps its key material behind a global `Keystore`, and reaching it
//! before one is installed panics with "GLOBAL not initialized" rather than
//! returning an error. Sign-in touches the keychain immediately, so with no
//! keystore the app died the instant the button was pressed.
//!
//! Upstream's `setup_keystore` expects a `NativeKeystore`: the Android Keystore
//! or the Secure Enclave. There is no such thing here, so this uses the pure
//! software path the keystore crate already ships.
//!
//! (`src/keystore.rs` in this tree is the Flutter-era binding layer for those
//! mobile backends. It is not compiled: it depends on uniffi, which is not a
//! dependency of this crate.)

use std::path::Path;
use std::sync::RwLock;

use anyhow::{Context, Result};
use keystore::init_keystore;
use keystore::software::{SoftwareEncryptor, SoftwareKeystore, SoftwareKeystoreState};
use log::error;

/// Installs the process-wide keystore. Safe to call more than once: the
/// underlying set is a OnceLock, so a second call is a no-op rather than a
/// panic or a swap.
pub fn init(data_dir: &Path) -> Result<()> {
    let state_path = data_dir.join("keystore_s.plist");
    let key_path = data_dir.join("keystore.key");

    // The wrapping key has to outlive the process or everything sealed with it
    // is unreadable on the next launch.
    let key: [u8; 32] = match std::fs::read(&key_path) {
        Ok(bytes) if bytes.len() == 32 => bytes.as_slice().try_into().expect("length checked"),
        _ => {
            let fresh: [u8; 32] = rand::random();
            std::fs::write(&key_path, fresh)
                .with_context(|| format!("writing {}", key_path.display()))?;
            fresh
        }
    };

    let state: SoftwareKeystoreState = plist::from_file(&state_path).unwrap_or_default();
    let save_to = state_path;

    init_keystore(SoftwareKeystore {
        state: RwLock::new(state),
        update_state: Box::new(move |s| {
            // Losing a write here costs the next launch its cached keys, which
            // means re-registering, not losing the account.
            if let Err(e) = plist::to_file_xml(&save_to, s) {
                error!("persisting keystore: {e}");
            }
        }),
        encryptor: SoftwareEncryptor(key),
    });

    Ok(())
}
