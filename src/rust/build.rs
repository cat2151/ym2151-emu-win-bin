use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let nuked_opm_dir = manifest_dir.join("vendor/nuked-opm");

    // Nuked-OPMのコンパイル
    cc::Build::new()
        .file(nuked_opm_dir.join("opm.c"))
        .include(&nuked_opm_dir)
        .opt_level(3)
        .compile("nuked-opm");

    println!("cargo:rerun-if-changed=vendor/nuked-opm/opm.c");
    println!("cargo:rerun-if-changed=vendor/nuked-opm/opm.h");
}
