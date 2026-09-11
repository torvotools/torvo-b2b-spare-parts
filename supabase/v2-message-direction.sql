-- TORVO V2 message direction hardening.
-- read_at means the intended recipient has read the message, never merely the sender.
alter table messages add column if not exists recipient_type text;
update messages m set recipient_type=case when exists(select 1 from app_users u where u.id=m.sender_id and u.role='dealer') then 'internal' else 'dealer' end where recipient_type is null;
alter table messages alter column recipient_type set default 'internal';
alter table messages alter column recipient_type set not null;
alter table messages drop constraint if exists messages_recipient_type_check;
alter table messages add constraint messages_recipient_type_check check(recipient_type in('dealer','internal'));

create or replace function send_dealer_message(p_dealer uuid,p_subject text,p_body text) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v uuid;d uuid;target text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found then raise exception 'Active user required';end if;
 if nullif(trim(p_body),'') is null then raise exception 'Message required';end if;
 if a.role='dealer' then
  d:=current_dealer_id();if d is null then raise exception 'Approved dealer required';end if;target:='internal';
 elsif a.role in('owner','admin','salesman') then
  if p_dealer is null or not exists(select 1 from dealers where id=p_dealer and status='approved') then raise exception 'Approved dealer required';end if;
  d:=p_dealer;target:='dealer';
 else raise exception 'Not authorized';end if;
 insert into messages(dealer_id,sender_id,subject,body,recipient_type) values(d,a.id,nullif(trim(p_subject),''),trim(p_body),target) returning id into v;
 return v;
end;$$;
revoke all on function send_dealer_message(uuid,text,text) from public,anon;grant execute on function send_dealer_message(uuid,text,text) to authenticated;

create or replace function mark_message_read(p_message uuid) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d uuid;m messages%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found then raise exception 'Active user required';end if;
 select * into m from messages where id=p_message for update;if not found then raise exception 'Message not found';end if;
 if a.role='dealer' then
  d:=current_dealer_id();if d is null or m.dealer_id is distinct from d or m.recipient_type<>'dealer' then raise exception 'Only an incoming dealer message can be marked read';end if;
 elsif a.role in('owner','admin','salesman') then
  if m.recipient_type<>'internal' then raise exception 'Only an incoming internal message can be marked read';end if;
 else raise exception 'Not authorized';end if;
 update messages set read_at=coalesce(read_at,now()) where id=p_message;
end;$$;
revoke all on function mark_message_read(uuid) from public,anon;grant execute on function mark_message_read(uuid) to authenticated;
