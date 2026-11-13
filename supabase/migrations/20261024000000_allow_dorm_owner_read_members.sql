-- Allow dormitory owners to read members of their own dorms
DROP POLICY IF EXISTS "Dormitory owner can read members of own dorms" ON public.dormitory_members;
CREATE POLICY "Dormitory owner can read members of own dorms"
  ON public.dormitory_members
  FOR SELECT
  USING (
    dormitory_id IN (
      SELECT id FROM public.dormitories WHERE created_by = auth.uid()
    )
  );
