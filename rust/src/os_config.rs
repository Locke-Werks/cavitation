use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::{anyhow, Context, Result};
use prost::Message as _;
use rand::Rng;
use rustpush::macos::{HardwareConfig, MacOSConfig};
use rustpush::{OSConfig, RelayConfig};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub const DEFAULT_RELAY_HOST: &str = "https://hw.openbubbles.app";

/// Activation codes from Mac Hardware Info come in two shapes, and they are
/// not interchangeable.
///
/// With "prevent sharing" left off, the code IS the hardware payload:
/// base64("OABS" + 0x00 + protobuf HwInfo). Everything needed to register is
/// in those bytes, validation data is computed locally against Apple's own
/// endpoints, and no third party is involved at all.
///
/// With it switched on, the payload stays on the Mac and the code is a
/// reference that only means something to a broker holding a reservation for
/// that device.
///
/// Sending the first kind to a broker gets "Device not reserved!", which is
/// the server correctly refusing a code that was never addressed to it.
const LOCAL_CODE_MAGIC: &[u8] = b"OABS";

fn generate_udid() -> String {
    let bytes: [u8; 32] = rand::thread_rng().gen();
    bytes.iter().fold(String::with_capacity(64), |mut s, b| {
        use std::fmt::Write;
        let _ = write!(&mut s, "{:02X}", b);
        s
    })
}

/// Either way of describing this device to Apple.
///
/// The local variant deliberately stores the activation code rather than the
/// decoded MacOSConfig. HardwareConfig's binary fields carry serde helpers
/// written for plist, and their visitor rejects the number arrays serde_json
/// produces, so a decoded config writes to JSON cleanly and then fails to load
/// back. The code is a short base64 string that survives the round trip, and
/// decoding it again costs a 410-byte protobuf parse.
#[derive(Serialize, Deserialize, Clone)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum DeviceConfig {
    /// Hardware identity carried in the code. No broker.
    Local { code: String, label: String },
    /// Hardware identity held by a broker, fetched per registration.
    Relay(Box<RelayConfig>),
}

impl DeviceConfig {
    pub fn as_os_config(&self) -> Result<Arc<dyn OSConfig>> {
        match self {
            DeviceConfig::Local { code, .. } => {
                let parsed = parse_local_code(code)?
                    .ok_or_else(|| anyhow!("stored activation code is no longer readable"))?;
                Ok(Arc::new(parsed))
            }
            DeviceConfig::Relay(c) => Ok(Arc::new((**c).clone())),
        }
    }

    pub fn summary(&self) -> String {
        match self {
            DeviceConfig::Local { label, .. } => label.clone(),
            DeviceConfig::Relay(c) => format!(
                "relay {} code={}… udid={} proto={}",
                c.host,
                c.code.chars().take(8).collect::<String>(),
                c.udid.as_deref().unwrap_or(""),
                c.protocol_version
            ),
        }
    }

    pub fn is_local(&self) -> bool {
        matches!(self, DeviceConfig::Local { .. })
    }
}

fn describe(cfg: &MacOSConfig) -> String {
    format!(
        "local {} ({}) build {}",
        cfg.inner.product_name, cfg.version, cfg.inner.os_build_num
    )
}

/// Decodes a self-contained activation code, or returns None if this is not
/// one (in which case it belongs to a broker).
pub fn parse_local_code(code: &str) -> Result<Option<MacOSConfig>> {
    let trimmed = code.trim();
    let raw = match base64_decode(trimmed) {
        Some(b) => b,
        None => return Ok(None),
    };

    if raw.len() < LOCAL_CODE_MAGIC.len() + 1 || &raw[..LOCAL_CODE_MAGIC.len()] != LOCAL_CODE_MAGIC
    {
        return Ok(None);
    }

    // magic, then a zero byte, then the protobuf.
    let payload = &raw[LOCAL_CODE_MAGIC.len() + 1..];
    let hw = crate::bbhwinfo::HwInfo::decode(payload)
        .context("decoding the hardware info inside the activation code")?;

    let inner = hw
        .inner
        .ok_or_else(|| anyhow!("activation code has no hardware section"))?;

    let mac: [u8; 6] = inner.io_mac_address.as_slice().try_into().map_err(|_| {
        anyhow!(
            "activation code has a {}-byte MAC address, expected 6",
            inner.io_mac_address.len()
        )
    })?;

    Ok(Some(MacOSConfig {
        inner: HardwareConfig {
            product_name: inner.product_name,
            io_mac_address: mac,
            platform_serial_number: inner.platform_serial_number,
            platform_uuid: inner.platform_uuid,
            root_disk_uuid: inner.root_disk_uuid,
            board_id: inner.board_id,
            os_build_num: inner.os_build_num,
            platform_serial_number_enc: inner.platform_serial_number_enc,
            platform_uuid_enc: inner.platform_uuid_enc,
            root_disk_uuid_enc: inner.root_disk_uuid_enc,
            rom: inner.rom,
            rom_enc: inner.rom_enc,
            mlb: inner.mlb,
            mlb_enc: inner.mlb_enc,
        },
        version: hw.version,
        protocol_version: hw.protocol_version as u32,
        device_id: hw.device_id,
        icloud_ua: hw.icloud_ua,
        aoskit_version: hw.aoskit_version,
        udid: Some(generate_udid()),
    }))
}

fn base64_decode(s: &str) -> Option<Vec<u8>> {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.decode(s).ok()
}

/// Turns a pasted code into a usable device identity, taking the local route
/// when the code carries its own payload.
pub async fn pair(
    host: &str,
    code: &str,
    beeper_token: Option<String>,
) -> Result<DeviceConfig> {
    if let Some(local) = parse_local_code(code)? {
        return Ok(DeviceConfig::Local {
            label: describe(&local),
            code: code.trim().to_string(),
        });
    }

    let versions = RelayConfig::get_versions(host, code, &beeper_token)
        .await
        .with_context(|| format!("fetching version info from {host}"))?;

    Ok(DeviceConfig::Relay(Box::new(RelayConfig {
        version: versions,
        icloud_ua: "com.apple.iCloudHelper/282 CFNetwork/1408.0.4 Darwin/22.5.0".into(),
        aoskit_version: "com.apple.AOSKit/282 (com.apple.accountsd/113)".into(),
        dev_uuid: Uuid::new_v4().to_string(),
        protocol_version: 1660,
        host: host.to_string(),
        code: code.to_string(),
        beeper_token,
        udid: Some(generate_udid()),
    })))
}

pub fn config_path(data_dir: &Path) -> PathBuf {
    data_dir.join("os_config.json")
}

pub fn save(path: &Path, config: &DeviceConfig) -> Result<()> {
    let json = serde_json::to_string_pretty(config)?;
    std::fs::write(path, json).with_context(|| format!("writing {}", path.display()))?;
    Ok(())
}

pub fn load(path: &Path) -> Result<Option<DeviceConfig>> {
    if !path.exists() {
        return Ok(None);
    }
    let json = std::fs::read_to_string(path)?;
    Ok(Some(serde_json::from_str(&json)?))
}

pub fn clear(path: &Path) -> Result<()> {
    if path.exists() {
        std::fs::remove_file(path)?;
    }
    Ok(())
}
