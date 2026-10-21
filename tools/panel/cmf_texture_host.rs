//! Bounded developer-only writer for one original cooked CMF block stream.
//! The copied, pinned w3edit library owns cache serialization.
use std::{env, fs, io::Write, path::PathBuf};
use std::os::windows::fs::MetadataExt;
use w3edit::{BundleFormat, TextureCache, TextureCacheEntry};

fn no_reparse(path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    for ancestor in path.ancestors() {
        match fs::symlink_metadata(ancestor) {
            Ok(meta) if meta.file_attributes() & 0x400 != 0 => return Err("reparse path refused".into()),
            Ok(_) => (),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => (),
            Err(e) => return Err(e.into()),
        }
    }
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<_> = env::args_os().collect();
    if args.len() != 4 { return Err("KIND COOKED_BC3 NEW_TEXTURE_CACHE".into()); }
    let kind = args[1].to_str().ok_or("non-UTF8 kind")?;
    let (name, width, height, expected) = match kind {
        "icon" => ("gameplay\\gui_new\\icons\\cmf_s03\\icon.png", 64u16, 64u16, 4096usize),
        "tile" => ("gameplay\\gui_new\\maps\\cmf_s03\\level0\\tile0x0.jpg", 1024u16, 1024u16, 1048576usize),
        _ => return Err("unqualified kind".into()),
    };
    let input = PathBuf::from(&args[2]);
    let output = PathBuf::from(&args[3]);
    no_reparse(&input)?; no_reparse(&output)?;
    let run = output.parent().ok_or("output parent")?.canonicalize()?;
    let root = run.ancestors().nth(2).ok_or("build root")?;
    if root.file_name().and_then(|s| s.to_str()) != Some("panel-runs") ||
       !run.to_string_lossy().contains("s03b-") || output.exists() ||
       input.parent().ok_or("input parent")?.canonicalize()? != run {
        return Err("input/output boundary or occupied target".into());
    }
    let cooked = fs::read(&input)?;
    if cooked.len() != expected { return Err("BC3 block-stream byte count".into()); }
    let hash = name.as_bytes().iter().fold(0u32, |h, b| h.wrapping_mul(31).wrapping_add(u32::from(*b)));
    let mut cache = TextureCache::for_format(BundleFormat::Remastered);
    cache.insert(std::ffi::CString::new(name)?, TextureCacheEntry {
        hash, base_width: width, base_height: height, mipcount: 1, slice_count: 1,
        base_alignment: 16, type1: 8, type2: 4, is_cube: 0, unk1: 0, time_stamp: 0,
        ..TextureCacheEntry::default()
    }, &[&cooked])?;
    let bytes = cache.write();
    let parsed = TextureCache::parse(&bytes)?;
    if parsed.version != 7 || parsed.entries.len() != 1 || parsed.entries[0].1.hash != hash {
        return Err("writer roundtrip differs".into());
    }
    fs::OpenOptions::new().write(true).create_new(true).open(&output)?.write_all(&bytes)?;
    println!("HOST_EMITTED kind={} width={} height={} stream={} cache={} hash={:08x}",
             kind, width, height, cooked.len(), bytes.len(), hash);
    Ok(())
}
