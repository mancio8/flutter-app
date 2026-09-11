CREATE TABLE viaggi (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  destinazione TEXT NOT NULL,
  paese TEXT,
  cover_url TEXT,
  note TEXT,
  budget_stimato NUMERIC,
  data_visita DATE,              -- null = ancora in wishlist
  rating INTEGER,                -- solo dopo la visita
  in_wishlist BOOLEAN NOT NULL DEFAULT true,
  wishlist_date TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_viaggi_user_id ON viaggi(user_id);
CREATE INDEX idx_viaggi_wishlist ON viaggi(user_id, in_wishlist) WHERE in_wishlist = true;

ALTER TABLE viaggi ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users select own viaggi" ON viaggi FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own viaggi" ON viaggi FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own viaggi" ON viaggi FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own viaggi" ON viaggi FOR DELETE USING (auth.uid() = user_id);