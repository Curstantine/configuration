mod environment;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("Hello, docker!");

    Ok(())
}
