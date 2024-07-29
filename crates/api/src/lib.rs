use models::{Mail, MailRequest};
use worker::*;

// This event is called on start worker
// So we use the `start` event to initialize our tracing subscriber when the worker starts.
#[event(start)]
fn start() {
    // Custom panic
    #[cfg(target_arch = "wasm32")]
    std::panic::set_hook(Box::new(|info: &std::panic::PanicInfo| {
        worker::console_error!("{info}")
    }));
}

//
// Docs: https://github.com/cloudflare/workers-rs#or-use-the-router
// Example: https://github.com/cloudflare/workers-rs/blob/main/examples/router/src/lib.rs
//
#[event(fetch)]
pub async fn main(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    Router::new()
        .post_async("/subscribe", subscribe)
        .run(req, env)
        .await
}

async fn subscribe(mut req: Request, ctx: RouteContext<()>) -> worker::Result<Response> {
    let db = ctx.d1("mail-subscription")?;
    let agent = req
        .headers()
        .get("Agent")?
        .expect("Se necesita un agent para la solicitud");
    let country = req
        .cf()
        .expect("No se pudieron obtener los valores de cloudflare")
        .country()
        .unwrap_or("Unknown".to_string());

    let req = req.json::<MailRequest>().await?;

    let mail = Mail::new(req, &country, &agent);
    let res = mail.insert(&db).await?;
    
    if res {
        return Response::ok("");
    }

    Response::error("Ha ocurrido un error", 500)

}
