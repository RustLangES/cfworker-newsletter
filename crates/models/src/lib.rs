

pub struct Mail {
    id: i32,
    email: String, 
    type_mail: i32,
    subscribed_from: i32,
    subscribe_at: String,
    last_email_sent_at: String, //de tipo date time
    unsubscribed_at: String, // de tipo datetime
    status: String,
    bounce_count: i32, 
    country: String,
    user_agent: String,
}

pub struct SubscriptionType {
    id: i32,
    name: String,
    description: String,
}

impl Mail {
    fn new(id:i32, email:&str, type_mail:i32, subscribed_from:i32,
           subscribe_at:&str, last_email_sent_at:&str, unsubscribed_at:&str,
           status:&str, bounce_count:i32, country:&str, user_agent:&str) -> Self {
        Self { 
            id,
            email: email.to_string(),
            type_mail,
            subscribed_from,
            subscribe_at: subscribe_at.to_string(),
            last_email_sent_at: last_email_sent_at.to_string(),
            unsubscribed_at: unsubscribed_at.to_string(),
            status: status.to_string(),
            bounce_count,
            country: country.to_string(),
            user_agent: user_agent.to_string(),
        }
    }

    //aca no se si inicializar los datos con valores por defectos
    // asi que la funcion esta
    fn default(&mut self, id:i32) -> Self {
        Self {
            id,
            email: String::from(""),
            type_mail: 0 as i32,
            subscribed_from: 0 as i32, //Aca no deberia ponerle nada
            subscribe_at:String::from(""), //No sabria cual es el timestam para ponerle como default
            last_email_sent_at:String::from(""),
            unsubscribed_at:String::from(""),
            status: String::from("active"),
            bounce_count: 0 as i32,
            country:String::from(""),
            user_agent: String::from(""),
        }
    }
}