CREATE TABLE campionato_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  json_url TEXT NOT NULL
    DEFAULT 'https://vincenzomancinelli.it/campionato_2026_EC_A.json',
  squadra_preferita TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE campionato_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own campionato_config"
ON campionato_config FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own campionato_config"
ON campionato_config FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own campionato_config"
ON campionato_config FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own campionato_config"
ON campionato_config FOR DELETE TO authenticated
USING (auth.uid() = user_id);






-- Inserisce una config di default per il tuo utente
INSERT INTO campionato_config (user_id, json_url, squadra_preferita)
VALUES (
  '688831cc-dc6a-40d9-b7ca-7c6d0a21073e',
  'https://vincenzomancinelli.it/campionato_2026_EC_A.json',
  'boys caivanese'
)
ON CONFLICT (user_id) DO UPDATE SET
  json_url = EXCLUDED.json_url,
  squadra_preferita = EXCLUDED.squadra_preferita,
  updated_at = now();