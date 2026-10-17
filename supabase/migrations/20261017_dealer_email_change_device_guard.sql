-- TORVO V2 / STAGING-FIRST REVIEW REQUIRED
-- Dealer email change requests must have a verified active device session.
-- Apply only after updating all callers to pass device_id and session_token.
-- Never apply to production without explicit owner approval.
BEGIN;
CREATE OR REPLACE FUNCTION public.request_my_dealer_email_change(
  p_dealer_code text, p_new_email text, p_device_id text, p_session_token text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE d public.dealers%rowtype; e text; rid uuid; v_dealer_id uuid;
BEGIN
  v_dealer_id := public.dealer_assert_my_device_session(p_device_id,p_session_token);
  SELECT * INTO d FROM public.dealers WHERE id=v_dealer_id AND lower(coalesce(status,''))='approved';
  IF NOT FOUND THEN RAISE EXCEPTION 'APPROVED_DEALER_REQUIRED'; END IF;
  IF upper(btrim(coalesce(p_dealer_code,'')))<>upper(btrim(coalesce(d.dealer_code,''))) THEN RAISE EXCEPTION 'DEALER_CODE_MISMATCH'; END IF;
  e:=lower(btrim(coalesce(p_new_email,'')));
  IF e !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' THEN RAISE EXCEPTION 'INVALID_EMAIL'; END IF;
  IF lower(btrim(coalesce(d.email,'')))=e THEN RAISE EXCEPTION 'EMAIL_UNCHANGED'; END IF;
  IF EXISTS(SELECT 1 FROM public.dealers x WHERE x.id<>d.id AND lower(btrim(coalesce(x.email,'')))=e) THEN RAISE EXCEPTION 'EMAIL_ALREADY_IN_USE'; END IF;
  INSERT INTO public.dealer_email_change_requests(dealer_id,dealer_code,old_email,new_email)
  VALUES(d.id,d.dealer_code,d.email,e) RETURNING id INTO rid;
  RETURN rid;
END
$function$;
REVOKE ALL ON FUNCTION public.request_my_dealer_email_change(text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.request_my_dealer_email_change(text,text,text,text) TO authenticated;
-- Fail closed: remove legacy 2-argument RPC so it cannot bypass device checks.
DROP FUNCTION public.request_my_dealer_email_change(text,text);
COMMIT;
