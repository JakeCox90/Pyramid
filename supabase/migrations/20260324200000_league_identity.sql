-- League identity: color palette, emoji, description
ALTER TABLE public.leagues ADD COLUMN IF NOT EXISTS color_palette text NOT NULL DEFAULT 'primary';
ALTER TABLE public.leagues ADD COLUMN IF NOT EXISTS emoji text NOT NULL DEFAULT '⚽';
ALTER TABLE public.leagues ADD COLUMN IF NOT EXISTS description text;

-- Constraints (idempotent via DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'leagues_color_palette_check') THEN
    ALTER TABLE public.leagues ADD CONSTRAINT leagues_color_palette_check CHECK (color_palette IN ('primary'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'leagues_description_length_check') THEN
    ALTER TABLE public.leagues ADD CONSTRAINT leagues_description_length_check CHECK (char_length(description) <= 80);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'leagues_name_length_check') THEN
    ALTER TABLE public.leagues ADD CONSTRAINT leagues_name_length_check CHECK (char_length(name) >= 3 AND char_length(name) <= 40);
  END IF;
END
$$;

-- Note: emoji validation is enforced at the Edge Function level rather than via CHECK constraint
-- because PostgreSQL CHECK constraints on multi-byte UTF-8 emoji characters are fragile
-- (variation selectors, ZWJ sequences). The Edge Function validates against the allowed set.
