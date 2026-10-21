//! CMF-owned one-resource host; all serialization belongs to copied w3edit.
use std::{env, ffi::CString, fs, io::Write, path::{Path, PathBuf}};
use std::os::windows::fs::MetadataExt;
use w3edit::{Bundle, BundleItem, BundleFormat, BundleCompression, Metadata};
use w3edit::metadata::MetadataHash;

const DEPOT: &str = "gameplay\\gui_new\\swf\\worldmap\\panel_worldmap.redswf";

fn no_reparse(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
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

fn fnv64(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf29ce484222325, |h, b| (h ^ u64::from(*b)).wrapping_mul(0x100000001b3))
}

fn create(path: &Path, bytes: &[u8]) -> Result<(), Box<dyn std::error::Error>> {
    no_reparse(path)?;
    fs::OpenOptions::new().write(true).create_new(true).open(path)?.write_all(bytes)?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<_> = env::args_os().collect();
    if args.len() != 3 && args.len() != 4 { return Err("INPUT_REDSWF NEW_OUTPUT_DIRECTORY [PROVIDER_DEPOT]".into()); }
    let depot = if args.len() == 4 { args[3].to_str().ok_or("non-UTF8 depot")? } else { DEPOT };
    if args.len() == 4 && depot != "gameplay\\gui_new\\swf\\cmf_s03\\icon.redswf" && depot != "gameplay\\gui_new\\swf\\cmf_s03\\grid.redswf" {
        return Err("unqualified provider depot".into());
    }
    let input = PathBuf::from(&args[1]);
    let output = PathBuf::from(&args[2]);
    no_reparse(&input)?; no_reparse(&output)?;
    let allowed = Path::new(env!("CARGO_MANIFEST_DIR")).ancestors().nth(3).ok_or("build root")?.join("panel-runs").canonicalize()?;
    let parent = output.parent().ok_or("output parent")?.canonicalize()?;
    if !parent.starts_with(&allowed) || output.exists() { return Err("output boundary/existing target".into()); }
    let data = fs::read(&input)?;
    if data.len() < 160 || data.len() > 16 * 1024 * 1024 || &data[..8] != b"CR2W\xa4\0\0\0" { return Err("unsupported input".into()); }
    let item = BundleItem::new(CString::new(depot)?, &data, BundleCompression::Lz4hc)?;
    let bundle = Bundle::from_items(BundleFormat::Remastered, vec![item]);
    let bytes = bundle.try_write()?;
    let parsed = Bundle::parse(bytes.as_slice())?;
    if parsed.version() != 5 || parsed.items().len() != 1 || parsed.try_write()? != bytes { return Err("emitted bundle roundtrip".into()); }
    let name = CString::new("blob0.bundle")?;
    let mut metadata = Metadata::from_bundle_files(BundleFormat::Remastered, &[(name.as_c_str(), &parsed)])?;
    if !metadata.hashes.is_empty() || !metadata.buffers.is_empty() || metadata.file_infos.len() != 2 || metadata.entry_infos.len() != 2 || metadata.bundle_infos.len() != 2 { return Err("constructor topology".into()); }
    let lookup = fnv64(depot.as_bytes());
    if fnv64(DEPOT.as_bytes()) != 0xEE5025C8ADA29263 { return Err("lookup known answer".into()); }
    metadata.hashes.push(MetadataHash { hash: lookup as i64, file_id: 1, unknown_upper_word: 0 });
    if metadata.version != 7 || metadata.file_infos[1].1.path_hash != 0 { return Err("unsupported metadata".into()); }
    let index = metadata.try_write()?;
    let reread = Metadata::parse(&index)?;
    if reread.try_write()? != index || reread.hashes != metadata.hashes { return Err("index roundtrip".into()); }
    fs::create_dir(&output)?;
    create(&output.join("blob0.bundle"), &bytes)?;
    create(&output.join("metadata.store"), &index)?;
    println!("HOST_EMITTED resource={} bundle={} metadata={} lookup={:016X} path_hash=0 runtime=UNOBSERVED", data.len(), bytes.len(), index.len(), lookup);
    Ok(())
}
