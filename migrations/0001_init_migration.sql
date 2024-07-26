-- Migration number: 0001 	 2024-07-21T06:56:02.706Z

-- Crear la tabla subscription_type
CREATE TABLE IF NOT EXISTS subscription_type (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL
);

-- Crear la tabla emails
CREATE TABLE IF NOT EXISTS email (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    type INTEGER NOT NULL,
    subscribed_from INTEGER,
    subscribed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_email_sent_at DATETIME,
    unsubscribed_at DATETIME,
    status TEXT CHECK(status IN ('active', 'unsubscribed', 'bounced')) DEFAULT 'active',
    bounce_count INTEGER DEFAULT 0,
    country TEXT,
    user_agent TEXT,
    FOREIGN KEY (type) REFERENCES subscription_type (id)
);

-- Insertar algunos subscription_type por defecto
INSERT INTO subscription_type (name, description) VALUES
('Newsletter', 'Suscripción general al boletín informativo'),
('Promociones', 'Ofertas y descuentos exclusivos'),
('Actualizaciones de producto', 'Información sobre nuevos productos y características'),
('Eventos', 'Invitaciones y noticias sobre eventos');
