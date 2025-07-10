---------------TABELLE BASE------------------
CREATE TABLE Proprietario (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome     VARCHAR(50)  NOT NULL,
  cognome  VARCHAR(50)  NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  CONSTRAINT chk_valori_distinti
    CHECK (
      nome    <> cognome
      AND nome    <> username
      AND cognome <> username
    )
);

CREATE TABLE Coltivatore (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome      VARCHAR(50)  NOT NULL,
  cognome   VARCHAR(50)  NOT NULL,
  username  VARCHAR(100) NOT NULL UNIQUE,
  esperienza VARCHAR(100) NOT NULL DEFAULT 'principiante'
    CHECK (esperienza IN (
      'principiante',
      'intermedio',
      'professionista'
    )),
  CONSTRAINT chk_valori_distinti_coltivatore
    CHECK (
      nome    <> cognome
      AND nome    <> username
      AND cognome <> username
    )
);

CREATE TABLE Progetto_Coltivazione (
  ID_Progetto     INT      PRIMARY KEY,
  stima_raccolto   NUMERIC,
  data_inizio      DATE     NOT NULL,
  data_fine        DATE     NOT NULL,
  CONSTRAINT chk_intervallo_date
    CHECK (data_fine >= data_inizio)
);

CREATE TABLE Coltura (
  ID_Coltura            INT PRIMARY KEY,
  varietà               VARCHAR(50),
  tipo                  VARCHAR(50),
  tempi_maturazione     INT,
  frequenza_irrigazione INT,
  periodo_semina        DATE NOT NULL,
  CONSTRAINT chk_mese_semina
    CHECK (
      EXTRACT(MONTH FROM periodo_semina) BETWEEN 2 AND 7
    )
);

CREATE TABLE Lotto (
  ID_Lotto       INT        PRIMARY KEY,
  metri_quadri   NUMERIC    NOT NULL
                   CHECK (metri_quadri = 500),
  tipo_terreno   VARCHAR(50),
  posizione      INT        NOT NULL
                   CHECK (posizione BETWEEN 1 AND 200),
  costo_terreno  NUMERIC    NOT NULL
                   CHECK (costo_terreno = 300),
  Codice_FiscalePr VARCHAR(16),
  CONSTRAINT uq_posizione UNIQUE (posizione),
  FOREIGN KEY (Codice_FiscalePr) REFERENCES Proprietario(Codice_Fiscale)
);


CREATE TABLE Attività (
  ID_Attività     INT     PRIMARY KEY,
  giorno_inizio   DATE    NOT NULL,
  giorno_fine     DATE    NOT NULL,
 
  
  CONSTRAINT chk_coerenza_date
    CHECK (giorno_inizio <= giorno_fine),

  Codice_FiscaleCol VARCHAR(16),
  ID_Lotto         INT,

  FOREIGN KEY (Codice_FiscaleCol)
    REFERENCES Coltivatore(Codice_Fiscale),
  FOREIGN KEY (ID_Lotto)
    REFERENCES Lotto(ID_Lotto)
);

CREATE TABLE Semina (
  ID_Semina    INT       PRIMARY KEY,
  profondita   NUMERIC   NOT NULL
                CONSTRAINT chk_profondita_std
                  CHECK (profondita = 10),
  tipo_semina  VARCHAR(50),
  ID_Attivita  INT       NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attività(ID_Attività)
);

CREATE TABLE Irrigazione (
  ID_Irrigazione   INT        PRIMARY KEY,
  tipo_irrigazione VARCHAR(50) NOT NULL
    CONSTRAINT chk_tipo_irrigazione
      CHECK (
        tipo_irrigazione IN (
          'a goccia',
          'a pioggia',
          'per scorrimento'
        )
      ),
  ID_Attivita      INT        NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);


CREATE TABLE Raccolta (
  ID_Raccolta        SERIAL PRIMARY KEY,
  raccolto_effettivo NUMERIC   NOT NULL
                      CONSTRAINT chk_raccolto_non_negativo
                        CHECK (raccolto_effettivo >= 0),
  ID_Attivita        INT       NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);


CREATE TABLE Notifica (
  ID_Notifica          INT PRIMARY KEY,
  Attivita_programmate VARCHAR(200) NOT NULL,
  Errori               VARCHAR(200) NOT NULL,
  Anomalie             VARCHAR(200) NOT NULL,
  CONSTRAINT chk_enti_lista
    CHECK (
      NULLIF(trim(Attivita_programmate), '') IS NOT NULL
      OR NULLIF(trim(Errori), '') IS NOT NULL
      OR NULLIF(trim(Anomalie), '') IS NOT NULL
    ),
  ID_Attivita          INT NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);
---------------TABELLE BASE------------------

----------------------TABELLE PONTE-----------------------------------
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
----------------------TABELLE PONTE-----------------------------------


-------------FUNZIONE ESPERIENZA DEL COLTIVATORE----------------------

CREATE OR REPLACE FUNCTION trg_promuovi_experience()
  RETURNS trigger AS $$
DECLARE
  cnt     INT;
  old_exp TEXT;
BEGIN
  -- Conta tutte le attività del coltivatore (inclusa la nuova)
  SELECT COUNT(*) INTO cnt
    FROM Attività
   WHERE Codice_FiscaleCol = NEW.Codice_FiscaleCol;

  IF cnt % 5 = 0 THEN
    -- Legge il livello corrente
    SELECT esperienza INTO old_exp
      FROM Coltivatore
     WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;

    -- Promuove al livello successivo a seconda del livello corrente
    IF old_exp = 'principiante' THEN
      UPDATE Coltivatore
         SET esperienza = 'intermedio'
       WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;
    ELSIF old_exp = 'intermedio' THEN
      UPDATE Coltivatore
         SET esperienza = 'professionista'
       WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
-------------FUNZIONE ESPERIENZA DEL COLTIVATORE----------------------

-------------TRIGGER ESPERIENZA DEL COLTIVATORE-----------------------
CREATE TRIGGER trg_after_attivita_insert
  AFTER INSERT ON Attività
  FOR EACH ROW
  EXECUTE FUNCTION trg_promuovi_experience();
-------------TRIGGER ESPERIENZA DEL COLTIVATORE-----------------------


---------------------FUNZIONE id_Progetto_Coltivazione------------------------------
CREATE OR REPLACE FUNCTION id_Progetto_Coltivazione()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Progetto) INTO ID_var FROM Progetto_Coltivazione;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
     END IF;

   	NEW.ID_Progetto :=ID_var+1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Progetto_Coltivazione------------------------------

---------------------TRIGGER Progetto_Coltivazione------------------------------
Trigger per Progetto_Coltivazione

CREATE TRIGGER trg_Progetto_Coltivazione_id
BEFORE INSERT ON Progetto_Coltivazione
FOR EACH ROW
EXECUTE FUNCTION id_Progetto_Coltivazione();
---------------------TRIGGER Progetto_Coltivazione------------------------------


---------------------FUNZIONE id_Coltura------------------------------
CREATE OR REPLACE FUNCTION id_Coltura()
RETURNS TRIGGER AS $$ 
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Coltura) INTO ID_var FROM Coltura;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Coltura := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Coltura------------------------------

---------------------TRIGGER Coltura------------------------------
CREATE TRIGGER trg_Coltura_id
BEFORE INSERT ON Coltura
FOR EACH ROW
EXECUTE FUNCTION id_Coltura();
---------------------TRIGGER Coltura------------------------------


---------------------FUNZIONE id_Lotto------------------------------
CREATE OR REPLACE FUNCTION id_Lotto()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Lotto) INTO ID_var FROM Lotto;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Lotto := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Lotto------------------------------

---------------------TRIGGER Lotto------------------------------
CREATE TRIGGER trg_Lotto_id
BEFORE INSERT ON Lotto
FOR EACH ROW
EXECUTE FUNCTION id_Lotto();
---------------------TRIGGER Lotto------------------------------


---------------------FUNZIONE id_Attività------------------------------
CREATE OR REPLACE FUNCTION id_Attività()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Attività) INTO ID_var FROM Attività;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Attività := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Attività------------------------------

---------------------TRIGGER Attività------------------------------
CREATE TRIGGER trg_Attività_id
BEFORE INSERT ON Attività
FOR EACH ROW
EXECUTE FUNCTION id_Attività();
---------------------TRIGGER Attività------------------------------


---------------------FUNZIONE id_Semina------------------------------
CREATE OR REPLACE FUNCTION id_Semina()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Semina) INTO ID_var FROM Semina;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Semina := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Semina------------------------------

---------------------TRIGGER Semina------------------------------
CREATE TRIGGER trg_Semina_id
BEFORE INSERT ON Semina
FOR EACH ROW
EXECUTE FUNCTION id_Semina();
---------------------TRIGGER Semina------------------------------


---------------------FUNZIONE id_Irrigazione------------------------------
CREATE OR REPLACE FUNCTION id_Irrigazione()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Irrigazione) INTO ID_var FROM Irrigazione;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Irrigazione := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Irrigazione------------------------------

---------------------TRIGGER Irrigazione------------------------------
CREATE TRIGGER trg_Irrigazione_id
BEFORE INSERT ON Irrigazione
FOR EACH ROW
EXECUTE FUNCTION id_Irrigazione();
---------------------TRIGGER Irrigazione------------------------------


---------------------FUNZIONE id_Raccolta------------------------------
CREATE OR REPLACE FUNCTION id_Raccolta()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Raccolta) INTO ID_var FROM Raccolta;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Raccolta := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Raccolta------------------------------

---------------------TRIGGER Raccolta------------------------------
CREATE TRIGGER trg_Raccolta_id
BEFORE INSERT ON Raccolta
FOR EACH ROW
EXECUTE FUNCTION id_Raccolta();
---------------------TRIGGER Raccolta------------------------------


---------------------FUNZIONE id_Notifica------------------------------
CREATE OR REPLACE FUNCTION id_Notifica()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Notifica) INTO ID_var FROM Notifica;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Notifica := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Notifica------------------------------

---------------------TRIGGER Notifica------------------------------
CREATE TRIGGER trg_Notifica_id
BEFORE INSERT ON Notifica
FOR EACH ROW
EXECUTE FUNCTION id_Notifica();
---------------------TRIGGER Notifica------------------------------

