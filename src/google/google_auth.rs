extern crate chrono;
extern crate reqwest;
extern crate serde;

use oauth2::basic::BasicClient;
// Alternatively, this can be oauth2::curl::http_client or a custom.
use oauth2::reqwest::http_client;
use oauth2::{
    AuthUrl, AuthorizationCode, ClientId, ClientSecret, CsrfToken, PkceCodeChallenge, RedirectUrl,
    RevocationUrl, Scope, TokenUrl,
};
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io;
use std::io::BufReader;

#[derive(Debug, Serialize, Deserialize)]
pub struct AccessTokenResponse {
    pub access_token: String,
    pub expires_in: i64,
    pub refresh_token: String,
    //pub token_type: String
}

#[derive(Debug, Serialize, Deserialize)]
struct SecretJson {
    //type: String,
    //project_id: String,
    //private_key_id: String,
    private_key: String,
    client_email: String,
    client_id: String,
    //auth_uri: String,
    token_uri: String,
    //auth_provider_x509_cert_url: String,
    //client_x509_cert_url: String
}

fn gets() -> String {
    let mut code = String::new();

    io::stdin()
        .read_line(&mut code)
        .expect("Failed to read line.");
    code
}

fn client_generate(credentials: Credentials) -> BasicClient {
    let client = BasicClient::new(
        ClientId::new(credentials.client_id),
        Some(ClientSecret::new(credentials.client_secret)),
        AuthUrl::new(credentials.auth_uri).unwrap(),
        Some(TokenUrl::new(credentials.token_uri).unwrap()),
    )
    .set_redirect_uri(
        RedirectUrl::new("urn:ietf:wg:oauth:2.0:oob".to_string()).expect("Invalid redirect URL"),
    )
    .set_revocation_uri(
        RevocationUrl::new("https://oauth2.googleapis.com/revoke".to_string())
            .expect("Invalid revocation endpoint URL"),
    );

    client
}

pub fn authorize(file: String) {
    let credentials = Credentials::new(file);
    let client = client_generate(credentials);
    let (pkce_code_challenge, pkce_code_verifier) = PkceCodeChallenge::new_random_sha256();
    let (authorize_url, csrf_state) = client
        .authorize_url(CsrfToken::new_random)
        .add_scope(Scope::new(
            "https://www.googleapis.com/auth/calendar".to_string(),
        ))
        .add_scope(Scope::new(
            "https://www.googleapis.com/auth/plus.me".to_string(),
        ))
        .set_pkce_challenge(pkce_code_challenge)
        .url();

    println!(
        "Open this URL in your browser:\n{}\n",
        authorize_url.to_string()
    );

    let code = gets();
    let token_result = client
        .exchange_code(AuthorizationCode::new(code))
        .set_pkce_verifier(pkce_code_verifier)
        .request(http_client)
        .unwrap();

    let file = File::create("token.json".to_string()).unwrap();
    match serde_json::to_writer(file, &token_result) {
        Ok(_) => println!("Authorize Success!"),
        Err(_) => println!("Fatal Authorize"),
    }
}

pub fn get_access_token() -> AccessTokenResponse {
    match File::open("token.json".to_string()) {
        Ok(_) => (),
        Err(_) => authorize("credentials.json".to_string()),
    }

    let file = File::open("token.json".to_string()).unwrap();
    let reader = BufReader::new(file);

    let token: AccessTokenResponse = serde_json::from_reader(reader).unwrap();

    token
}

#[derive(Debug, Serialize, Deserialize)]
struct Credentials {
    client_id: String,
    project_id: String,
    auth_uri: String,
    token_uri: String,
    auth_provider_x509_cert_url: String,
    client_secret: String,
    redirect_uris: Vec<String>,
}

impl Credentials {
    fn new(filepath: String) -> Credentials {
        let file = File::open(filepath).unwrap();
        let reader = BufReader::new(file);

        let config: Credentials = serde_json::from_reader(reader).unwrap();
        config
    }
}
