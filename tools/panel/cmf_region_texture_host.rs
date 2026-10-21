//! Bounded original CMF21-key regional fixture; pinned vendor cache serializer.
use std::{env, fs, io::Write, path::{Path, PathBuf}};
use std::os::windows::fs::MetadataExt;
use w3edit::{BundleFormat, TextureCache, TextureCacheEntry};

fn no_reparse(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    for ancestor in path.ancestors() {
        match fs::symlink_metadata(ancestor) {
            Ok(meta) if meta.file_attributes() & 0x400 != 0 => return Err("reparse path refused".into()),
            Ok(_) => (),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => (),
            Err(error) => return Err(error.into()),
        }
    }
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<_> = env::args_os().collect();
    if args.len() != 4 { return Err("ART_DIRECTORY MISSING_ROW_0_OR_6 NEW_CACHE".into()); }
    let art = PathBuf::from(&args[1]);
    let missing: usize = args[2].to_str().ok_or("ASCII missing row")?.parse()?;
    let output = PathBuf::from(&args[3]);
    no_reparse(&art)?; no_reparse(&output)?;
    let art = art.canonicalize()?;
    let run = art.parent().ok_or("run parent")?;
    if !matches!(missing, 0 | 6) || output.exists() ||
       !run.file_name().and_then(|s| s.to_str()).ok_or("run name")?.starts_with("s03e-b-assets-") ||
       run.parent().and_then(|p| p.file_name()).and_then(|s| s.to_str()) != Some("panel-runs") ||
       output.parent().ok_or("output parent")?.canonicalize()? != art {
        return Err("bounded regional output/run/variant".into());
    }
    let mut cache = TextureCache::for_format(BundleFormat::Remastered);
    let mut row = 0;
    for lod in 0..=2 {
        for y in 0..(1 << lod) {
            for x in 0..(1 << lod) {
                row += 1;
                if row == missing { continue; }
                let path = art.join(format!("level{lod}_tile{x}x{y}.bc3"));
                no_reparse(&path)?;
                let cooked = fs::read(path)?;
                if cooked.len() != 1048576 { return Err("1024-square BC3 stream length".into()); }
                let name = format!("gameplay\\gui_new\\maps\\cmf_s03e\\level{lod}\\tile{x}x{y}.jpg");
                let hash = name.as_bytes().iter().fold(0u32, |h,b| h.wrapping_mul(31).wrapping_add(u32::from(*b)));
                cache.insert(std::ffi::CString::new(name)?, TextureCacheEntry {
                    hash, base_width: 1024, base_height: 1024, mipcount: 1, slice_count: 1,
                    base_alignment: 16, type1: 8, type2: 4, is_cube: 0, unk1: 0, time_stamp: 0,
                    ..TextureCacheEntry::default()
                }, &[&cooked])?;
            }
        }
    }
    let bytes = cache.write();
    let parsed = TextureCache::parse(&bytes)?;
    let count = if missing == 0 { 21 } else { 20 };
    if parsed.version != 7 || parsed.entries.len() != count {
        return Err("regional writer roundtrip differs".into());
    }
    fs::OpenOptions::new().write(true).create_new(true).open(output)?.write_all(&bytes)?;
    println!("CMF_REGION_CACHE_EMITTED entries={count} bytes={}", bytes.len());
    Ok(())
}
