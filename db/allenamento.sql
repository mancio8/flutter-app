-- Tabella esercizi
CREATE TABLE esercizi (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  nome TEXT NOT NULL,
  categoria TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabella serie (le singole registrazioni peso/ripetizioni)
CREATE TABLE serie_esercizio (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  esercizio_id UUID REFERENCES esercizi(id) ON DELETE CASCADE NOT NULL,
  peso NUMERIC NOT NULL,
  ripetizioni INTEGER NOT NULL,
  data DATE NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_esercizi_user_id ON esercizi(user_id);
CREATE INDEX idx_serie_esercizio_user_id ON serie_esercizio(user_id);
CREATE INDEX idx_serie_esercizio_esercizio_id ON serie_esercizio(esercizio_id);

ALTER TABLE esercizi ENABLE ROW LEVEL SECURITY;
ALTER TABLE serie_esercizio ENABLE ROW LEVEL SECURITY;

-- Policy esercizi
CREATE POLICY "Users select own esercizi" ON esercizi FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own esercizi" ON esercizi FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own esercizi" ON esercizi FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own esercizi" ON esercizi FOR DELETE USING (auth.uid() = user_id);

-- Policy serie
CREATE POLICY "Users select own serie" ON serie_esercizio FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own serie" ON serie_esercizio FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own serie" ON serie_esercizio FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own serie" ON serie_esercizio FOR DELETE USING (auth.uid() = user_id);