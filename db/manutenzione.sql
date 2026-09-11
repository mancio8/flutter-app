-- ============================================================
-- MANUTENZIONI & SCADENZE VEICOLO
-- Script completo con RLS, policy e default automatico
-- ============================================================

-- ============================================================
-- 1. TABELLA MANUTENZIONI
-- ============================================================
CREATE TABLE IF NOT EXISTS manutenzioni (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  veicolo_id UUID NOT NULL
    REFERENCES veicoli(id) ON DELETE CASCADE,
  titolo TEXT NOT NULL,
  data DATE NOT NULL,
  chilometraggio NUMERIC,
  costo NUMERIC DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 2. TABELLA SCADENZE VEICOLO
-- ============================================================
CREATE TABLE IF NOT EXISTS scadenze_veicolo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  veicolo_id UUID NOT NULL
    REFERENCES veicoli(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL
    CHECK (tipo IN ('assicurazione', 'bollo', 'revisione', 'altro')),
  data_scadenza DATE NOT NULL,
  importo_stimato NUMERIC,
  completato BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 3. INDICI per performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_manutenzioni_user_id
  ON manutenzioni(user_id);
CREATE INDEX IF NOT EXISTS idx_manutenzioni_veicolo_id
  ON manutenzioni(veicolo_id);
CREATE INDEX IF NOT EXISTS idx_manutenzioni_data
  ON manutenzioni(data DESC);

CREATE INDEX IF NOT EXISTS idx_scadenze_user_id
  ON scadenze_veicolo(user_id);
CREATE INDEX IF NOT EXISTS idx_scadenze_veicolo_id
  ON scadenze_veicolo(veicolo_id);
CREATE INDEX IF NOT EXISTS idx_scadenze_data_scadenza
  ON scadenze_veicolo(data_scadenza ASC);

-- ============================================================
-- 4. ABILITA ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE manutenzioni ENABLE ROW LEVEL SECURITY;
ALTER TABLE scadenze_veicolo ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. POLICY PER manutenzioni
-- ============================================================

-- SELECT: leggi solo le proprie manutenzioni
CREATE POLICY "Users can view own manutenzioni"
ON manutenzioni FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- INSERT: inserisci solo con il proprio user_id
CREATE POLICY "Users can insert own manutenzioni"
ON manutenzioni FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- UPDATE: modifica solo le proprie
CREATE POLICY "Users can update own manutenzioni"
ON manutenzioni FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: cancella solo le proprie
CREATE POLICY "Users can delete own manutenzioni"
ON manutenzioni FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- 6. POLICY PER scadenze_veicolo
-- ============================================================

-- SELECT
CREATE POLICY "Users can view own scadenze"
ON scadenze_veicolo FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- INSERT
CREATE POLICY "Users can insert own scadenze"
ON scadenze_veicolo FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- UPDATE
CREATE POLICY "Users can update own scadenze"
ON scadenze_veicolo FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE
CREATE POLICY "Users can delete own scadenze"
ON scadenze_veicolo FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- 7. VERIFICA (opzionale — esegui per controllare)
-- ============================================================
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
--   AND tablename IN ('manutenzioni', 'scadenze_veicolo');

-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('manutenzioni', 'scadenze_veicolo')
-- ORDER BY tablename, cmd;