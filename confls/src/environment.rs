#[derive(Debug, Clone)]
pub struct EnvironmentConfig {
    pub info: EnvironmentConfigInfo,
}

#[derive(Debug, Clone)]
pub struct EnvironmentConfigInfo {
    /// Name of the environment
    pub name: String,

    /// Positive whole integer
    pub version: u32,

    /// Name of the user these changes should take place in.
    ///
    /// Used to resolve the home directory of the user.
    pub username: String,

    /// List of dependencies available from the AUR.
    pub requires: Vec<String>,

    /// Use shared config
    pub use_shared: bool,
}
