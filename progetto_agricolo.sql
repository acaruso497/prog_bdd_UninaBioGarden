
-- ==============================
-- SCHEMA: Progetto Agricolo
-- ==============================

-- TABELLE BASE
CREATE TABLE Proprietario (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome VARCHAR(50),
  cognome VARCHAR(50),
  email VARCHAR(100)
);

CREATE TABLE Coltivatore (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome VARCHAR(50),
  cognome VARCHAR(50),
  email VARCHAR(100),
  esperienza TEXT
);

CREATE TABLE Progetto_Coltivazione (
  ID_Progetto SERIAL PRIMARY KEY,
  stima_raccolto NUMERIC,
  data_inizio DATE,
  data_fine DATE
);

CREATE TABLE Coltura (
  ID_Coltura SERIAL PRIMARY KEY,
  varieta VARCHAR(50),
  tipo VARCHAR(50),
  tempi_maturazione INTERVAL,
  frequenza_irrigazione VARCHAR(50),
  periodo_semina VARCHAR(50)
);

CREATE TABLE Lotto (
  ID_Lotto SERIAL PRIMARY KEY,
  metri_quadri NUMERIC,
  tipo_terreno VARCHAR(50),
  posizione VARCHAR(100),
  coordinate VARCHAR(100),
  costo_terreno NUMERIC,
  Codice_FiscalePr VARCHAR(16),
  FOREIGN KEY (Codice_FiscalePr) REFERENCES Proprietario(Codice_Fiscale)
);

CREATE TABLE Attivita (
  ID_Attivita SERIAL PRIMARY KEY,
  giorno_inizio DATE,
  giorno_fine DATE,
  orario_inizio TIME,
  giorno_lavoro TEXT,
  Codice_FiscaleCol VARCHAR(16),
  ID_Lotto INT,
  FOREIGN KEY (Codice_FiscaleCol) REFERENCES Coltivatore(Codice_Fiscale),
  FOREIGN KEY (ID_Lotto) REFERENCES Lotto(ID_Lotto)
);

CREATE TABLE Semina (
  ID_Semina SERIAL PRIMARY KEY,
  profondità NUMERIC,
  tipo_seminazione VARCHAR(50),
  ID_Attivita INT,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);

CREATE TABLE Irrigazione (
  ID_Irrigazione SERIAL PRIMARY KEY,
  tipo_irrigazione VARCHAR(50),
  ID_Attivita INT,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);

CREATE TABLE Raccolta (
  ID_Raccolta SERIAL PRIMARY KEY,
  raccolto_effettivo NUMERIC,
  ID_Attivita INT,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);

CREATE TABLE Notifica (
  ID_Notifica SERIAL PRIMARY KEY,
  Attivita_programmate TEXT,
  Errori TEXT,
  Anomalie TEXT,
  ID_Attivita INT,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);

-- TABELLE PONTE
CREATE TABLE Invia (
  ID_Notifica INT,
  Codice_FiscalePr VARCHAR(16),
  PRIMARY KEY (ID_Notifica, Codice_FiscalePr),
  FOREIGN KEY (ID_Notifica) REFERENCES Notifica(ID_Notifica),
  FOREIGN KEY (Codice_FiscalePr) REFERENCES Proprietario(Codice_Fiscale)
);

CREATE TABLE Ospita (
  ID_Lotto INT,
  ID_Coltura INT,
  PRIMARY KEY (ID_Lotto, ID_Coltura),
  FOREIGN KEY (ID_Lotto) REFERENCES Lotto(ID_Lotto),
  FOREIGN KEY (ID_Coltura) REFERENCES Coltura(ID_Coltura)
);

CREATE TABLE Ospita_Lotto_Progetto (
  ID_Lotto INT,
  ID_Progetto INT,
  PRIMARY KEY (ID_Lotto, ID_Progetto),
  FOREIGN KEY (ID_Lotto) REFERENCES Lotto(ID_Lotto),
  FOREIGN KEY (ID_Progetto) REFERENCES Progetto_Coltivazione(ID_Progetto)
);
