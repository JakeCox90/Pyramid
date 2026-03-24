-- League identity: color palette, emoji, description
ALTER TABLE public.leagues ADD COLUMN color_palette text NOT NULL DEFAULT 'primary';
ALTER TABLE public.leagues ADD COLUMN emoji text NOT NULL DEFAULT '⚽';
ALTER TABLE public.leagues ADD COLUMN description text;

-- Constraints
ALTER TABLE public.leagues ADD CONSTRAINT leagues_color_palette_check
  CHECK (color_palette IN ('primary'));

ALTER TABLE public.leagues ADD CONSTRAINT leagues_description_length_check
  CHECK (char_length(description) <= 80);

ALTER TABLE public.leagues ADD CONSTRAINT leagues_name_length_check
  CHECK (char_length(name) >= 3 AND char_length(name) <= 40);

-- Note: emoji validation is enforced at the Edge Function level rather than via CHECK constraint
-- because PostgreSQL CHECK constraints on multi-byte UTF-8 emoji characters are fragile
-- (variation selectors, ZWJ sequences). The Edge Function validates against the allowed set.
