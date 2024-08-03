use serde::{Deserialize, Serialize};
use worker::{d1, D1Database, D1PreparedStatement};

#[derive(Default, Deserialize)]
pub struct Mail {
    id: i32,
    email: String,
    #[serde(rename = "type")]
    type_mail: i32,
    subscribed_from: i32,
    subscribe_at: String,
    // de tipo date time
    last_email_sent_at: String,
    // de tipo datetime
    unsubscribed_at: String,
    status: SubscriptionStatus,
    bounce_count: i32,
    country: String,
    user_agent: String,
}

#[derive(Default, Deserialize)]
pub struct MailRequest {
    email: String,
    type_mail: i32,
    subscribed_from: i32,
}

pub struct SubscriptionType {
    id: i32,
    name: String,
    description: String,
}

#[derive(Default, Deserialize, Serialize, Debug)]
#[serde(rename_all = "lowercase")]
pub enum SubscriptionStatus {
    #[default]
    Active,
    Unsubscribed,
    Bounced,
}

pub enum SubscriptionFrom {
    Discord,
    Website,
    SocialMedia,
}

impl SubscriptionType{
    pub fn new(&mut self, id:i32, name:&str, description:&str) -> Self {
        Self {
            id,
            name: name.to_string(),
            description: description.to_string()
        }
    }

    pub async fn insert(&self, db:&D1Database)-> worker::Result<bool>{
        // prepare statement to add values into subscription_type table
        let prepare:D1PreparedStatement = db.prepare("INSERT INTO subscription_type (id,name,description) VALUES (?1,?2,?3)");
        // binding values into prepare
        let bind = prepare.bind(&[
            self.id.into(),
            self.name.clone().into(),
            self.description.clone().into(),
        ]);
        let resultado = bind?.run().await?;
        //handling error
        if let Some(err) = resultado.error() {
            return Err(worker::Error::from(err));
        }
        //it's ok!
        Ok(resultado.success())
    }
}

impl Mail {
    pub fn new<T: ToString>(
        MailRequest {
            email,
            type_mail,
            subscribed_from,
        }: MailRequest,
        country: T,
        user_agent: T,
    ) -> Self {
        Self {
            id: 0,
            email: email.to_string(),
            type_mail,
            subscribed_from,
            country: country.to_string(),
            user_agent: user_agent.to_string(),
            ..Default::default()
        }
    }

    pub async fn insert(&self, db: &D1Database) -> worker::Result<bool> {
        let prepare = db.prepare("INSERT INTO email (email, type, subscribed_from, status, country, user_agent) VALUES (?1, ?2, ?3, ?4, ?5, ?6)");
        let bind = prepare.bind(&[
            self.email.clone().into(),
            self.type_mail.into(),
            self.subscribed_from.into(),
            format!("{:?}", self.status).into(),
            self.country.clone().into(),
            self.user_agent.clone().into(),
        ]);
        let res = bind?.run().await?;

        if let Some(err) = res.error() {
            return Err(worker::Error::from(err));
        }

        Ok(res.success())
    }
}
